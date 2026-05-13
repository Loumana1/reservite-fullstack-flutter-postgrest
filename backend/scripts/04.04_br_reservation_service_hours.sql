

create or replace  function trg_check_reservation_service_hours() returns trigger as $$
declare
    res_day_of_week INT;
    res_time TIME;
    service_exists BOOLEAN;

begin

    res_day_of_week := EXTRACT(ISODOW FROM NEW.datetime)::INT;
    res_time := NEW.datetime::TIME;

    select EXISTS (
        select 1 from services
        where restaurant = new.restaurant
          and day_of_week = res_day_of_week
          and res_time >= start_time
          and res_time < end_time
    ) INTO service_exists;


    if not service_exists and NEW.status != 'cancelled' then
        raise exception 'L''heure de réservation ne correspond à aucun service ouvert.';
    end if;

    return NEW;
end;
$$ language plpgsql;

create or replace trigger br_04_reservation_service_hours
    before insert or update on reservations
    for each row execute function trg_check_reservation_service_hours();