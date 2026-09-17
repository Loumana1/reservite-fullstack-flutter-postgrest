
drop trigger if exists modification_reservation on reservations;
drop function if exists trg_check_modification_reservation();

create or replace function trg_check_modification_reservation()
    returns trigger as $$
begin
    if old.restaurant is distinct
        from new.restaurant then
        raise exception 'Impossible de modifier le restaurant d''une réservation.';

end if;



    if old.client is distinct
        from new.client then

        raise exception 'Impossible de modifier le client d''une réservation.';
end if;

return new;
end;
$$ language plpgsql;

create or replace trigger modification_reservation
    before update on reservations
 for each row execute function trg_check_modification_reservation();
