CREATE OR REPLACE package pkg_taxi_api as
	bulk_data_mode boolean := false;
	
	-- бронирование автомобиля водителем  (на главной странице)
	PROCEDURE rent_car(p_driver_id number, p_car_id number, p_start_date date);
	
	-- снятие автомобиля с брони (на главной странице)
	PROCEDURE removing_car_from_rent(p_driver_id number, p_gas_mileage number, p_stop_date date);
	
	-- создание платежа
	FUNCTION insert_payment(p_amount_to_paid number, p_currency_id number, p_payment_type_id number, p_payment_date date) return number;
	
	-- заправка автомобиля  (на главной странице)
	PROCEDURE refueling_car(p_driver_id       number, p_address_id         number, p_amount_to_paid number, 
	                        p_payment_type_id number, p_amount_of_gasoline number, p_refueling_date date);
	
	-- получить идентификатор статуса заказа по имени
	FUNCTION get_order_status_id(p_order_status_name varchar2) return number;
	
	TYPE addrs_ids_array_type is varray(10) of number;	-- при необходимости можно расширить EXTEND-ом
	TYPE distances_array_type is varray(10) of number;
	
	-- преобразование строки со списком ид-в адресов в массив (разделитель полей - ':')
	FUNCTION addr_ids_string2addrs_ids_array(p_addrs_ids varchar2) return addrs_ids_array_type;
	
	-- Получить расстояния поездки по списку адресов
	FUNCTION get_distances(p_start_address_id number, p_address_ids addrs_ids_array_type) return distances_array_type;
	
	-- суммарное расстояние по списку дистанций
	FUNCTION get_total_distance(p_distances distances_array_type) return number;
	
	-- расчет стоимости поездки по расстоянию
	FUNCTION calculate_amount_to_paid(p_city_id number, p_orders_date date, p_total_distance number) return number;
	
	-- создание заказа (на главной странице)
	FUNCTION creating_order( p_passenger_id               number, p_address_id     number, p_addrs_ids       addrs_ids_array_type, 
							 p_distances    distances_array_type, p_amount_to_paid number, p_payment_type_id number,
							 p_start_time                   date) return number;
	
	-- проверка, что заказ действующий (не закрыт и не отменен)
	FUNCTION order_is_valid(p_order_id number, p_order_date date) return BOOLEAN;
	
	-- изменение статуса заказа
	PROCEDURE updating_order_status(p_order_id number, p_new_status_id number, p_order_date date);
	
	-- назначение автомобиля на заказ
	PROCEDURE assign_car_to_order(p_order_id number, p_car_id number, p_driver_id number, p_assign_date date);
	
	-- отмена заказа  (на главной странице)
	PROCEDURE order_cancellation(p_order_id number, p_time_end date);
	
	-- добавление пробег заказа к пробегу арендованной машины
	PROCEDURE add_distance_for_rent_car(p_order_id number, p_driver_id number, p_rent_date date);
	
	-- закрытие заказа  (на главной странице)
	PROCEDURE closing_order(p_order_id                number,
	                        p_average_driver_speed    number,
							p_rating_passenger2driver number default null,
							p_rating_driver2passenger number default null,
							p_time_end                date);
	
	-- обновление рейтинга пассажиров
	PROCEDURE update_passengers_rating(p_city_id number, p_period_in_days number);
	
	-- обновление рейтинга водителей
	PROCEDURE update_drivers_rating(p_city_id number, p_period_in_days number);
	
	TYPE salaries_type  is record (driver_id number, salary number);
	TYPE salaries_table is table of salaries_type;
	
	-- расчет ЗП водителей
	cursor c_get_salary_for_drivers(cp_begin_month_date date, cp_last_month_date date) is
		select t.DRIVER_ID, 
			sum(case when payment_category = 0 then p.AMOUNT_TO_PAID else 0 end) income,
			sum(case when payment_category = 1 then p.AMOUNT_TO_PAID else 0 end) outlay
		from (
			select o.DRIVER_ID, o.TIME_START, o.PAYMENT_ID payment_id, 0 payment_category
			from   ORDERS o
			where  o.TIME_START between cp_begin_month_date and cp_last_month_date 
			union all
			select r.DRIVER_ID, r.REFUELING_DATE, r.PAYMENT_ID payment_id, 1 payment_category
			from   REFUELING r
			where  r.REFUELING_DATE between cp_begin_month_date and cp_last_month_date
		) t
		join PAYMENT p on t.payment_id = p.ID 
					and p.PAYMENT_DATE between cp_begin_month_date and cp_last_month_date
		group by t.DRIVER_ID;

	FUNCTION calc_salary_drivers(p_year number, p_month number) return salaries_table pipelined;
	
	PROCEDURE set_bulk_data_mode;
	PROCEDURE unset_bulk_data_mode;
	FUNCTION  check_bulk_data_mode return boolean;
	
	rended_error_exp exception;
	pragma exception_init(rended_error_exp, -20100);

	reserved_error_exp exception;
	pragma exception_init(reserved_error_exp, -20101);

	incorrect_order_status exception;
	pragma exception_init(incorrect_order_status, -20102);
