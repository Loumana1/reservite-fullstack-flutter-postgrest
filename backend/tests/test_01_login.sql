set search_path to public;

-- Chaque bloc de test est exécuté dans une transaction dédiée
-- que l'on annule avec ROLLBACK pour ne laisser aucune trace
-- dans la base de données.

-- 1. Cas de login correct : on vérifie simplement que l'appel
-- à la fonction login ne lève pas d'exception.
begin;
do
$test$
    begin
        raise notice 'TEST: login correct';
        perform login('bepenelle@epfc.eu', 'Password1,');
    end
$test$;
rollback;

-- 2. Cas d'email inexistant : on utilise should_fail pour vérifier
-- que la fonction login échoue bien (lève une exception) quand
-- l'email n'est pas connu.
begin;
do
$test$
    begin
        raise notice 'TEST: login avec un email qui n''existe pas';
        perform should_fail($$
            select login('xxx', 'Password1,');
        $$);
    end
$test$;
rollback;

-- 3. Cas de mot de passe incorrect : on vérifie de la même façon
-- que login échoue lorsque l'email existe mais que le mot de passe
-- est erroné.
begin;
do
$test$
    begin
        raise notice 'TEST: login avec un mauvais mot de passe';
        perform should_fail($$
            select login('bepenelle@epfc.eu', 'xxx');
        $$);
    end
$test$;
rollback;
