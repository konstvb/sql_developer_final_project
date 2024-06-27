CREATE OR REPLACE package pkg_gen_proccesses_api as
	-----------------------------------------------
	-- Генерация данных по бизнес-процессам сервиса
	-----------------------------------------------
	-- Процессы бронирования машин
	------------------------------
	type get_cars_type  is record(car_id number);
	type get_cars_table is table of get_cars_type;
	
	v_get_cars_table get_cars_table;
	
	cursor c_get_cars(p_city_id number) is
		select  c.id from car c
		join parking p on c.parking_id = p.id 
		join address a on p.address_id = a.id 
		join street  s on a.street_id  = s.id
		where s.city_id = p_city_id;
	
	type get_addresses_type  is record(address_id number);
	type get_addresses_table is table of get_addresses_type;
	
	v_get_addresses_table get_addresses_table;
	
	cursor c_get_addresses(p_city_id number) is
		select a.id address_id
		from address a
		join street s on a.street_id = s.id 
		where s.city_id = p_city_id;
	
	type get_passengers_type  is record(passenger_id number, home_address_id number);
	type get_passengers_table is table of get_passengers_type;
	
	v_get_passengers_table get_passengers_table;
	
	cursor c_get_passengers(p_city_id number) is
		select p.id passenger_id, p.home_address_id
		from passenger p
		join address a on p.home_address_id = a.id 
		join street  s on a.street_id       = s.id
		where s.city_id = p_city_id;
	
	procedure gen_rent_car(p_city_id number, p_rent_date date);
	
	procedure gen_orders(p_city_id number, p_orders_date date);
	
	procedure gen_ending_rent_car(p_city_id number, p_rent_date date);
	
	procedure gen_proccesses(p_start_date date, p_days_nmb number);
	
	procedure test_gen_proccesses(p_city_id number, p_start_date date);
	
	type get_drivers_type  is record(driver_id number, car_id number, rent_start_time date);
	type get_drivers_table is table of get_drivers_type;
	
	v_get_drivers_table get_drivers_table;
	
	cursor c_get_drivers_with_rent(cv_city_id number, cv_orders_date date) is
		select d.id driver_id, r.car_id, r.date_start rent_start_time
		from   driver d 
		join   rent   r on r.driver_id = d.id 
		               and r.date_start between trunc(cv_orders_date) and trunc(cv_orders_date) + numtodsinterval(86399, 'second') 
		where  d.city_id = cv_city_id;
	
end pkg_gen_proccesses_api;
/

