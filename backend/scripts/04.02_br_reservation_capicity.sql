create or replace function tgr_check_reservation_capacity()
    returns trigger as
$$
begin
    if exists(select r.id, r.number_of_guests, coalesce(sum(t.capacity), 0)
              from reservations r
                       left join reservation_tables rt on rt.reservation = r.id
                       left join tables t on t.id = rt."table"
              where r.status in ('confirmed'::status_type, 'completed'::status_type)
              group by r.id, r.number_of_guests
              having r.number_of_guests > coalesce(sum(t.capacity), 0)) then
        raise exception 'Le nombre de convives dépasse la capacité totale.';
    end if;

    return null;
end;
$$ language plpgsql;

create trigger trigger_validate_reservation_capacity
    after insert or update of number_of_guests, status
    on reservations
    for each row
execute function tgr_check_reservation_capacity();


create constraint trigger trigger_validate_reservation_tables_capacity
    after delete
    on reservation_tables
    deferrable initially deferred
    for each row
execute function tgr_check_reservation_capacity();


create trigger trigger_validate_tables_capacity
    after update of capacity or delete
    on tables
    for each row

execute function tgr_check_reservation_capacity();