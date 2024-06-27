create table country(
	id          number(10)    generated as identity, 
	name        varchar2(255) not null, 
	time_create timestamp     not null, 
	primary key(id)
);

create or replace trigger country_trg 
	before insert on country for each row
begin
	:new.time_create := systimestamp;
end;
/

comment on table  country             is 'Список стран';
comment on column country.id          is 'Идентификатор страны';
comment on column country.name        is 'Наименование страны';
comment on column country.time_create is 'Дата и время создания записи';

-----------------------------------------
create table city(
	id          number(10)    generated as identity, 
	name        varchar2(255) not null, 
	country_id  number(10)    not null, 
	time_create timestamp     not null, 
	primary key(id),
	foreign key(country_id) references country(id)
);

create or replace trigger city_trg 
	before insert on city for each row
begin
	:new.time_create := systimestamp;
end;
/

comment on table  city             is 'Список городов';
comment on column city.id          is 'Идентификатор города';
comment on column city.name        is 'Наименование города';
comment on column city.country_id  is 'Идентификатор страны';
comment on column city.time_create is 'Дата и время создания записи';

-----------------------------------------
create table street(
	id          number(10)    generated as identity, 
	name        varchar2(255) not null, 
	city_id     number(10)    not null, 
	time_create timestamp     not null, 
	primary key(id),
	foreign key(city_id) references city(id)
);

create or replace trigger street_trg 
	before insert on street for each row
begin
	:new.time_create := systimestamp;
end;
/

comment on table  street             is 'Список улиц';
comment on column street.id          is 'Идентификатор улицы';
comment on column street.name        is 'Наименование улицы';
comment on column street.city_id     is 'Идентификатор города';
comment on column street.time_create is 'Дата и время создания записи';

-----------------------------------------
create table address(
	id           number(10) generated as identity,
	house_number number(10) not null, 
	street_id    number(10) not null,
	time_create  timestamp  not null, 
	primary key(id),
	foreign key(street_id) references street(id)
);

create or replace trigger address_trg 
	before insert on address for each row
begin
	:new.time_create := systimestamp;
end;
/

comment on table  address              is 'Адреса';
comment on column address.id           is 'Идентификатор адреса';
comment on column address.house_number is 'Номер дома';
comment on column address.street_id    is 'Идентификатор улицы';
comment on column address.time_create  is 'Дата и время создания записи';

-----------------------------------------
create table gender(
	id   number(1)    not null, 
	name varchar2(50) not null, 
	primary key(id)
);
 
comment on table  gender      is 'Пол пассажира';
comment on column gender.id   is 'Идентификатор пола';
comment on column gender.name is 'Наименование пола';

-----------------------------------------
create table passenger(
	id              number(10) generated as identity, 
	name            varchar2(255), 
	age             number(5), 
	home_address_id number(10), 
	phone_number    varchar2(50) not null, 
	gender_id       number(1)    not null, 
	time_create     timestamp    not null, 
	primary key(id),
	foreign key(home_address_id) references address (id), 
	foreign key(gender_id) references gender(id)
);

create or replace trigger passenger_trg 
	before insert on passenger for each row
begin
	:new.time_create := systimestamp;
end;
/

comment on table  passenger                 is 'Пассажиры';
comment on column passenger.id              is 'Идентификатор пассажира';
comment on column passenger.name            is 'Имя';
comment on column passenger.age             is 'Возраст';
comment on column passenger.home_address_id is 'Идентификатор домашнего адреса';
comment on column passenger.phone_number    is 'Номер телефона';
comment on column passenger.gender_id       is 'Идентификатор пола пассажира';
comment on column passenger.time_create     is 'Дата и время создания записи';

-----------------------------------------
create table passenger_image(
	passenger_id number(10) not null,
	image        blob,
	time_create  timestamp  not null,
	primary key(passenger_id),
	foreign key(passenger_id) references passenger(id)
);

create or replace trigger passenger_image_trg 
	before insert on passenger_image for each row
begin
	:new.time_create := systimestamp;
end;
/

comment on table  passenger_image              is 'Фотографии пассажиров';
comment on column passenger_image.passenger_id is 'Идентификатор пассажира';
comment on column passenger_image.image        is 'Фото';
comment on column passenger_image.time_create  is 'Дата и время создания записи';

-----------------------------------------
create table passenger_rating(
	passenger_id  number(10) not null, 
	rating        number(1)  not null, 
	updating_time timestamp  not null, 
	primary key(passenger_id),
	foreign key(passenger_id) references passenger(id),
	constraint passenger_rating_chk check (rating between 1 and 5)
);

create or replace trigger passenger_rating_trg 
	before insert or update on passenger_rating for each row
begin
	:new.updating_time := systimestamp;
end;
/

comment on table  passenger_rating               is 'Рейтинги пассажиров';
comment on column passenger_rating.passenger_id  is 'Идентификатор пассажира';
comment on column passenger_rating.rating        is 'Оценка от 1 до 5';
comment on column passenger_rating.updating_time is 'Дата и время обновления рейтинга';

-----------------------------------------
create table driver(
	id                 number(10)    generated as identity, 
	name               varchar2(255) not null, 
	age                number(5)     not null, 
	phone_number       varchar2(50)  not null, 
	city_id            number        not null, 
	percent_of_payment number        not null, 
	registration_date  date          not null, 
	time_create        timestamp     not null, 
	primary key(id),
	foreign key(city_id) references city(id)
);

create or replace trigger driver_trg 
	before insert on driver for each row
begin
	:new.time_create := systimestamp;
end;
/

