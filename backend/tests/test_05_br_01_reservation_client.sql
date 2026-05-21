set search_path to public;

begin;
do
$test$
begin

        raise notice 'TEST: BR-01 reussit: Une réservation doit être associée à un utilisateur ayant le rôle de client. ';
        perform should_fail($$

            insert into reservations (client, restaurant, datetime, number_of_guests, status)
            values (2, 2, '2024-12-04 20:00:00', 2, 'pending');
        $$);

end
$test$;
rollback;