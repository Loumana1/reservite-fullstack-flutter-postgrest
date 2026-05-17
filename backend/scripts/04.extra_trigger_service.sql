create or replace function trg_check_service_unique_restaurant()

    returns trigger as $$
    begin
        if old.restaurant  is distinct from new.restaurant then
            raise exception 'Le restaurant de associer à service ne peut pas être modifié';
        end if;
    return new;
    end;
    $$ language plpgsql;


create or replace trigger service_unique_restaurant
    before update on services
    for each row execute function trg_check_service_unique_restaurant();