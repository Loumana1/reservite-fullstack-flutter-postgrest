
create or replace function trg_check_table_conflict()
    returns trigger as $$
    declare
        res_id INT;
        tab_id INT;
        current_status VARCHAR;
        current_datetime TIMESTAMP;
        current_service_id INT;
        conflict_count INT;
    begin
        conflict_count := 0 ;
    if TG_TABLE_NAME = 'reservations' then
        res_id := NEW.id;
        current_status := NEW.status;
        current_datetime := NEW.datetime;
        -- en cours ou cancelled ?
        if current_status not in ('confirmed', 'completed') then
           return new;
        END IF;

        current_service_id := get_service_for_reservation(NEW.restaurant, current_datetime);

        --  conflit ?
        select COUNT(*) into conflict_count
        from reservation_tables rt1
                 join reservation_tables rt2 ON rt1."table" = rt2."table"
                 join reservations r2 ON rt2.reservation = r2.id
        where rt1.reservation = res_id
          AND r2.id != res_id
          AND r2.status IN ('confirmed', 'completed')
          AND r2.datetime::DATE = current_datetime::DATE
          AND get_service_for_reservation(r2.restaurant, r2.datetime) = current_service_id;

    elsif TG_TABLE_NAME = 'reservation_tables' THEN
        res_id := NEW.reservation;
        tab_id := NEW."table";

        select status, datetime INTO current_status, current_datetime
        from reservations
        where id = res_id;
        if current_status not in ('confirmed', 'completed') then
            RETURN new;
        END IF;

        current_service_id := get_service_for_reservation((SELECT restaurant FROM reservations WHERE id = res_id), current_datetime);

        SELECT COUNT(*) INTO conflict_count
        FROM reservation_tables rt2
                 JOIN reservations r2 ON rt2.reservation = r2.id
        WHERE rt2."table" = tab_id
          AND r2.id != res_id
          AND r2.status IN ('confirmed', 'completed')
          AND r2.datetime::DATE = current_datetime::DATE
          AND get_service_for_reservation(r2.restaurant, r2.datetime) = current_service_id;
    END IF;

    IF conflict_count > 0 THEN
        RAISE EXCEPTION 'BR-6 : La table est déjà réservée  à cette date.';
    END IF;

    RETURN new;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS br_06_table_conflict_res ON reservations;

CREATE or replace TRIGGER br_06_table_conflict_res
   before insert OR UPDATE ON reservations

    FOR EACH ROW EXECUTE FUNCTION trg_check_table_conflict();

DROP TRIGGER IF EXISTS br_06_table_conflict_rt ON reservation_tables;

CREATE or replace TRIGGER br_06_table_conflict_rt
    before insert OR UPDATE ON reservation_tables

    FOR EACH ROW EXECUTE FUNCTION trg_check_table_conflict();