end pkg_taxi_api;
/

-------------------------------------------------------------------------
CREATE OR REPLACE package body pkg_taxi_api as
	-- бронирование автомобиля водителем
	PROCEDURE rent_car(p_driver_id number, p_car_id number, p_start_date date) as
		v_is_rended number(1) := 0;
	begin
		select c.IS_RENDED into v_is_rended from CAR c where c.ID = p_car_id;
		
		if v_is_rended != 0 then
			raise rended_error_exp;
		end if;
		
		insert into RENT(DRIVER_ID, CAR_ID, DATE_START) values(p_driver_id, p_car_id, p_start_date);
		
		update CAR
		set    IS_RENDED = 1, 
		       RENT_DATE = p_start_date,
			   DRIVER_ID = p_driver_id
		where  ID        = p_car_id;
		
		if not bulk_data_mode then commit; end if;
	
	exception
		when rended_error_exp then dbms_output.put_line('rent_car: car_id = ' || p_car_id || ':  Автомобиль уже арендован!');
		when others           then dbms_output.put_line('rent_car: Ошибка: ' || sqlerrm);
		
	end rent_car;
	
-------------------------------------------------------------------------
	-- снятие автомобиля с брони (по звонку водителя)
	PROCEDURE removing_car_from_rent(p_driver_id number, p_gas_mileage number, p_stop_date date) as
		v_car_id    number;
		v_rent_id   number;
	begin
		select ID, CAR_ID into v_rent_id, v_car_id 
		from   RENT
		where  DRIVER_ID  = p_driver_id 
		  and  DATE_STOP is null;
		
		if v_rent_id is null then
			raise rended_error_exp;
		end if;
		
		update RENT
		set    DATE_STOP = p_stop_date, GAS_MILEAGE = p_gas_mileage
		where  ID        = v_rent_id;
		
		update CAR
		set    IS_RENDED = 0, 
		       RENT_DATE = null,
			   DRIVER_ID = null
		where  ID        = v_car_id;
		
		if not bulk_data_mode then commit; end if;
	
	exception
		when rended_error_exp then 
			dbms_output.put_line('removing_car_from_rent: Не найден арендованный автомобиль для водителя - ' || p_driver_id);
		when others           then dbms_output.put_line('removing_car_from_rent: Ошибка: '  || sqlerrm);
		
	end removing_car_from_rent;
	
-------------------------------------------------------------------------
	-- создание платежа
	FUNCTION insert_payment(p_amount_to_paid number, p_currency_id number, p_payment_type_id number, p_payment_date date) return number as
		v_inserted_id number;
	begin
		insert into PAYMENT(AMOUNT_TO_PAID, CURRENCY_ID, PAYMENT_TYPE_ID, PAYMENT_DATE)
		values(p_amount_to_paid, p_currency_id, p_payment_type_id, p_payment_date) returning ID into v_inserted_id;
		
		if not bulk_data_mode then commit; end if;
		
		return v_inserted_id;
		
	end insert_payment;
	
