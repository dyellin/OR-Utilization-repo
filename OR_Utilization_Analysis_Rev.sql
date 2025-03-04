# OPERATING ROOM UTILIZATION: Exploration and Analysis

# This dataset was downloaded from: https://www.kaggle.com/datasets/thedevastator/optimizing-operating-room-utilization
# The copyright is here: https://creativecommons.org/licenses/by/4.0/
# It was made available by Jennifer Falk and 4.0 "to help provide gainful insights into potential areas of waste surrounding OR utilization."
# "This dataset can be used to help optimize operating room utilization by identifying workflow delays, inaccurate booking times, and cancellations."

# Let's have a look at the entire dataset:

SELECT *
FROM Operating_Room_Utilization.q1_or_utilization_clean;


# Looks like the data includes id numbers, procedure info, dates, times, and durations, but not all useful data is given.
# I will reconstruct the schedule using many of the existing columns and by adding new ones, including scheduled end time, actual duration and timing:

SELECT
	or_suite, service, cpt_desc,
	or_sched AS or_sched_start, wheels_in, start_time, end_time, wheels_out,
	DATE_ADD(CAST(or_sched AS datetime), INTERVAL booked_dur MINUTE) AS or_sched_end,
	booked_dur, actual_dur, timing
FROM Operating_Room_Utilization.q1_or_utilization_clean;

# Here are the average durations between each of these data points, and compare them to the average actual and booked durations:

SELECT
	ROUND(AVG(TIMESTAMPDIFF(MINUTE, CAST(or_sched AS datetime), CAST(wheels_in AS datetime))), 0) AS avg_wait_time,
	ROUND(AVG(TIMESTAMPDIFF(MINUTE, CAST(wheels_in AS datetime), CAST(start_time AS datetime))), 0) AS avg_prep_time,
	ROUND(AVG(TIMESTAMPDIFF(MINUTE, CAST(start_time AS datetime), CAST(end_time AS datetime))), 0) AS avg_actual_dur,
	ROUND(AVG(TIMESTAMPDIFF(MINUTE, CAST(end_time AS datetime), CAST(wheels_out AS datetime))), 0) AS avg_wrap_time,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, CAST(or_sched AS datetime), CAST(wheels_out AS datetime))), 0) AS avg_case_time,
    ROUND(AVG(booked_dur), 0) AS avg_booked_dur
FROM Operating_Room_Utilization.q1_or_utilization_clean;


# Examining the schedule, it seems 15 minutes is usually scheduled between each case, but other issues are apparent as well. I'll verify:

SELECT or_suite, or_sched_end, next_or_sched,
	TIMESTAMPDIFF(MINUTE, CAST(or_sched_end AS datetime), CAST(next_or_sched AS datetime)) AS sched_buffer
FROM
	(
	SELECT or_suite,
	DATE_ADD(or_sched, INTERVAL booked_dur MINUTE) AS or_sched_end,
	LEAD(or_sched, 1) OVER(PARTITION BY or_suite ORDER BY or_sched) AS next_or_sched
	FROM Operating_Room_Utilization.q1_or_utilization_clean
	) AS x
WHERE
	TIME(or_sched_end) != TIME('07:00:00')
	AND TIME(next_or_sched) != TIME('07:00:00')
ORDER BY sched_buffer ASC;
    
-- How many double bookings were there, where the next case was scheduled to start before the previous one ended?
    
WITH cte AS (    
	SELECT or_suite, or_sched_end, next_or_sched,
		TIMESTAMPDIFF(MINUTE, CAST(or_sched_end AS datetime), CAST(next_or_sched AS datetime)) AS sched_buffer
	FROM
		(
		SELECT or_suite,
		DATE_ADD(or_sched, INTERVAL booked_dur MINUTE) AS or_sched_end,
		LEAD(or_sched, 1) OVER(PARTITION BY or_suite ORDER BY or_sched) AS next_or_sched
		FROM Operating_Room_Utilization.q1_or_utilization_clean
		) AS x
	WHERE
		TIME(or_sched_end) != TIME('07:00:00')
		AND TIME(next_or_sched) != TIME('07:00:00')
	ORDER BY sched_buffer ASC)
SELECT COUNT(*) AS double_bookings
FROM cte
WHERE sched_buffer <0;
    

# Why are these operating rooms being booked so tight? Are these scheduling errors, typos, or cancellations?

# Before getting in the weeds of a deep dive, I'll backtrack to some EDA, including lists and aggregates, to understand the scope of the data:

-- How many cases were performed in total?
-- How many operating rooms are there?

SELECT
	COUNT(*) AS total_cases,
	COUNT(DISTINCT or_suite) AS num_or_suite
FROM Operating_Room_Utilization.q1_or_utilization_clean;

-- What services are there and which operarting room do they use?

SELECT or_suite, service
FROM Operating_Room_Utilization.q1_or_utilization_clean
GROUP BY service, or_suite
ORDER BY or_suite;

-- What procedures were performed?
-- How many times was each procedure performed?

SELECT cpt_desc, cpt_code, COUNT(cpt_desc) AS cases
FROM Operating_Room_Utilization.q1_or_utilization_clean
GROUP BY cpt_desc, cpt_code
ORDER BY cpt_desc;


# Next, I'll examine aggregate data:

-- How many cases were performed each day? How much OR time was used?
-- What were the averages for those metrics?
-- This is broken down first by date, then by service:

SELECT
	date,
	COUNT(encounter_id) AS total_cases,
    ROUND(COUNT(encounter_id)/8, 1) AS avg_per_or,
    ROUND(SUM(actual_dur)/60, 1) AS total_hrs,
    ROUND(AVG(actual_dur), 0) AS avg_dur_min
FROM Operating_Room_Utilization.q1_or_utilization_clean
GROUP BY date
ORDER BY date;

SELECT
	service,
    COUNT(encounter_id) AS total_cases,
    ROUND(COUNT(encounter_id)/8, 1) AS avg_per_or,
    ROUND(SUM(actual_dur)/60, 1) AS total_hrs,
    ROUND(AVG(actual_dur), 0) AS avg_dur_min
FROM Operating_Room_Utilization.q1_or_utilization_clean
GROUP BY service
ORDER BY service;


# Do any operating rooms have time for additional cases?

-- What was the daily average of operating hours per operating room?

SELECT
	ROUND(SUM(TIMESTAMPDIFF(MINUTE, CAST(or_sched AS datetime), CAST(wheels_out AS datetime))) / COUNT(DISTINCT date) / COUNT(DISTINCT or_suite) / 60, 1) AS avg_or_daily_hrs
FROM Operating_Room_Utilization.q1_or_utilization_clean;

-- What were the daily averages for each operating room and service?

SELECT or_suite, service,
	ROUND(SUM(TIMESTAMPDIFF(MINUTE, CAST(or_sched AS datetime), CAST(wheels_out AS datetime))) / COUNT(DISTINCT date) / 60, 1) AS avg_daily_hrs
FROM Operating_Room_Utilization.q1_or_utilization_clean
GROUP BY or_suite, service;

# Whether cases should be shifted to less busy operating rooms depends on how many daily operating hours should be the standard.
# If a standard day is 8 hours, there is no room for more cases, as the average day is over 8 hours already.
# But if the standard is 9 or 10 hours, then there's more room to work with.


# Were there any cyclical patterns, by day of the week or month?

-- How many total cases were performed each month?

SELECT 
    ROUND(SUM(CASE WHEN MONTH(date) = '1' THEN 1 ELSE 0 END), 0) AS Januray,
    ROUND(SUM(CASE WHEN MONTH(date) = '2' THEN 1 ELSE 0 END), 0) AS February,
    ROUND(SUM(CASE WHEN MONTH(date) = '3' THEN 1 ELSE 0 END), 0) AS March
FROM Operating_Room_Utilization.q1_or_utilization_clean;

-- How many cases were performed each day of the week by each service?
-- How many cases were performed each day of the week in total?

SELECT
	'zTotal' AS service,
    SUM(CASE WHEN WEEKDAY(date) = '0' THEN 1 ELSE 0 END) AS monday,
    SUM(CASE WHEN WEEKDAY(date) = '1' THEN 1 ELSE 0 END) AS tuesday,
    SUM(CASE WHEN WEEKDAY(date) = '2' THEN 1 ELSE 0 END) AS wednesday,
    SUM(CASE WHEN WEEKDAY(date) = '3' THEN 1 ELSE 0 END) AS thursday,
    SUM(CASE WHEN WEEKDAY(date) = '4' THEN 1 ELSE 0 END) AS friday
