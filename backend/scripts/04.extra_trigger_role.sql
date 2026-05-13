--************************************************************************************************************************************************
                                                            --USERS--
--************************************************************************************************************************************************

create or replace function modification_role()

returns trigger as $$
    begin
        if old.role != new.role then
            raise exception 'The role of a user cannot be changed';
        end if;
        return new;
    end;
    $$ language plpgsql;

create or replace trigger modification_role
    before update on users
    for each row
execute function modification_role();