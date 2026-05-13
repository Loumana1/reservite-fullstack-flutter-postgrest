create or replace function tgr_check_service_overlap()
returns trigger as $$
    begin
        if exists(
            select 1
            from services
            where restaurant = new.restaurant
            and day_of_week = new.day_of_week
            and id != new.id
            and new.start_time < end_time
            and new.end_time > start_time
        ) then
            raise exception 'Le service chevauche un autre service existant pour ce restaurant le meme jour !';

        end if;
        return new;
    end;
    $$language plpgsql;

create or replace trigger trigger_service_overlap
    before insert or update on services
    for each row
    execute function tgr_check_service_overlap()