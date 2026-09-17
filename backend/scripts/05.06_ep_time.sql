set search_path to public, auth;

create or replace function get_simulated_time()
    returns timestamp
    language plpgsql
    security definer
    set search_path to public
as $$
    declare
    res timestamp;
    begin
    select simulated_time into res from system_time limit 1;
    return coalesce(res, now_local());
    end;
    $$;




create or replace function set_simulated_time(new_time timestamp)
    returns timestamp
    language plpgsql
    security definer
    set search_path to public
as $$
begin
update system_time
set simulated_time = set_simulated_time.new_time;

if not found then
        insert into system_time (simulated_time)
        values (set_simulated_time.new_time);
end if;

return set_simulated_time.new_time;
end;
$$;

grant execute on function get_simulated_time() to anon, client, manager;
grant execute on function set_simulated_time(timestamp) to anon, client, manager;