create database amaha_assignment;
use amaha_assignment;
select * from users;
select * from sessions;
select * from feedback;

alter table users add column new_signup_date date;
desc users;
set sql_safe_updates=0;
update users set 
new_signup_date = str_to_date(signup_date,'%d-%m-%Y');
select * from users;
update users set 
signup_date = str_to_date(signup_date,'%d-%m-%Y');
alter table users drop column new_signup_date;


desc sessions;
update sessions set
session_date = str_to_date(session_date,'%d-%m-%Y');
select * from sessions;

drop table feedback;
drop table sessions;
drop table users;

drop table if exists users;

-- Table creation

create table users(
	user_id int primary key,
    signup_date date,
    source varchar(50)
);
desc users;

drop table if exists sessions;

create table sessions(
	session_id int primary key,
    user_id int,
    session_date date,
    session_number int,
    therapist_id int,
    fee decimal(10,2),
    foreign key (user_id) references users(user_id)
);
desc sessions;

drop table if exists feedback;

create table feedback(
	session_id int,
    rating int,
    review_text varchar(150),
    foreign key (session_id) references sessions(session_id)
);
desc feedback;

-- Data loading

set global local_infile=1;
show variables like 'secure-file-priv';
SHOW VARIABLES LIKE 'secure_file_priv';

load data infile
'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\users.csv'
into table users
fields terminated by ','
enclosed by '"'
lines terminated by '\n' 
ignore 1 rows
(user_id,@signup_date,source)
set signup_date = str_to_date(@signup_date,'%d-%m-%Y');

select * from users;
select count(*) from users;

load data infile
'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\sessions.csv'
into table sessions
fields terminated by ','
enclosed by '"'
lines terminated by '\n' 
ignore 1 rows
(session_id , user_id , @session_date , session_number , therapist_id , fee )
set session_date = str_to_date(@session_date,'%d-%m-%Y');

select * from sessions;
select count(*) from sessions;

load data infile
'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\feedback.csv'
into table feedback
fields terminated by ','
enclosed by '"'
lines terminated by '\n' 
ignore 1 rows;

select * from feedback;
select count(*) from feedback;