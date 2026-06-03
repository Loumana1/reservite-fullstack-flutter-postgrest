create or replace function tgr_check_reservation_capacity()
returns trigger as $$
    declare
        total_capacity int ;
        res_guests int ;
        res_status varchar;
        res_id int;

    begin
        if tg_table_name = 'reservations' then
            res_id:= new.id ;
            res_guests := new.number_of_guests;
            res_status := new.status;
        elsif tg_table_name = 'reservation_tables' then

            if tg_op = 'delete' then
                res_id:=old.reservation;
                else
               res_id:= new.reservation;
            end if;


            select number_of_guests, status into res_guests , res_status
            from reservations
            where id = res_id;
        elsif tg_table_name = 'tables' then
            return null;
        end if;


             if res_status in ('confirmed' , 'completed') then
                select coalesce(sum(capacity),0) into total_capacity
                from tables t join reservation_tables rt on t.id = rt."table"
                where rt.reservation =res_id;

                if total_capacity < res_guests then
                    raise exception '(BR-2 : Capacite insuffusante : % places pour % convives.', total_capacity , res_guests;
                end if;
            end if;
        return  null ;
    end;
    $$language  plpgsql;


drop trigger if exists trigger_check_capacity on reservation_tables;
drop trigger if exists trigger_check_capacity on reservations;

create constraint trigger  trigger_check_capacity
   after insert or update  on reservations
    deferrable  initially deferred
    for each row execute function tgr_check_reservation_capacity();



create constraint trigger trigger_check_capacity
    after insert or update or delete on reservation_tables
    deferrable initially deferred
    for each row execute function tgr_check_reservation_capacity();
