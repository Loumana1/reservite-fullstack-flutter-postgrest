set search_path to public, auth;

/* check_email_available */
create or replace function check_email_available(email text, user_id integer default null)
    returns boolean as
$$
begin
return not exists(
    select 1 from users u
    where trim(lower(u.email)) = trim(lower(check_email_available.email))
      and (check_email_available.user_id is null or u.id != check_email_available.user_id)
);
end;
$$ language plpgsql security definer;

grant execute on function check_email_available(text, integer) to anon, client, manager;

/* check_full_name_available */
create or replace function check_full_name_available(full_name text, user_id integer default null)
    returns boolean as
$$
begin
return not exists(
    select 1 from users u
    where trim(lower(u.full_name)) = trim(lower(check_full_name_available.full_name))
      and (check_full_name_available.user_id is null or u.id != check_full_name_available.user_id)
);
end;
$$ language plpgsql security definer;

grant execute on function check_full_name_available(text, integer) to anon, client, manager;

/* signup */
create or replace function signup(full_name text, email text, password text)
    returns void as
$$
begin
insert into users (email, password, full_name, role)
values (signup.email, signup.password, signup.full_name, 'client');
end;
$$ language plpgsql security definer;

grant execute on function signup(text, text, text) to anon;