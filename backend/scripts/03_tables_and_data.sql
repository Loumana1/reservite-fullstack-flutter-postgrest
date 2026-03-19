set search_path to public;

create table restaurants
(
    id          serial primary key,
    name        varchar(256) not null,
    address     varchar(512) not null,
    city        varchar(256) not null,
    phone       varchar(50)  not null,
    description text             default null,
    rating      double precision default null,
    price_range int              default null,
    slot_duration int           not null default 30
);

create unique index on restaurants (trim(lower(name)), trim(lower(city)));

create table tables
(
    id             serial primary key,
    restaurant     int not null references restaurants (id) on delete cascade,
    table_number   int not null,
    capacity       int not null,
    unique (restaurant, table_number)
);

create table services
(
    id          serial primary key,
    restaurant  int  not null references restaurants (id) on delete cascade,
    day_of_week int  not null,
    start_time  time not null,
    end_time    time not null,
    unique (restaurant, day_of_week, start_time, end_time)
);


create table restaurant_managers
(
    restaurant int not null references restaurants (id) on delete cascade,
    manager    int not null references users (id) on delete cascade,
    primary key (restaurant, manager)
);

drop type if exists status_type;
create type status_type as enum ('pending', 'confirmed', 'cancelled', 'completed');

create table reservations
(
    id               serial primary key,
    client           int         not null references users (id) on delete cascade,
    restaurant       int         not null references restaurants (id) on delete cascade,
    datetime         timestamp   not null,
    number_of_guests int         not null,
    status           status_type not null default 'pending'::status_type,
    special_requests text                 default null
);

create table reservation_tables
(
    reservation int not null references reservations (id) on delete cascade,
    "table"     int not null references tables (id) on delete cascade,
    primary key (reservation, "table")
);

create table system_time
(
    simulated_time timestamp default null
);

/*
 ==========================================
 FONCTION RESET_DATABASE
 ==========================================
 */

drop function if exists reset_database;

create or replace function reset_database()
    returns void as
