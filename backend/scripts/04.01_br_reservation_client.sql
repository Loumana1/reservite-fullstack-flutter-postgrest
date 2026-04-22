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
            raise exception 'Reservation must be linked to a user with role client';
        end if;
    end;
    $$ language plpgsql;

create trigger trigger_reservation_client_role
    before insert or update on reservations
    for each row
execute function tgr_reservation_client_role();