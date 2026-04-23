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

create or replace function tgr_check_status_cycle()
returns trigger as $$
    begin
      if old.status = new.status
          then return new;
      end if;

      if old.status = 'pending' then

          if new.status not in ('confirmed', 'cancelled')

              then raise exception 'Depuis pending, seul confirmed ou cancelled est autorise';

              end if;

          elseif old.status = 'confirmed' then

              if new.status = 'pending' then

                if new.datetime <= get_time()

                    then raise exception 'Retour au status pending impossible car la reservation est dans le passe ou en cours.';

                    end if;
            else if new.status not in ('completed' , 'canceled')

                then raise exception 'Depuis confirmed, seul completed, cancelled ou pending';

                end if;

            end if;

            return new;

            end if;
    end;
    $$ language plpgsql;

create trigger trigger_status_cycle
    before update on reservations
    for each row
    execute function tgr_check_status_cycle();