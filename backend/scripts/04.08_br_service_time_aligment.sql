create or replace function tgr_check_service_alignment()
returns trigger as $$
    declare
        slot int;
    begin
        select slot_duration into slot
        from restaurants
        where id = new.restaurant;

        if not is_time_aligned_on_slot(new.start_time, slot)
            or not is_time_aligned_on_slot(new.end_time, slot )
            then
                raise exception 'Horaire pas alignes sur % minutes !' , slot;
        end if;

        return new ;
    end;
    $$ language plpgsql;


create or replace trigger trigger_service_simple
    before insert or update on services
    for each row execute function tgr_check_service_alignment();