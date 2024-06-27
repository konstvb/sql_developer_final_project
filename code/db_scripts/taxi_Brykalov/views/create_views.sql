create or replace view vw_full_address as 
	select a.id    address_id, 
	       cn.id   country_id, 
	       cn.name country, 
		   c.id    city_id, 
		   c.name  city, 
		   s.id    street_id, 
		   s.name  street, 
		   a.house_number, 
		   cn.name || ', г. ' || c.name || ', ул. ' || s.name ||', д. ' || a.house_number full_addr
	from address  a
	join street   s  on a.street_id  = s.id
	join city     c  on s.city_id    = c.id
	join country  cn on c.country_id = cn.id;

-- Представление, которое для каждого пользователя выдает 5 водителей, с которыми он ещё не ездил и у которых средняя оценка выше 4
-- Если взять за весь период, то большая вероятность, что пассажир ездил со всеми водителями, 
-- поэтому ограничил выборку водителей последним месяцем
create or replace view vw_drivers_for_passenger as 
	with drivers_for_passenger as (
		select t.*, row_number() over(partition by t.passenger_id order by t.driver_id) rn
		from (
			select p.ID passenger_id, d.ID driver_id 
			from   PASSENGER        p
			join   VW_FULL_ADDRESS fa on fa.ADDRESS_ID = p.HOME_ADDRESS_ID
			join   DRIVER           d on d.CITY_ID     = fa.CITY_ID
			join   DRIVER_RATING   dr on dr.DRIVER_ID  = d.ID and dr.RATING > 4
			minus
			select o.PASSENGER_ID, o.DRIVER_ID
			from PASSENGER p
			join ORDERS    o on o.PASSENGER_ID  = p.ID 
							and o.TIME_START   >= (select trunc(MAX(TIME_START), 'mm') from ORDERS)
			group by o.PASSENGER_ID, o.DRIVER_ID
		) t
	)
	select passenger_id, driver_id from drivers_for_passenger where rn <= 5;

-- Представление, которое для каждого пользователя, у которых больше 10 поездок, 
-- в порядке убывания подберёт 5 самых частых мест начала или окончания поездки.
-- Ограничил по времени - за последний год
-- Более оптимально можно сделать, как материализованное представление
create or replace view vw_passenger_often_addrs as 
	with 
	pass_addr_nmb as (
		select o.PASSENGER_ID, o.END_TRIP_ADDRESS_ID, w.FROM_ADDRESS_ID , count(1) cnt
		from ORDERS o 
		join WAY w on o.ID = w.ORDER_ID and w.PREVIEW_WAY_ID is null 
		where o.TIME_START >= add_months(trunc(sysdate, 'yyyy') , -12)
		and o.PASSENGER_ID in (
			select o.PASSENGER_ID from ORDERS o 
			where o.TIME_START >= add_months(trunc(sysdate, 'yyyy') , -12)
			group by o.PASSENGER_ID
			having count(1) > 10		
		)
		group by o.PASSENGER_ID, o.END_TRIP_ADDRESS_ID, w.FROM_ADDRESS_ID 
	), 
	pass_addr as (
		select t.*, row_number() over(partition by t.PASSENGER_ID order by t.cnt desc) rn
		from pass_addr_nmb t
	)
	select PASSENGER_ID, FROM_ADDRESS_ID, END_TRIP_ADDRESS_ID, cnt from pass_addr where rn <= 5;

-- Представление, которое отобразит, в каких городах самые дорогие тарифы на бензин в основной валюте
-- с учётом курса валюты на тот момент, когда была оплата за бензин
create or replace view vw_gasoline_prices as 
	select gp.PRICE_DATE, ct.NAME city, round(gp.PRICE * nvl(er.EXCHANGE_RATE, 1), 2) base_price
	from      GASOLINE_PRICES gp
	join      CITY            ct on gp.CITY_ID     = ct.ID 
	join      CURRENCY        cr on gp.CURRENCY_ID = cr.ID
	left join EXCHANGE_RATES  er on cr.ID           = er.CURRENCY_ID
								and er.RATE_DATE    = gp.PRICE_DATE
	order by gp.PRICE_DATE, base_price desc;

-- Представление, которое отобразит средний чек за поездку в разных странах.
-- Более оптимально можно сделать, как материализованное представление. (Выборка 20 сек)
create or replace view vw_avg_amount_to_paid as 
	select oo.date_start, oo.COUNTRY_NAME, ROUND(AVG(p.AMOUNT_TO_PAID),2) avg_amount
	from (
		SELECT trunc(o.TIME_START) date_start, o.DRIVER_ID, o.PAYMENT_ID, c.NAME country_name
		FROM   ORDERS o
		join DRIVER   d on o.DRIVER_ID   = d.ID
		join CITY    ct on d.CITY_ID     = ct.ID
		join COUNTRY c  on ct.COUNTRY_ID = c.ID
	) oo
	join PAYMENT  p on oo.PAYMENT_ID = p.ID 
	group by oo.date_start, oo.COUNTRY_NAME;

-- Представление, которое отобразит месячную динамику цен на проезд за 1 километр в городах
create or replace view vw_travel_prices_dynamics as 
	select r.START_DATE price_date, ct.NAME city, ct.COUNTRY_ID, r.RATE
	from RATE r
	join CITY ct on r.CITY_ID = ct.ID;
