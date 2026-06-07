use amaha_assignment;

/*	Create a cohort based on month of first session */

select session_id,user_id,session_date,
monthname(session_date) as session_month,fee,
count(user_id) over(partition by date_format(session_date,'%m-%Y')) as cohort_count
from sessions
where session_number=1
order by session_date;

select date_format(session_date,'%m-%Y') as cohort_month,
count(user_id) as cohort_size
from sessions
where session_number=1
group by cohort_month
order by cohort_month;

/*	Calculate retention (%) for session 2, 3, 4 */

select
count( case when session_number=2 then 1 end) as session_2_size,
count( case when session_number=2 then 1 end)*100.0/
count( case when session_number=1 then 1 end) as session_2_reten_prcn,
count( case when session_number=3 then 1 end) as session_3_size,
count( case when session_number=3 then 1 end)*100.0/
count( case when session_number=1 then 1 end) as session_3_reten_prcn,
count( case when session_number=4 then 1 end) as session_4_size,
count( case when session_number=4 then 1 end)*100.0/
count( case when session_number=1 then 1 end) as session_3_reten_prcn
from sessions;

with session_1_count as(
select count(case when session_number=1 then 1 end) as session_1_cohort
from sessions)
select 
round(coalesce(count( case when session_number=2 then 1 end)*100/
nullif(max(c.session_1_cohort),0),0),1) as session_2_reten_prcntg,
round(coalesce(count( case when session_number=3 then 1 end)*100/
nullif(max(c.session_1_cohort),0),0),1) as session_3_reten_prcntg,
round(coalesce(count( case when session_number=4 then 1 end)*100/
nullif(max(c.session_1_cohort),0),0),1) as session_4_reten_prcntg
from sessions s cross join session_1_count c;

select
round(count( case when session_number=2 then 1 end)*100.0/
nullif(count( case when session_number=1 then 1 end),0),1) as session_2_reten_prcntg,
round(count( case when session_number=3 then 1 end)*100.0/
nullif(count( case when session_number=1 then 1 end),0),1) as session_3_reten_prcntg,
round(count( case when session_number=4 then 1 end)*100.0/
nullif(count( case when session_number=1 then 1 end),0),1) as session_4_reten_prcntg
from sessions;

/*	Total users → users who completed session 1 → session 2 → session 3 and 
show conversion % at each step */

select
count( case when session_number=1 then user_id end) as session_1_size,
round(count( case when session_number=1 then 1 end)*100.0/
(select count(user_id) from users),1) as session_1_completion_prcntg,
count( case when session_number=2 then 1 end) as session_2_size,
round(count( case when session_number=2 then 1 end)*100.0/
count( case when session_number=1 then 1 end),1) as session_2_completion_prcntg,
count( case when session_number=3 then 1 end) as session_3_size,
round(count( case when session_number=3 then 1 end)*100.0/
count( case when session_number=2 then 1 end),1) as session_3_completion_prcntg
from sessions;

with total_user as(
select count(user_id) as user_count from users),
user_count_per_session as(
select count(distinct case when session_number =1 then user_id end) as session_1_user_count,
count(distinct case when session_number =2 then user_id end) as session_2_user_count,
count(distinct case when session_number =3 then user_id end) as session_3_user_count
from sessions)
select user_count as total_users,
session_1_user_count,
round(coalesce(session_1_user_count * 100.0/nullif(t.user_count,0),0),1) as session_1_cmpl_prcntg,
session_2_user_count,
round(coalesce(session_2_user_count * 100.0/nullif(session_1_user_count,0),0),1) as session_2_cmpl_prcntg,
session_3_user_count,
round(coalesce(session_3_user_count * 100.0/nullif(session_2_user_count,0),0),1) as session_3_cmpl_prcntg
from user_count_per_session u,total_user t;

/* 	Calculate:	Total revenue */

select sum(fee) as total_revenue
from sessions;

/* 	Calculate:	Revenue per user */

select user_id, sum(fee) as revenue_per_user
from sessions
group by user_id
order by revenue_per_user desc;

/* 	Calculate:	Revenue per cohort */

select session_number, sum(fee) as revenue_per_cohort
from sessions
group by session_number;

/* 	Calculate:	Revenue per therapist */

select therapist_id, sum(fee) as revenue_per_therapist
from sessions
group by therapist_id
order by revenue_per_therapist desc;

/* 	Calculate:	If a therapist completed more than 10 sessions in a month we 
are providing 20% of the total revenue as the bonus calculate monthly bonus for them. */

