-- br03
create or replace function trg_check_reservation_table_same_restaurant()
    returns trigger as $$

    declare
        res_restaurant INT;
        tab_restaurant INT;
    begin
        select restaurant into res_restaurant
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

create or replace trigger br_03_tables_same_restaurant
    before insert or update on reservation_tables
    for each row execute function trg_check_reservation_table_same_restaurant();