create  or replace function trg_check_restaurant_mananger_count()
    returns trigger as $$
    declare
        manager_count INT;
    begin
        select count(*) into manager_count
        from restaurant_managers
        where restaurant = new.id;

        if manager_count<1 then
            raise exception 'le restaurant % doit avoir un manager min 1 manager', NEW.id;
            end if;
    return null;


    end;
    $$language plpgsql;

create or replace function trg_check_on_managers_count()
   returns trigger as $$
    declare
        manager_count INT;
        res_id INT;
    begin

        if (old.restaurant is not null and not exists(
            select 1
            from restaurant_managers
            where restaurant = old.restaurant)
        )
               OR

        (new.restaurant is not  null and not exists(
            select 1
            from restaurant_managers
            where restaurant= new.restaurant)

            )
        then
            raise exception 'Min 1 manager necessaire pour valider un restaurant';
        end if;

    end;
    $$language plpgsql;

create constraint  trigger min_manager_restaurants
    after insert or update  on restaurants
    deferrable initially deferred
for each row execute function trg_check_restaurant_mananger_count();

create constraint  trigger min_manager_min_managers
  after  delete or update  on restaurants
    deferrable initially deferred
for each row execute function trg_check_on_managers_count();