-------------------------------------------------------------------------
	-- заправка автомобиля
	PROCEDURE refueling_car(p_driver_id       number, p_address_id         number, p_amount_to_paid  number, 
							p_payment_type_id number, p_amount_of_gasoline number, p_refueling_date  date) as
		v_payment_id  number := 0;
		v_currency_id number;
		v_car_id      number;
	begin
		select cr.ID into v_currency_id
		from   DRIVER d
		join   CITY      c on d.CITY_ID    = c.ID
		join   CURRENCY cr on c.COUNTRY_ID = cr.COUNTRY_ID 
		where  d.ID = p_driver_id;
		
		v_payment_id := insert_payment(p_amount_to_paid, v_currency_id, p_payment_type_id, p_refueling_date);
		
		select CAR_ID into v_car_id 
		from   RENT
		where  DRIVER_ID        = p_driver_id 
		  and  DATE_STOP       is null
		  and  DATE_START between trunc(p_refueling_date) and trunc(p_refueling_date) + numtodsinterval(86399, 'second');
		
		
		insert into REFUELING(DRIVER_ID, CAR_ID, PAYMENT_ID, AMOUNT_OF_GASOLINE, ADDRESS_ID, REFUELING_DATE)
		values(p_driver_id, v_car_id, v_payment_id, p_amount_of_gasoline, p_address_id, p_refueling_date);
		
		if not bulk_data_mode then commit; end if;
	
	exception
		when others then dbms_output.put_line('refueling_car: Ошибка: ' || sqlerrm);
	end refueling_car;
	
-------------------------------------------------------------------------
	-- получить идентификатор статуса заказа по имени
	FUNCTION get_order_status_id(p_order_status_name varchar2) return number as
		v_status_id number := 0;
	begin
		select id into v_status_id from ORDER_STATUSES where ORDER_STATUS_NAME = p_order_status_name;
		
		if v_status_id is null then
			raise incorrect_order_status;
		end if;
			
		return v_status_id;
	
	exception
		when incorrect_order_status then 
			dbms_output.put_line('get_order_status_id: Неизвестное наименование статуса - ' || p_order_status_name);
		
	end get_order_status_id;

-------------------------------------------------------------------------
	-- преобразование строки со списком ид-в адресов в массив (разделитель полей - ':')
	FUNCTION addr_ids_string2addrs_ids_array(p_addrs_ids varchar2) return addrs_ids_array_type as
		v_out_arr  addrs_ids_array_type := addrs_ids_array_type(null);
		v_addr_cnt number;
		
		cursor c_addrs_ids(cp_ids_list varchar2, cp_ids_cnt number) is
			select to_number(regexp_substr(cp_ids_list, '[^:]+', 1, level)) 
			from dual
			connect by level <= cp_ids_cnt;
	begin
		v_addr_cnt := regexp_count(p_addrs_ids, ':') + 1;
		
		if v_addr_cnt = 1 then
			v_out_arr(1) := to_number(p_addrs_ids);
		else
			v_out_arr.extend(v_addr_cnt - 1);
			
			open  c_addrs_ids(p_addrs_ids, v_addr_cnt);
			fetch c_addrs_ids bulk collect into v_out_arr;
			close c_addrs_ids;
		end if;
		
		return v_out_arr;
	end;
	
-------------------------------------------------------------------------
	-- Получить расстояния поездки по списку адресов
	FUNCTION get_distances(p_start_address_id number, p_address_ids addrs_ids_array_type) return distances_array_type as
		v_out_arr  distances_array_type := distances_array_type(0);
		v_addr_cnt number;
	begin
		if p_address_ids(1) is not null then
			v_addr_cnt := p_address_ids.count;
			
			if v_addr_cnt = 1 then
				v_out_arr(1) := round(dbms_random.value(3, 70));
			else
				v_out_arr.extend(v_addr_cnt - 1);
				
				for nmb in 1..v_addr_cnt loop
					v_out_arr(nmb) := round(dbms_random.value(3, 70));
				end loop;
			end if;
		end if;
		
		return v_out_arr;
	end;
	