CREATE OR REPLACE package body pkg_gen_proccesses_api as
	------------------------------
	-- Процессы бронирования машин
	------------------------------
	-- Водители бронируют машины: в 3 смены по 15 водителей на 8 часов
	procedure gen_rent_car(p_city_id number, p_rent_date date) as
		--p_city_id   number := 10;
		--p_rent_date date   := date'2023-01-01';
		
		v_cnt                  number := 0;
		v_car_id               number;
		v_tmp_date             date;
		v_distance             number;
		v_gas_mileage          number;
		v_refueling_address_id number;
		v_currency_id          number;
		v_gasoline_price       number;
		v_amount_to_paid       number;
		
	begin
		--dbms_output.put_line('gen_rent_car');
		
		-- водители для заданного города - 3 смены по 8 часов по 15 водителей
		for i_driver in (select ID from DRIVER d where CITY_ID = p_city_id order by ID) loop
			v_cnt      := v_cnt + 1;
			v_tmp_date := p_rent_date  + trunc((v_cnt - 1) / 15) * 8 / 24;
			v_car_id   := v_get_cars_table(v_cnt).car_id;
			
			pkg_taxi_api.rent_car(i_driver.id, v_car_id, v_tmp_date);
			
			--dbms_output.put_line(i_driver.ID || ';' || v_car_id || ';' || to_char(v_tmp_date, 'dd.mm.yyyy hh24'));
		end loop;
	end gen_rent_car;
	
	----------------------
	-- Процессы с заказами
	----------------------
	-- Пассажиры оформляют заказы по 5 в день для каждого водителя
	-- На заказы назначаются машины
	-- Заказы закрываются
	procedure gen_orders(p_city_id number, p_orders_date date) as
		--p_city_id     number := 10;
		--p_orders_date date   := date'2023-01-01';
		
		v_driver_id            number;
		v_driver_rating_min    number;
		v_driver_rating_max    number;
		v_car_id               number;
		v_rent_start_time      date;
		
		v_cnt                  number;
		v_order_id             number;
		v_rnd_nmb              number;
						       
		v_currency_id          number;
		v_rate                 number;
		v_passenger_id         number;
		v_pass_rating_min      number;
		v_pass_rating_max      number;
		v_start_address_id     number;
		v_amount_to_paid       number;
		v_start_time           date;
		v_end_time             date;
		v_passengers_table_cnt number;
		v_addresses_table_cnt  number;

		v_addresses_ids pkg_taxi_api.addrs_ids_array_type := pkg_taxi_api.addrs_ids_array_type(null);
		v_distances     pkg_taxi_api.distances_array_type := pkg_taxi_api.distances_array_type(null);

		type ids_array_type is varray(1000) of number;

		v_ids_array     ids_array_type := ids_array_type(null);
		
		function dupl_cnt(p_array ids_array_type, p_val number) return number is
			v_dupl_cnt number := 0;
		begin
			for v_i in 1..p_array.count loop
				if p_array(v_i) = p_val then
					v_dupl_cnt := v_dupl_cnt + 1;
				end if;
			end loop;
			
			return v_dupl_cnt;
		end;
	
	begin
		--dbms_output.put_line('gen_orders');

		-- тариф в заданном городе
		select R.RATE into v_rate
		from   RATE r
		where  R.CITY_ID     = p_city_id
		  and  p_orders_date between START_DATE and END_DATE;

		v_passengers_table_cnt := v_get_passengers_table.count;
		v_addresses_table_cnt  := v_get_addresses_table.count;
		
		v_ids_array.extend(v_get_drivers_table.count * 5 - 1);
		
		-- Генерация списка пассажиров с повторяемостью не больше 2
		for v_cnt in 1..v_ids_array.count loop
			v_rnd_nmb := trunc(dbms_random.value(1, v_passengers_table_cnt));
			
			while dupl_cnt(v_ids_array, v_rnd_nmb) >= 2 loop
				v_rnd_nmb := trunc(dbms_random.value(1, v_passengers_table_cnt));
			end loop;
				
			v_ids_array(v_cnt) := v_rnd_nmb;
			--dbms_output.put_line(v_rnd_nmb);
		end loop;
			
		-- для каждого водителя, который арендовал машину в заданном горооде, создаем по 5 заказов
		v_cnt := 0;
		for i_driver_nmb in 1..v_get_drivers_table.count loop
			v_driver_id       := v_get_drivers_table(i_driver_nmb).driver_id;
			v_car_id          := v_get_drivers_table(i_driver_nmb).car_id;
			v_rent_start_time := v_get_drivers_table(i_driver_nmb).rent_start_time;
			
			select dr.RATING into v_driver_rating_min from DRIVER_RATING dr where dr.DRIVER_ID = v_driver_id;
			
			if v_driver_rating_min < 2.5 then
				v_driver_rating_min := 1;
				v_driver_rating_max := 3;
			else
				v_driver_rating_min := 3;
				v_driver_rating_max := 5;
			end if;
			
			for i_nmb in 1..5 loop
				v_cnt := v_cnt + 1;
				
				v_rnd_nmb          := v_ids_array(v_cnt);
				v_passenger_id     := v_get_passengers_table(v_rnd_nmb).passenger_id;
				v_start_address_id := v_get_passengers_table(v_rnd_nmb).home_address_id;
				
				v_rnd_nmb          := round(dbms_random.value(1, v_addresses_table_cnt));
				v_addresses_ids(1) := v_get_addresses_table(v_rnd_nmb).address_id;
				v_distances(1)     := round(dbms_random.value(3, 70));
				v_amount_to_paid   := v_distances(1)    * v_rate;
				v_start_time       := v_rent_start_time + (i_nmb - 1) * 100 / 1440;
				v_end_time         := v_start_time      + v_distances(1) / 1440;                   -- средняя скорость 60 км/ч = 1 км/мин
				
				select RATING into v_pass_rating_min from PASSENGER_RATING where PASSENGER_ID = v_passenger_id;
				
				if v_pass_rating_min < 2.5 then
					v_pass_rating_min := 1;
					v_pass_rating_max := 3;
				else
					v_pass_rating_min := 3;
					v_pass_rating_max := 5;
				end if;
				
				-- создание заказа
				v_order_id := pkg_taxi_api.creating_order(v_passenger_id,   v_start_address_id,             v_addresses_ids, v_distances, 
				                                          v_amount_to_paid, round(dbms_random.value(1, 2)), v_start_time);
				
				-- назначение водителя на заказ
				pkg_taxi_api.assign_car_to_order(v_order_id, v_car_id, v_driver_id, v_start_time);
				
				-- закрытие заказа
				pkg_taxi_api.closing_order(v_order_id, 
				                           null, 
										   round(dbms_random.value(v_driver_rating_min, v_driver_rating_max)), 
										   round(dbms_random.value(v_pass_rating_min,   v_pass_rating_max)), 
										   v_end_time);
				
				--dbms_output.put_line(rpad(v_driver_id, 5)        || '| ' || rpad(v_passenger_id, 5)     || '| ' || 
				--                     rpad(v_start_address_id, 5) || '|'  || rpad(v_addresses_ids(1), 5) || '| ' || 
				--                     rpad(v_distances(1),     5) || '| ' || rpad(v_amount_to_paid, 5)   || '| ' || 
				--                     to_char(v_start_time, 'dd.mm.yyyy hh24:mi:ss') || ' | ' || to_char(v_end_time, 'dd.mm.yyyy hh24:mi:ss'));
				
			end loop;
		end loop;
		
		v_ids_array.delete;		