comment on table  driver                    is 'Список водителей';
comment on column driver.id                 is 'Идентификатор ';
comment on column driver.name               is 'Имя';
comment on column driver.age                is 'Возраст';
comment on column driver.phone_number       is 'Номер телефона';
comment on column driver.city_id            is 'Идентификатор города водителя';
comment on column driver.percent_of_payment is 'Сколько водитель получает от каждого чека';
comment on column driver.registration_date  is 'Дата регистрации';
comment on column driver.time_create        is 'Дата и время создания записи';

-----------------------------------------
create table driver_image(
	driver_id   number(10) not null, 
	image       blob, 
	time_create timestamp  not null, 
	primary key(driver_id),
	foreign key(driver_id) references driver(id)
);

create or replace trigger driver_image_trg 
	before insert on driver_image for each row
begin
	:new.time_create := systimestamp;
end;
/

comment on table  driver_image             is 'Фотографии водителей';
comment on column driver_image.driver_id   is 'Идентификатор водителя';
comment on column driver_image.image       is 'Фото';
comment on column driver_image.time_create is 'Дата и время создания записи';

-----------------------------------------
create table driver_rating(
	driver_id     number(10) not null, 
	rating        number     not null, 
	updating_time timestamp  not null, 
	primary key(driver_id),
	foreign key(driver_id) references driver (id)
);

create or replace trigger driver_rating_trg 
	before insert on driver_rating for each row
begin
	:new.updating_time := systimestamp;
end;
/

comment on table  driver_rating               is 'Рейтинги водителей';
comment on column driver_rating.driver_id     is 'Идентификатор водителя';
comment on column driver_rating.rating        is 'Рейтинг';
comment on column driver_rating.updating_time is 'Дата и время обновления рейтинга';

-----------------------------------------
create table car_colors(
	id              number(2)    not null, 
	car_colors_name varchar2(20) not null, 
	time_create     timestamp    not null, 
	primary key(id)
);

create or replace trigger car_colors_trg
	before insert on car_colors for each row
begin
	:new.time_create := systimestamp;
end;
/

comment on table  car_colors                 is 'Список цветов автомобиля';
comment on column car_colors.id              is 'Идентификатор ';
comment on column car_colors.car_colors_name is 'Цвет';
comment on column car_colors.time_create     is 'Дата и время создания записи';

-----------------------------------------
create table parking(
	id          number(10) generated as identity, 
	parking_nmb number(10) not null, 
	address_id  number(10) not null, 
	time_create timestamp  not null, 
	primary key(id),
	foreign key(address_id) references address(id),
	constraint parking_nmb_uniq unique (parking_nmb)
);

create or replace trigger parking_trg 
	before insert on parking for each row
begin
	:new.time_create := systimestamp;
end;
/

comment on table  parking             is 'Место парковки автомобиля';
comment on column parking.id          is 'Идентификатор ';
comment on column parking.parking_nmb is 'Номер парковки';
comment on column parking.address_id  is 'Идентификатор адреса парковки';
comment on column parking.time_create is 'Дата и время создания записи';

-----------------------------------------
create table car(
	id            number(10)   generated as identity, 
	brand         varchar2(50) not null, 
	model         varchar2(50) not null, 
	color_id      number(2)    not null, 
	is_rended     number(1)    default 0,
	driver_id     number,
	rent_date     date, 
	is_reserved   number(1)    default 0, 
	reserved_date date, 
	state_number  varchar2(50) not null, 
	parking_id    number(10)   not null, 
	mileage       number       not null, 
	time_create   timestamp    not null, 
	primary key(id),
	foreign key(parking_id)        references parking(id),
	foreign key(color_id)          references car_colors(id),
	foreign key(driver_id)         references driver(id),
	constraint car_state_nmb_uniq  unique (state_number),
	constraint car_is_reserved_chk check (is_reserved in (0,1))
);

create or replace trigger car_trg 
	before insert on car for each row
begin
	:new.time_create := systimestamp;
end;
/

comment on table  car               is 'Автомобили';
comment on column car.id            is 'Идентификатор автомобиля';
comment on column car.brand         is 'Марка';
comment on column car.model         is 'Модель';
comment on column car.color_id      is 'Идентификатор цвета';
comment on column car.is_rended     is 'В аренде? 0 - нет, 1 - да';
comment on column car.rent_date     is 'Дата и время начала аренды. Если не арендован, то null';
comment on column car.driver_id     is 'Идентификатор водителя арендовавшего автомобиль. Если не арендован, то null';
comment on column car.is_reserved   is 'Заказан? 0 - нет, 1 - да';
comment on column car.reserved_date is 'Дата и время начала заказа. Если не заказан, то null';
comment on column car.state_number  is 'Гос номер';
comment on column car.parking_id    is 'Идентификатор парковки';
comment on column car.mileage       is 'Пробег в км';
comment on column car.time_create   is 'Дата и время создания записи';

-----------------------------------------
create table currency(
	id           number(  10) generated as identity, 
	name         varchar2(50) not null, 
	abbreviation varchar2(8)  not null, 
	country_id   number(  10) not null, 
	time_create  timestamp    not null, 
	primary key(id),
	foreign key(country_id) references country(id)
);

create or replace trigger currency_trg 
	before insert on currency for each row
begin
	:new.time_create := systimestamp;
end;
/

comment on table  currency              is 'Валюты. Id = 1 - основная валюта';
comment on column currency.id           is 'Идентификатор валюты';
comment on column currency.name         is 'Наименование валюты';
comment on column currency.abbreviation is 'Сокращенное наименование валюты';
comment on column currency.country_id   is 'Идентификатор страны';
comment on column currency.time_create  is 'Дата и время создания записи';

-----------------------------------------
create table exchange_rates(
	id            number(10) generated as identity,
	currency_id   number(10) not null,
	exchange_rate number(10) not null,
	rate_date     date       not null,
	primary key(id),
	foreign key(currency_id) references currency(id) 
);

