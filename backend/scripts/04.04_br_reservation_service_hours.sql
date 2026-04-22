

create or replace  function trg_check_reservation_service_hours() returns trigger as $$
declare
    res_day_of_week INT;
    res_time TIME;
    service_exists BOOLEAN;
    day_name TEXT ;

begin

    day_name := TO_CHAR(NEW.datetime, 'FMDay');

    if day_name = 'Monday'      then  res_day_of_week := 1; end if;
    if day_name = 'Tuesday'   then res_day_of_week := 2; end if;
    if day_name = 'Wednesday' then res_day_of_week := 3; end if;
    if day_name = 'Thursday' then res_day_of_week := 4; end if;
    if  day_name = 'Friday'   then res_day_of_week := 5; end if;
    if day_name = 'Saturday'  then res_day_of_week := 6; end if;
    if day_name = 'Sunday'   then  res_day_of_week := 7; end if;

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

create constraint trigger br_04_res_service_hours
    before insert or  update
    on reservations
    for each row execute function trg_check_reservation_service_hours();