select therapist_id, date_format(session_date,'%m-%Y') as month,
count(session_id) as session_count, sum(fee) as total_revenue,
sum(fee)*0.2 as monthly_bonus
from sessions
group by therapist_id,month
having session_count >10
order by session_count desc;

with base_query as(
select therapist_id, date_format(session_date,'%m-%Y') as month,
count(session_id) as session_count, sum(fee) as total_revenue
from sessions
group by therapist_id,month
having session_count >10)
select therapist_id, month, total_revenue*0.2 as monthly_bonus
from base_query;

/* 	Identify at which session most users drop off and provide % distribution  */

select distinct session_number from sessions;
with total_user as(
select count(user_id) as user_count
from users),
user_per_session as(
select count( case when session_number = 1 then user_id end) as session_1_user_count,
count( case when session_number = 2 then user_id end) as session_2_user_count,
count( case when session_number = 3 then user_id end) as session_3_user_count,
count( case when session_number = 4 then user_id end) as session_4_user_count,
count( case when session_number = 5 then user_id end) as session_5_user_count
from sessions)
select round((t.user_count - session_1_user_count)*100.0/t.user_count,1) as session_1_drop_off_prcntg,
round((session_1_user_count - session_2_user_count)*100.0/session_1_user_count,1) as session_2_drop_off_prcntg,
round((session_2_user_count - session_3_user_count)*100.0/session_2_user_count,1) as session_3_drop_off_prcntg,
round((session_3_user_count - session_4_user_count)*100.0/session_3_user_count,1) as session_4_drop_off_prcntg,
round((session_4_user_count - session_5_user_count)*100.0/session_4_user_count,1) as session_5_drop_off_prcntg
from user_per_session,total_user t;

with total_user as(
select count(user_id) as user_count
from users),
user_session_1 as(
select session_number,count(user_id) as user_count,
round((max(t.user_count)-count(user_id))*100.0/max(t.user_count),1) as user_drop_off_prcntg
from sessions,total_user t
where session_number=1
group by session_number),
user_session_2 as(
select s.session_number,count(s.user_id) as user_count,
round((max(s1.user_count)-count(s.user_id))*100.0/max(s1.user_count),1) as user_drop_off_prcntg
from sessions s,user_session_1 s1
where s.session_number=2
group by s.session_number),
user_session_3 as(
select s.session_number,count(s.user_id) as user_count,
round((max(s2.user_count)-count(s.user_id))*100.0/max(s2.user_count),1) as user_drop_off_prcntg
from sessions s,user_session_2 s2
where s.session_number=3
group by s.session_number),
user_session_4 as(
select s.session_number,count(s.user_id) as user_count,
round((max(s3.user_count)-count(s.user_id))*100.0/max(s3.user_count),1) as user_drop_off_prcntg
from sessions s,user_session_3 s3
where s.session_number=4
group by s.session_number),
user_session_5 as(
select s.session_number,count(s.user_id) as user_count,
round((max(s4.user_count)-count(s.user_id))*100.0/max(s4.user_count),1) as user_drop_off_prcntg
from sessions s,user_session_4 s4
where s.session_number=5
group by s.session_number)
select *
from user_session_1
union all
select *
from user_session_2
union all
select *
from user_session_3
union all
select * 
from user_session_4
union all 
select *
from user_session_5;

with user_base as(
select session_number, count(user_id) as user_count,
lag(count(user_id)) over(order by session_number) as prev_session_user_count
from sessions
group by session_number),
drop_off_metrics as(
select session_number,
user_count as total_user,
round(coalesce((prev_session_user_count-user_count)*100.0/nullif(prev_session_user_count,0),0),1) 
as user_drop_off_prcntg
from user_base)
select session_number,
total_user, user_drop_off_prcntg
from (select *,
      dense_rank() over(order by user_drop_off_prcntg desc) as rnk
	  from drop_off_metrics) t
where t.rnk=1;


/* 	days between sessions */

with prev_session_details as(
select user_id,session_number,
session_date,
lag(session_date) over(partition by user_id order by session_date) as prev_session_date
from sessions)
select *,
datediff(session_date,prev_session_date) as days_between_session
from prev_session_details
where prev_session_date is not null;

