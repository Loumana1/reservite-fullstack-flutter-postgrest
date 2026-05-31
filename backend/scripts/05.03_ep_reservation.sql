set search_path to public;

drop type if exists reservation_info cascade;
create type reservation_info as
(
    id               integer,
    client           integer,
    restaurant       integer,
    datetime         timestamp,
    number_of_guests integer,
    status           varchar,
    special_requests text,
    restaurant_name  varchar,
    restaurant_city  varchar,
    client_full_name varchar,
    client_email     varchar
);

create or replace function get_reservation(reservation_id integer)
    returns reservation_info as
$$
declare
    result       reservation_info;
    v_role text;
    v_uid  integer;
begin
    perform auth.check_logged();
    v_role := auth.role();
    v_uid  := auth.id()::integer;

    select res.id, res.client, res.restaurant, res.datetime, res.number_of_guests,
           res.status::varchar, res.special_requests,
           rest.name, rest.city,
           u.full_name, u.email
    into result
    from reservations res
             join restaurants rest on rest.id = res.restaurant
             join users u on u.id = res.client
    where res.id = get_reservation.reservation_id
      and (
        (v_role = 'client' and res.client = v_uid)
            or
        (v_role = 'manager' and exists(
            select 1 from restaurant_managers rm
            where rm.restaurant = res.restaurant and rm.manager = v_uid))
        );

    if result.id is null then
        raise exception 'Réservation non trouvée ou accès refusé';
    end if;
    return result;
end;
$$ language plpgsql security definer;

grant execute on function get_reservation(integer) to client, manager;

/* ===== get_reservations =====
- client : ses propres résas (toutes ou filtrées par statut)
- manager : les résas d'un restaurant qu'il gère */
create or replace function get_reservations(restaurant_id integer default null,
                                            status_filter text default null)
    returns setof reservation_info as
$$
declare
    v_role text;
    v_uid  integer;
begin
    perform auth.check_logged();
    v_role := auth.role();
    v_uid  := auth.id()::integer;

    if v_role = 'client' then
    return query
        select res.id, res.client, res.restaurant, res.datetime, res.number_of_guests,
               res.status::varchar, res.special_requests,
               rest.name, rest.city,
               u.full_name, u.email
        from reservations res
                 join restaurants rest on rest.id = res.restaurant
                 join users u on u.id = res.client
        where res.client = v_uid
          and (status_filter is null or res.status::varchar = status_filter)
          and (restaurant_id is null or res.restaurant = restaurant_id)
        order by res.datetime desc, res.id desc;
    else
    return query
        select res.id, res.client, res.restaurant, res.datetime, res.number_of_guests,
               res.status::varchar, res.special_requests,
               rest.name, rest.city,
               u.full_name, u.email
        from reservations res
                 join restaurants rest on rest.id = res.restaurant
                 join users u on u.id = res.client
        where exists(select 1 from restaurant_managers rm
                     where rm.restaurant = res.restaurant and rm.manager = v_uid)
          and (restaurant_id is null or res.restaurant = restaurant_id)
          and (status_filter is null or res.status::varchar = status_filter)
        order by res.datetime desc, res.id desc;
end if;
    end;
$$ language plpgsql security definer;

grant execute on function get_reservations(integer, text) to client, manager;
