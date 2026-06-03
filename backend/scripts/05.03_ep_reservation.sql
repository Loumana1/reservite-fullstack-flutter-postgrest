set search_path to public;


drop type if exists reservation_info cascade;
drop type if exists table_info cascade;
create type table_info as
(
    id           integer,
    restaurant   integer,
    table_number integer,
    capacity     integer
);

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
    client_email     varchar,
    assigned_tables  table_info[]
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
           u.full_name, u.email,
           coalesce((
               select array_agg(
                          (t.id, t.restaurant, t.table_number, t.capacity)::table_info
                          order by t.capacity, t.table_number)
               from reservation_tables rt
                        join tables t on t.id = rt."table"
               where rt.reservation = res.id
           ), '{}')
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
               u.full_name, u.email,
               coalesce((
                   select array_agg(
                              (t.id, t.restaurant, t.table_number, t.capacity)::table_info
                              order by t.capacity, t.table_number)
                   from reservation_tables rt
                            join tables t on t.id = rt."table"
                   where rt.reservation = res.id
               ), '{}')
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
               u.full_name, u.email,
               coalesce((
                   select array_agg(
                              (t.id, t.restaurant, t.table_number, t.capacity)::table_info
                              order by t.capacity, t.table_number)
                   from reservation_tables rt
                            join tables t on t.id = rt."table"
                   where rt.reservation = res.id
               ), '{}')
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

/* ===== save_reservation  ===== */
create or replace function save_reservation(restaurant_id integer,
                                            datetime timestamp,
                                            number_of_guests integer,
                                            special_requests text default null,
                                            reservation_id integer default null)
    returns reservation_info as
$$
declare
    v_uid integer;
    new_id      integer;
begin
    perform auth.check_logged();
    if auth.role() != 'client' then
        raise exception 'Seuls les clients peuvent créer/modifier une réservation';
    end if;
    v_uid := auth.id()::integer;

    if save_reservation.reservation_id is null then

        insert into reservations (client, restaurant, datetime, number_of_guests,
                                  special_requests, status)
        values (v_uid, save_reservation.restaurant_id, save_reservation.datetime,
                save_reservation.number_of_guests, save_reservation.special_requests,
                'pending'::status_type)
        returning id into new_id;
    else

        update reservations
        set restaurant       = save_reservation.restaurant_id,
            datetime         = save_reservation.datetime,
            number_of_guests = save_reservation.number_of_guests,
            special_requests = save_reservation.special_requests,
            status           = 'pending'::status_type
        where id = save_reservation.reservation_id
          and client = v_uid;

        if not found then
            raise exception 'Réservation non trouvée ou accès refusé';
        end if;

        delete from reservation_tables where reservation = save_reservation.reservation_id;
        new_id := save_reservation.reservation_id;
    end if;

    return get_reservation(new_id);
end;
$$ language plpgsql security definer;

grant execute on function save_reservation(integer, timestamp, integer, text, integer) to client;

/*  cancel_reservation */
create or replace function cancel_reservation(reservation_id integer)
    returns reservation_info as
$$
declare
    v_role text;
    v_uid  integer;
begin
    perform auth.check_logged();
    v_role := auth.role();
    v_uid  := auth.id()::integer;

    update reservations
    set status = 'cancelled'::status_type
    where id = cancel_reservation.reservation_id
      and (
        (v_role = 'client' and client = v_uid)
            or
        (v_role = 'manager' and exists(
            select 1 from restaurant_managers rm
            where rm.restaurant = reservations.restaurant and rm.manager = v_uid))
        );

    if not found then
        raise exception 'Réservation non trouvée ou accès refusé';
    end if;


    delete from reservation_tables where reservation = cancel_reservation.reservation_id;

    return get_reservation(cancel_reservation.reservation_id);
end;
$$ language plpgsql security definer;

grant execute on function cancel_reservation(integer) to client, manager;

/* confirm_reservation */
create or replace function confirm_reservation(reservation_id integer, table_ids int[])
    returns reservation_info as
$$
declare
    v_uid integer;
    tid         integer;
begin
    perform auth.check_logged();
    if auth.role() != 'manager' then
        raise exception 'Seul un manager peut confirmer une réservation';
    end if;
    v_uid := auth.id()::integer;

    if not exists(
        select 1 from reservations res
                          join restaurant_managers rm on rm.restaurant = res.restaurant
        where res.id = confirm_reservation.reservation_id
          and rm.manager = v_uid
    ) then
        raise exception 'Réservation non trouvée ou accès refusé';
    end if;

    update reservations set status = 'confirmed'::status_type
    where id = confirm_reservation.reservation_id;


    delete from reservation_tables where reservation = confirm_reservation.reservation_id;
    if table_ids is not null then
        foreach tid in array table_ids loop
                insert into reservation_tables (reservation, "table")
                values (confirm_reservation.reservation_id, tid);
            end loop;
    end if;

    return get_reservation(confirm_reservation.reservation_id);
end;
$$ language plpgsql security definer;

grant execute on function confirm_reservation(integer, int[]) to manager;

/* complete_reservation (manager : confirmed -> completed) */
create or replace function complete_reservation(reservation_id integer)
    returns reservation_info as
$$
declare
    v_uid integer;
begin
    perform auth.check_logged();
    if auth.role() != 'manager' then
        raise exception 'Seul un manager peut terminer une réservation';
    end if;
    v_uid := auth.id()::integer;

    update reservations set status = 'completed'::status_type
    where id = complete_reservation.reservation_id
      and exists(select 1 from restaurant_managers rm
                 where rm.restaurant = reservations.restaurant
                   and rm.manager = v_uid);

    if not found then
        raise exception 'Réservation non trouvée ou accès refusé';
    end if;
    return get_reservation(complete_reservation.reservation_id);
end;
$$ language plpgsql security definer;

grant execute on function complete_reservation(integer) to manager;
