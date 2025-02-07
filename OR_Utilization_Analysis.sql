# OPERATING ROOM UTILIZATION: Exploration and Analysis

# This dataset was downloaded from here: https://www.kaggle.com/datasets/thedevastator/optimizing-operating-room-utilization
# The copyright is here: https://creativecommons.org/licenses/by/4.0/
# It was made available by Jennifer Falk and 4.0 "to help provide gainful insights into potential areas of waste surrounding OR utilization."
# "This dataset can be used to help optimize operating room utilization by identifying workflow delays, inaccurate booking times, and cancellations."

# Let's have a look at the entire dataset:

SELECT *
FROM Operating_Room_Utilization.q1_or_utilization_clean;


# Looks like the data includes id numbers, dates, procedure info, times, and durations.
# We can use this data to analyze how the operating rooms are being used and if scheduling improvements can increase efficiency.

# I'll attempt to reconstruct the schedule, and add in actual duration and timing.

SELECT or_suite, service, cpt_desc, or_sched, booked_dur, actual_dur, timing
FROM Operating_Room_Utilization.q1_or_utilization_clean;

# Examining the schedule, it seems 15 minutes is scheduled between each case:

SELECT or_suite, service, cpt_desc, or_sched, booked_dur,
	DATE_ADD(CAST(or_sched AS datetime), INTERVAL booked_dur MINUTE) AS sched_end,
    actual_dur, timing
FROM Operating_Room_Utilization.q1_or_utilization_clean;

# However, some cases are scheduled within half an hour of the next one in the same operating room:

SELECT
	or_suite,
    date,
    service,
    cpt_desc,
    or_sched,
    booked_dur,
	DATE_ADD(or_sched, INTERVAL booked_dur MINUTE) AS sched_end,
    next_or_sched
FROM
	(
    SELECT
    	or_suite,
		date,
		service,
		cpt_desc,
		or_sched,
        booked_dur,
        DATE_ADD(or_sched, INTERVAL booked_dur MINUTE) AS sched_end,
		LEAD(or_sched, 1) OVER(PARTITION BY or_suite ORDER BY or_sched) AS next_or_sched
	FROM Operating_Room_Utilization.q1_or_utilization_clean
    ) AS subq
WHERE sched_end > next_or_sched
	AND TIME(or_sched) != '07:00:00'; 

# Why are these operating rooms being double booked? Are these scheduling errors, typos, or cancellations?


# I'll start with basic queries, including lists and aggregates, to understand the scope of the data:

-- How many cases were performed in total?

SELECT COUNT(*) AS total_cases
FROM Operating_Room_Utilization.q1_or_utilization_clean;

-- How many operating rooms are there?

SELECT COUNT(DISTINCT or_suite) AS num_or_suite
FROM Operating_Room_Utilization.q1_or_utilization_clean;

-- What services are there?

SELECT DISTINCT service
FROM Operating_Room_Utilization.q1_or_utilization_clean
ORDER BY service;

-- Which service used which operating room?

SELECT or_suite, service
FROM Operating_Room_Utilization.q1_or_utilization_clean
GROUP BY service, or_suite
ORDER BY or_suite;

-- What procedures were performed?

SELECT DISTINCT cpt_desc, cpt_code
FROM Operating_Room_Utilization.q1_or_utilization_clean
ORDER BY cpt_desc;

-- How many times was each procedure performed?

SELECT cpt_desc, COUNT(cpt_desc) AS cpt_desc_count
FROM Operating_Room_Utilization.q1_or_utilization_clean
GROUP BY cpt_desc
ORDER BY cpt_desc;


# Next, I'll examine aggregate data to look for patterns.

# By date or day of the week:

-- How many cases were performed each day? How much OR time was used?
-- What were the average actual durations each day? What were the average deviations between the booked durations and actual durations?

SELECT
	date,
	COUNT(encounter_id) AS total_cases,
    SUM(actual_dur) AS total_time,
    AVG(actual_dur) AS avg_dur,
    AVG(timing) AS avg_timing
FROM Operating_Room_Utilization.q1_or_utilization_clean
GROUP BY date
ORDER BY date;

-- How many cases were performed on each day of the week? Are any days busier than others?

