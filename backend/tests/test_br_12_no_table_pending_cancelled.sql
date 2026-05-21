set search_path to public;

begin;
do
$test$
begin

        raise notice 'TEST: BR-12, Une réservation en attente ou annulée ne peut être associée à aucune une table.';
        perform should_fail($$
            insert into reservation_tables (reservation, "table")
            values (2, 4);
        $$);
end
$test$;
rollback;