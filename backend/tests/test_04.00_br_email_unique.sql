set search_path to public;

-- On teste ici la règle métier "l'email d'un user doit être unique".
-- On passe 'unique_violation' à should_fail pour indiquer que l'on
-- s'attend précisément à cette erreur de contrainte UNIQUE, et que
-- toute autre erreur (ou aucune erreur) doit faire échouer le test.
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
