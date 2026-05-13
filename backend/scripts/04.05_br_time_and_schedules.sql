


create or replace function trg_check_reservation_slot_ok()
    returns trigger as $$
    declare
    res_slot_duration INT;

    begin

        select slot_duration into res_slot_duration from restaurants where id = NEW.restaurant;

        if not is_aligned_on_slot(NEW.datetime, res_slot_duration) THEN
                RAISE EXCEPTION 'L''heure de la réservation n''est pas alignée sur la durée des créneaux du restaurant .';
        end if;

        return NEW;
    end;
$$ language plpgsql;

create trigger br_05_reservation_slot_ok
    before insert or update on reservations
    for each row execute function trg_check_reservation_slot_ok();
