
CREATE OR REPLACE FUNCTION get_current_time() RETURNS TIMESTAMP AS $$
DECLARE
    sim_time TIMESTAMP;
BEGIN
    SELECT simulated_time INTO sim_time FROM system_time LIMIT 1;
    IF sim_time IS NOT NULL THEN
        RETURN sim_time;
    END IF;
    RETURN CURRENT_TIMESTAMP;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION is_aligned_on_slot(time_val TIMESTAMP, slot_mins INT) RETURNS BOOLEAN AS $$
BEGIN
    RETURN (EXTRACT(MINUTE FROM time_val)::INTEGER % slot_mins) = 0
           AND EXTRACT(SECOND FROM time_val) = 0;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION is_time_aligned_on_slot(time_val TIME, slot_mins INT) RETURNS BOOLEAN AS $$
BEGIN
    RETURN (EXTRACT(MINUTE FROM time_val)::INTEGER % slot_mins) = 0
           AND EXTRACT(SECOND FROM time_val) = 0;
END;
$$ LANGUAGE plpgsql;


-----service  reservation
CREATE OR REPLACE FUNCTION get_service_for_reservation(res_restaurant INT, res_datetime TIMESTAMP) RETURNS INT AS $$
DECLARE
    svc_id INT;
BEGIN
    SELECT id INTO svc_id
    FROM services
    WHERE restaurant = res_restaurant
      AND day_of_week = EXTRACT(ISODOW FROM res_datetime)
      AND res_datetime::TIME >= start_time
      AND res_datetime::TIME < end_time
    LIMIT 1;
    RETURN svc_id;
    END ;
$$ LANGUAGE plpgsql;
