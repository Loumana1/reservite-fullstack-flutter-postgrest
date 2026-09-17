/**************************************************************/
/*                                                            */
/* 01_CLEAN                                                   */
/*                                                            */
/**************************************************************/

set search_path to public;

/*
 Clear everything
 */

-- au cas où on aurait pris un autre rôle
reset role;

drop schema if exists public cascade;
drop schema if exists auth cascade;

drop role if exists anon, authenticator, authenticated;

/*
 Create roles
 */

create role authenticator noinherit login password 'mysecretpassword';
create role anon nologin;
create role authenticated nologin;

grant anon to authenticator;
grant authenticated to authenticator;

grant anon to authenticated;

/*
 Create schema
 */

create schema public;

-- par défaut tout est privé
-- (le 'public' qui est dans le from signifie "tous les rôles présents et futurs")
revoke all on schema public from public;

-- donne accès à certains rôles
grant usage on schema public to anon, authenticated;

-- par défault les fonctions ne sont pas accessibles
alter default privileges revoke all on functions from public;

/**************************************************************/
/*                                                            */
/* 02_POSTGREST_RELOAD_CACHE                                  */
/*                                                            */
/**************************************************************/

/*
 fait en sorte que la cache de postgrest soit rechargée à chaque commande ddl

 (voir https://postgrest.org/en/stable/references/schema_cache.html#automatic-schema-cache-reloading)
 */

-- create an event trigger function
create or replace function pgrst_watch() returns event_trigger
    language plpgsql
as
$$
begin
    notify pgrst, 'reload schema';
    raise notice 'pgrst_watch: reload schema';
end;
$$;

-- this event trigger will fire after every ddl_command_end event
drop event trigger if exists pgrst_watch;
create event trigger pgrst_watch
    on ddl_command_end
execute procedure pgrst_watch();

-- test : force un reload
notify pgrst, 'reload schema';

/**************************************************************/
/*                                                            */
/* 03_JWT                                                     */
/*                                                            */
/**************************************************************/

/*
--------------------------------------------------------------------------------
Met en place la sécurité à base de jetons JWT
--------------------------------------------------------------------------------
*/

drop schema if exists auth cascade;

create schema auth;

grant usage on schema auth to anon, authenticated;

set search_path to auth;
-- par défault les fonctions ne sont pas accessibles
alter default privileges revoke all on functions from public;
set search_path to public;

create extension if not exists pgcrypto with schema auth;

create type auth.jwt_token as
(
    token text
);

/*
 Code copié depuis pgjwt (voir https://github.com/michelp/pgjwt).
 Je n'utilise pas l'extension car elle n'est généralement pas dispo dans les VM hostées.
 */

-- create extension if not exists pgjwt;

create or replace function auth.url_encode(data bytea) returns text
    language sql as
$$
select translate(encode(data, 'base64'), E'+/=\n', '-_');
$$ immutable;


create or replace function auth.url_decode(data text) returns bytea
    language sql as
$$
with t as (select translate(data, '-_', '+/') as trans),
     rem as (select length(t.trans) % 4 as remainder from t) -- compute padding size
select decode(
               t.trans ||
               case
                   when rem.remainder > 0
                       then repeat('=', (4 - rem.remainder))
                   else '' end,
               'base64')
from t,
     rem;
$$ immutable;


create or replace function auth.algorithm_sign(signables text, secret text, algorithm text)
    returns text
    language sql as
$$
with alg as (select case
                        when algorithm = 'HS256' then 'sha256'
                        when algorithm = 'HS384' then 'sha384'
                        when algorithm = 'HS512' then 'sha512'
                        else '' end as id) -- hmac throws error
select auth.url_encode(auth.hmac(signables, secret, alg.id))
from alg;
$$ immutable;


create or replace function auth.sign(payload json, secret text, algorithm text default 'HS256')
    returns text
    language sql as
$$
with header as (select auth.url_encode(convert_to('{"alg":"' || algorithm || '","typ":"JWT"}', 'utf8')) as data),
     payload as (select auth.url_encode(convert_to(payload::text, 'utf8')) as data),
     signables as (select header.data || '.' || payload.data as data
                   from header,
                        payload)
select signables.data || '.' ||
       auth.algorithm_sign(signables.data, secret, algorithm)
from signables;
$$ immutable;


