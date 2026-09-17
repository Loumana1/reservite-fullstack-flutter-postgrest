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
    is_sponsored           boolean,
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
               r.rating, r.price_range, r.slot_duration,r.is_sponsored,
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
           or r.description ilike '%' || filter_text || '%'
        order by r.name
        limit limit_count + 1;
    else
    return query
        select r.id, r.name, r.address, r.city, r.phone, r.description,
               r.rating, r.price_range, r.slot_duration,is_sponsored,
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
        order by last_reservation_date desc nulls last, r.name
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
           r.rating, r.price_range, r.slot_duration,is_sponsored,
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


create or replace function update_sponsor(restaurant_id integer, sponsor_state boolean)
returns restaurant_info as
    $$
declare
    v_uid integer;
begin
    -- (1) il faut être connecté
    perform auth.check_logged();
    v_uid := auth.id()::integer;

    -- (2) le restaurant doit exister
    if not exists(select 1 from restaurants where id = update_sponsor.restaurant_id) then
        raise exception 'Restaurant non trouvé';
    end if;

    -- (3) l'utilisateur connecté doit être manager du restaurant
    if not exists(
        select 1 from restaurant_managers rm
        where rm.restaurant = update_sponsor.restaurant_id
          and rm.manager = v_uid
    ) then
        raise exception 'Accès refusé : vous n''êtes pas manager de ce restaurant';
    end if;

    -- (4) pour sponsoriser, il faut au moins une réservation confirmée ou complétée
    -- (cette condition ne s'applique pas lorsqu'on retire le sponsoring)
    if sponsor_state and not exists(
        select 1 from reservations res
        where res.restaurant = update_sponsor.restaurant_id
          and res.status in ('confirmed', 'completed')
    ) then
        raise exception 'Le restaurant doit avoir au moins une réservation confirmée ou complétée pour être sponsorisé';
    end if;

    update restaurants
    set is_sponsored = sponsor_state
    where id = update_sponsor.restaurant_id;

    return get_restaurant(update_sponsor.restaurant_id);
end;
    $$language plpgsql security definer ;

grant execute on function update_sponsor(integer, boolean) to manager;