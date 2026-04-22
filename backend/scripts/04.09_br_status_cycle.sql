create or replace function tgr_check_status_cycle()
returns trigger as $$
    begin

    end;
    $$ language plpgsql;

create trigger trigger_status_cycle
    before insert or update on reservations
    for each row
    execute function tgr_check_status_cycle();