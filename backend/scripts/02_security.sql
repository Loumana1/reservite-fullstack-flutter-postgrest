set search_path to public, auth;

/**************************************************************
  Roles
 **************************************************************/

drop role if exists client, manager;
create role client nologin;
create role manager nologin;
grant client to authenticator;
grant manager to authenticator;
grant authenticated to client;
grant authenticated to manager;

/**************************************************************
  Table users
 **************************************************************/

drop type if exists role_type;
create type role_type as enum ('client', 'manager');

drop table if exists users;
create table users
(
    id        serial primary key,
    email     varchar(256) not null,
    password  varchar(512) not null,
    full_name varchar(256) not null,
    role      role_type    not null default 'client',
    phone     varchar(50)  default null
);

create unique index on users (trim(lower(email)));
create unique index on users (trim(lower(full_name)));

create function reset_users()
    returns void as
$$
begin
    -- Désactiver temporairement les triggers sur la table pour permettre la réinitialisation
    -- sans contraintes de règles métier
    alter table users disable trigger all;

    truncate table users cascade;

    insert into users (id, email, password, full_name, role)
    values (1, 'boverhaegen@epfc.eu', 'Password2,', 'Boris', 'manager'),
           (2, 'bepenelle@epfc.eu', 'Password2,', 'Benoît', 'manager'),
           (3, 'xapigeolet@epfc.eu', 'Password2,', 'Xavier', 'client'),
           (4, 'mamichel@epfc.eu', 'Password2,', 'Marc', 'client'),
           (5, 'gedielman@epfc.eu', 'Password2,', 'Geoffrey', 'manager'),
           (6, 'brlacroix@epfc.eu', 'Password2,', 'Bruno', 'client'),
           (7, 'client@epfc.eu', 'Password2,', 'Client', 'client'),
           (8, 'manager@epfc.eu', 'Password2,', 'Manager', 'manager');

    alter table users enable trigger all;

    perform setval('users_id_seq', (select max(id) from users));

    -- met à jour les mots de passe pour forcer le hashage
    -- noinspection SqlWithoutWhere
    update users
    set password = 'Password1,';

end;
$$ language plpgsql security definer;

/**************************************************************
 Trigger pour encrypter automatiquement le mot de passe
 **************************************************************/

create or replace function auth.encrypt_pass() returns trigger as
$$
declare
    hash text;
begin
    -- si c'est un INSERT ou si le mot de passe a changé et 
    -- qu'il n'est pas déjà crypté
    if tg_op = 'INSERT' or new.password != old.password and
                           not (new.password ~ '^\$2[aby]\$\d{2}\$[./A-Za-z0-9]{53}$') then
        -- on crypte le mot de passe
        hash = auth.crypt(new.password, auth.gen_salt('bf'));
        update users set password = hash where users.id = new.id;
    end if;
    return null;
end
$$ language plpgsql;

drop trigger if exists encrypt_pass on users;
create trigger encrypt_pass
    -- on choisit un trigger AFTER pour permettre aux contraintes de check
    -- de s'exécuter avant le cryptage
    after insert or update
    on users
    for each row
execute procedure auth.encrypt_pass();

/*
 Crée les users.

 On doit le faire ici pour que le trigger qui hache les mots de passe soit dispo.
 */

select *
from reset_users();

/**************************************************************
 Fonction qui permet de faire le login et retourne un jeton JWT
 **************************************************************/

create or replace function
    login(email text, password text) returns auth.jwt_token as
$$
declare
    role      name;
    full_name text;
    user_id   integer;
    result    auth.jwt_token;
begin
    -- check email and password
    if not exists(select *
                  from users
                  where users.email = login.email
                    and users.password = auth.crypt(login.password, users.password)) then
        raise exception using message = 'invalid user or password';
    end if;

    select users.id, users.role, users.full_name
    from users
    where users.email = login.email
    into user_id, role, full_name;

    select auth.sign(row_to_json(r), '94VEF6BGSV4MHACYQYWYZZXILQR7412Z') as token
    from (select role                                              as role,
                 email                                              as sub,
                 full_name                                         as name,
                 user_id                                           as user_id,
                 -- valid for 24 hours
                 extract(epoch from public.now_local())::integer + 24 * 60 * 60 as exp) r
    into result;
    return result;
end;
$$ language plpgsql security definer;

grant execute on function login to anon;

/**************************************************************
 Fonctions utilitaires vàv de la sécurité
 **************************************************************/

/*
 Retourne le user_id de l'utilisateur connecté via JWT
 */

create or replace function auth.id()
    returns int as
$$
begin
    return current_setting('request.jwt.claims', true)::json ->> 'user_id';
end;
$$ language plpgsql;

/*
 Retourne le mail de l'utilisateur connecté via JWT
 */

create or replace function auth.email()
    returns varchar as
$$
begin
    return current_setting('request.jwt.claims', true)::json ->> 'sub';
end;
$$ language plpgsql;

/*
 Retourne le rôle de l'utilisateur connecté via JWT
 */

create or replace function auth.role()
    returns varchar as
$$
begin
    return current_setting('request.jwt.claims', true)::json ->> 'role';
end;
$$ language plpgsql;


/*
 Vérifie si l'utilisateur est connecté
 */

create or replace function auth.check_logged()
    returns void as
$$
begin
    if auth.email() is null then
        raise exception 'You must be logged';
    end if;
end
$$ language plpgsql;

/*
 Lors des tests, permet de simuler une connexion anonyme
 */

create or replace function auth.login_anonymously_for_test() returns void as
$$
begin
    execute 'set session role to anon';
    -- true = pour la Tx, false = pour la session
    perform set_config('request.jwt.claims', '{"role":"anon"}', false);
end
$$ language plpgsql;

/*
 Lors des tests, permet de simuler une connexion avec un utilisateur donné
 */

create or replace function auth.login_for_test(email text) returns void as
$$
declare
    role    text;
    user_id int;
begin
    if not exists(select 1 from users u where u.email = login_for_test.email) then
        raise exception 'User ''%'' does not exist', email;
    end if;
    select m.id, m.role from users m where m.email = login_for_test.email into user_id, role;
    execute 'set session role to ' || role;
    -- true = pour la Tx, false = pour la session
    perform set_config('request.jwt.claims',
                       concat('{"role": "', role, '", "sub": "', email, '", "user_id": "', user_id, '"}'), false);
end
$$ language plpgsql;

/*
 Permet de revenir à son rôle normal (après un login_for_test)
 */

create or replace function auth.logout_for_test() returns void as
$$
begin
    perform set_config('request.jwt.claims', '{}', false);
    reset role;
end;
$$ language plpgsql;


grant execute on function auth.login_anonymously_for_test() to anon;
grant execute on function auth.login_for_test(text) to anon;
grant execute on function auth.logout_for_test() to anon;
grant execute on function auth.id() to anon;
grant execute on function auth.email() to anon;
grant execute on function auth.role() to anon;
