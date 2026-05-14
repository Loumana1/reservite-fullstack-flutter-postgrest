--********************************************************************************************************************************************************************
                                                     --USERS--
--********************************************************************************************************************************************************************
alter table users
    drop constraint if exists users_full_name_min_length;
alter table users
    drop constraint if exists users_passwords_strength;

alter table users
    add constraint users_full_name_min_length
    check ( length(trim(full_name)) >= 3) ,

    add constraint users_passwords_strength
    check ( length(trim(password)) >= 8
                and password ~ '[0-9]'
                and password ~ '[A-z]'
                and password ~ '[a-z]'
                and password ~ '[,;.:!?/$%&@#]');


--*********************************************************************************************************************************************************************
                                                    --TABLES--
--**********************************************************************************************************************************************************************
alter table tables
    drop constraint if exists table_number_positive;
alter table tables
    drop constraint if exists table_capacity_positive;
alter table tables
    add constraint table_number_positive
    check ( table_number > 0) ,

    add constraint table_capacity_positive
    check ( capacity > 0 );

--*********************************************************************************************************************************************************************
                                                   --RESTAURANT--
--**********************************************************************************************************************************************************************
alter table restaurants
    drop constraint if exists restaurants_name_min_length ;
alter table restaurants
    drop constraint if exists restaurants_address_min_length;
alter table restaurants
    drop constraint if exists restaurants_city_min_length;
alter table restaurants
    drop constraint if exists restaurants_phone_format;
alter table restaurants
    drop constraint if exists restaurants_description_min_length;
alter table restaurants
    drop constraint if exists restaurants_rating;
alter table restaurants
    drop constraint if exists restaurants_price_range;
alter table restaurants
    drop constraint if exists restaurants_slot_duration;


alter table restaurants
     ADD CONSTRAINT  restaurants_name_min_length
    check ( length(trim(name))>=5 ),

    ADD CONSTRAINT  restaurants_address_min_length
    check ( length(trim(address))>=5 ),

    ADD CONSTRAINT restaurants_city_min_length
    check(length(trim(city))>=3),

    ADD CONSTRAINT restaurants_phone_format
    check (phone ~ '^(\+32\s?|0)[1-9][0-9\s.-]{7,11}$'),

    ADD CONSTRAINT restaurants_description_min_length
    check ( length(trim(description))>=10 ),

    ADD CONSTRAINT restaurants_rating
    check ( rating BETWEEN 0.0 AND 5.0),

    ADD CONSTRAINT  restaurants_price_range
    check(price_range is null
              or price_range BETWEEN 1.0 AND 4.0),

    ADD CONSTRAINT restaurants_slot_duration
    check ( slot_duration in ( 10,15,20, 30,60));


--*********************************************************************************************************************************************************************
                                                                --SERVICES--
--**********************************************************************************************************************************************************************
alter table services
    drop constraint if exists services_day_of_week;
alter table services
    drop constraint if exists service_min_length;
alter table services
    ADD CONSTRAINT services_day_of_week
        check( day_of_week BETWEEN 1 AND 7),


    ADD CONSTRAINT service_min_length
        check (end_time >=  start_time + interval '1 hour' );


--*********************************************************************************************************************************************************************
                                                                    --RESERVATION--
--**********************************************************************************************************************************************************************
alter table reservations
    drop constraint if exists number_guest_positive;
alter table reservations
    drop constraint if exists special_request_length;

alter table reservations
    add constraint number_guest_positive
    check ( number_of_guests > 0 ),

    add constraint special_request_length
    check (special_requests is null or length(trim(special_requests)) >= 10)
