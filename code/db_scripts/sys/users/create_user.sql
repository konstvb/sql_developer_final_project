---------------------------------
-- Name conn:	Oracle Test DB <user>
-- server:		localhost
-- DB:			XEPDB1
-- Port:		1521

CREATE USER kvb_taxi
	IDENTIFIED BY        User_Password_?
	DEFAULT   TABLESPACE sysaux
	TEMPORARY TABLESPACE temp
	ACCOUNT              unlock;
	
alter user kvb_taxi quota unlimited on sysaux;
grant create session             to kvb_taxi;
grant create table               to kvb_taxi;
grant create sequence            to kvb_taxi;
grant create trigger             to kvb_taxi;
grant create view                to kvb_taxi;
grant create any procedure       to kvb_taxi;
grant create any directory       to kvb_taxi;
grant read on directory blob_dir to kvb_taxi;
grant read on directory blob_dir to kvb_taxi;