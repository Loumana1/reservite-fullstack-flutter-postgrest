set search_path to public, auth;



create or replace function get_tables(restaurant_id integer)
    returns setof table_info as
$$
begin
    perform auth.check_logged();
return query
select t.id, t.restaurant, t.table_number, t.capacity, t.is_signature
from tables t
where t.restaurant = get_tables.restaurant_id
order by t.capacity, t.table_number;
end;
$$ language plpgsql security definer;

grant execute on function get_tables(integer) to client, manager;


create or replace function save_table(restaurant_id integer,
                                      table_number integer,
                                      capacity integer,
                                      table_id integer default null)
    returns table_info as
$$
declare
result      table_info;
    current_uid integer;
    new_id      integer;
begin
    perform auth.check_logged();
    if auth.role() != 'manager' then
        raise exception 'Seul un manager peut gérer les tables';
end if;
    current_uid := auth.id()::integer;

    if not exists(select 1 from restaurant_managers rm
                  where rm.restaurant = save_table.restaurant_id
                    and rm.manager = current_uid) then
        raise exception 'Accès refusé sur ce restaurant';
end if;

    if save_table.table_id is null then
        insert into tables (restaurant, table_number, capacity)
        values (save_table.restaurant_id, save_table.table_number, save_table.capacity)
        returning id into new_id;
else
update tables
set restaurant   = save_table.restaurant_id,
    table_number = save_table.table_number,
    capacity     = save_table.capacity
where id = save_table.table_id;
new_id := save_table.table_id;
end if;

select t.id, t.restaurant, t.table_number, t.capacity, t.is_signature
into result from tables t where t.id = new_id;
return result;
end;
$$ language plpgsql security definer;

grant execute on function save_table(integer, integer, integer, integer) to manager;


create or replace function update_signature(table_id integer, newsignature boolean)
    returns table_info as
$$
declare
    result table_info;
begin
    perform auth.check_logged();

    update tables
    set is_signature = newSignature
    where tables.id = update_signature.table_id;

    select t.id, t.restaurant, t.table_number, t.capacity, t.is_signature
    into result
    from tables t
    where t.id = update_signature.table_id;

    return result;
end;
$$ language plpgsql security definer;

-- IMPORTANT : le grant actuel pointe vers update(integer, boolean) → 404
grant execute on function update_signature(integer, boolean) to manager;