FROM Operating_Room_Utilization.q1_or_utilization_clean
UNION ALL
SELECT
	service,
    SUM(CASE WHEN WEEKDAY(date) = '0' THEN 1 ELSE 0 END) AS monday,
    SUM(CASE WHEN WEEKDAY(date) = '1' THEN 1 ELSE 0 END) AS tuesday,
    SUM(CASE WHEN WEEKDAY(date) = '2' THEN 1 ELSE 0 END) AS wednesday,
    SUM(CASE WHEN WEEKDAY(date) = '3' THEN 1 ELSE 0 END) AS thursday,
    SUM(CASE WHEN WEEKDAY(date) = '4' THEN 1 ELSE 0 END) AS friday
FROM Operating_Room_Utilization.q1_or_utilization_clean
GROUP BY service
ORDER BY service;


# Now to go deeper into the scheduling data:

-- What time blocks are used for scheduling, and how many times were each booked?

SELECT
	booked_dur,
    COUNT(booked_dur) AS times_booked
FROM Operating_Room_Utilization.q1_or_utilization_clean
GROUP BY booked_dur
ORDER BY booked_dur;

# Scheduling a case for a certain time block is one thing, but what were the actual case durations?

-- What were the average, maximum, and minimum case durations (in minutes)?

SELECT
	ROUND(SUM(booked_dur)/COUNT(booked_dur), 0) AS avg_booked_dur,
	ROUND(AVG(actual_dur), 0) AS avg_actual_dur,
    MAX(booked_dur) AS max_booked_dur,
    MAX(actual_dur) AS max_actual_dur,
    MIN(booked_dur) AS min_booked_dur,
    MIN(actual_dur) AS min_actual_dur
FROM Operating_Room_Utilization.q1_or_utilization_clean;

# Maximum and minimum actuals are less than their booked counterparts, so cases should be able to be scheduled correctly.
# However, there is a discrepancy between average booked and average actual case durations, so let's look closer.
# I will compare the average booked duration vs average actual duration for each distinct procedure (in minutes):

SELECT
	cpt_desc,
    COUNT(cpt_desc) AS cases,
    ROUND(AVG(booked_dur), 0) AS avg_booked_dur,
	ROUND(AVG(actual_dur), 0) AS avg_actual_dur,
    ROUND(AVG(booked_dur) - AVG(actual_dur), 0) AS difference
FROM Operating_Room_Utilization.q1_or_utilization_clean
GROUP BY cpt_desc
ORDER BY difference;

# We've identified a significant issue - certain procedures are consistently running long.


# Another way to examine this is by measuring efficiency.
# Efficiency can be measured by the rate of work, comparing total cases, total OR time, and average OR time by date.

# Ordering the results by total OR time in ascending order reveals 3 dates where 37 cases were performed, while having a total OR time similar to days with 32-34 cases.
# It follows that those 3 dates also have among the lowest average case times.

SELECT
	date,
    COUNT(encounter_id) AS cases,
    SUM(TIMESTAMPDIFF(MINUTE, CAST(or_sched AS datetime), CAST(wheels_out AS datetime))) AS total_or_time,
    ROUND(SUM(TIMESTAMPDIFF(MINUTE, CAST(or_sched AS datetime), CAST(wheels_out AS datetime)))/COUNT(encounter_id), 0) AS avg_case_time
FROM Operating_Room_Utilization.q1_or_utilization_clean
GROUP BY date
ORDER BY total_or_time;


# Efficiency is also a function of staying on schedule.
# Did a case ever run long and cause the next scheduled case to be delayed?

SELECT *
FROM
	(
	SELECT
		date, or_suite, encounter_id, service, cpt_code, or_sched, wheels_in, wheels_out,
		LAG(CAST(wheels_out AS datetime)) OVER(PARTITION BY or_suite ORDER BY date) AS prev_wheels_out
	FROM Operating_Room_Utilization.q1_or_utilization_clean
    WHERE EXTRACT(HOUR FROM or_sched) != 7
	) AS lag_time
WHERE prev_wheels_out > CAST(or_sched AS datetime)
ORDER BY date, or_suite;

# Now that delays have been identified, how many times has that happened?

SELECT
	COUNT(encounter_id) AS late_cases
FROM
	(
	SELECT
		date, or_suite, encounter_id, service, cpt_code, or_sched, wheels_in, wheels_out,
		LAG(CAST(wheels_out AS datetime)) OVER(PARTITION BY or_suite ORDER BY date) AS prev_wheels_out
	FROM Operating_Room_Utilization.q1_or_utilization_clean
    WHERE EXTRACT(HOUR FROM or_sched) != 7
	) AS lag_time
WHERE prev_wheels_out > CAST(or_sched AS datetime);

-- How many delayed cases has each service caused?

