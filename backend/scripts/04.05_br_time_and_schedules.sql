CREATE OR REPLACE FUNCTION is_aligned_on_slot(time_val TIMESTAMP, slot_mins INT)
       RETURNS BOOLEAN AS $$
BEGIN
RETURN (EXTRACT(MINUTE FROM time_val)::INTEGER % slot_mins) = 0
    AND EXTRACT(SECOND FROM time_val) = 0;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION is_time_aligned_on_slot(time_val TIME, slot_mins INT)
       RETURNS BOOLEAN AS $$
    BEGIN
    RETURN (EXTRACT(MINUTE FROM time_val)::INTEGER % slot_mins) = 0
        AND EXTRACT(SECOND FROM time_val) = 0;
    END;
    $$ LANGUAGE plpgsql;


       --Br 4 heure de res aligné sur creneau
       --Br 5 here de res inclus dans servie du jour


CREATE OR REPLACE FUNCTION trg_check_br04_br05_reservation_time() RETURNS TRIGGER AS $$
DECLARE
res_slot_duration INT;
    res_day_of_week INT;
    res_time TIME;
    service_exists BOOLEAN;
   day_name TEXT ;
BEGIN

SELECT slot_duration INTO res_slot_duration FROM restaurants WHERE id = NEW.restaurant;

--Br 5
IF NOT is_aligned_on_slot(NEW.datetime, res_slot_duration) THEN
        RAISE EXCEPTION 'L''heure de la réservation n''est pas alignée sur la durée des créneaux du restaurant .', res_slot_duration;
END IF;

    -- -br4
    day_name := TO_CHAR(NEW.datetime, 'FMDay');

    IF day_name = 'Monday'      THEN res_day_of_week := 1; END IF;
    IF day_name = 'Tuesday'   THEN res_day_of_week := 2; END IF;
    IF day_name = 'Wednesday' THEN res_day_of_week := 3; END IF;
    IF day_name = 'Thursday'  THEN res_day_of_week := 4; END IF;
    IF day_name = 'Friday'   THEN res_day_of_week := 5; END IF;
    IF day_name = 'Saturday'  THEN res_day_of_week := 6; END IF;
    IF day_name = 'Sunday'   THEN res_day_of_week := 7; END IF;

    res_time := NEW.datetime::TIME;

SELECT EXISTS (
    SELECT 1 FROM services
    WHERE restaurant = NEW.restaurant
      AND day_of_week = res_day_of_week
      AND res_time >= start_time
      AND res_time < end_time
) INTO service_exists;


IF NOT service_exists AND NEW.status != 'cancelled' THEN
        RAISE EXCEPTION 'L''heure de réservation ne correspond à aucun service ouvert.';
END IF;

RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER br_04_05_res_time
    BEFORE INSERT OR UPDATE ON reservations
FOR EACH ROW EXECUTE FUNCTION trg_check_br04_br05_reservation_time();