/* user lifetime sessions
   total number of sessions a user has had over their entire lifetime in the platform */
   
   select user_id,
   count(session_id) as session_count
   from sessions
   group by user_id;
   
   /* 	avg rating */
   
   select round(avg(rating),2) as avg_rating
   from feedback;
   
   /* 	Average rating per therapist */
   
   select therapist_id, round(avg(rating),2) as avg_rating_therapist
   from sessions s 
   left join feedback f
   on s.session_id=f.session_id
   group by therapist_id;
   
   /* 	Correlation between rating and retention */
   
   with session_rating_combined as(
   select s.user_id,s.session_number,
   s.session_date,f.rating
   from sessions s
   left join feedback f
   on s.session_id=f.session_id),
   next_session_metrics as(
   select *,
   lead(session_number) over(partition by user_id order by session_date) as next_session
   from session_rating_combined)
   select coalesce(rating,'Missing') as rating,
   count(user_id) as total_user,
   sum(case when next_session is not null then 1 else 0 end) as user_retention_count,
   round(coalesce(sum( case when next_session is not null then 1 else 0 end)*100.0/
   nullif(count(user_id),0),0),1) as user_retention_prcntg
   from next_session_metrics
   group by rating;
   
   -- using median rating value per user to handle missing values
   
   with user_rating_base as(
   select s.user_id,s.session_number,
   s.session_date,f.rating
   from sessions s left join
   feedback f 
   on s.session_id= f.session_id),
   user_rating_rank as(
   select user_id,rating,
   row_number() over(partition by user_id order by rating) as rn,
   count(*) over(partition by user_id) as ct
   from user_rating_base
   where rating is not null),
   user_median_rating as(
   select user_id,
   round(avg(rating),0) as median_rating
   from user_rating_rank
   where rn in (floor((ct+1)/2),floor((ct+2)/2))
   group by user_id),
   global_rating_rank as(
   select rating,
   row_number() over(order by rating) as rn,
   count(*) over() as ct
   from user_rating_base
   where rating is not null),
   global_median_rating as(
   select round(avg(rating),0) as global_median_rating
   from global_rating_rank
   where rn in (floor((ct+1)/2),floor((ct+2)/2))),
   modified_user_base as(
   select u.user_id,
   session_number,session_date,
   coalesce(rating,m.median_rating,g.global_median_rating) as rating
   from user_rating_base u left join
   user_median_rating m 
   on u.user_id=m.user_id
   cross join global_median_rating g),
   next_session_metrics as(
   select *,
   lead(session_number) over(partition by user_id order by session_date) as next_session
   from modified_user_base)
   select rating,
   count(user_id) as total_user,
   sum( case when next_session is not null then 1 else 0 end) as user_retention_count,
   round(coalesce(sum( case when next_session is not null then 1 else 0 end) * 100.0/
   nullif(count(user_id),0),0),1) as user_retention_prcntg
   from next_session_metrics 
   group by rating;
   
   /* 	Retention curve (Session vs % users) */
   
with session_1_user as(
select  count(user_id) as session1_user_count
from sessions
where session_number=1),
retention_calc_base as(
select s.session_number, count(s.user_id) as user_count,
max(u.session1_user_count) as session1_user_count
from sessions s, session_1_user u
group by s.session_number)
select session_number, user_count,session1_user_count,
round(user_count *100.0/session1_user_count,1) as retention_prcntg_per_session
from retention_calc_base;

-- true retention logic (acc to chatgpt)
-- calculating retention at each session wrt all the users who attended 1st session
-- users who are actually coming back after 1st session

with session_1_user as(
select user_id
from sessions
where session_number =1),
user_metrics_per_session as(
select s.session_number,
count(s.user_id) as total_user
from session_1_user s1 join
sessions s 
on s1.user_id=s.user_id
group by session_number),
session_1_cohort as(
select count(user_id) as session_1_cohort_size
from session_1_user)
select u.session_number,
u.total_user,
-- c.session_1_cohort_size,
round(u.total_user*100.0/c.session_1_cohort_size,1) as retention_rate
from user_metrics_per_session u cross join
session_1_cohort c;


/* 	Which acquisition source performs best? */