comment on table  exchange_rates               is 'Курсы валют';
comment on column exchange_rates.id            is 'Идентификатор курса';
comment on column exchange_rates.currency_id   is 'Идентификатор валюты';
comment on column exchange_rates.exchange_rate is 'Курс валюты относительно основной валюты (currency.id = 1)';
comment on column exchange_rates.rate_date     is 'Дата курса';

-----------------------------------------
create table rate(
	id           number(10) generated as identity, 
	currency_id  number(10)   not null, 
	rate         number(10,2) not null, 
	city_id      number(10)   not null, 
	start_date   date         not null,
	end_date     date         not null,
	time_create  timestamp    not null, 
	primary key(id),
	foreign key(currency_id) references currency(id), 
	foreign key(city_id)      references city(id)
);


create or replace trigger rate_trg 
	before insert on rate for each row
begin
	:new.time_create := systimestamp;
end;
/

comment on table  rate             is 'Тарифы';
comment on column rate.id          is 'Идентификатор тарифа';
comment on column rate.currency_id is 'Идентификатор валюты';
comment on column rate.rate        is 'Тариф: цена в местной валюте за 1 км';
comment on column rate.city_id     is 'Идентификатор города';
comment on column rate.start_date  is 'Дата начала действия тарифа';
comment on column rate.end_date    is 'Дата окончания действия тарифа (включительно)';
comment on column rate.time_create is 'Дата и время создания записи';

-----------------------------------------
create table payment_types(
	id                number(2)    not null, 
	payment_type_name varchar2(20) not null, 
	time_create       timestamp    not null, 
	primary key(id)
);

create or replace trigger payment_types_trg 
	before insert on payment_types for each row
begin
	:new.time_create := systimestamp;
end;
/

comment on table  payment_types                   is 'Вид оплаты';
comment on column payment_types.id                is 'Идентификатор';
comment on column payment_types.payment_type_name is 'Картой или наличными';
comment on column payment_types.time_create       is 'Дата и время создания записи';

-----------------------------------------
create table payment(
	id              number(10) generated as identity, 
	amount_to_paid  number       not null, 
	currency_id     number(10)   not null, 
	payment_type_id number(1)    not null, 
	payment_date    date         not null, 
	time_create     timestamp    not null, 
	primary key(id),
	foreign key(currency_id)     references currency(id), 
	foreign key(payment_type_id) references payment_types(id)
)
partition by range(payment_date)(
	partition payment_202101 values less than (date'2021-02-01'),
	partition payment_202102 values less than (date'2021-03-01'),
	partition payment_202103 values less than (date'2021-04-01'),
	partition payment_202104 values less than (date'2021-05-01'),
	partition payment_202105 values less than (date'2021-06-01'),
	partition payment_202106 values less than (date'2021-07-01'),
	partition payment_202107 values less than (date'2021-08-01'),
	partition payment_202108 values less than (date'2021-09-01'),
	partition payment_202109 values less than (date'2021-10-01'),
	partition payment_202110 values less than (date'2021-11-01'),
	partition payment_202111 values less than (date'2021-12-01'),
	partition payment_202112 values less than (date'2022-01-01'),
	partition payment_202201 values less than (date'2022-02-01'),
	partition payment_202202 values less than (date'2022-03-01'),
	partition payment_202203 values less than (date'2022-04-01'),
	partition payment_202204 values less than (date'2022-05-01'),
	partition payment_202205 values less than (date'2022-06-01'),
	partition payment_202206 values less than (date'2022-07-01'),
	partition payment_202207 values less than (date'2022-08-01'),
	partition payment_202208 values less than (date'2022-09-01'),
	partition payment_202209 values less than (date'2022-10-01'),
	partition payment_202210 values less than (date'2022-11-01'),
	partition payment_202211 values less than (date'2022-12-01'),
	partition payment_202212 values less than (date'2023-01-01'),
	partition payment_202301 values less than (date'2023-02-01'),
	partition payment_202302 values less than (date'2023-03-01'),
	partition payment_202303 values less than (date'2023-04-01'),
	partition payment_202304 values less than (date'2023-05-01'),
	partition payment_202305 values less than (date'2023-06-01'),
	partition payment_202306 values less than (date'2023-07-01'),
	partition payment_202307 values less than (date'2023-08-01'),
	partition payment_202308 values less than (date'2023-09-01'),
	partition payment_202309 values less than (date'2023-10-01'),
	partition payment_202310 values less than (date'2023-11-01'),
	partition payment_202311 values less than (date'2023-12-01'),
	partition payment_202312 values less than (date'2024-01-01'),
	partition payment_202401 values less than (date'2024-02-01'),
	partition payment_202402 values less than (date'2024-03-01'),
	partition payment_202403 values less than (date'2024-04-01'),
	partition payment_202404 values less than (date'2024-05-01'),
	partition payment_202405 values less than (date'2024-06-01'),
	partition payment_202406 values less than (date'2024-07-01'),
	partition payment_202407 values less than (date'2024-08-01'),
	partition payment_202408 values less than (date'2024-09-01')
);

create or replace trigger payment_trg 
	before insert on payment for each row
begin
	:new.time_create := systimestamp;
end;
/

create index payment_id_date_inx on payment(id, payment_date) local;

comment on table  payment                 is 'Список оплат';
comment on column payment.id              is 'Идентификатор оплаты';
comment on column payment.amount_to_paid  is 'Сумма к оплате';
comment on column payment.currency_id     is 'Идентификатор валюты';
comment on column payment.payment_type_id is 'Идентификатор вида оплаты';
comment on column payment.payment_date    is 'Дата и время оплаты';
comment on column payment.time_create     is 'Дата и время создания записи';

