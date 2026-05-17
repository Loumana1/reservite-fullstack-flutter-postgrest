create or replace function tgr_check_reservation_table_for_pending_or_cancelled()
returns trigger as $$
    begin
        if exists(
            select 1
            from reservations
            where id = new.reservation
            and status in ('pending' , 'cancelled')
        ) then raise exception 'On ne peut pas assigner de table à une reservation en attente ou annulée.';
        end if;

        return new;
    end;
    $$ language plpgsql;

create or replace trigger trigger_table_assigment
    before insert or update on reservation_tables
    for each row
    execute function tgr_check_reservation_table_for_pending_or_cancelled()