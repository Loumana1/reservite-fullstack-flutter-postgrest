create  or replace function trg_check_min_manager_on_restaurants()
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

create or replace function trg_check_min_manager_on_managers()
   returns trigger as $$

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
            raise exception 'BR-10 : Un restaurant ne peut pas se retrouver sans manager.';
        end if;
        RETURN NULL;
    end;
    $$language plpgsql;

drop trigger if exists min_manager_on_restaurants on restaurants;
drop trigger if exists min_manager_on_managers on restaurant_managers;

create constraint  trigger min_manager_on_restaurants
    after insert or update  on restaurants
    deferrable initially deferred
for each row execute function trg_check_min_manager_on_restaurants();

create constraint  trigger min_manager_on_managers
  after  delete or update  on restaurant_managers
    deferrable initially deferred
for each row execute function trg_check_min_manager_on_managers();