-----------------------------------------
create table rent(
	id          number(10) generated as identity, 
	driver_id   number(10) not null, 
	car_id      number(10) not null, 
	date_start  date       not null, 
	date_stop   date, 
	gas_mileage number     default 0, 
	distance    number     default 0,
	time_create timestamp  not null, 
	primary key(id),
	foreign key(driver_id) references driver(id), 
	foreign key(car_id)    references car(id)
)
partition by range(date_start)(
	partition rent_202101 values less than (date'2021-02-01'),
	partition rent_202102 values less than (date'2021-03-01'),
	partition rent_202103 values less than (date'2021-04-01'),
	partition rent_202104 values less than (date'2021-05-01'),
	partition rent_202105 values less than (date'2021-06-01'),
	partition rent_202106 values less than (date'2021-07-01'),
	partition rent_202107 values less than (date'2021-08-01'),
	partition rent_202108 values less than (date'2021-09-01'),
	partition rent_202109 values less than (date'2021-10-01'),
	partition rent_202110 values less than (date'2021-11-01'),
	partition rent_202111 values less than (date'2021-12-01'),
	partition rent_202112 values less than (date'2022-01-01'),
	partition rent_202201 values less than (date'2022-02-01'),
	partition rent_202202 values less than (date'2022-03-01'),
	partition rent_202203 values less than (date'2022-04-01'),
	partition rent_202204 values less than (date'2022-05-01'),
	partition rent_202205 values less than (date'2022-06-01'),
	partition rent_202206 values less than (date'2022-07-01'),
	partition rent_202207 values less than (date'2022-08-01'),
	partition rent_202208 values less than (date'2022-09-01'),
	partition rent_202209 values less than (date'2022-10-01'),
	partition rent_202210 values less than (date'2022-11-01'),
	partition rent_202211 values less than (date'2022-12-01'),
	partition rent_202212 values less than (date'2023-01-01'),
	partition rent_202301 values less than (date'2023-02-01'),
	partition rent_202302 values less than (date'2023-03-01'),
	partition rent_202303 values less than (date'2023-04-01'),
	partition rent_202304 values less than (date'2023-05-01'),
	partition rent_202305 values less than (date'2023-06-01'),
	partition rent_202306 values less than (date'2023-07-01'),
	partition rent_202307 values less than (date'2023-08-01'),
	partition rent_202308 values less than (date'2023-09-01'),
	partition rent_202309 values less than (date'2023-10-01'),
	partition rent_202310 values less than (date'2023-11-01'),
	partition rent_202311 values less than (date'2023-12-01'),
	partition rent_202312 values less than (date'2024-01-01'),
	partition rent_202401 values less than (date'2024-02-01'),
	partition rent_202402 values less than (date'2024-03-01'),
	partition rent_202403 values less than (date'2024-04-01'),
	partition rent_202404 values less than (date'2024-05-01'),
	partition rent_202405 values less than (date'2024-06-01'),
	partition rent_202406 values less than (date'2024-07-01'),
	partition rent_202407 values less than (date'2024-08-01'),
	partition rent_202408 values less than (date'2024-09-01')
);

create or replace trigger rent_trg 
	before insert on rent for each row
begin
	:new.time_create := systimestamp;
end;
/

create index rent_id_date_idx     on rent(id,        date_start) local; 
create index rent_driver_date_idx on rent(driver_id, date_start) local; 
create index rent_car_date_idx    on rent(car_id,    date_start) local; 

comment on table  rent             is 'Аренда автомобилей';
comment on column rent.id          is 'Идентификатор аренды';
comment on column rent.driver_id   is 'Идентификатор водителя';
comment on column rent.car_id      is 'Идентификатор автомобиля';
comment on column rent.date_start  is 'Дата начала';
comment on column rent.date_stop   is 'Дата окончания';
comment on column rent.gas_mileage is 'Расход топлива в литрах';
comment on column rent.distance    is 'Пройденное расстояние в км';
comment on column rent.time_create is 'Дата и время создания записи';

-----------------------------------------
create table order_statuses(
	id                number(2)    not null, 
	order_status_name varchar2(50) not null, 
	time_create       timestamp    not null, 
	primary key(id)
);

create or replace trigger order_statuses_trg 
	before insert on order_statuses for each row
begin
	:new.time_create := systimestamp;
end;
/

comment on table  order_statuses                   is 'Статусы заказов';
comment on column order_statuses.id                is 'Идентификатор заказа';
comment on column order_statuses.order_status_name is 'Статус';
comment on column order_statuses.time_create       is 'Дата и время создания записи';