with user_rating_base as(
select s.*,u.signup_date,u.source,f.rating
from sessions s left join
users u
on s.user_id=u.user_id
left join feedback f
on s.session_id=f.session_id),
user_rating_rank as(
select user_id,rating,
row_number() over(partition by user_id order by rating) as rn,
count(*) over(partition by user_id) as ct
from user_rating_base
where rating is not null),
user_median_rating as(
select user_id,
round(avg(rating)) as median_rating
from user_rating_rank
where rn between round((ct+1)/2) and round((ct+2)/2)
group by user_id),
global_rating_rank as(
select rating,
row_number() over(order by rating) as rn,
count(*) over() as ct
from user_rating_base
where rating is not null),
global_median_rating as(
select round(avg(rating)) as global_median_rating
from global_rating_rank
where rn between round((ct+1)/2) and round((ct+2)/2)),
imputed_user_rating_base as(
select u.session_id,u.user_id,u.session_number,u.session_date,
u.signup_date,u.fee,u.source,
coalesce(u.rating,m.median_rating,g.global_median_rating) as rating
from user_rating_base u left join
user_median_rating m 
on u.user_id= m.user_id
cross join global_median_rating g),
prev_session_metrics as(
select *,
row_number() over(partition by user_id order by session_date) as rn,
lag(session_date) over(partition by user_id order by session_date) as prev_session
from imputed_user_rating_base),
days_between_session_metrics as(
select user_id,source,
case when rn=1 and session_date is not null
     then datediff(session_date,signup_date)
end as days_to_1st_session,
case when prev_session is not null
     then datediff(session_date,prev_session)
end as days_between_session
from prev_session_metrics),
onboarding_engagement_speed as(
select source,
round(avg(case when days_to_1st_session is not null
    then days_to_1st_session end),1) as days_to_1st_session,
round(avg(case when days_between_session is not null
    then days_between_session end),1) as days_between_session
from days_between_session_metrics
group by source),
user_retention_metrics as(
select *,
lead(session_date) over(partition by user_id order by session_date) as next_session
from imputed_user_rating_base),
retention_rate as(
select source,
round(coalesce(count(distinct case when next_session is not null then user_id end)*100.0/
nullif(count(distinct user_id),0),0),1) as retention_rate
from user_retention_metrics
group by source),
total_user_revenue_session as(
select source,
count(distinct user_id) as users,
sum(fee) as revenue,
round(sum(fee)*1.0/count(distinct session_id),2) as avg_revenue_per_session,
count(session_id) as sessions,
round(count(session_id)*1.0/count(distinct user_id),1) as avg_session_per_user 
from imputed_user_rating_base
group by source),
daily_user_metrics as(
select source,
count(distinct user_id) as daily_active_user,
count(session_id) as daily_session,
round(count(session_id)*1.0/count(distinct user_id),1) as session_per_user
from imputed_user_rating_base
group by source,session_date),
daily_user_metrics_per_source as(
select source,
round(avg(daily_active_user),2) as avg_DAU,
round(avg(daily_session),2) as avg_daily_session,
round(avg(session_per_user),1) as daily_avg_session_per_user
from daily_user_metrics
group by source),
revenue_per_user as(
select source,
sum(fee)*1.0/count(distinct user_id) as avg_revenue_per_user
from imputed_user_rating_base
group by source)
select t.source,
t.revenue,t.users,ru.avg_revenue_per_user,
t.sessions,t.avg_revenue_per_session,t.avg_session_per_user,
d.avg_DAU,d.avg_daily_session,d.daily_avg_session_per_user,
r.retention_rate,o.days_to_1st_session as onboarding_speed_in_days,
o.days_between_session as user_engagement_frequency_in_days
from total_user_revenue_session t join
daily_user_metrics_per_source d
on t.source=d.source
join retention_rate r
on d.source=r.source
join onboarding_engagement_speed o
on r.source=o.source
join revenue_per_user ru
on o.source=ru.source;


/* MOM retention */

with month1_cohort as(
select user_id,min(session_date) as session_1_date,
date_format(min(session_date),'%Y-%m') as session1_month
from sessions
group by user_id),
user_activity_cohort as(
select user_id,
session_date
-- date_format(session_date,'%m-%Y') as activity_month
from sessions
order by user_id),
session1_activity_combined as(
select m1.user_id,
date_format(m1.session_1_date,'%Y-%m') as session1_month,
date_format(u.session_date,'%Y-%m') as activity_month,
period_diff(date_format(u.session_date,'%Y%m'),
			date_format(m1.session_1_date,'%Y%m'))as month_name
from month1_cohort m1 join
user_activity_cohort u
on m1.user_id=u.user_id
),
retained_user_size_per_cohort as(
select session1_month,
-- activity_month,
month_name,
count(distinct user_id) as retained_user
from session1_activity_combined
group by session1_month,month_name),
starting_cohort_size as(
select session1_month,count(distinct user_id) as starting_user
from month1_cohort
group by session1_month)
select s.session1_month,
-- r.activity_month,
r.month_name,
s.starting_user,r.retained_user,
round(r.retained_user*100/s.starting_user,2) as retention_pct
from starting_cohort_size s join retained_user_size_per_cohort r 
on s.session1_month=r.session1_month
order by s.session1_month,r.month_name;-- r.activity_month;
   
   
   
   