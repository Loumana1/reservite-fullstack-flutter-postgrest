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

    ;

alter table restaurants
     ADD CONSTRAINT  restaurants_name_min_length
    check ( length(trim(name))>=5 ),

    ADD CONSTRAINT  restaurants_address_min_length
    check ( length(trim(address))>=5 ),

    ADD CONSTRAINT restaurants_city_min_length
    check(length(trim(city))>=3),
--A ameriorrer avec regex
    ADD CONSTRAINT restaurants_phone_min_length
    check ( length(trim(phone)) == (10 or 11)),

    ADD CONSTRAINT restaurants_description_min_length
    check ( length(trim(description))>=10 ),

    ADD CONSTRAINT restaurants_rating
    check ( rating BETWEEN 0.0 AND 5.0),

ADD CONSTRAINT  restaurants_price_range
    check(price_range is null
              or price_range BETWEEN 1 AND 5.0),

    ADD CONSTRAINT restaurants_slot_duration
    check ( slot_duration in ( 10,15,20, 30,60)
        )
;


alter table services
 ADD CONSTRAINT services_day_of_week
check( day_of_week BETWEEN 1 AND 7),


ADD CONSTRAINT service_min_length
check (end_time >=  start_time+interval('1 hour') )

