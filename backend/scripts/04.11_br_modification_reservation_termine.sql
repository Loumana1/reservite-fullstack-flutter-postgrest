create or replace function tgr_check_modification_reservation()
returns trigger as $$
    begin
        if old.status in ('completed', 'cancelled')
            then raise exception 'Interdit ! Cette reservation est deja % et ne peut plus etre touche. ', old.status;
        end if;

        return new;
    end;
    $$ language plpgsql;

create or replace trigger trigger_modification_reservation
    before update on reservations
    for each row
    execute  function tgr_check_modification_reservation();