-------------------------------------------------------------------------
	-- суммарное расстояние по списку дистанций
	FUNCTION get_total_distance(p_distances distances_array_type) return number as
		v_total_distance number := 0;
	begin
		for nmb in 1..p_distances.count loop
			v_total_distance := v_total_distance + p_distances(nmb);
		end loop;
		
		return v_total_distance;
	end;
	
-------------------------------------------------------------------------
	-- расчет стоимости поездки по расстоянию
	FUNCTION calculate_amount_to_paid(p_city_id number, p_orders_date date, p_total_distance number) return number as
		v_rate number;
	begin
		-- тариф в заданном городе
		select R.RATE into v_rate
		from   RATE r
		where  R.CITY_ID           = p_city_id
		  and  p_orders_date between START_DATE and END_DATE;
		
		return p_total_distance * v_rate;
	end;
	
-------------------------------------------------------------------------
	-- создание заказа
	FUNCTION creating_order(p_passenger_id               number, p_address_id     number, p_addrs_ids       addrs_ids_array_type, 
							p_distances    distances_array_type, p_amount_to_paid number, p_payment_type_id number,
							p_start_time                   date) return number as
		v_currency_id    number;
		v_payment_id     number := 0;
		v_address_id     number := 0;
		v_order_id       number;
		v_preview_way_id number; 

	begin
		select cr.ID into v_currency_id
		from   ADDRESS   a
		join   STREET    s on a.STREET_ID  = s.ID 
		join   CITY      c on s.CITY_ID    = c.ID
		join   CURRENCY cr on c.COUNTRY_ID = cr.COUNTRY_ID 
		where  a.ID = p_address_id;

		v_payment_id := insert_payment(p_amount_to_paid, v_currency_id, p_payment_type_id, p_start_time);
		
		v_address_id := p_addrs_ids(p_addrs_ids.count);
		
		insert into ORDERS(PASSENGER_ID, TIME_START, STATUS_ID, PAYMENT_ID, END_TRIP_ADDRESS_ID)
		values(p_passenger_id, p_start_time, get_order_status_id('Поиск машины'), v_payment_id, v_address_id) 
		returning ID into v_order_id;
		
		v_address_id     := p_address_id;
		v_preview_way_id := null;
		for i in 1..p_addrs_ids.count loop
			insert into WAY(FROM_ADDRESS_ID, TO_ADDRESS_ID, DISTANCE, ORDER_ID, PREVIEW_WAY_ID, WAY_DATE)
			values(v_address_id, p_addrs_ids(i), p_distances(i), v_order_id, v_preview_way_id, p_start_time)
			returning ID into v_preview_way_id;
			
			v_address_id := p_addrs_ids(i);
		end loop;
		
		if not bulk_data_mode then commit; end if;
		
		return v_order_id;
	end creating_order;
	
-------------------------------------------------------------------------
	-- проверка, что заказ действующий (не закрыт и не отменен)
	FUNCTION order_is_valid(p_order_id number, p_order_date date) return BOOLEAN as
		v_completion_of_trip_id number;
		v_order_cancellation_id number;
		v_current_status_id     number;
	begin
		v_completion_of_trip_id := get_order_status_id('Завершение поездки');
		v_order_cancellation_id := get_order_status_id('Отмена заказа');
		
		select STATUS_ID into v_current_status_id 
		from ORDERS 
		where ID = p_order_id
		  and TIME_START between trunc(p_order_date) and trunc(p_order_date) + numtodsinterval(86399, 'second');
		
		if v_current_status_id is not null or
		   v_current_status_id != v_completion_of_trip_id or 
		   v_current_status_id != v_order_cancellation_id then
			return TRUE;
		else
			return FALSE;
		end if;
	end;
	
-------------------------------------------------------------------------
	-- изменение статуса заказа
	PROCEDURE updating_order_status(p_order_id number, p_new_status_id number, p_order_date date) as
	begin
		if order_is_valid(p_order_id, p_order_date) then
			update ORDERS 
			set STATUS_ID = p_new_status_id 
			where ID = p_order_id
			  and TIME_START between trunc(p_order_date) and trunc(p_order_date) + numtodsinterval(86399, 'second');
			  
			if not bulk_data_mode then commit; end if;
		else
			raise incorrect_order_status;
		end if;
		
	exception 
		when incorrect_order_status then
			dbms_output.put_line('updating_order_status: order_id = ' || p_order_id || ' : Заказ закрыт или отменен!');
		when others then
			dbms_output.put_line('updating_order_status: Ошибка: ' || sqlerrm);
	end;
	