create or replace function auth.try_cast_double(inp text)
    returns double precision as
$$
begin
    begin
        return inp::double precision;
    exception
        when others then return null;
    end;
end;
$$ language plpgsql immutable;


create or replace function auth.verify(token text, secret text, algorithm text default 'HS256')
    returns table
            (
                header  json,
                payload json,
                valid   boolean
            )
    language sql
as
$$
select jwt.header                                  as header,
       jwt.payload                                 as payload,
       jwt.signature_ok and tstzrange(
                                    to_timestamp(auth.try_cast_double(jwt.payload ->> 'nbf')),
                                    to_timestamp(auth.try_cast_double(jwt.payload ->> 'exp'))
                            ) @> current_timestamp as valid
from (select convert_from(auth.url_decode(r[1]), 'utf8')::json                  as header,
             convert_from(auth.url_decode(r[2]), 'utf8')::json                  as payload,
             r[3] = auth.algorithm_sign(r[1] || '.' || r[2], secret, algorithm) as signature_ok
      from regexp_split_to_array(token, '\.') r) jwt
$$ immutable;

create or replace function now_local()
    returns timestamp
    language sql as
$$
select now() at time zone 'Europe/Brussels';
$$ immutable;

select now_local();

/**************************************************************
  Tests helpers
 **************************************************************/

/*
Helper de tests qui exécute une commande SQL et vérifie qu'elle échoue
avec un code d'erreur donné. Si la commande réussit ou échoue avec un
autre code que celui attendu, la fonction lève une exception.
*/
create or replace function should_fail(
    sql_cmd text,
    -- voir https://www.postgresql.org/docs/current/errcodes-appendix.html pour les noms des erreurs
    errname text default 'raise_exception'
)
    returns void as
$$
begin
    begin
        execute sql_cmd;

        /*
        Forcer l'exécution des éventuels triggers différés pour capturer les erreurs immédiatement

        Un trigger DEFERRED ne s'exécute qu'à la fin de la transaction, et donc pas immédiatement.
        Dès lors, aucune exception n'est levée immédiatement ici => le test échoue.
        Pour pouvoir tester un trigger DEFERRED ici, il faut forcer son exécution avant la fin de la transaction.
        Cette commande change le mode pour les reste de la transaction. Le mode revient automatiquement à DEFERRED
        à la fin de la transaction.
        */
        execute 'set constraints all immediate';

        raise exception using errcode = 'P0004', message = 'Test failed: command should have raised an exception';
    exception
        when others then
            if SQLSTATE = get_sqlstate(errname) then
                -- Exception attendue, OK
                null;
            else
                raise exception using errcode = SQLSTATE, message = 'Unexpected error code: ' || SQLSTATE;
            end if;
    end;
end;
$$ language plpgsql;

