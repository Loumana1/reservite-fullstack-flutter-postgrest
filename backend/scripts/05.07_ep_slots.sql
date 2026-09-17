set search_path to public, auth;

drop type if exists slot_info cascade;
create type slot_info as
(
    datetime         timestamp,
    service_id       integer,
    available        boolean,
    capacity_left    integer
);

drop type if exists slots_response cascade;
create type slots_response as
(
    slots                  slot_info[],
    restaurant_closed      boolean,
    user_fully_booked      boolean
);
create or replace function get_available_slots(restaurant_id integer,
                                               target_date date,
                                               exclude_reservation_id integer default null)
    returns slots_response as
$$
declare
    v_uid           integer;
    v_now           timestamp;
    v_dow           integer;
    v_slot_duration integer;
    v_services_today integer;
    v_user_resas    integer;
    v_result        slots_response;
    v_slots         slot_info[] := '{}';
    v_service       record;
    v_slot_time     timestamp;
    v_capacity_left integer;
begin
    perform auth.check_logged();
    v_uid := auth.id()::integer;
    v_now := get_current_time();

    select slot_duration into v_slot_duration
    from restaurants where id = restaurant_id;
    if not found then
        raise exception 'Restaurant non trouvé';
    end if;

    v_dow := extract(isodow from target_date)::integer;

    -- nombre de services ouverts ce jour
    select count(*) into v_services_today
    from services s
    where s.restaurant = restaurant_id and s.day_of_week = v_dow;

    if v_services_today = 0 then
        v_result.slots := '{}';
        v_result.restaurant_closed := true;
        v_result.user_fully_booked := false;
        return v_result;
    end if;

    -- nombre de services déjà couverts par les résas actives du client
    select count(distinct s.id) into v_user_resas
    from services s
             join reservations r on r.restaurant = s.restaurant
        and date(r.datetime) = target_date
        and r.client = v_uid
        and r.status in ('pending'::status_type, 'confirmed'::status_type)
        and (exclude_reservation_id is null or r.id != exclude_reservation_id)
        and r.datetime::time >= s.start_time
        and r.datetime::time < s.end_time
    where s.restaurant = restaurant_id and s.day_of_week = v_dow;

    if v_user_resas >= v_services_today then
        v_result.slots := '{}';
        v_result.restaurant_closed := false;
        v_result.user_fully_booked := true;
        return v_result;
    end if;

    -- génération des créneaux
    for v_service in
        select id, start_time, end_time
        from services
        where restaurant = restaurant_id and day_of_week = v_dow
        order by start_time
        loop
            v_slot_time := target_date + v_service.start_time;

            while v_slot_time::time < v_service.end_time loop
                    -- Ignorer les créneaux passés (par rapport au temps simulé)
                    if v_slot_time >= v_now
                        and not exists(
                            select 1 from reservations r
                            where r.restaurant = restaurant_id
                              and r.client = v_uid
                              and r.datetime = v_slot_time
                              and r.status in ('pending'::status_type, 'confirmed'::status_type)
                              and (exclude_reservation_id is null or r.id != exclude_reservation_id)
                        )
                    then
                        v_capacity_left := coalesce((
                                                        select sum(t.capacity)::integer
                                                        from tables t
                                                        where t.restaurant = restaurant_id
                                                          and t.id not in (
                                                            select rt."table"
                                                            from reservation_tables rt
                                                                     join reservations r on r.id = rt.reservation
                                                            where r.restaurant = restaurant_id
                                                              and r.datetime = v_slot_time
                                                              and r.status = 'confirmed'::status_type
                                                              and (exclude_reservation_id is null or r.id != exclude_reservation_id)
                                                        )
                                                    ), 0);

                        v_slots := array_append(v_slots, ROW(
                            v_slot_time,
                            v_service.id,
                            v_capacity_left > 0,
                            v_capacity_left
                            )::slot_info);
                    end if;

                    v_slot_time := v_slot_time + (v_slot_duration || ' minutes')::interval;
                end loop;
        end loop;

    v_result.slots := v_slots;
    v_result.restaurant_closed := false;
    v_result.user_fully_booked := false;
    return v_result;
end;
$$ language plpgsql security definer;

grant execute on function get_available_slots(integer, date, integer) to client, manager;


/*
   check_capacity(restaurant_id, target_datetime, guests, exclude_reservation_ */
create or replace function check_capacity(restaurant_id integer,
                                          target_datetime timestamp,
                                          guests integer,
                                          exclude_reservation_id integer default null)
    returns boolean as
$$
declare
    v_capacity_left integer;
begin
    perform auth.check_logged();

    select coalesce(sum(t.capacity), 0)::integer into v_capacity_left
    from tables t
    where t.restaurant = restaurant_id
      and t.id not in (
        select rt."table"
        from reservation_tables rt
                 join reservations r on r.id = rt.reservation
        where r.restaurant = restaurant_id
          and r.datetime = target_datetime
          and r.status = 'confirmed'::status_type
          and (exclude_reservation_id is null or r.id != exclude_reservation_id)
    );

    return v_capacity_left >= guests;
end;
$$ language plpgsql security definer;

grant execute on function check_capacity(integer, timestamp, integer, integer) to client, manager;