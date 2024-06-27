CREATE OR REPLACE package pkg_gen_data_api as
	-------------------------------------------
	-- Загрузка и генерация данных справочников
	-------------------------------------------
	type get_addresses_type  is record(address_id number);
	type get_addresses_table is table of get_addresses_type;
	
	v_get_addresses_table get_addresses_table;
	
	cursor c_get_addresses(p_city_id number) is
		select a.id address_id
		from address a
		join street s on a.street_id = s.id 
		where s.city_id = p_city_id;
		
	procedure load_info;
	procedure gen_countries(        p_countries_nmb   number);
	procedure gen_cities(           p_cities_nmb      number);
	procedure gen_streets(          p_streets_nmb     number);
	procedure gen_addresses(        p_addresses_nmb   number);
	procedure gen_passengers(       p_max_nmb_in_city number);
	procedure gen_passengers_images;
	procedure gen_passenger_ratings;
	procedure gen_currencies;
	procedure gen_drivers(          p_max_nmb_in_city number);
	procedure gen_drivers_images;
	procedure gen_drivers_ratings;
	procedure gen_parking(          p_max_nmb_in_city number);
	procedure gen_cars;
	procedure gen_rates(            p_start_year      date);
	procedure gen_gasoline_prices(  p_start_year      date);
	procedure gen_exchange_rates(   p_start_year      date);
	
	procedure gen_data;
end pkg_gen_data_api;
/

