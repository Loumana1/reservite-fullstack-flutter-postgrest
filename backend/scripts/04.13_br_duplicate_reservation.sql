create or replace function tgr_check_duplicate_reservation()
returns trigger as $$
    begin
        if exists(
            select 1
            from reservations r
            join services s on r.restaurant = s.restaurant
            and extract(dow from r.datetime) = s.day_of_week
            where r.client = new.client
            and r.id != new.id
            and r.status in ('pending', 'confirmed', 'completed')
            and r.datetime::date = new.datetime::date
            and new.datetime::time >= s.start_time and new.datetime::time < s.end_time
            and r.datetime::time >= s.start_time and r.datetime::time < s.end_time
        )then raise exception 'Client a deja une reservation active pour ce service ce jour-la ';
        end if;

        return new;
    end;
    $$language  plpgsql;



create trigger trigger_duplicate_reservation
    before insert or update on reservations
    for each row
    execute function tgr_check_duplicate_reservation();