-----------------------------------------
create table orders(
	id number(10)        generated as identity, 
	passenger_id         number(10)     not null, 
	driver_id            number(10), 
	time_start           timestamp  not null, 
	time_end             timestamp, 
	status_id            number(2)      not null, 
	payment_id           number(10)     not null, 
	end_trip_address_id  number(10)     not null, 
	average_driver_speed number,
	time_create          timestamp      not null, 
	primary key(id),
	foreign key(passenger_id)        references passenger(id), 
	foreign key(driver_id)           references driver(id), 
	foreign key(payment_id)          references payment(id), 
	foreign key(end_trip_address_id) references address(id), 
	foreign key(status_id)           references order_statuses(id)
)
partition by range(time_start)(
	partition orders_202101 values less than (date'2021-02-01'),
	partition orders_202102 values less than (date'2021-03-01'),
	partition orders_202103 values less than (date'2021-04-01'),
	partition orders_202104 values less than (date'2021-05-01'),
	partition orders_202105 values less than (date'2021-06-01'),
	partition orders_202106 values less than (date'2021-07-01'),
	partition orders_202107 values less than (date'2021-08-01'),
	partition orders_202108 values less than (date'2021-09-01'),
	partition orders_202109 values less than (date'2021-10-01'),
	partition orders_202110 values less than (date'2021-11-01'),
	partition orders_202111 values less than (date'2021-12-01'),
	partition orders_202112 values less than (date'2022-01-01'),
	partition orders_202201 values less than (date'2022-02-01'),
	partition orders_202202 values less than (date'2022-03-01'),
	partition orders_202203 values less than (date'2022-04-01'),
	partition orders_202204 values less than (date'2022-05-01'),
	partition orders_202205 values less than (date'2022-06-01'),
	partition orders_202206 values less than (date'2022-07-01'),
	partition orders_202207 values less than (date'2022-08-01'),
	partition orders_202208 values less than (date'2022-09-01'),
	partition orders_202209 values less than (date'2022-10-01'),
	partition orders_202210 values less than (date'2022-11-01'),
	partition orders_202211 values less than (date'2022-12-01'),
	partition orders_202212 values less than (date'2023-01-01'),
	partition orders_202301 values less than (date'2023-02-01'),
	partition orders_202302 values less than (date'2023-03-01'),
	partition orders_202303 values less than (date'2023-04-01'),
	partition orders_202304 values less than (date'2023-05-01'),
	partition orders_202305 values less than (date'2023-06-01'),
	partition orders_202306 values less than (date'2023-07-01'),
	partition orders_202307 values less than (date'2023-08-01'),
	partition orders_202308 values less than (date'2023-09-01'),
	partition orders_202309 values less than (date'2023-10-01'),
	partition orders_202310 values less than (date'2023-11-01'),
	partition orders_202311 values less than (date'2023-12-01'),
	partition orders_202312 values less than (date'2024-01-01'),
	partition orders_202401 values less than (date'2024-02-01'),
	partition orders_202402 values less than (date'2024-03-01'),
	partition orders_202403 values less than (date'2024-04-01'),
	partition orders_202404 values less than (date'2024-05-01'),
	partition orders_202405 values less than (date'2024-06-01'),
	partition orders_202406 values less than (date'2024-07-01'),
	partition orders_202407 values less than (date'2024-08-01'),
	partition orders_202408 values less than (date'2024-09-01')
);

create or replace trigger orders_trg 
	before insert on orders for each row
begin
	:new.time_create := systimestamp;
end;
/

create index orders_id_date_idx on orders(id, time_start) local;

comment on table  orders                      is 'Заказы';
comment on column orders.id                   is 'Идентификатор заказа';
comment on column orders.passenger_id         is 'Идентификатор пассажира';
comment on column orders.driver_id            is 'Идентификатор водителя';
comment on column orders.time_start           is 'Дата и время начала';
comment on column orders.time_end             is 'Дата и время окончания';
comment on column orders.status_id            is 'Идентификатор статуса заказа';
comment on column orders.payment_id           is 'Идентификатор оплаты';
comment on column orders.end_trip_address_id  is 'Идентификатор конечного адреса поездки';
comment on column orders.average_driver_speed is 'Средняя скорость движения км в час';
comment on column orders.time_create          is 'Дата и время создания записи';

-----------------------------------------
create table way(
	id              number(10)   generated as identity, 
	from_address_id number(10)   not null, 
	to_address_id   number(10)   not null, 
	distance        number       not null, 
	order_id        number(10)   not null, 
	preview_way_id  number(10),
	way_date        date         not null, 
	time_create     timestamp    not null, 
	primary key(id),
	foreign key(from_address_id) references address(id), 
	foreign key(to_address_id)   references address(id), 
	foreign key(order_id)        references orders(id), 
	foreign key(preview_way_id)  references way(id)
)
partition by range(way_date)(
	partition way_202101 values less than (date'2021-02-01'),
	partition way_202102 values less than (date'2021-03-01'),
	partition way_202103 values less than (date'2021-04-01'),
	partition way_202104 values less than (date'2021-05-01'),
	partition way_202105 values less than (date'2021-06-01'),
	partition way_202106 values less than (date'2021-07-01'),
	partition way_202107 values less than (date'2021-08-01'),
	partition way_202108 values less than (date'2021-09-01'),
	partition way_202109 values less than (date'2021-10-01'),
	partition way_202110 values less than (date'2021-11-01'),
	partition way_202111 values less than (date'2021-12-01'),
	partition way_202112 values less than (date'2022-01-01'),
	partition way_202201 values less than (date'2022-02-01'),
	partition way_202202 values less than (date'2022-03-01'),
	partition way_202203 values less than (date'2022-04-01'),
	partition way_202204 values less than (date'2022-05-01'),
	partition way_202205 values less than (date'2022-06-01'),
	partition way_202206 values less than (date'2022-07-01'),
	partition way_202207 values less than (date'2022-08-01'),
	partition way_202208 values less than (date'2022-09-01'),
	partition way_202209 values less than (date'2022-10-01'),
	partition way_202210 values less than (date'2022-11-01'),
	partition way_202211 values less than (date'2022-12-01'),
	partition way_202212 values less than (date'2023-01-01'),
	partition way_202301 values less than (date'2023-02-01'),
	partition way_202302 values less than (date'2023-03-01'),
	partition way_202303 values less than (date'2023-04-01'),
	partition way_202304 values less than (date'2023-05-01'),
	partition way_202305 values less than (date'2023-06-01'),
	partition way_202306 values less than (date'2023-07-01'),
	partition way_202307 values less than (date'2023-08-01'),
	partition way_202308 values less than (date'2023-09-01'),
	partition way_202309 values less than (date'2023-10-01'),
	partition way_202310 values less than (date'2023-11-01'),
	partition way_202311 values less than (date'2023-12-01'),
	partition way_202312 values less than (date'2024-01-01'),
	partition way_202401 values less than (date'2024-02-01'),
	partition way_202402 values less than (date'2024-03-01'),
	partition way_202403 values less than (date'2024-04-01'),
	partition way_202404 values less than (date'2024-05-01'),
	partition way_202405 values less than (date'2024-06-01'),
	partition way_202406 values less than (date'2024-07-01'),
	partition way_202407 values less than (date'2024-08-01'),
	partition way_202408 values less than (date'2024-09-01')
);

