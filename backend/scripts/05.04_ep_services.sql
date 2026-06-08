set search_path to public, auth;

drop type if exists service_info cascade;
create type service_info as
(
    id          integer,
    restaurant  integer,
    day_of_week integer,
    start_time  time,
    end_time    time
);

/*  get_services  */
create or replace function get_services(restaurant_id integer)
    returns setof service_info as
$$
begin
    perform auth.check_logged();
    return query
        select s.id, s.restaurant, s.day_of_week, s.start_time, s.end_time
        from services s
        where s.restaurant = get_services.restaurant_id
        order by s.day_of_week, s.start_time;
end;
$$ language plpgsql security definer;

grant execute on function get_services(integer) to client, manager;

/*  save_service */
create or replace function save_service(restaurant_id integer,
                                        day_of_week integer,
                                        start_time time,
                                        end_time time,
                                        service_id integer default null)
    returns service_info as
$$
declare
    result      service_info;
    current_uid integer;
    new_id      integer;
begin
    perform auth.check_logged();
    if auth.role() != 'manager' then
        raise exception 'Seul un manager peut gérer les services';
    end if;
    current_uid := auth.id()::integer;

    if not exists(select 1 from restaurant_managers rm
                  where rm.restaurant = save_service.restaurant_id
                    and rm.manager = current_uid) then
        raise exception 'Accès refusé sur ce restaurant';
    end if;

    if save_service.service_id is not null and exists (
        select 1
        from reservations r
                 join services s on s.id = save_service.service_id
        where r.restaurant = s.restaurant
          and r.status in ('pending', 'confirmed')

          and extract(isodow from r.datetime)::int = s.day_of_week
          and r.datetime::time >= s.start_time
          and r.datetime::time <  s.end_time

          and (
            extract(isodow from r.datetime)::int <> save_service.day_of_week
                or r.datetime::time <  save_service.start_time
                or r.datetime::time >= save_service.end_time
            )
    ) then
        raise exception
            'Modification impossible : des réservations en attente ou confirmées seraient en dehors des horaires du service.';
    end if;

    if save_service.service_id is null then
        insert into services (restaurant, day_of_week, start_time, end_time)
        values (save_service.restaurant_id, save_service.day_of_week,
                save_service.start_time, save_service.end_time)
        returning id into new_id;
    else
        update services
        set restaurant  = save_service.restaurant_id,
            day_of_week = save_service.day_of_week,
            start_time  = save_service.start_time,
            end_time    = save_service.end_time
        where id = save_service.service_id;
        new_id := save_service.service_id;
    end if;

    select s.id, s.restaurant, s.day_of_week, s.start_time, s.end_time
    into result from services s where s.id = new_id;
    return result;
end;
$$ language plpgsql security definer;

grant execute on function save_service(integer, integer, time, time, integer) to manager;

/*  delete_service  */
create or replace function delete_service(service_id integer)
    returns void as
$$
declare
    current_uid integer;
begin
    perform auth.check_logged();
    if auth.role() != 'manager' then
        raise exception 'Accès refusé';
    end if;
    current_uid := auth.id()::integer;



    if exists (
        select 1
        from reservations r
                 join services s on s.id = delete_service.service_id
        where r.restaurant = s.restaurant
          and r.status in ('pending', 'confirmed')
          and extract(isodow from r.datetime)::int = s.day_of_week
          and r.datetime::time >= s.start_time
          and r.datetime::time <  s.end_time
    ) then
        raise exception
            'Impossible de supprimer ce service : des réservations non annulées utilisent ce service' ;
    end if;
end;
$$ language plpgsql security definer;

grant execute on function delete_service(integer) to manager;

