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

drop trigger if exists trigger_table_assigment on reservation_tables;

create constraint trigger trigger_table_assigment
    after insert or update on reservation_tables
    deferrable  initially deferred
    for each row
    execute function tgr_check_reservation_table_for_pending_or_cancelled();