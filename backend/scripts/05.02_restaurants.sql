set search_path to public;

/* restaurant_info */
drop type if exists restaurant_info cascade;
create type restaurant_info as
(
    id                     integer,
    name                   varchar,
    address                varchar,
    city                   varchar,
    phone                  varchar,
    description            text,
    rating                 double precision,
    price_range            integer,
    slot_duration          integer,
    last_reservation_date  timestamp,
    pending_requests       integer
);

/*   get_restaurants (recherche + limite)
   - client : tous les restaurants (avec compteurs personnels)
   - manager : uniquement ses restaurants */
create or replace function get_restaurants(search_filter text default null,
                                           limit_count integer default 20)
    returns setof restaurant_info as
$$
declare
    v_role text;
    v_uid  integer;
    filter_text  text;
begin
    perform auth.check_logged();
    v_role := auth.role();
    v_uid  := auth.id()::integer;
    filter_text  := nullif(trim(coalesce(search_filter, '')), '');

    if v_role = 'client' then
    return query
        select r.id, r.name, r.address, r.city, r.phone, r.description,
               r.rating, r.price_range, r.slot_duration,
               (select max(res.datetime) from reservations res
                where res.restaurant = r.id and res.client = v_uid)
                   as last_reservation_date,
               (select count(*)::int from reservations res
                where res.restaurant = r.id and res.client = v_uid
                  and res.status = 'pending'::status_type)
                   as pending_requests
        from restaurants r
        where filter_text is null
           or r.name ilike '%' || filter_text || '%'
           or r.city ilike '%' || filter_text || '%'
        order by r.name
        limit limit_count + 1;
    else
    return query
        select r.id, r.name, r.address, r.city, r.phone, r.description,
               r.rating, r.price_range, r.slot_duration,
               (select max(res.datetime) from reservations res where res.restaurant = r.id)
                   as last_reservation_date,
               (select count(*)::int from reservations res
                where res.restaurant = r.id and res.status = 'pending'::status_type)
                   as pending_requests
        from restaurants r
        where exists(select 1 from restaurant_managers rm
                     where rm.restaurant = r.id and rm.manager = v_uid)
          and (filter_text is null
            or r.name ilike '%' || filter_text || '%'
            or r.city ilike '%' || filter_text || '%')
        order by r.name
        limit limit_count + 1;
end if;
    end;
$$ language plpgsql security definer;

grant execute on function get_restaurants(text, integer) to client, manager;

/* get_restaurant (détail) */
create or replace function get_restaurant(restaurant_id integer)
    returns restaurant_info as
$$
declare
    result       restaurant_info;
    v_role text;
    v_uid  integer;
begin
    perform auth.check_logged();
    v_role := auth.role();
    v_uid  := auth.id()::integer;

    -- contrôle d'accès manager
    if v_role = 'manager' and not exists(
        select 1 from restaurant_managers rm
        where rm.restaurant = get_restaurant.restaurant_id and rm.manager = v_uid
        ) then
    raise exception 'Accès refusé';
end if;

    select r.id, r.name, r.address, r.city, r.phone, r.description,
           r.rating, r.price_range, r.slot_duration,
           (select max(res.datetime) from reservations res
            where res.restaurant = r.id
              and (v_role = 'manager' or res.client = v_uid)),
           (select count(*)::int from reservations res
            where res.restaurant = r.id and res.status = 'pending'::status_type
              and (v_role = 'manager' or res.client = v_uid))
    into result
    from restaurants r
    where r.id = get_restaurant.restaurant_id;

    if result.id is null then
        raise exception 'Restaurant non trouvé';
    end if;
    return result;
end;
$$ language plpgsql security definer;

grant execute on function get_restaurant(integer) to client, manager;