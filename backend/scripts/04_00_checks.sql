set search_path to public ;

alter table users
    add constraint users_full_name_min_length
    check ( length(trim(full_name)) >= 3) ,

    add constraint users_passwords_strength
    check ( length(trim(password)) >= 8
                and password ~ '[0-9]'
                and password ~ '[A-z]'
                and password ~ '[a-z]'
                and password ~ '[]')