SELECT 
    SUM(CASE WHEN WEEKDAY(date) = '0' THEN 1 ELSE 0 END) AS monday,
    SUM(CASE WHEN WEEKDAY(date) = '1' THEN 1 ELSE 0 END) AS tuesday,
    SUM(CASE WHEN WEEKDAY(date) = '2' THEN 1 ELSE 0 END) AS wednesday,
    SUM(CASE WHEN WEEKDAY(date) = '3' THEN 1 ELSE 0 END) AS thursday,
    SUM(CASE WHEN WEEKDAY(date) = '4' THEN 1 ELSE 0 END) AS friday
FROM Operating_Room_Utilization.q1_or_utilization_clean;


# By service:

-- How many cases were performed? How much OR time was used?
-- What was the average actual case duration? What was the average deviation between the scheduled duration and actual duration?

SELECT
	service,
    COUNT(encounter_id) AS total_cases,
    SUM(actual_dur) AS total_time,
    AVG(actual_dur) AS avg_dur,
    AVG(timing) AS avg_timing
FROM Operating_Room_Utilization.q1_or_utilization_clean
GROUP BY service
ORDER BY service;

-- Which service had the most cases on each day of the week? The example below orders Monday from highest to lowest.

SELECT
	service,
    SUM(CASE WHEN WEEKDAY(date) = '0' THEN 1 ELSE 0 END) AS monday,
    SUM(CASE WHEN WEEKDAY(date) = '1' THEN 1 ELSE 0 END) AS tuesday,
    SUM(CASE WHEN WEEKDAY(date) = '2' THEN 1 ELSE 0 END) AS wednesday,
    SUM(CASE WHEN WEEKDAY(date) = '3' THEN 1 ELSE 0 END) AS thursday,
    SUM(CASE WHEN WEEKDAY(date) = '4' THEN 1 ELSE 0 END) AS friday
FROM Operating_Room_Utilization.q1_or_utilization_clean
GROUP BY service
ORDER BY SUM(CASE WHEN WEEKDAY(date) = '0' THEN 1 ELSE 0 END) DESC;


# By operating room (or_suite):

-- How many cases were performed? How much OR time was used?
-- What was the average actual case duration? What was the average deviation between the scheduled duration and actual duration?

SELECT
	or_suite,
    COUNT(encounter_id) AS total_cases,
    SUM(actual_dur) AS total_time,
    AVG(actual_dur) AS avg_dur,
    AVG(timing) AS avg_timing
FROM Operating_Room_Utilization.q1_or_utilization_clean
GROUP BY or_suite
ORDER BY or_suite;

-- What were the average duration and average timing of each service by operating room?

SELECT
	or_suite,
	service,
    AVG(actual_dur) AS avg_time,
    AVG(timing) AS avg_timing
FROM Operating_Room_Utilization.q1_or_utilization_clean
GROUP BY service, or_suite
ORDER BY or_suite;

-- How many cases were there for each OR by day of the week?

SELECT
	or_suite,
    SUM(CASE WHEN WEEKDAY(date) = '0' THEN 1 ELSE 0 END) AS monday,
    SUM(CASE WHEN WEEKDAY(date) = '1' THEN 1 ELSE 0 END) AS tuesday,
    SUM(CASE WHEN WEEKDAY(date) = '2' THEN 1 ELSE 0 END) AS wednesday,
    SUM(CASE WHEN WEEKDAY(date) = '3' THEN 1 ELSE 0 END) AS thursday,
    SUM(CASE WHEN WEEKDAY(date) = '4' THEN 1 ELSE 0 END) AS friday
FROM Operating_Room_Utilization.q1_or_utilization_clean
GROUP BY or_suite
ORDER BY or_suite;


# Now that I've explored the who, what, where, and when in some detail, it's time to go deeper into the scheduling data:

-- What time blocks are used for scheduling?

SELECT DISTINCT booked_dur
FROM Operating_Room_Utilization.q1_or_utilization_clean
ORDER BY booked_dur;

-- How many times was each block duration booked? Which was most common?

SELECT
	booked_dur,
    COUNT(booked_dur) AS times_booked
FROM Operating_Room_Utilization.q1_or_utilization_clean
GROUP BY booked_dur
ORDER BY times_booked DESC;

-- How many blocks of each length were booked by each service?

SELECT service, booked_dur, COUNT(booked_dur) AS instances
FROM Operating_Room_Utilization.q1_or_utilization_clean
GROUP BY service, booked_dur
ORDER BY service;

# Scheduling a case for a certain time block is all well and good, but what were the actual case durations?

-- What were the average, maximum, and minimum case durations?

