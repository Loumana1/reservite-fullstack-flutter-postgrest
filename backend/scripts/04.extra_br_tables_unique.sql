--********************************************************************************************************************************************
                                                        --TABLES--
--********************************************************************************************************************************************

--pas offiellment un br,  vient de completer les contraites checks table
create or replace function table_unique_restaurant()

returns trigger as $$
    begin
        if old.restaurant != new.restaurant then
            raise exception 'The restaurant of the table cannot be changed';
        end if;
        return new;
    end;
    $$ language plpgsql;

create trigger table_unique_restaurant
    before update on tables
    for each row
execute function table_unique_restaurant();