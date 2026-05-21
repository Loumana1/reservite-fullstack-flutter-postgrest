create or replace function tgr_check_reservation_no_client_duplicate()
returns trigger as $$
    declare
    current_service_id int;
    conflict_exists boolean;
    begin
        if new.status = 'cancelled' then
            return new;
        end if;

        current_service_id:=get_service_for_reservation(NEW.restaurant, NEW.datetime);


        select  exists(
            select 1
            from reservations r
            where r.client = new.client
            and r.id != coalesce(new.id, -1)
            and r.status != 'cancelled'
            and r.datetime::date = new.datetime::date
            and get_service_for_reservation(r.restaurant, r.datetime)
                    = current_service_id
        )into conflict_exists;

        if conflict_exists then
        raise exception 'Client a deja une reservation active pour ce service ce jour-la ';
        end if;

        return new;
    end;
    $$language  plpgsql;



create or replace trigger trigger_duplicate_reservation
    before insert or update on reservations
    for each row
    execute function tgr_check_reservation_no_client_duplicate();