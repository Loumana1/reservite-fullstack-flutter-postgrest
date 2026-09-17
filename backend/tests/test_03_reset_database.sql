set search_path to public;

begin;
do
$test$
    begin
        raise notice 'TEST: reset_database';
        perform auth.login_anonymously_for_test();
        perform reset_database();
        perform auth.logout_for_test();
    end
$test$;
rollback;