create or replace trigger way_trg 
	before insert on way for each row
begin
	:new.time_create := systimestamp;
end;
/

create index way_id_date_idx  on way(id, way_date) local;
create index way_order_id_idx on way(order_id)     local;

comment on table  way                 is 'Маршрут';
comment on column way.id              is 'Идентификатор маршрута';
comment on column way.from_address_id is 'Идентификатор начального адреса';
comment on column way.to_address_id   is 'Идентификатор конечногоё адреса';
comment on column way.distance        is 'Расстояние в км';
comment on column way.order_id        is 'Идентификатор заказа';
comment on column way.preview_way_id  is 'Предыдущий маршрут';
comment on column way.way_date        is 'Дата и время маршрута';
comment on column way.time_create     is 'Дата и время создания записи';

-----------------------------------------
create table rating_passenger2driver(
	id           number(10)   generated as identity, 
	passenger_id number(10)   not null, 
	driver_id    number(10)   not null, 
	order_id     number(10)   not null, 
	rating       number, 
	rating_date  date         not null,
	time_create  timestamp    not null,
	primary key(id),
	foreign key(passenger_id) references passenger(id), 
	foreign key(driver_id)    references driver(id), 
	foreign key(order_id)     references orders(id),
	constraint passenger2driver_rating_chk check (rating between 1 and 5)
)
partition by range(rating_date)(
	partition rating_passenger2driver_202101 values less than (date'2021-02-01'),
	partition rating_passenger2driver_202102 values less than (date'2021-03-01'),
	partition rating_passenger2driver_202103 values less than (date'2021-04-01'),
	partition rating_passenger2driver_202104 values less than (date'2021-05-01'),
	partition rating_passenger2driver_202105 values less than (date'2021-06-01'),
	partition rating_passenger2driver_202106 values less than (date'2021-07-01'),
	partition rating_passenger2driver_202107 values less than (date'2021-08-01'),
	partition rating_passenger2driver_202108 values less than (date'2021-09-01'),
	partition rating_passenger2driver_202109 values less than (date'2021-10-01'),
	partition rating_passenger2driver_202110 values less than (date'2021-11-01'),
	partition rating_passenger2driver_202111 values less than (date'2021-12-01'),
	partition rating_passenger2driver_202112 values less than (date'2022-01-01'),
	partition rating_passenger2driver_202201 values less than (date'2022-02-01'),
	partition rating_passenger2driver_202202 values less than (date'2022-03-01'),
	partition rating_passenger2driver_202203 values less than (date'2022-04-01'),
	partition rating_passenger2driver_202204 values less than (date'2022-05-01'),
	partition rating_passenger2driver_202205 values less than (date'2022-06-01'),
	partition rating_passenger2driver_202206 values less than (date'2022-07-01'),
	partition rating_passenger2driver_202207 values less than (date'2022-08-01'),
	partition rating_passenger2driver_202208 values less than (date'2022-09-01'),
	partition rating_passenger2driver_202209 values less than (date'2022-10-01'),
	partition rating_passenger2driver_202210 values less than (date'2022-11-01'),
	partition rating_passenger2driver_202211 values less than (date'2022-12-01'),
	partition rating_passenger2driver_202212 values less than (date'2023-01-01'),
	partition rating_passenger2driver_202301 values less than (date'2023-02-01'),
	partition rating_passenger2driver_202302 values less than (date'2023-03-01'),
	partition rating_passenger2driver_202303 values less than (date'2023-04-01'),
	partition rating_passenger2driver_202304 values less than (date'2023-05-01'),
	partition rating_passenger2driver_202305 values less than (date'2023-06-01'),
	partition rating_passenger2driver_202306 values less than (date'2023-07-01'),
	partition rating_passenger2driver_202307 values less than (date'2023-08-01'),
	partition rating_passenger2driver_202308 values less than (date'2023-09-01'),
	partition rating_passenger2driver_202309 values less than (date'2023-10-01'),
	partition rating_passenger2driver_202310 values less than (date'2023-11-01'),
	partition rating_passenger2driver_202311 values less than (date'2023-12-01'),
	partition rating_passenger2driver_202312 values less than (date'2024-01-01'),
	partition rating_passenger2driver_202401 values less than (date'2024-02-01'),
	partition rating_passenger2driver_202402 values less than (date'2024-03-01'),
	partition rating_passenger2driver_202403 values less than (date'2024-04-01'),
	partition rating_passenger2driver_202404 values less than (date'2024-05-01'),
	partition rating_passenger2driver_202405 values less than (date'2024-06-01'),
	partition rating_passenger2driver_202406 values less than (date'2024-07-01'),
	partition rating_passenger2driver_202407 values less than (date'2024-08-01'),
	partition rating_passenger2driver_202408 values less than (date'2024-09-01')
);

create or replace trigger rating_passenger2driver_trg 
	before insert or update on rating_passenger2driver for each row
begin
	:new.time_create := systimestamp;
end;
/

create index rating_passr2drvr_id_date_idx on rating_passenger2driver(id, rating_date) local;

