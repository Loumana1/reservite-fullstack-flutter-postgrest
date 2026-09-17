-- Analyse
------ :
-- si un restaurant a 3 reservation VIP declecher errerur
--
-- Insert : trigger pas declenché car par default false
-- update : ! (select cout(reservation) <= 3) --> exception




create or replace function trigger_reservation_vip()
       returns  trigger as
    $$
    declare

    begin

      if not  ( select count(*)
        from reservations r
        where r.id = new.id and r.is_vip = true )
        <=3 then raise exception
          '(BR-15): Le restaurant a atteien sont maximum de reservation VIP';
      end if;


return new ;
    end;
       $$language plpgsql;


create or replace trigger reservation_vip
    before update on reservations
    for each row execute function trigger_reservation_vip()

