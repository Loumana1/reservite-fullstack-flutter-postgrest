create or replace function trg_check_reservation_status_transitions()
       returns trigger as $$
       begin

           if tg_op = 'insert' then
               if new.status != 'pending' then
                   raise exception 'BR-9 : Une nouvelle réservation doit être créée avec le statut "en attente".';
               end if;
               return new;
           end if;

        if old.status = new.status
        then
           return new;
        end if ;

        if old.status = 'pending' then

              if new.status not in ('confirmed', 'cancelled')
              then
                raise exception 'BR-9 : Une reservation en attente ne peu être que : confirmée ou annulée';
              end if;

        elsif old.status = 'confirmed'
        then
              if new.status = 'pending'
              then
                    if new.datetime<= get_current_time()
                    then
                        raise exception 'BR-9 : Retour au statut en attente impossible car la réservation est dans le passé ou en cours.';
                    end if;

              end if;
        end if;
        return new;
end ;

$$ language plpgsql;

create or replace trigger trigger_reservation_status_transitions
before insert or update on reservations
for each row execute function trg_check_reservation_status_transitions();