-------------------------------------------------------------------------
	-- назначение автомобиля на заказ
	PROCEDURE assign_car_to_order(p_order_id number, p_car_id number, p_driver_id number, p_assign_date date) as
		v_current_status_id  number;
		v_is_rended          number(1);  
		v_is_reserved        number(1);  
	begin
		select c.IS_RENDED, c.IS_RESERVED into v_is_rended, v_is_reserved from CAR c where c.ID = p_car_id;
		
		if v_is_rended != 1 then
			raise rended_error_exp;
		end if;
		
		if v_is_reserved != 0 then
			raise reserved_error_exp;
		end if;
		
		select STATUS_ID into v_current_status_id from ORDERS where ID = p_order_id;
		
		if v_current_status_id != get_order_status_id('Поиск машины') then
			raise incorrect_order_status;
		end if;
		
		update CAR
		set    IS_RESERVED   = 1, 
		       RESERVED_DATE = p_assign_date
		where  ID            = p_car_id;
		
		update ORDERS 
		set    DRIVER_ID = p_driver_id 
		where  ID        = p_order_id
		  and  TIME_START between trunc(p_assign_date) and trunc(p_assign_date) + numtodsinterval(86399, 'second');
		
		if not bulk_data_mode then commit; end if;
		
		updating_order_status(p_order_id, get_order_status_id('Ожидание машины'), p_assign_date);
		
	exception 
		when rended_error_exp then
			dbms_output.put_line('assign_car_to_order: Машина не арендована!');
		when reserved_error_exp then
			dbms_output.put_line('assign_car_to_order: Машина уже назначена!');
		when incorrect_order_status then
			dbms_output.put_line('assign_car_to_order: Заказ не в статусе <Поиск машины>!');
		when others then
			dbms_output.put_line('assign_car_to_order: Ошибка: ' || sqlerrm);		
	end;
	
-------------------------------------------------------------------------
	-- отмена заказа
	-- приложением по имени пассажира определяется order_id
	PROCEDURE order_cancellation(p_order_id number, p_time_end date) as
		v_car_id number;
	begin
		if order_is_valid(p_order_id, p_time_end) = FALSE then
			raise incorrect_order_status;
		end if;
		
		select c.ID into v_car_id
		from   CAR c 
		join   ORDERS o on c.DRIVER_ID = o.DRIVER_ID and o.ID = p_order_id
		where  c.IS_RENDED = 1;
		
		if v_car_id is null then
			raise rended_error_exp;
		end if;
		
		update CAR
		set    IS_RESERVED   = 0, 
		       RESERVED_DATE = null
		where  ID            = v_car_id;		
		
		update ORDERS 
		set    TIME_END = p_time_end 
		where  ID       = p_order_id
		  and  TIME_START between trunc(p_time_end) and trunc(p_time_end) + numtodsinterval(86399, 'second');
		
		if not bulk_data_mode then commit; end if;
		
		updating_order_status(p_order_id, get_order_status_id('Отмена заказа'), p_time_end);
		
	exception 
		when incorrect_order_status then
			dbms_output.put_line('order_cancellation: Заказ закрыт или отменен!');
		when rended_error_exp then
			dbms_output.put_line('order_cancellation: Автомобиль не арендован!');
		when others then
			dbms_output.put_line('order_cancellation: Ошибка: ' || sqlerrm);
	end;
	
