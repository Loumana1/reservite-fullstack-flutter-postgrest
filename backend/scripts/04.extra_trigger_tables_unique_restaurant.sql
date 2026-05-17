
create or replace function trg_check_table_unique_restaurant()

returns trigger as $$
    begin
        if old.restaurant is distinct from new.restaurant then
            raise exception 'Le restaurant de cette table ne pas être modifié';
        end if;
        return new;
    end;
    $$ language plpgsql;

create or replace trigger table_unique_restaurant
    before update on tables
    for each row
execute function trg_check_table_unique_restaurant();