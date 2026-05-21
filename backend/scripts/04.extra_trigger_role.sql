--************************************************************************************************************************************************
                                                            --USERS--
--************************************************************************************************************************************************

create or replace function trg_check_modification_role()

returns trigger as $$
    begin
        if old.role is distinct from new.role then
            raise exception 'Modification du role interdite';
        end if;
        return new;
    end;
    $$ language plpgsql;

create or replace trigger modification_role
    before update on users
    for each row
execute function trg_check_modification_role();