CREATE OR REPLACE package body pkg_gen_data_api as
	-------------------------------------------
	-- Загрузка и генерация данных справочников
	-------------------------------------------
	procedure load_info as
	begin
		insert into car_colors(id, car_colors_name) values(1, 'Белый');
		insert into car_colors(id, car_colors_name) values(2, 'Черный');
		insert into car_colors(id, car_colors_name) values(3, 'Серый');
		insert into car_colors(id, car_colors_name) values(4, 'Красный');
		insert into car_colors(id, car_colors_name) values(5, 'Голубой');
		insert into car_colors(id, car_colors_name) values(6, 'Желтый');
		insert into car_colors(id, car_colors_name) values(7, 'Зеленый');
		commit;
		
		insert into order_statuses(id, order_status_name) values(1, 'Поиск машины');
		insert into order_statuses(id, order_status_name) values(2, 'Ожидание машины');
		insert into order_statuses(id, order_status_name) values(3, 'Ожидание пассажира');
		insert into order_statuses(id, order_status_name) values(4, 'Начало поездки');
		insert into order_statuses(id, order_status_name) values(5, 'Ожидание оплаты');
		insert into order_statuses(id, order_status_name) values(6, 'Отмена заказа');
		insert into order_statuses(id, order_status_name) values(7, 'Завершение поездки');
		commit;
		
		insert into payment_types(id, payment_type_name) values(1, 'Наличные');
		insert into payment_types(id, payment_type_name) values(2, 'Карта');
		commit;
		
		insert into gender(id,name) values(0,'не определено');
		insert into gender(id,name) values(1,'мужской');
		insert into gender(id,name) values(2,'женский');
		commit;
	end load_info;
	
	---------------------------------------------------------------
	procedure gen_countries(p_countries_nmb number) as
		v_str_tmp varchar2(100) := 'Страна';
		v_out_str varchar2(255);
	begin
		dbms_output.put_line('gen_countries: ');
		
		for v_nmb in 1..p_countries_nmb loop
			v_out_str := v_str_tmp || '_' || v_nmb;
			
			insert into country(name) values(v_out_str);
		end loop;
		commit;
	end gen_countries;
	
	---------------------------------------------------------------
	procedure gen_cities(p_cities_nmb number) as
		v_str_tmp varchar2(100) := 'Город';
		v_out_str varchar2(255);
	begin
		dbms_output.put_line('gen_cities: ');
		
		for c in (select id country_id from country) loop
			for i in 1..p_cities_nmb loop
				v_out_str := v_str_tmp || '_' || c.country_id || '_' || i;
				
				insert into city(name,country_id) values(v_out_str, c.country_id);
			end loop;
		end loop;
		commit;
	end gen_cities;
	
	---------------------------------------------------------------
	procedure gen_streets(p_streets_nmb number) as
		v_str_tmp varchar2(100) := 'Улица';
		v_out_str varchar2(255);
	begin
		dbms_output.put_line('gen_streets: ');
		
		for c in (select id city_id, country_id from city) loop
			for i in 1..p_streets_nmb loop
				v_out_str := v_str_tmp || '_' || c.country_id || '_' || c.city_id || '_' || i;
			
				insert into street(name,city_id) values(v_out_str, c.city_id);
			end loop;
		end loop;
		commit;
	end gen_streets;
	
	---------------------------------------------------------------
	procedure gen_addresses(p_addresses_nmb number) as
	begin
		dbms_output.put_line('gen_addresses: ');
		
		for c in (select id street_id from street) loop
			for i in 1..p_addresses_nmb loop
				insert into address(house_number,street_id) values(i, c.street_id);
			end loop;
		end loop;
		commit;
	end gen_addresses;
	
	---------------------------------------------------------------
	procedure gen_passengers(p_max_nmb_in_city number) as
		v_rnd_nmb         number;
		v_str_tmp         varchar2(100) := 'Пассажир';
		v_out_str         varchar2(255);
	begin
		dbms_output.put_line('gen_passengers: ');
			
		for c in (select id city_id, REGEXP_REPLACE(NAME, '^\w+_(\d+_\d+)', '\1') city_postfix from CITY) loop
			open  c_get_addresses(c.city_id);
			fetch c_get_addresses bulk collect into v_get_addresses_table;
			close c_get_addresses;
			
			for i in 1..p_max_nmb_in_city loop
				v_out_str := v_str_tmp || '_' || c.city_postfix || '_' || i;
				v_rnd_nmb := round(dbms_random.value(1, v_get_addresses_table.count));
				
				insert into passenger(name, age, home_address_id, phone_number, gender_id) 
				values(v_out_str, round(dbms_random.value(20, 70)), v_get_addresses_table(v_rnd_nmb).address_id,
					   '(111) 111 111 1111', round(dbms_random.value(1, 2))); 
			end loop;
		end loop;
		commit;
	end gen_passengers;
	
	---------------------------------------------------------------
	procedure gen_passengers_images as
	begin
		dbms_output.put_line('gen_passengers_images: ');
	
		for c in (select p.id, p.gender_id from passenger p order by id) loop
			--dbms_output.put_line(c.id || ' - ' || c.gender_id);
			
			if    c.gender_id = 1 then
				insert into PASSENGER_IMAGE(PASSENGER_ID, IMAGE) values(c.id, bfilename('BLOB_DIR','men.jpg'));
			elsif c.gender_id = 2 then
				insert into PASSENGER_IMAGE(PASSENGER_ID, IMAGE) values(c.id, bfilename('BLOB_DIR','women.jpg'));
			else
				insert into PASSENGER_IMAGE(PASSENGER_ID, IMAGE) values(c.id, bfilename('BLOB_DIR','unknown.jpg'));
			end if;
		end loop;
		commit;
	end gen_passengers_images;
	
	---------------------------------------------------------------
	procedure gen_passenger_ratings as
	begin
		dbms_output.put_line('gen_passenger_ratings: ');
	
		for c in (select p.id from passenger p order by id) loop
			insert into passenger_rating(passenger_id, rating) values(c.id, round(dbms_random.value(1, 5)));
		end loop;
		commit;
	end gen_passenger_ratings;
	
	---------------------------------------------------------------
	procedure gen_currencies as
		v_str_tmp  varchar2(100) := 'Валюта';
		v_abbr_str varchar2(8)   := 'CRS';
	begin
		
		dbms_output.put_line('gen_currencies: ');
		
		for c in (select id from country) loop
			insert into currency(name, abbreviation, country_id) values(v_str_tmp || c.id, v_abbr_str || c.id, c.id);
		end loop;
		commit;
	end gen_currencies;
	
	---------------------------------------------------------------
	procedure gen_drivers(p_max_nmb_in_city number) as
		v_str_tmp varchar2(100) := 'Водитель';
		v_out_str varchar2(255);
	begin
		dbms_output.put_line('gen_drivers: ');
		
		for c in (select id city_id, REGEXP_REPLACE(NAME, '^\w+(_\d+_\d+)', '\1') city_postfix from CITY) loop
			for i  in 1..p_max_nmb_in_city loop
				v_out_str := v_str_tmp || c.city_postfix || '_' || i;
			
				insert into driver(name, age, phone_number, city_id, percent_of_payment, registration_date)
				values( v_out_str, 
						round(dbms_random.value(24, 60)),
						'(111) 111 111 1111', 
						c.city_id, 
						round(dbms_random.value(70, 90)), 
						date'2010-01-01');
			end loop;
		end loop;
		commit;
	end gen_drivers;
	
	---------------------------------------------------------------
	procedure gen_drivers_images as
	begin
		dbms_output.put_line('gen_drivers_images: ');
		
		for c in (select id driver_id from driver) loop
			insert into driver_image(driver_id, image) values(c.driver_id, bfilename('BLOB_DIR', 'driver.jpg'));
		end loop;
		commit;
	end gen_drivers_images;
	
	---------------------------------------------------------------
	procedure gen_drivers_ratings as
	begin
		dbms_output.put_line('gen_drivers_ratings: ');
		
		for c in (select id from driver order by id) loop
			insert into driver_rating(driver_id, rating) values(c.id, round(dbms_random.value(1, 5)));
		end loop;
		commit;
	end gen_drivers_ratings;
	
	---------------------------------------------------------------
	procedure gen_parking(p_max_nmb_in_city number) as
		v_parking_nmb number := 0;
		v_rnd_nmb     number;
	begin
		dbms_output.put_line('gen_parking: ');
		
		select nvl(max(parking_nmb), 0) into v_parking_nmb from parking p;
		
		for c in (select id city_id from city) loop
			open c_get_addresses(c.city_id);
			fetch c_get_addresses bulk collect into v_get_addresses_table;
			close c_get_addresses;
	
			for i  in 1..p_max_nmb_in_city loop
				v_parking_nmb := v_parking_nmb + 1;
				v_rnd_nmb     := round(dbms_random.value(1, v_get_addresses_table.count));
				
				insert into parking(parking_nmb, address_id) values(v_parking_nmb, v_get_addresses_table(v_rnd_nmb).address_id);
			end loop;
		end loop;
		commit;
	end gen_parking;
	
	---------------------------------------------------------------
	-- для каждой парковки, сгенерим авто
	procedure gen_cars as
		v_min_color_id number;
		v_max_color_id number;
		v_nmb          number := 0;
		v_stat_number  number;
	begin
		select min(id), max(id) into v_min_color_id, v_max_color_id from car_colors;
		dbms_output.put_line('gen_cars: ');
		
		select nvl(max(TO_NUMBER(c.STATE_NUMBER)), 100) into v_stat_number from CAR c;
		
		for c in (select p.id parking_id from parking p where not exists(select 1 from car c where c.parking_id = p.id)) loop
			v_nmb := v_nmb + 1;
			
			insert into car(brand, model, color_id, is_reserved, state_number, parking_id, mileage) 
			values ('Hyundai',
					'Solaris',
					round(dbms_random.value(v_min_color_id, v_max_color_id)),
					0,
					to_char(v_stat_number + v_nmb),
					c.parking_id,
					0);
		end loop;
		commit;
	end gen_cars;
	
	---------------------------------------------------------------
	-- массив тарифов с начала заданного года по текущую дату
	-- тариф может менятся каждый месяц в сторону увеличения или уменьшения
	procedure gen_rates(p_start_year date) as
		--p_start_year date   := date'2021-01-01';
		
		v_days_nmb          number;
		v_currency_id       number;
		v_tmp_date          date;
		v_current_rate      number;
		v_previous_entry_id number;
	begin
		dbms_output.put_line('gen_rates: ');
		
		v_days_nmb := trunc(sysdate) - trunc(p_start_year, 'yyyy');
		
		for c in (select id city_id from city) loop
			select cr.id into v_currency_id 
			from   currency cr 
			join   city ct on cr.country_id = ct.country_id and ct.id = c.city_id;
			
			-- базовый тариф для города
			v_current_rate := round(dbms_random.value(3, 10), 2);
			
			v_previous_entry_id := null;
			for i_day_nmb in 0..v_days_nmb loop
				v_tmp_date     := p_start_year   + i_day_nmb;
				v_current_rate := v_current_rate + round(v_current_rate * dbms_random.value(-0.03, 0.03), 2);
				
				--dbms_output.put_line(to_char(c.city_id) || ' - ' || TO_CHAR(V_CURRENT_RATE) || ' - ' || TO_CHAR(V_TMP_DATE, 'DD.MM.YYYY'));
				
				-- предыдущую запись надо закрыть 
				if v_previous_entry_id is not null then
					update RATE set END_DATE = v_tmp_date - 1 where ID = v_previous_entry_id;
				end if;
				
				-- новый тариф
				insert into RATE(CURRENCY_ID, RATE, CITY_ID, START_DATE, END_DATE) 
				values(v_currency_id, v_current_rate, c.city_id, v_tmp_date, date'2099-12-31') returning ID into v_previous_entry_id;
				
			end loop;
		end loop;
		commit;
	end gen_rates;
	
	-----------------------------------------------------------------
	-- массив цен на топливо с начала заданного года по текущую дату
	-- цена меняется каждый день в сторону увеличения или уменьшения
	procedure gen_gasoline_prices(p_start_year date) as
		--p_start_year date   := date'2021-01-01';
		
		v_days_nmb          number;
		v_curr_country_id number := null;
		v_currency_id     number;
		v_country_price   number;
		v_current_price   number;
		v_price_time      date;
	begin
		dbms_output.put_line('gen_gasoline_prices: ');
		
		v_days_nmb := trunc(sysdate) - trunc(p_start_year, 'yyyy');
		
		for c_country in (select id from country) loop
			select cr.id into v_currency_id 
			from   currency cr 
			where  cr.country_id = c_country.id;
			
			-- базовая цена для страны
			if c_country.id = 1 then
				v_country_price := 53;
			else
				v_country_price := round(dbms_random.value(1, 5));
			end if;
			
			for c_city in (select c.id city_id from city c where c.country_id = c_country.id) loop
				-- базовая цена для города
				v_current_price := v_country_price + round(v_country_price * dbms_random.value(-0.03, 0.03), 2);
				
				for i_day_nmb in 0..v_days_nmb loop
					v_price_time    := p_start_year + i_day_nmb;
					v_current_price := v_current_price + round(v_current_price * dbms_random.value(-0.03, 0.03), 2);
					
					--dbms_output.put_line(to_char(c_city.city_id) || ' - ' || to_char(v_current_price) || ' - ' || 
					--                     to_char(v_price_time, 'dd.mm.yyyy'));
					
					insert into gasoline_prices(currency_id, price, city_id, price_date) 
					values(v_currency_id, v_current_price, c_city.city_id, v_price_time);
				end loop;
			end loop;
		end loop;
		commit;
	end gen_gasoline_prices;

	---------------------------------------------------------------
	-- массив курсов валют по отношению к базовой (рубль) с начала заданного года по текущую дату
	-- курс меняется каждый день в сторону увеличения или уменьшения
	procedure gen_exchange_rates(p_start_year date) as
		--p_start_year date   := date'2021-01-01';
		
		v_days_nmb          number;
		v_currency_id   number;
		v_currency_rate number;
		v_tmp_date      date;
	begin
		dbms_output.put_line('gen_exchange_rates: ');
		
		v_days_nmb := trunc(sysdate) - trunc(p_start_year, 'yyyy');
		
		-- валюта страны с id = 1 - базовая, относительно неё указывается курс остальных валют
		for c in (select id country_id from country where id > 1) loop
			select cr.id into v_currency_id 
			from   currency   cr 
			join   country    cnt on cr.country_id = cnt.id and cnt.id = c.country_id;
						
			-- начальный курс для страны
			v_currency_rate := round(dbms_random.value(50, 100), 2);

			for i_day_nmb in 0..v_days_nmb loop
				v_tmp_date      := p_start_year    + i_day_nmb;
				v_currency_rate := v_currency_rate + round(dbms_random.value(-1, 1), 2);
								
				insert into EXCHANGE_RATES(CURRENCY_ID, EXCHANGE_RATE, RATE_DATE) 
				values(v_currency_id, v_currency_rate, v_tmp_date);
				
				--dbms_output.put_line(v_currency_id || ' - ' || v_currency_rate || ' - ' || to_char(v_tmp_date, 'dd.mm.yyyy'));
			end loop;
		end loop;
		commit;
	end gen_exchange_rates;

	-----------------------------------------------------------------
	-- скрипт загрузки и генерации всех данных
	procedure gen_data as
		v_countries_nmb          number;
		v_cities_nmb             number;
		v_streets_nmb            number;
		v_addresses_nmb          number;
		v_max_passengers_in_city number;
		v_max_drivers_in_city    number;
		v_max_parking_in_city    number;
		v_start_year             date;
		v_years_nmb              number;
	begin
		v_countries_nmb          := 3;
		v_cities_nmb             := 10;
		v_streets_nmb            := 50;
		v_addresses_nmb          := 100;
		v_max_passengers_in_city := 1000;
		v_max_drivers_in_city    := 45;
		v_max_parking_in_city    := 45;
		v_start_year             := date'2022-01-01';
		
		load_info;
		gen_countries(v_countries_nmb);
		gen_cities(v_cities_nmb);
		gen_streets(v_streets_nmb);
		gen_addresses(v_addresses_nmb);
		gen_passengers(v_max_passengers_in_city);
		gen_passengers_images;
		gen_passenger_ratings;
		gen_drivers(v_max_drivers_in_city);
		gen_drivers_images;
		gen_drivers_ratings;
		gen_currencies;
		gen_parking(v_max_parking_in_city);
		gen_cars;
		gen_rates(v_start_year);
		gen_gasoline_prices(v_start_year);
		gen_exchange_rates(v_start_year);
	end gen_data;
end pkg_gen_data_api;
/