comment on table  rating_passenger2driver              is 'Оценки водителей пассажирами';
comment on column rating_passenger2driver.id           is 'Идентификатор оценки';
comment on column rating_passenger2driver.passenger_id is 'Идентификатор пассажира';
comment on column rating_passenger2driver.driver_id    is 'Идентификатор водителя';
comment on column rating_passenger2driver.order_id     is 'Идентификатор заказа';
comment on column rating_passenger2driver.rating       is 'Оценка от 1 до 5';
comment on column rating_passenger2driver.rating_date  is 'Дата и время оценки';
comment on column rating_passenger2driver.time_create  is 'Дата и время создания записи';

-----------------------------------------
create table rating_driver2passenger(
	id           number(10)   generated as identity, 
	passenger_id number(10)   not null,
	driver_id    number(10)   not null,
	order_id     number(10)   not null,
	rating       number,
	rating_date  date         not null,
	time_create  timestamp    not null,
	primary key(id),
	foreign key(passenger_id) references passenger(id), 
	foreign key(driver_id)    references driver(id), 
	foreign key(order_id)     references orders(id),
	constraint driver2passenger_rating_chk check (rating between 1 and 5)
)
partition by range(rating_date)(
	partition rating_driver2passenger_202101 values less than (date'2021-02-01'),
	partition rating_driver2passenger_202102 values less than (date'2021-03-01'),
	partition rating_driver2passenger_202103 values less than (date'2021-04-01'),
	partition rating_driver2passenger_202104 values less than (date'2021-05-01'),
	partition rating_driver2passenger_202105 values less than (date'2021-06-01'),
	partition rating_driver2passenger_202106 values less than (date'2021-07-01'),
	partition rating_driver2passenger_202107 values less than (date'2021-08-01'),
	partition rating_driver2passenger_202108 values less than (date'2021-09-01'),
	partition rating_driver2passenger_202109 values less than (date'2021-10-01'),
	partition rating_driver2passenger_202110 values less than (date'2021-11-01'),
	partition rating_driver2passenger_202111 values less than (date'2021-12-01'),
	partition rating_driver2passenger_202112 values less than (date'2022-01-01'),
	partition rating_driver2passenger_202201 values less than (date'2022-02-01'),
	partition rating_driver2passenger_202202 values less than (date'2022-03-01'),
	partition rating_driver2passenger_202203 values less than (date'2022-04-01'),
	partition rating_driver2passenger_202204 values less than (date'2022-05-01'),
	partition rating_driver2passenger_202205 values less than (date'2022-06-01'),
	partition rating_driver2passenger_202206 values less than (date'2022-07-01'),
	partition rating_driver2passenger_202207 values less than (date'2022-08-01'),
	partition rating_driver2passenger_202208 values less than (date'2022-09-01'),
	partition rating_driver2passenger_202209 values less than (date'2022-10-01'),
	partition rating_driver2passenger_202210 values less than (date'2022-11-01'),
	partition rating_driver2passenger_202211 values less than (date'2022-12-01'),
	partition rating_driver2passenger_202212 values less than (date'2023-01-01'),
	partition rating_driver2passenger_202301 values less than (date'2023-02-01'),
	partition rating_driver2passenger_202302 values less than (date'2023-03-01'),
	partition rating_driver2passenger_202303 values less than (date'2023-04-01'),
	partition rating_driver2passenger_202304 values less than (date'2023-05-01'),
	partition rating_driver2passenger_202305 values less than (date'2023-06-01'),
	partition rating_driver2passenger_202306 values less than (date'2023-07-01'),
	partition rating_driver2passenger_202307 values less than (date'2023-08-01'),
	partition rating_driver2passenger_202308 values less than (date'2023-09-01'),
	partition rating_driver2passenger_202309 values less than (date'2023-10-01'),
	partition rating_driver2passenger_202310 values less than (date'2023-11-01'),
	partition rating_driver2passenger_202311 values less than (date'2023-12-01'),
	partition rating_driver2passenger_202312 values less than (date'2024-01-01'),
	partition rating_driver2passenger_202401 values less than (date'2024-02-01'),
	partition rating_driver2passenger_202402 values less than (date'2024-03-01'),
	partition rating_driver2passenger_202403 values less than (date'2024-04-01'),
	partition rating_driver2passenger_202404 values less than (date'2024-05-01'),
	partition rating_driver2passenger_202405 values less than (date'2024-06-01'),
	partition rating_driver2passenger_202406 values less than (date'2024-07-01'),
	partition rating_driver2passenger_202407 values less than (date'2024-08-01'),
	partition rating_driver2passenger_202408 values less than (date'2024-09-01')
);

create or replace trigger rating_driver2passenger_trg 
	before insert or update on rating_driver2passenger for each row
begin
	:new.time_create := systimestamp;
end;
/

create index rating_drvr2passr_id_date_idx on rating_driver2passenger(id, rating_date) local;

comment on table  rating_driver2passenger              is 'Оценки пассажиров водителями';
comment on column rating_driver2passenger.id           is 'Идентификатор оценки';
comment on column rating_driver2passenger.passenger_id is 'Идентификатор пассажира';
comment on column rating_driver2passenger.driver_id    is 'Идентификатор водителя';
comment on column rating_driver2passenger.order_id     is 'Идентификатор заказа';
comment on column rating_driver2passenger.rating       is 'Оценка от 1 до 5';
comment on column rating_driver2passenger.rating_date  is 'Дата и время оценки';
comment on column rating_driver2passenger.time_create  is 'Дата и время создания записи';

