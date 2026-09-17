create or replace function trigger_restaurant_sponsored()
returns trigger as
    $$
    begin

        if not ( (select count(*)
            from restaurants r
            where r.id = new.id
              and r.is_sponsored = true) <= 3 )
        then raise exception
            'le restaurant a deja attien le nom ma de sponsoring' ;
        end if;

        return new;

    end;

    $$language plpgsql;

create or replace trigger restaurant_sponsored
    before update on restaurants
    for each row execute function trigger_restaurant_sponsored();