SELECT
	AVG(actual_dur) AS avg_actual_dur,
    MAX(actual_dur) AS max_dur,
    MIN(actual_dur) AS min_dur
FROM Operating_Room_Utilization.q1_or_utilization_clean;

# The dataset includes timing data for when:
	-- the case is scheduled to start (or_sched)
    -- the patient is brought into the operating room (wheels_in)
    -- start time
    -- end time
    -- the patient leaves the operating room (wheels_out)

# Here I show the average durations between each of these data points, and compare them to the average actual and booked durations:

SELECT
	AVG(TIMESTAMPDIFF(MINUTE, CAST(or_sched AS datetime), CAST(wheels_in AS datetime))) AS avg_wait_time,
	AVG(TIMESTAMPDIFF(MINUTE, CAST(wheels_in AS datetime), CAST(start_time AS datetime))) AS avg_prep_time,
	AVG(TIMESTAMPDIFF(MINUTE, CAST(start_time AS datetime), CAST(end_time AS datetime))) AS avg_actual_dur,
	AVG(TIMESTAMPDIFF(MINUTE, CAST(end_time AS datetime), CAST(wheels_out AS datetime))) AS avg_wrap_time,
    AVG(TIMESTAMPDIFF(MINUTE, CAST(or_sched AS datetime), CAST(wheels_out AS datetime))) AS avg_case_time,
    AVG(booked_dur) AS avg_booked_dur
FROM Operating_Room_Utilization.q1_or_utilization_clean;

# Compare the average booked duration vs average actual duration for each procedure type.
	-- Include the difference between the durations and the total number of cases for each procedure type.

SELECT
	cpt_desc,
    COUNT(cpt_desc) AS cases,
    AVG(booked_dur) AS avg_booked_dur,
	AVG(actual_dur) AS avg_actual_dur,
    AVG(booked_dur) - AVG(actual_dur) AS difference
FROM Operating_Room_Utilization.q1_or_utilization_clean
GROUP BY cpt_desc
ORDER BY difference;


# There is a big discrepancy between the average actual duration and the average booked duration of a case - almost 40 minutes!

# We've identified a significant issue - cases are consistently running long - but that's only part of the problem.
# Next we must figure out why cases are running long by testing the schedule's efficiency.

# Performing as many cases per day as possible could be a measure of efficiency, since it should be more profitable.

# Let's look at the difference between booked duration and actual duration by service, cpt code, and cpt description.
# I've assigned an efficiency score for each procedure, which indicates the avergae time saved or lost making this comparison, by service.
	-- Positive numbers = time saved
    -- Negative numbers = time lost
# Services that save time allow more cases to be booked per day, and may need their booked time blocks shortened to more accurately reflect their outcomes.
# The same can be said of services that lose time. Their booked time blocks could be lengthened so cases after them have more realistic start time expecations.

SELECT
	service,
    cpt_code,
    cpt_desc,
    AVG(booked_dur - actual_dur) AS efficiency_score
FROM Operating_Room_Utilization.q1_or_utilization_clean
GROUP BY
	service, cpt_code, cpt_desc
ORDER BY
	efficiency_score DESC;
    
    
# Efficiency can also be measured by the rate of work, comparing total cases, total OR time, and average OR time (actual_dur) per date.
# Ordering the results by total OR time reveals 3 dates where 37 cases were performed, while having a total OR time similar to days with 32-34 cases.
# It follows that those 3 dates also have among the lowest average case times.

SELECT
	date,
    COUNT(encounter_id) AS cases,
    SUM(TIMESTAMPDIFF(MINUTE, CAST(or_sched AS datetime), CAST(wheels_out AS datetime))) AS or_time,
    (SUM(TIMESTAMPDIFF(MINUTE, CAST(or_sched AS datetime), CAST(wheels_out AS datetime)))/COUNT(encounter_id)) AS avg_case_time
FROM Operating_Room_Utilization.q1_or_utilization_clean
GROUP BY date
ORDER BY or_time;


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

# Now that delays have been identified, how many times has that happened? Note: Total cases = 2172.

SELECT
	COUNT(encounter_id) AS late_cases,
    (COUNT(encounter_id)/2172) * 100 AS pct_cases_late
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

