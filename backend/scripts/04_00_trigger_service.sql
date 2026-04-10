create or replace function service_unique_restaurant()

    returns trigger as $$
    begin
        if old.restaurant  != new.restaurant then
            raise exception 'the restaurant of the service can not be changed';
        end if;

    end;
    $$ language plpgsql;


create trigger service_unique_restaurant
    before update on services
    for each row

    execute function service_unique_restaurant();