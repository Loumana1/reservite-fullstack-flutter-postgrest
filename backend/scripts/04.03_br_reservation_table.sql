-- br03
create or replace function trg_check_tables_insert()
    returns trigger as $$

    declare
        res_restaurant INT;
        res_status VARCHAR;
        tab_restaurant INT;
    begin
        select restaurant, status into res_restaurant, res_status
        from reservations
        where id = NEW.reservation;
        select restaurant INTO tab_restaurant
        from tables
        where id = NEW."table";


        if res_restaurant is distinct from tab_restaurant THEN
            raise exception ' La table  n''appartient pas au même restaurant que la réservation.';
        END IF;


        RETURN NEW;
    END;
$$ LANGUAGE plpgsql;