--************************************************************************************************************************************************
                                                             --RESERVATION--
--************************************************************************************************************************************************

create or replace function tgr_reservation_client_role()
returns trigger as $$
    begin
        if exists(
          select 1
          from users
          where id = new.client
            and role = 'client'
        ) then
            return new ;
        else
            raise exception 'BR-1 : Une réservation doit appartenir à un client.';
        end if;
    end;
    $$ language plpgsql;

create or replace trigger trigger_reservation_client_role
    before insert or update on reservations
    for each row
execute function tgr_reservation_client_role();