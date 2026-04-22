create or replace function check_reservation_capacity()
returns trigger as $$
    declare
        total_capacity int ;
        res_guests int ;
        res_status text;
        res_restaurant_id int;
        inv_table_count int;
    begin

        select number_of_guests, status , restaurant
        into res_guests , res_status , res_restaurant_id
        from reservations
        where id = new.reservation;

        if res_status in ('confirmed' , 'completed') then
            select count(*) into inv_table_count
            from reservation_tables rt
            join tables t on rt.table = t.id
            where rt.reservation = new.reservation
            and t.restaurant != res_restaurant_id;

            if inv_table_count > 0 then
                raise exception 'plusiers table n''appartiennent pas au restaurant de la reservation !';

            end if;

            select sum(capacity) into total_capacity
            from tables
            where id in (select  "tables" from reservation_tables where reservation = new.reservation)
            or id = new.table;

            if total_capacity < res_guests then
                raise exception 'Capacite insuffusante : % places pour % convives.', total_capacity;
            end if;
        end if;
        return  new ;
    end;
    $$language  plpgsql;

create trigger trigger_check_capacity
    before insert or update  on reservation_tables
    for each row
    execute function check_reservation_capacity();