SELECT service, COUNT(service) AS offenses
FROM
	(
	SELECT
		date, or_suite, encounter_id, service, cpt_code, or_sched, wheels_in, wheels_out,
		LAG(CAST(wheels_out AS datetime)) OVER(PARTITION BY or_suite ORDER BY date) AS prev_wheels_out
	FROM Operating_Room_Utilization.q1_or_utilization_clean
    WHERE EXTRACT(HOUR FROM or_sched) != 7
	) AS lag_time
WHERE prev_wheels_out > CAST(or_sched AS datetime)
GROUP BY service
ORDER BY offenses DESC;

-- How many delayed cases has each procedure caused?

SELECT service, cpt_desc, COUNT(cpt_desc) AS offenses
FROM
	(
	SELECT
		date, or_suite, encounter_id, service, cpt_code, cpt_desc, or_sched, wheels_in, wheels_out,
		LAG(CAST(wheels_out AS datetime)) OVER(PARTITION BY or_suite ORDER BY date) AS prev_wheels_out
	FROM Operating_Room_Utilization.q1_or_utilization_clean
    WHERE EXTRACT(HOUR FROM or_sched) != 7
	) AS lag_time
WHERE prev_wheels_out > CAST(or_sched AS datetime)
GROUP BY service, cpt_desc
ORDER BY cpt_desc;


# On average, how many minutes elapse between one case ending and the one starting?

SELECT
	ROUND(AVG(TIMESTAMPDIFF(MINUTE, CAST(prev_wheels_out AS datetime), CAST(wheels_in AS datetime))), 0) AS avg_late_out_to_in
FROM
	(
	SELECT *,
		LAG(CAST(wheels_out AS datetime)) OVER(PARTITION BY or_suite ORDER BY date, encounter_id) AS prev_wheels_out
	FROM Operating_Room_Utilization.q1_or_utilization_clean
	WHERE EXTRACT(HOUR FROM or_sched) != 7
    ) AS lag_time
WHERE CAST(prev_wheels_out AS date) = CAST(wheels_in AS date);
 
# If we look at the daily average of cases per operating room again:

SELECT
    ROUND(COUNT(encounter_id) / COUNT(DISTINCT or_suite) / COUNT(DISTINCT date), 1) AS daily_avg_cases_per_or
FROM Operating_Room_Utilization.q1_or_utilization_clean;

# Between 4 and 5 cases per day, with about 30 minutes in between each, is an additional 90-120 minutes per OR that could potentially be put to better use.


# Delays can have a ripple effect on a schedule. If the first case of the day is not on time, all subsequent cases will have a difficult time staying on schedule.
# The more consistently the first case of the day starts on time, the more efficiently the schedule can operate.

-- How many first cases (7am booking) were on time (wheels in within 15 minutes of scheduled start)? = 479

SELECT COUNT(*) AS on_time_first_cases
FROM
	(
	SELECT date, or_suite, encounter_id, service, or_sched, wheels_in
	FROM Operating_Room_Utilization.q1_or_utilization_clean
    WHERE TIMESTAMPDIFF(MINUTE, CAST(or_sched AS datetime), CAST(wheels_in AS datetime)) <= 15
	ORDER BY date, or_suite
    ) AS first_cases
WHERE or_sched LIKE '%7:00%';

-- How many first cases where there in total? = 497

SELECT COUNT(*) AS total_first_cases
FROM
	(
	SELECT date, or_suite, encounter_id, service, or_sched, wheels_in
	FROM Operating_Room_Utilization.q1_or_utilization_clean
	ORDER BY date, or_suite
    ) AS first_cases
WHERE or_sched LIKE '%7:00%';

-- Most first cases did start on time, 479 of 497.
-- Of all cases, how many started on time? = 911

SELECT COUNT(*) AS on_time_cases
FROM
	(
	SELECT date, or_suite, encounter_id, service, or_sched, wheels_in
	FROM Operating_Room_Utilization.q1_or_utilization_clean
    WHERE TIMESTAMPDIFF(MINUTE, CAST(or_sched AS datetime), CAST(wheels_in AS datetime)) <= 15
    ) AS on_time_cases;

-- Subtract on time first cases from on time total cases: 911 - 479 = 432 on time cases that were not first of the day.
-- Subtract first cases from total cases 2172 - 497 = 1675 cases that were not first.
-- Therefore 432 of 1675 is just 26% of non-first cases that started on time vs. 479 of 497 or 96% first cases started on time.

# Do the factors explored above account for such a dramatic drop off in punctuality?