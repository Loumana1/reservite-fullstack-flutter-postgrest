create or replace function tgr_check_reservation_terminee_ou_annulee()
returns trigger as $$
    begin
        if old.status in ('completed', 'cancelled')
            then raise exception 'BR-11 : Interdit ! Cette reservation est deja % et ne peut plus etre modifiée.', old.status;
        end if;

        return new;
    end;
    $$ language plpgsql;

create or replace trigger trigger_modification_reservation
    before update on reservations
    for each row
    execute  function tgr_check_reservation_terminee_ou_annulee();
