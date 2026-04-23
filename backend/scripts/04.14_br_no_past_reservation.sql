create or replace function get_time()
    returns timestamp as $$
    declare
        simul_time timestamp;

    begin
        select simulated_time into simul_time
        from system_time LIMIT 1;

        if simul_time is not null then
            return simul_time;
        end if;

        return current_timestamp;

end;
$$language plpgsql;


create or replace function trg_check_reservation_to_past()
    returns trigger as $$
begin
    if new.datetime < get_time() then
        raise exception 'impossible de creer ou delacer une reservation dans le passé';
    end if ;
    return new;
end;
$$language plpgsql;

create trigger reservation_to_past
    before insert on reservations
    for each row execute function trg_check_reservation_to_past()