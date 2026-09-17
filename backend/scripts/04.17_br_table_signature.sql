create or replace function trigger_table_sponsored()
returns trigger as
    $$
    begin
        if not (
        select count(*)
        from tables t
        where t.restaurant = new.restaurant  and t.is_signature = true)
            <=3 then raise exception 'ce resto a deja 2 table sponso';

            end if ;


    end;

    $$language plpgsql;

create or replace trigger table_sponsored
    before update on tables
    for each row execute function trigger_table_sponsored();