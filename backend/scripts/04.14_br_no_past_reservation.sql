


create or replace function trg_check_reservation_to_past()
    returns trigger as $$
begin
    if new.datetime < get_current_time() then
        raise exception 'impossible de creer ou delacer une reservation dans le passé';
    end if ;
    return new;
end;
$$language plpgsql;

create or replace trigger reservation_to_past
    before insert on reservations
    for each row execute function trg_check_reservation_to_past()