-----------------------------------------
create table refueling(
	id                 number(10) generated as identity, 
	driver_id          number(10) not null, 
	car_id             number(10) not null, 
	payment_id         number(10) not null, 
	amount_of_gasoline number     not null, 
	address_id         number(10) not null, 
	refueling_date     date       not null, 
	time_create        timestamp  not null, 
	primary key(id),
	foreign key(driver_id)        references driver(id), 
	foreign key(car_id)           references car(id), 
	foreign key(payment_id)       references payment(id), 
	foreign key(address_id)       references address(id)
)
partition by range(refueling_date)(
	partition refueling_202101 values less than (date'2021-02-01'),
	partition refueling_202102 values less than (date'2021-03-01'),
	partition refueling_202103 values less than (date'2021-04-01'),
	partition refueling_202104 values less than (date'2021-05-01'),
	partition refueling_202105 values less than (date'2021-06-01'),
	partition refueling_202106 values less than (date'2021-07-01'),
	partition refueling_202107 values less than (date'2021-08-01'),
	partition refueling_202108 values less than (date'2021-09-01'),
	partition refueling_202109 values less than (date'2021-10-01'),
	partition refueling_202110 values less than (date'2021-11-01'),
	partition refueling_202111 values less than (date'2021-12-01'),
	partition refueling_202112 values less than (date'2022-01-01'),
	partition refueling_202201 values less than (date'2022-02-01'),
	partition refueling_202202 values less than (date'2022-03-01'),
	partition refueling_202203 values less than (date'2022-04-01'),
	partition refueling_202204 values less than (date'2022-05-01'),
	partition refueling_202205 values less than (date'2022-06-01'),
	partition refueling_202206 values less than (date'2022-07-01'),
	partition refueling_202207 values less than (date'2022-08-01'),
	partition refueling_202208 values less than (date'2022-09-01'),
	partition refueling_202209 values less than (date'2022-10-01'),
	partition refueling_202210 values less than (date'2022-11-01'),
	partition refueling_202211 values less than (date'2022-12-01'),
	partition refueling_202212 values less than (date'2023-01-01'),
	partition refueling_202301 values less than (date'2023-02-01'),
	partition refueling_202302 values less than (date'2023-03-01'),
	partition refueling_202303 values less than (date'2023-04-01'),
	partition refueling_202304 values less than (date'2023-05-01'),
	partition refueling_202305 values less than (date'2023-06-01'),
	partition refueling_202306 values less than (date'2023-07-01'),
	partition refueling_202307 values less than (date'2023-08-01'),
	partition refueling_202308 values less than (date'2023-09-01'),
	partition refueling_202309 values less than (date'2023-10-01'),
	partition refueling_202310 values less than (date'2023-11-01'),
	partition refueling_202311 values less than (date'2023-12-01'),
	partition refueling_202312 values less than (date'2024-01-01'),
	partition refueling_202401 values less than (date'2024-02-01'),
	partition refueling_202402 values less than (date'2024-03-01'),
	partition refueling_202403 values less than (date'2024-04-01'),
	partition refueling_202404 values less than (date'2024-05-01'),
	partition refueling_202405 values less than (date'2024-06-01'),
	partition refueling_202406 values less than (date'2024-07-01'),
	partition refueling_202407 values less than (date'2024-08-01'),
	partition refueling_202408 values less than (date'2024-09-01')
);

create or replace trigger refueling_trg 
	before insert on refueling for each row
begin
	:new.time_create := systimestamp;
end;
/

create index refueling_id_date_idx on refueling(id, refueling_date) local;

comment on table  refueling                    is 'Информация о заправках автомобилей';
comment on column refueling.id                 is 'Идентификатор заправки';
comment on column refueling.driver_id          is 'Идентификатор водителя';
comment on column refueling.car_id             is 'Идентификатор автомобиля';
comment on column refueling.payment_id         is 'Идентификатор оплаты';
comment on column refueling.amount_of_gasoline is 'Залитый объем в литрах';
comment on column refueling.address_id         is 'Идентификатор адреса заправки';
comment on column refueling.refueling_date     is 'Дата и время заправки';
comment on column refueling.time_create        is 'Дата и время создания записи';

-----------------------------------------
-- цены на топливо (этот справочник нужен для тестовых данных. В продуктивной схеме он не понадобится)
create table gasoline_prices(
	id           number(10) generated as identity, 
	currency_id  number(10)   not null, 
	price        number(10,2) not null, 
	city_id      number(10)   not null, 
	price_date   date         not null, 
	time_create  timestamp    not null, 
	primary key(id),
	foreign key(currency_id) references currency(id), 
	foreign key(city_id)     references city(id)
);


create or replace trigger gasoline_prices_trg 
	before insert on gasoline_prices for each row
begin
	:new.time_create := systimestamp;
end;
/

comment on table  gasoline_prices             is 'Цены на бензин';
comment on column gasoline_prices.id          is 'Идентификатор цены';
comment on column gasoline_prices.currency_id is 'Идентификатор валюты';
comment on column gasoline_prices.price       is 'Цена за литр';
comment on column gasoline_prices.city_id     is 'Идентификатор города';
comment on column gasoline_prices.price_date  is 'Дата цены';
comment on column gasoline_prices.time_create is 'Дата и время создания записи';

----------------------------------------
create table gen_proccesses_log(
	city_id       number(10) not null, 
	gen_date      date       not null, 
	start_time    date       not null, 
	end_time      date       default sysdate
);

comment on table  gen_proccesses_log               is 'Лог генерации процессов';
comment on column gen_proccesses_log.city_id       is 'Идентификатор города';
comment on column gen_proccesses_log.gen_date      is 'Дата, за которую генерировались процессы';
comment on column gen_proccesses_log.start_time    is 'Дата / время начала генерации';
comment on column gen_proccesses_log.end_time      is 'Дата / время завершения генерации';