/*
Helper de tests qui convertit un nom d'erreur PostgreSQL (par exemple
'foreign_key_violation', 'raise_exception', ...) en code SQLSTATE
correspondant. Si le nom n'est pas connu, il est renvoyé tel quel pour
permettre de passer directement un code SQLSTATE explicite.
*/
create or replace function get_sqlstate(name text) returns text as $$
begin
    return case lower(name)
               when 'successful_completion' then '00000'
               when 'warning' then '01000'
               when 'dynamic_result_sets_returned' then '0100C'
               when 'implicit_zero_bit_padding' then '01008'
               when 'null_value_eliminated_in_set_function' then '01003'
               when 'privilege_not_granted' then '01007'
               when 'privilege_not_revoked' then '01006'
               when 'string_data_right_truncation' then '01004'
               when 'deprecated_feature' then '01P01'
               when 'no_data' then '02000'
               when 'no_additional_dynamic_result_sets_returned' then '02001'
               when 'sql_statement_not_yet_complete' then '03000'
               when 'connection_exception' then '08000'
               when 'connection_does_not_exist' then '08003'
               when 'connection_failure' then '08006'
               when 'sqlclient_unable_to_establish_sqlconnection' then '08001'
               when 'sqlserver_rejected_establishment_of_sqlconnection' then '08004'
               when 'transaction_resolution_unknown' then '08007'
               when 'protocol_violation' then '08P01'
               when 'triggered_action_exception' then '09000'
               when 'feature_not_supported' then '0A000'
               when 'invalid_transaction_initiation' then '0B000'
               when 'locator_exception' then '0F000'
               when 'invalid_locator_specification' then '0F001'
               when 'invalid_grantor' then '0L000'
               when 'invalid_grant_operation' then '0LP01'
               when 'invalid_role_specification' then '0P000'
               when 'diagnostics_exception' then '0Z000'
               when 'stacked_diagnostics_accessed_without_active_handler' then '0Z002'
               when 'invalid_argument_for_xquery' then '10608'
               when 'case_not_found' then '20000'
               when 'cardinality_violation' then '21000'
               when 'data_exception' then '22000'
               when 'array_subscript_error' then '2202E'
               when 'character_not_in_repertoire' then '22021'
               when 'datetime_field_overflow' then '22008'
               when 'division_by_zero' then '22012'
               when 'error_in_assignment' then '22005'
               when 'escape_character_conflict' then '2200B'
               when 'indicator_overflow' then '22022'
               when 'interval_field_overflow' then '22015'
               when 'invalid_argument_for_logarithm' then '2201E'
               when 'invalid_argument_for_ntile_function' then '22014'
               when 'invalid_argument_for_nth_value_function' then '22016'
               when 'invalid_argument_for_power_function' then '2201F'
               when 'invalid_argument_for_width_bucket_function' then '2201G'
               when 'invalid_character_value_for_cast' then '22018'
               when 'invalid_datetime_format' then '22007'
               when 'invalid_escape_character' then '22019'
               when 'invalid_escape_octet' then '2200D'
               when 'invalid_escape_sequence' then '22025'
               when 'nonstandard_use_of_escape_character' then '22P06'
               when 'invalid_indicator_parameter_value' then '22010'
               when 'invalid_parameter_value' then '22023'
               when 'invalid_preceding_or_following_size' then '22013'
               when 'invalid_regular_expression' then '2201B'
               when 'invalid_row_count_in_limit_clause' then '2201W'
               when 'invalid_row_count_in_result_offset_clause' then '2201X'
               when 'invalid_tablesample_argument' then '2202H'
               when 'invalid_tablesample_repeat' then '2202G'
               when 'invalid_time_zone_displacement_value' then '22009'
               when 'invalid_use_of_escape_character' then '2200C'
               when 'most_specific_type_mismatch' then '2200G'
               when 'null_value_not_allowed' then '22004'
               when 'null_value_no_indicator_parameter' then '22002'
               when 'numeric_value_out_of_range' then '22003'
               when 'sequence_generator_limit_exceeded' then '2200H'
               when 'string_data_length_mismatch' then '22026'
               when 'string_data_right_truncation' then '22001'
               when 'substring_error' then '22011'
               when 'trim_error' then '22027'
               when 'unterminated_c_string' then '22024'
               when 'zero_length_character_string' then '2200F'
               when 'floating_point_exception' then '22P01'
               when 'invalid_text_representation' then '22P02'
               when 'invalid_binary_representation' then '22P03'
               when 'bad_copy_file_format' then '22P04'
               when 'untranslatable_character' then '22P05'
               when 'not_an_xml_document' then '2200L'
               when 'invalid_xml_document' then '2200M'
               when 'invalid_xml_content' then '2200N'
               when 'invalid_xml_comment' then '2200S'
               when 'invalid_xml_processing_instruction' then '2200T'
               when 'duplicate_json_object_key_value' then '22030'
               when 'invalid_argument_for_sql_json_datetime_function' then '22031'
               when 'invalid_json_text' then '22032'
               when 'invalid_sql_json_subscript' then '22033'
               when 'more_than_one_sql_json_item' then '22034'
               when 'no_sql_json_item' then '22035'
               when 'non_numeric_sql_json_item' then '22036'
               when 'non_unique_keys_in_a_json_object' then '22037'
               when 'singleton_sql_json_item_required' then '22038'
               when 'sql_json_array_not_found' then '22039'
               when 'sql_json_member_not_found' then '2203A'
               when 'sql_json_number_not_found' then '2203B'
               when 'sql_json_object_not_found' then '2203C'
               when 'too_many_json_array_elements' then '2203D'
               when 'too_many_json_object_members' then '2203E'
               when 'sql_json_scalar_required' then '2203F'
               when 'sql_json_item_cannot_be_cast_to_target_type' then '2203G'
               when 'integrity_constraint_violation' then '23000'
               when 'restrict_violation' then '23001'
               when 'not_null_violation' then '23502'
               when 'foreign_key_violation' then '23503'
               when 'unique_violation' then '23505'
               when 'check_violation' then '23514'
               when 'exclusion_violation' then '23P01'
               when 'invalid_cursor_state' then '24000'
               when 'invalid_transaction_state' then '25000'
               when 'active_sql_transaction' then '25001'
               when 'branch_transaction_already_active' then '25002'
               when 'held_cursor_requires_same_isolation_level' then '25008'
               when 'inappropriate_access_mode_for_branch_transaction' then '25003'
               when 'inappropriate_isolation_level_for_branch_transaction' then '25004'
               when 'no_active_sql_transaction_for_branch_transaction' then '25005'
               when 'read_only_sql_transaction' then '25006'
               when 'schema_and_data_statement_mixing_not_supported' then '25007'
               when 'no_active_sql_transaction' then '25P01'
               when 'in_failed_sql_transaction' then '25P02'
               when 'idle_in_transaction_session_timeout' then '25P03'
               when 'transaction_timeout' then '25P04'
               when 'invalid_sql_statement_name' then '26000'
               when 'triggered_data_change_violation' then '27000'
               when 'invalid_authorization_specification' then '28000'
               when 'invalid_password' then '28P01'
               when 'dependent_privilege_descriptors_still_exist' then '2B000'
               when 'dependent_objects_still_exist' then '2BP01'
               when 'invalid_transaction_termination' then '2D000'
               when 'sql_routine_exception' then '2F000'
               when 'function_executed_no_return_statement' then '2F005'
               when 'modifying_sql_data_not_permitted' then '2F002'
               when 'prohibited_sql_statement_attempted' then '2F003'
               when 'reading_sql_data_not_permitted' then '2F004'
               when 'invalid_cursor_name' then '34000'
               when 'external_routine_exception' then '38000'
               when 'containing_sql_not_permitted' then '38001'
               when 'modifying_sql_data_not_permitted_38' then '38002'
               when 'prohibited_sql_statement_attempted_38' then '38003'
               when 'reading_sql_data_not_permitted_38' then '38004'
               when 'external_routine_invocation_exception' then '39000'
               when 'invalid_sqlstate_returned' then '39001'
               when 'null_value_not_allowed_39' then '39004'
               when 'trigger_protocol_violated' then '39P01'
               when 'srf_protocol_violated' then '39P02'
               when 'event_trigger_protocol_violated' then '39P03'
               when 'savepoint_exception' then '3B000'
               when 'invalid_savepoint_specification' then '3B001'
               when 'invalid_catalog_name' then '3D000'
               when 'invalid_schema_name' then '3F000'
               when 'transaction_rollback' then '40000'
               when 'transaction_integrity_constraint_violation' then '40002'
               when 'serialization_failure' then '40001'
               when 'statement_completion_unknown' then '40003'
               when 'deadlock_detected' then '40P01'
               when 'syntax_error_or_access_rule_violation' then '42000'
               when 'syntax_error' then '42601'
               when 'insufficient_privilege' then '42501'
               when 'cannot_coerce' then '42846'
               when 'grouping_error' then '42803'
               when 'windowing_error' then '42P20'
               when 'invalid_recursion' then '42P19'
               when 'invalid_foreign_key' then '42830'
               when 'invalid_name' then '42602'
               when 'name_too_long' then '42622'
               when 'reserved_name' then '42939'
               when 'datatype_mismatch' then '42804'
               when 'indeterminate_datatype' then '42P18'
               when 'collation_mismatch' then '42P21'
               when 'indeterminate_collation' then '42P22'
               when 'wrong_object_type' then '42809'
               when 'generated_always' then '428C9'
               when 'undefined_column' then '42703'
               when 'undefined_function' then '42883'
               when 'undefined_table' then '42P01'
               when 'undefined_parameter' then '42P02'
               when 'undefined_object' then '42704'
               when 'duplicate_column' then '42701'
               when 'duplicate_cursor' then '42P03'
               when 'duplicate_database' then '42P04'
               when 'duplicate_function' then '42723'
               when 'duplicate_prepared_statement' then '42P05'
               when 'duplicate_schema' then '42P06'
               when 'duplicate_table' then '42P07'
               when 'duplicate_alias' then '42712'
               when 'duplicate_object' then '42710'
               when 'ambiguous_column' then '42702'
               when 'ambiguous_function' then '42725'
               when 'ambiguous_parameter' then '42P08'
               when 'ambiguous_alias' then '42P09'
               when 'invalid_column_reference' then '42P10'
               when 'invalid_column_definition' then '42611'
               when 'invalid_cursor_definition' then '42P11'
               when 'invalid_database_definition' then '42P12'
               when 'invalid_function_definition' then '42P13'
               when 'invalid_prepared_statement_definition' then '42P14'
               when 'invalid_schema_definition' then '42P15'
               when 'invalid_table_definition' then '42P16'
               when 'invalid_object_definition' then '42P17'
               when 'with_check_option_violation' then '44000'
               when 'insufficient_resources' then '53000'
               when 'disk_full' then '53100'
               when 'out_of_memory' then '53200'
               when 'too_many_connections' then '53300'
               when 'configuration_limit_exceeded' then '53400'
               when 'program_limit_exceeded' then '54000'
               when 'statement_too_complex' then '54001'
               when 'too_many_columns' then '54011'
               when 'too_many_arguments' then '54023'
               when 'object_not_in_prerequisite_state' then '55000'
               when 'object_in_use' then '55006'
               when 'cant_change_runtime_param' then '55P02'
               when 'lock_not_available' then '55P03'
               when 'unsafe_new_enum_value_usage' then '55P04'
               when 'operator_intervention' then '57000'
               when 'query_canceled' then '57014'
               when 'admin_shutdown' then '57P01'
               when 'crash_shutdown' then '57P02'
               when 'cannot_connect_now' then '57P03'
               when 'database_dropped' then '57P04'
               when 'idle_session_timeout' then '57P05'
               when 'system_error' then '58000'
               when 'io_error' then '58030'
               when 'undefined_file' then '58P01'
               when 'duplicate_file' then '58P02'
               when 'file_name_too_long' then '58P03'
               when 'config_file_error' then 'F0000'
               when 'lock_file_exists' then 'F0001'
               when 'fdw_error' then 'HV000'
               when 'fdw_column_name_not_found' then 'HV005'
               when 'fdw_dynamic_parameter_value_needed' then 'HV002'
               when 'fdw_function_sequence_error' then 'HV010'
               when 'fdw_inconsistent_descriptor_information' then 'HV021'
               when 'fdw_invalid_attribute_value' then 'HV024'
               when 'fdw_invalid_column_name' then 'HV007'
               when 'fdw_invalid_column_number' then 'HV008'
               when 'fdw_invalid_data_type' then 'HV004'
               when 'fdw_invalid_data_type_descriptors' then 'HV006'
               when 'fdw_invalid_descriptor_field_identifier' then 'HV091'
               when 'fdw_invalid_handle' then 'HV00B'
               when 'fdw_invalid_option_index' then 'HV00C'
               when 'fdw_invalid_option_name' then 'HV00D'
               when 'fdw_invalid_string_length_or_buffer_length' then 'HV090'
               when 'fdw_invalid_string_format' then 'HV00A'
               when 'fdw_invalid_use_of_null_pointer' then 'HV009'
               when 'fdw_too_many_handles' then 'HV014'
               when 'fdw_out_of_memory' then 'HV001'
               when 'fdw_no_schemas' then 'HV00P'
               when 'fdw_option_name_not_found' then 'HV00J'
               when 'fdw_reply_handle' then 'HV00K'
               when 'fdw_schema_not_found' then 'HV00Q'
               when 'fdw_table_not_found' then 'HV00R'
               when 'fdw_unable_to_create_execution' then 'HV00L'
               when 'fdw_unable_to_create_reply' then 'HV00M'
               when 'fdw_unable_to_establish_connection' then 'HV00N'
               when 'plpgsql_error' then 'P0000'
               when 'raise_exception' then 'P0001'
               when 'no_data_found' then 'P0002'
               when 'too_many_rows' then 'P0003'
               when 'assert_failure' then 'P0004'
               when 'internal_error' then 'XX000'
               when 'data_corrupted' then 'XX001'
               when 'index_corrupted' then 'XX002'
               else name -- Permet de passer le code direct si le nom n'est pas connu
        end;
end;
$$ language plpgsql;