-------------------------------------------------------------------------
	-- добавление пробег заказа к пробегу арендованной машины
	PROCEDURE add_distance_for_rent_car(p_order_id number, p_driver_id number, p_rent_date date) as
		v_begin_rent_time date;
		v_end_rent_time   date;
		v_rent_id         number;
		v_is_rended       number(1);
		v_distance        number;
	begin
		v_begin_rent_time := trunc(p_rent_date);
		v_end_rent_time   := v_begin_rent_time + numtodsinterval(86399, 'second');
		
		select case when DATE_STOP is null then 1 else 0 end, ID into v_is_rended, v_rent_id
		from   RENT 
		where  DRIVER_ID        = p_driver_id 
		  and  DATE_START between v_begin_rent_time and v_end_rent_time;
		
		if v_is_rended = 0 then raise rended_error_exp; end if;
		
		select sum(DISTANCE) into v_distance 
		from   WAY 
		where  ORDER_ID       = p_order_id
		  and  WAY_DATE between v_begin_rent_time and v_end_rent_time;
		
		update RENT
		set    DISTANCE  = nvl(DISTANCE, 0) + v_distance
		where  ID        = v_rent_id
		  and  DRIVER_ID = p_driver_id;
		
		if not bulk_data_mode then commit; end if;
		
		exception
		when rended_error_exp then dbms_output.put_line('add_distance_for_rent_car: Автомобиль уже снят с аренды водителем driver_id = ' || p_driver_id);
		when others           then dbms_output.put_line('add_distance_for_rent_car: Ошибка: ' || sqlerrm);
	end;
	
-------------------------------------------------------------------------
	-- закрытие заказа
	PROCEDURE closing_order(p_order_id                number,
	                        p_average_driver_speed    number,
							p_rating_passenger2driver number default null,
							p_rating_driver2passenger number default null,
							p_time_end                date) as
		v_passenger_id number;
		v_driver_id    number;
		v_car_id       number;
	begin
		select passenger_id, driver_id into v_passenger_id, v_driver_id from orders where id = p_order_id;
		
		select ID into v_car_id
		from   CAR
		where  IS_RENDED = 1
		  and  DRIVER_ID = v_driver_id;
		
		if v_car_id is null then
			raise rended_error_exp;
		end if;
		
		-- освобождение автомобиля
		update CAR
		set    IS_RESERVED   = 0, 
		       RESERVED_DATE = null
		where  ID            = v_car_id;		
		
		-- закрытие заказа
		update ORDERS 
		set    TIME_END             = p_time_end, 
		       AVERAGE_DRIVER_SPEED = p_average_driver_speed
		where  ID                   = p_order_id;
		
		-- сохранение рейтингов пассажира и водителя
		if p_rating_passenger2driver is not null then
			insert into RATING_PASSENGER2DRIVER(PASSENGER_ID, DRIVER_ID, ORDER_ID, RATING, RATING_DATE)
			values(v_passenger_id, v_driver_id, p_order_id, p_rating_passenger2driver, p_time_end);
		end if;
		
		if p_rating_driver2passenger is not null then
			insert into RATING_DRIVER2PASSENGER(PASSENGER_ID, DRIVER_ID, ORDER_ID, RATING, RATING_DATE)
			values(v_passenger_id, v_driver_id, p_order_id, p_rating_driver2passenger, p_time_end);
		end if;
		
		if not bulk_data_mode then commit; end if;
		
		updating_order_status(p_order_id, get_order_status_id('Завершение поездки'), p_time_end);
		
		add_distance_for_rent_car(p_order_id, v_driver_id, p_time_end);
		
	exception 
		when incorrect_order_status then
			dbms_output.put_line('closing_order: Заказ закрыт или отменен!');
		when rended_error_exp then
			dbms_output.put_line('closing_order: Автомобиль не арендован!');
		when others then
			dbms_output.put_line('closing_order: Ошибка: ' || sqlerrm);
	end;

	
