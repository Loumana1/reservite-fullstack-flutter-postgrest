set search_path to public;


begin;
do
$test$
begin
        raise notice 'TEST: email du user est unique';
        perform should_fail($$
            update users set email = 'bepenelle@epfc.eu' where id = 1;
        $$, 'unique_violation');
end
$test$;
rollback;