SELECT cpt_desc, COUNT(cpt_desc) AS offenses
FROM
	(
	SELECT
		date, or_suite, encounter_id, service, cpt_code, cpt_desc, or_sched, wheels_in, wheels_out,
		LAG(CAST(wheels_out AS datetime)) OVER(PARTITION BY or_suite ORDER BY date) AS prev_wheels_out
	FROM Operating_Room_Utilization.q1_or_utilization_clean
    WHERE EXTRACT(HOUR FROM or_sched) != 7
	) AS lag_time
WHERE prev_wheels_out > CAST(or_sched AS datetime)
GROUP BY cpt_desc
ORDER BY offenses DESC;

-- When a delay occurs, what is the average time until wheels in on the next case?

SELECT
	AVG(TIMESTAMPDIFF(MINUTE, CAST(prev_wheels_out AS datetime), CAST(wheels_in AS datetime))) AS avg_out_to_in
FROM
	(
	SELECT
		date,
        or_suite,
        encounter_id,
        service,
        cpt_code,
        or_sched,
        wheels_in,
        wheels_out,
		LAG(CAST(wheels_out AS datetime)) OVER(PARTITION BY or_suite ORDER BY date, encounter_id) AS prev_wheels_out
	FROM Operating_Room_Utilization.q1_or_utilization_clean
	WHERE EXTRACT(HOUR FROM or_sched) != 7
    ) AS lag_time
WHERE prev_wheels_out IS NOT NULL
	AND CAST(prev_wheels_out AS date) = CAST(wheels_in AS date);

# If we then look at the daily average of cases per operating room again (using 8 ORs over 62 days):

SELECT
    COUNT(encounter_id) / 8 / 62 AS daily_avg_cases_per_or
FROM Operating_Room_Utilization.q1_or_utilization_clean;

# Between 4 and 5 cases each day, with about 30 minutes in between each, is an additional 90-120 minutes per OR that could be put to better use, depending on room turnover time.


# Delays can have a ripple effect on a schedule. If the first case of the day is not on time, all subsequent cases will have a difficult time staying on schedule.
# The more consistently the first case of the day starts on time, the more efficiently the schedule can operate.

-- Total first cases (7am booking) = 497

SELECT COUNT(*)
FROM
	(
	SELECT date, or_suite, encounter_id, service, or_sched, wheels_in
	FROM Operating_Room_Utilization.q1_or_utilization_clean
	ORDER BY date, or_suite
    ) AS first_cases
WHERE or_sched LIKE '%7:00%';

-- Total on time cases (wheels in within 15 minutes) = 911

SELECT COUNT(*)
FROM
	(
	SELECT date, or_suite, encounter_id, service, or_sched, wheels_in
	FROM Operating_Room_Utilization.q1_or_utilization_clean
    WHERE TIMESTAMPDIFF(MINUTE, CAST(or_sched AS datetime), CAST(wheels_in AS datetime)) <= 15
    ) AS on_time_cases;

-- What percent of cases start on time (wheels in within 15 minutes)?

SELECT
	(COUNT(*) / (SELECT COUNT(*) FROM Operating_Room_Utilization.q1_or_utilization_clean)) * 100 AS on_time_pct
FROM
	Operating_Room_Utilization.q1_or_utilization_clean
WHERE
	TIMESTAMPDIFF(MINUTE, CAST(or_sched AS datetime), CAST(wheels_in AS datetime)) <= 15;


# Balancing each operating room's daily hours by shifting caseload may help keep the schedule on track.

# The first step is to find average daily hours per opreating room:

SELECT
	SUM(TIMESTAMPDIFF(MINUTE, CAST(or_sched AS datetime), CAST(wheels_out AS datetime))) / COUNT(DISTINCT date) / 60 / 8 AS avg_or_daily_hrs
FROM Operating_Room_Utilization.q1_or_utilization_clean;

# Next I'll look at the daily average hours for each specific operating room:

SELECT or_suite,
	SUM(TIMESTAMPDIFF(MINUTE, CAST(or_sched AS datetime), CAST(wheels_out AS datetime))) / COUNT(DISTINCT date) / 60 AS avg_daily_hrs
FROM Operating_Room_Utilization.q1_or_utilization_clean
GROUP BY or_suite;

# What is the deviation range? Do any operating rooms have time for additional cases?
# Whether cases should be shifted to less busy operating rooms depends on how many daily operating hours should be the standard.
# If a standard day is 8 hours, there is no room for more cases, as the average day is over 8 hours already.
# But if the standard is 9 or 10 hours, then there's more room to work with.

# This will all make more sense when visualized...