end gen_orders;
	
	--------------------------------
	-- Процессы закрытия брони машин
	--------------------------------
	-- Водители заправляют машины и закрывают бронь на машину
	procedure gen_ending_rent_car(p_city_id number, p_rent_date date) as
		--p_city_id   number := 10;
		--p_rent_date date   := date'2023-01-01';
		
		v_driver_id            number;
		v_car_id               number;
		v_rent_start_time      date;
		
		v_gasoline_price       number;
		v_currency_id          number;
		v_refueling_address_id number;
		v_distance             number;
		v_gas_mileage          number;
		v_amount_to_paid       number;	
	begin
		--dbms_output.put_line('gen_ending_rent_car: ');
		
		-- стоимость бензина и валюта для заданного города
		select price, currency_id into v_gasoline_price, v_currency_id
		from  gasoline_prices 
		where city_id      = p_city_id
		  and time_create >= p_rent_date 
		  and rownum       = 1 
		order by time_create;
	
		-- для каждого водителя, который арендовал машину в заданном городе
		for i_driver_nmb in 1..v_get_drivers_table.count loop
			v_driver_id       := v_get_drivers_table(i_driver_nmb).driver_id;
			v_car_id          := v_get_drivers_table(i_driver_nmb).car_id;
			v_rent_start_time := v_get_drivers_table(i_driver_nmb).rent_start_time;
			
			v_refueling_address_id := v_get_addresses_table(round(dbms_random.value(1, v_get_addresses_table.count))).address_id;
			
			-- пробег берем из таблицы RENT
			select DISTANCE into v_distance from RENT 
			where  DRIVER_ID  = v_driver_id
			  and  CAR_ID     = v_car_id 
			  and  DATE_START between trunc(p_rent_date) and trunc(p_rent_date) + numtodsinterval(86399, 'second');
			
			v_gas_mileage    := round(v_distance * 0.09);                    -- Норма расхода топлива в городе 9 л на 100 км
			v_amount_to_paid := v_gas_mileage * v_gasoline_price;
			
			pkg_taxi_api.refueling_car(v_driver_id, 
			                           v_refueling_address_id,
			                           v_amount_to_paid, 
			                           round(dbms_random.value(1, 2)), 
									   v_gas_mileage, 
									   p_rent_date);
			
			pkg_taxi_api.removing_car_from_rent(v_driver_id, v_gas_mileage, v_rent_start_time + 8 / 24);
			
			--dbms_output.put_line(rpad(v_driver_id, 5)        || ' | ' || rpad(v_car_id, 5)          || ' | ' || 
			--                     to_char(v_rent_start_time, 'dd.mm.yyyy hh24:mi:ss')                || ' | ' || 
			--                     rpad(v_distance, 5)         || ' | ' || rpad(v_gas_mileage, 10)    || ' | ' ||
			--                     rpad(v_gasoline_price, 5)   || ' | ' || rpad(v_amount_to_paid, 10) || ' | ' || 
			--                     rpad( v_refueling_address_id, 5));
	
		end loop;
	end gen_ending_rent_car;
	
	-----------------------------------
	-- Общий скрипт генерации процессов
	-----------------------------------
	procedure gen_proccesses(p_start_date date, p_days_nmb number) as
		v_tmp_date date;
		v_log_time date;
	begin
		pkg_taxi_api.set_bulk_data_mode;
		
		for i_city in (select id city_id from city order by id) loop
			-- список машин для заданного города
			open  c_get_cars(i_city.city_id);
			fetch c_get_cars bulk collect into v_get_cars_table;
			close c_get_cars;
			
			-- список пассажиров для заданного города
			open  c_get_passengers(i_city.city_id);
			fetch c_get_passengers bulk collect into v_get_passengers_table;
			close c_get_passengers;
			
			-- список адресов для заданного города
			open  c_get_addresses(i_city.city_id);
			fetch c_get_addresses bulk collect into v_get_addresses_table;
			close c_get_addresses;

			for i_day in 0..(p_days_nmb - 1) loop
				v_log_time := sysdate;
				v_tmp_date := p_start_date + i_day;
				
				if v_tmp_date > v_log_time then exit; end if;
			
				--dbms_output.put_line('gen_proccesses: date - ' || to_char(v_tmp_date, 'dd.mm.yyyy hh24:mi:ss') || '; city_id - ' || i_city.city_id);
		
				gen_rent_car(i_city.city_id, v_tmp_date);
				commit;
				
				-- список водителей с арендованными автомобилями
				open  c_get_drivers_with_rent(i_city.city_id, v_tmp_date);
				fetch c_get_drivers_with_rent bulk collect into v_get_drivers_table;
				close c_get_drivers_with_rent;		
		
				gen_orders(i_city.city_id, v_tmp_date);
				commit;
				
				gen_ending_rent_car(i_city.city_id, v_tmp_date);
				commit;
				
				insert into gen_proccesses_log(city_id, gen_date, start_time, end_time)
				values(i_city.city_id, v_tmp_date, v_log_time, sysdate);
			end loop;
			commit;
		end loop;
	end gen_proccesses;

	-----------------------------------
	-- Тестовый скрипт генерации процессов
	-----------------------------------
	procedure test_gen_proccesses(p_city_id number, p_start_date date) as
	begin
		pkg_taxi_api.set_bulk_data_mode;
		
		-- список машин для заданного города
		open  c_get_cars(p_city_id);
		fetch c_get_cars bulk collect into v_get_cars_table;
		close c_get_cars;
		
		-- список пассажиров для заданного города
		open  c_get_passengers(p_city_id);
		fetch c_get_passengers bulk collect into v_get_passengers_table;
		close c_get_passengers;
		
		-- список адресов для заданного города
		open  c_get_addresses(p_city_id);
		fetch c_get_addresses bulk collect into v_get_addresses_table;
		close c_get_addresses;

		--dbms_output.put_line('gen_proccesses: date - ' || to_char(p_start_date, 'dd.mm.yyyy hh24:mi:ss') || '; city_id - ' || p_city_id);
		
		gen_rent_car(p_city_id, p_start_date);
		commit;
		
		-- список водителей с арендованными автомобилями
		open  c_get_drivers_with_rent(p_city_id, p_start_date);
		fetch c_get_drivers_with_rent bulk collect into v_get_drivers_table;
		close c_get_drivers_with_rent;		
		
		gen_orders(p_city_id, p_start_date);
		commit;
		
		gen_ending_rent_car(p_city_id, p_start_date);
		commit;
	end test_gen_proccesses;
end pkg_gen_proccesses_api;
/