$$
begin
    -- Désactiver temporairement tous les triggers sur toutes les tables pour permettre la réinitialisation
    -- sans contraintes de règles métier
    alter table reservations disable trigger all;
    alter table reservation_tables disable trigger all;
    alter table tables disable trigger all;
    alter table restaurants disable trigger all;
    alter table services disable trigger all;
    alter table restaurant_managers disable trigger all;

    truncate table reservations cascade;
    truncate table restaurant_managers cascade;
    truncate table services cascade;
    truncate table tables cascade;
    truncate table restaurants cascade;
    truncate table system_time cascade;

    perform reset_users();

    insert into system_time (simulated_time)
    values ('2024-12-04 16:00:00');

    insert into restaurants (id, name, address, city, phone, description, rating, price_range, slot_duration)
    values (1, 'Le Gourmet', 'Rue de la Paix 12', 'Bruxelles', '+32 2 123 45 67',
            'Restaurant gastronomique français', 4.5, 3, 30),
           (2, 'La Trattoria', 'Avenue Louise 45', 'Bruxelles', '+32 2 234 56 78',
            'Cuisine italienne authentique', 4.2, 2, 30),
           (3, 'Sushi House', 'Chaussée de Waterloo 89', 'Bruxelles', '+32 2 345 67 89',
            'Sushi et cuisine japonaise', 4.7, 3, 30),
           (4, 'Bistrot du port', 'Grote Markt 15', 'Anvers', '+32 3 456 78 90',
            'Brasserie traditionnelle belge au cœur d''Anvers', 4.3, 2, 15),
           (5, 'Le Bistrot Flamand', 'Korenmarkt 8', 'Gand', '+32 95 67 89 01',
            'Cuisine flamande traditionnelle dans un cadre chaleureux', 4.4, 2, 30),
           (6, 'La Table du Chef', 'Place Saint-Lambert 22', 'Liège', '+32 467 89 10 12',
            'Restaurant gastronomique avec vue sur la place', 4.6, 3, 30),
           (7, 'Pizzeria Bella Vista', 'Boulevard Tirou 45', 'Charleroi', '+32 71 79 01 23',
            'Pizzeria italienne avec four à bois', 4.1, 1, 30),
           (8, 'Le Jardin Secret', 'Rue de Fer 18', 'Namur', '+32 81 89 12 34',
            'Restaurant végétarien et bio dans un jardin caché', 4.5, 2, 30);

    perform setval('restaurants_id_seq', (select max(id) from restaurants));

    insert into tables (id, restaurant, table_number, capacity)
    values (1, 1, 1, 2),
           (2, 1, 2, 4),
           (3, 1, 3, 6),
           (4, 2, 1, 2),
           (5, 2, 2, 4),
           (6, 3, 1, 4),
           (7, 3, 2, 6),
           (8, 4, 1, 2),
           (9, 4, 2, 4),
           (10, 4, 3, 4),
           (11, 4, 4, 6),
           (12, 5, 1, 2),
           (13, 5, 2, 4),
           (14, 5, 3, 6),
           (15, 5, 4, 8),
           (16, 6, 1, 2),
           (17, 6, 2, 4),
           (18, 6, 3, 4),
           (19, 7, 1, 2),
           (20, 7, 2, 4),
           (21, 7, 3, 4),
           (22, 7, 4, 6),
           (23, 8, 1, 2),
           (24, 8, 2, 4),
           (25, 8, 3, 4);

    perform setval('tables_id_seq', (select max(id) from tables));

    insert into services (id, restaurant, day_of_week, start_time, end_time)
    values (1, 1, 1, '12:00', '14:00'),
           (2, 1, 1, '19:00', '22:00'),
           (3, 1, 2, '12:00', '14:00'),
           (4, 1, 2, '19:00', '22:00'),
           (5, 1, 3, '12:00', '14:00'),
           (6, 1, 3, '19:00', '22:00'),
           (7, 1, 4, '12:00', '14:00'),
           (8, 1, 4, '19:00', '22:00'),
           (9, 1, 5, '12:00', '14:00'),
           (10, 1, 5, '19:00', '23:00'),
           (11, 1, 6, '19:00', '23:00'),
           (12, 1, 7, '12:00', '14:00'),
           (13, 2, 1, '12:00', '14:30'),
           (14, 2, 1, '18:30', '22:30'),
           (15, 2, 2, '12:00', '14:30'),
           (16, 2, 2, '18:30', '22:30'),
           (17, 2, 3, '12:00', '14:30'),
           (18, 2, 3, '18:30', '22:30'),
           (19, 2, 4, '12:00', '14:30'),
           (20, 2, 4, '18:30', '22:30'),
           (21, 2, 5, '12:00', '14:30'),
           (22, 2, 5, '18:30', '23:00'),
           (23, 2, 6, '18:30', '23:00'),
           (24, 2, 7, '12:00', '15:00'),
           (25, 3, 2, '18:00', '22:00'),
           (26, 3, 3, '18:00', '22:00'),
           (27, 3, 4, '18:00', '22:00'),
           (28, 3, 5, '18:00', '23:00'),
           (29, 3, 6, '18:00', '23:00'),
           (30, 3, 7, '18:00', '22:00'),
           (31, 4, 1, '11:30', '14:30'),
           (32, 4, 1, '18:00', '22:00'),
           (33, 4, 2, '11:30', '14:30'),
           (34, 4, 2, '18:00', '22:00'),
           (35, 4, 3, '11:30', '14:30'),
           (36, 4, 3, '18:00', '22:00'),
           (37, 4, 4, '11:30', '14:30'),
           (38, 4, 4, '18:00', '22:00'),
           (39, 4, 5, '11:30', '14:30'),
           (40, 4, 5, '18:00', '23:00'),
           (41, 4, 6, '18:00', '23:00'),
           (42, 4, 7, '11:30', '15:00'),
           (43, 5, 1, '12:00', '14:00'),
           (44, 5, 1, '19:00', '22:30'),
           (45, 5, 2, '12:00', '14:00'),
           (46, 5, 2, '19:00', '22:30'),
           (47, 5, 3, '12:00', '14:00'),
           (48, 5, 3, '19:00', '22:30'),
           (49, 5, 4, '12:00', '14:00'),
           (50, 5, 4, '19:00', '22:30'),
           (51, 5, 5, '12:00', '14:00'),
           (52, 5, 5, '19:00', '23:00'),
           (53, 5, 6, '19:00', '23:00'),
           (54, 5, 7, '12:00', '15:00'),
           (55, 6, 2, '12:00', '14:00'),
           (56, 6, 2, '19:00', '22:00'),
           (57, 6, 3, '12:00', '14:00'),
           (58, 6, 3, '19:00', '22:00'),
           (59, 6, 4, '12:00', '14:00'),
           (60, 6, 4, '19:00', '22:00'),
           (61, 6, 5, '12:00', '14:00'),
           (62, 6, 5, '19:00', '23:00'),
           (63, 6, 6, '19:00', '23:00'),
           (64, 6, 7, '12:00', '15:00'),
           (65, 7, 1, '11:30', '14:00'),
           (66, 7, 1, '18:00', '22:00'),
           (67, 7, 2, '11:30', '14:00'),
           (68, 7, 2, '18:00', '22:00'),
           (69, 7, 3, '11:30', '14:00'),
           (70, 7, 3, '18:00', '22:00'),
           (71, 7, 4, '11:30', '14:00'),
           (72, 7, 4, '18:00', '22:00'),
           (73, 7, 5, '11:30', '14:00'),
           (74, 7, 5, '18:00', '23:00'),
           (75, 7, 6, '18:00', '23:00'),
           (76, 7, 7, '11:30', '15:00'),
           (77, 8, 1, '12:00', '14:30'),
           (78, 8, 1, '19:00', '21:30'),
           (79, 8, 2, '12:00', '14:30'),
           (80, 8, 2, '19:00', '21:30'),
           (81, 8, 3, '12:00', '14:30'),
           (82, 8, 3, '19:00', '21:30'),
           (83, 8, 4, '12:00', '14:30'),
           (84, 8, 4, '19:00', '21:30'),
           (85, 8, 5, '12:00', '14:30'),
           (86, 8, 5, '19:00', '22:00'),
           (87, 8, 6, '19:00', '22:00'),
           (88, 8, 7, '12:00', '15:00');

    perform setval('services_id_seq', (select max(id) from services));

    insert into restaurant_managers (restaurant, manager)
    values  (1, 1),
            (1, 2),
            (2, 1),
            (2, 2),
            (3, 2),
            (4, 1),
            (4, 2),
            (4, 5),
            (5, 2),
            (6, 5),
            (7, 1),
            (8, 2),
            (8, 5);

    insert into reservations (id, client, restaurant, datetime, number_of_guests, status, special_requests)
    values  (1, 3, 1, '2024-11-15 19:00:00', 2, 'confirmed', 'Table près de la fenêtre'),
            (2, 4, 2, '2024-11-16 20:00:00', 2, 'pending', null),
            (3, 6, 3, '2024-11-17 19:30:00', 4, 'confirmed', 'Anniversaire'),
            (4, 3, 1, '2024-11-18 12:30:00', 4, 'confirmed', 'Déjeuner d''affaires'),
            (5, 4, 2, '2024-11-19 19:00:00', 2, 'pending', 'Allergie aux noix'),
            (6, 6, 3, '2024-11-20 20:00:00', 6, 'confirmed', null),
            (7, 3, 1, '2024-11-21 19:30:00', 8, 'confirmed', 'Célébration'),
            (8, 4, 2, '2024-11-22 12:00:00', 2, 'cancelled', null),
            (9, 6, 3, '2024-11-23 18:30:00', 4, 'confirmed', 'Première visite'),
            (10, 3, 1, '2024-11-24 12:30:00', 2, 'pending', null),
            (11, 4, 2, '2024-11-25 19:00:00', 4, 'confirmed', 'Dîner romantique'),
            (12, 6, 3, '2024-11-26 19:30:00', 2, 'completed', 'Excellent service'),
            (13, 6, 1, '2024-11-27 19:00:00', 2, 'confirmed', 'Dîner en amoureux'),
            (14, 6, 2, '2024-11-28 20:00:00', 3, 'confirmed', 'Soirée entre amis'),
            (15, 6, 4, '2024-11-29 19:30:00', 4, 'confirmed', 'Découverte d''Anvers'),
            (16, 6, 5, '2024-11-30 19:00:00', 2, 'confirmed', null),
            (17, 6, 6, '2024-12-01 13:00:00', 4, 'confirmed', 'Célébration spéciale'),
            (18, 6, 7, '2024-12-02 18:30:00', 2, 'cancelled', 'Pizza du vendredi'),
            (19, 3, 8, '2024-12-03 19:00:00', 3, 'confirmed', 'Restaurant végétarien'),
            (20, 6, 1, '2024-12-04 12:30:00', 2, 'confirmed', 'Déjeuner d''affaires'),
            (21, 6, 2, '2024-12-05 20:00:00', 4, 'pending', 'Anniversaire de mariage'),
            (22, 6, 4, '2024-12-06 19:00:00', 2, 'pending', null);

    perform setval('reservations_id_seq', (select max(id) from reservations));

    insert into reservation_tables (reservation, "table")
    values  (1, 1),
            (3, 6),
            (4, 2),
            (6, 7),
            (7, 2),
            (7, 3),
            (9, 6),
            (11, 5),
            (12, 7),
            (13, 1),
            (14, 5),
            (15, 9),
            (16, 12),
            (17, 17),
            (19, 24),
            (20, 1);

    -- Réactiver tous les triggers sur toutes les tables
    alter table reservations enable trigger all;
    alter table reservation_tables enable trigger all;
    alter table tables enable trigger all;
    alter table restaurants enable trigger all;
    alter table services enable trigger all;
    alter table restaurant_managers enable trigger all;

end;
$$ language plpgsql security definer;

grant execute on function reset_database to anon;

select reset_database();
