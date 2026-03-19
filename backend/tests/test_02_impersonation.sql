set search_path to public;

-- Chaque bloc de test est exécuté dans une transaction dédiée,
-- annulée avec ROLLBACK pour ne laisser aucune trace en base.
-- On teste ici les helpers d'authentification utilisés uniquement
-- pendant les tests automatisés. Les instructions assert vérifient
-- que la condition est vraie et lèvent une exception (échec du test)
-- si ce n'est pas le cas.

-- 1. Connexion anonyme de test : on vérifie que l'utilisateur courant
-- et les fonctions auth.* reflètent bien un utilisateur anonyme.
begin;
do
$test$
    begin
        raise notice 'TEST: login_anonymously_for_test';
        perform auth.login_anonymously_for_test();
        assert current_user = 'anon';
        assert auth.role() = 'anon';
        assert auth.id() is null;
        assert auth.email() is null;
        perform auth.logout_for_test();
    end
$test$;
rollback;

-- 2. Connexion de test en tant que client : on vérifie que le rôle,
-- l'id et l'email retournés correspondent bien au client attendu.
begin;
do
$test$
    begin
        raise notice 'TEST: login_for_test en tant que client';
        perform auth.login_for_test('brlacroix@epfc.eu');
        assert current_user = 'client';
        assert auth.role() = 'client';
        assert auth.id() = 6;
        assert auth.email() = 'brlacroix@epfc.eu';
        perform auth.logout_for_test();
    end
$test$;
rollback;

-- 3. Connexion de test en tant que manager : même principe, mais pour
-- le rôle manager et l'utilisateur correspondant.
begin;
do
$test$
    begin
        raise notice 'TEST: login_for_test en tant que manager';
        perform auth.login_for_test('bepenelle@epfc.eu');
        assert current_user = 'manager';
        assert auth.role() = 'manager';
        assert auth.id() = 2;
        assert auth.email() = 'bepenelle@epfc.eu';
        perform auth.logout_for_test();
    end
$test$;
rollback;
