create or replace function tgr_check_service_alignment()
returns trigger as $$
    declare
        slot int;
    begin
        select slot_duration into slot
        from restaurants
        where id = new.restaurant;

        if (date_part('minute', new.start_time)::int % slot != 0 )
            or(date_part('minute', new.end_time)::int % slot != 0 )
            then raise exception 'Horaire pas alignes sur % minutes !' , slot;
        end if;

        return new ;
    end;
    $$ language plpgsql;


create or replace trigger trigger_service_simple
    before insert or update on services
    for each row
    execute function tgr_check_service_alignment();