-------------------------------------------------------------------------
	-- обновление рейтинга пассажиров
	PROCEDURE update_passengers_rating(p_city_id number, p_period_in_days number) as
		v_id_exists number;
		v_last_date  date;
	begin
		select trunc(max(rdp.RATING_DATE)) into v_last_date
		from   RATING_DRIVER2PASSENGER rdp;
		
		for i in (
			select rdp.PASSENGER_ID, round(avg(rdp.RATING)) new_rating
			from   RATING_DRIVER2PASSENGER rdp 
			where  rdp.PASSENGER_ID in (
				select p.ID from PASSENGER p
				join VW_FULL_ADDRESS fa on fa.ADDRESS_ID = p.HOME_ADDRESS_ID and fa.CITY_ID = p_city_id
			)
			  and  rdp.RATING_DATE between v_last_date - p_period_in_days and v_last_date
			group by rdp.PASSENGER_ID
		) loop
			select count(1) into v_id_exists 
			from   PASSENGER_RATING 
			where  PASSENGER_ID = i.passenger_id;
			
			if v_id_exists != 0 then
				update PASSENGER_RATING set RATING = i.new_rating where PASSENGER_ID = i.passenger_id;
			else
				insert into PASSENGER_RATING(PASSENGER_ID, RATING) values(i.passenger_id, i.new_rating);
			end if;	
		end loop;
		
		if not bulk_data_mode then commit; end if;
	exception 
		when others then
			dbms_output.put_line('update_passengers_rating: Ошибка: ' || sqlerrm);
	end update_passengers_rating;
	
-------------------------------------------------------------------------
	-- обновление рейтинга водителей
	PROCEDURE update_drivers_rating(p_city_id number, p_period_in_days number) as
		v_id_exists  number;
		v_last_date  date;
	begin
		select trunc(max(rpd.RATING_DATE)) into v_last_date
		from   RATING_PASSENGER2DRIVER rpd;
		
		for i in (
			select rpd.DRIVER_ID, round(avg(rpd.RATING)) new_rating
			from   RATING_PASSENGER2DRIVER rpd 
			where  rpd.DRIVER_ID in (select d.ID from DRIVER d where d.CITY_ID = p_city_id)
			  and  rpd.RATING_DATE between v_last_date - p_period_in_days and v_last_date
			group by rpd.DRIVER_ID
		) loop
			select count(1) into v_id_exists 
			from   DRIVER_RATING 
			where  DRIVER_ID = i.driver_id;
		
			if v_id_exists != 0 then
				update DRIVER_RATING set RATING = i.new_rating where DRIVER_ID = i.driver_id;
			else
				insert into DRIVER_RATING(DRIVER_ID, RATING) values(i.driver_id, i.new_rating);
			end if;
		end loop;
		
		if not bulk_data_mode then commit; end if;
		
	exception 
		when others then
			dbms_output.put_line('update_drivers_rating: Ошибка: ' || sqlerrm);
	end update_drivers_rating;
	
-------------------------------------------------------------------------
	-- расчет ЗП водителей
	FUNCTION calc_salary_drivers(p_year number, p_month number) return salaries_table pipelined as
		v_begin_month_date   date;
		v_last_month_date    date;
		v_percent_of_payment number(3, 2);
		
		v_salary_rec salaries_type;
	begin
		v_begin_month_date := to_date(to_char(p_year)     || to_char(p_month), 'yyyymm');
		v_last_month_date  := LAST_DAY(v_begin_month_date) + NUMTODSINTERVAL(86399, 'second');
		
		for i_cursor in c_get_salary_for_drivers(v_begin_month_date, v_last_month_date) loop
			select d.PERCENT_OF_PAYMENT / 100 into v_percent_of_payment 
			from   DRIVER d 
			where  d.ID = i_cursor.driver_id;
			
			v_salary_rec.driver_id := i_cursor.driver_id;
			v_salary_rec.salary    := i_cursor.income * v_percent_of_payment - i_cursor.outlay;
			
			pipe row(v_salary_rec);
		end loop;
		
		return;
	end calc_salary_drivers;
	
-------------------------------------------------------------------------
	PROCEDURE set_bulk_data_mode as
	begin
		bulk_data_mode := true;
	end set_bulk_data_mode;
	
-------------------------------------------------------------------------
	PROCEDURE unset_bulk_data_mode as
	begin
		bulk_data_mode := false;
	end unset_bulk_data_mode;
	
-------------------------------------------------------------------------
	FUNCTION check_bulk_data_mode return boolean as
	begin
		return bulk_data_mode;
	end check_bulk_data_mode;
end pkg_taxi_api;
/