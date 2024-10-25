----------------------- Employee_table---------------------------
SELECT * FROM employee;
-- 1- How many unique employees are there in the Maji Ndogo dataset?
SELECT COUNT(DISTINCT assigned_employee_id) as total_emp 
FROM employee;

-- 2- Which provinces have the highest number of employees
SELECT  province_name,
        COUNT(assigned_employee_id) as count_emp
FROM employee
GROUP BY province_name
ORDER BY count_emp DESC;

 -- 3- Which town have the highest number of employees
SELECT town_name, 
       COUNT(assigned_employee_id) AS emp_count
FROM employee
GROUP BY town_name
HAVING emp_count > 1
ORDER BY emp_count DESC;

-- 4- Which position have the highest number of employees
SELECT position,
       COUNT(assigned_employee_id) AS count_emp
FROM employee
GROUP BY position
HAVING count_emp > 1
ORDER BY count_emp DESC;

-- 5- What is the average number of employees per town or province?
SELECT province_name,
       town_name,
       ROUND(AVG(emp_count), 2) AS avg_emp
FROM (
    SELECT province_name, 
           town_name, 
           COUNT(assigned_employee_id) AS emp_count
    FROM employee
    GROUP BY 1, 2
) AS emp_grouped
GROUP BY province_name, town_name
ORDER BY avg_emp DESC;

-- -------------------location_table -----------------------
SELECT * FROM location;
-- 1- What is the distribution of different location types (urban/rural) across various provinces?
SELECT province_name, location_type, 
	   count(*) AS loc_type_count
FROM location
GROUP BY 1, 2
ORDER BY loc_type_count DESC;

-- 2- Which towns have the highest number of recorded locations in each province?
SELECT town_name, province_name,
	count(*) AS loc_type_count
FROM location
GROUP BY 1, 2
ORDER BY loc_type_count DESC
LIMIT 10;

-- 3- How does the number of locations compare across different provinces?
SELECT province_name,
       count(*) AS loc_type_count
FROM location
GROUP BY 1
ORDER BY loc_type_count DESC;

-- 2. ---------------------------------------- Visits Table --------------------
SELECT * FROM visits;

-- Visits Volume: What are the busiest times of day for visits across different locations?
SELECT HOUR(time_of_record) AS hour_of_day, 
       COUNT(*) AS visit_count
FROM visits
GROUP BY hour_of_day
ORDER BY visit_count DESC;

-- Waiting Time Analysis: What is the average time spent in queue per visit in each town or province?
SELECT town_name, 
       province_name,
       AVG(time_in_queue) AS avg_queue_time
FROM visits v
JOIN location l ON v.location_id = l.location_id
GROUP BY town_name, province_name
ORDER BY avg_queue_time DESC;

-- Which employees are associated with the most visits, and what is the average wait time for each?
SELECT e.employee_name,
       COUNT(v.record_id) AS total_visits,
       AVG(v.time_in_queue) AS avg_queue_time
FROM visits v
JOIN employee e ON v.assigned_employee_id = e.assigned_employee_id
GROUP BY 1
ORDER BY total_visits DESC, avg_queue_time;

-- ----------------------------------------------- Water Source Table -----------------------
SELECT * FROM water_source;

SELECT type_of_water_source, COUNT(*) AS source_count
FROM water_source
GROUP BY type_of_water_source
ORDER BY source_count DESC;

-- What is the distribution of water source types across different regions or towns?
SELECT l.province_name, 
       ws.type_of_water_source, 
       COUNT(*) AS water_source_count
FROM visits v
JOIN location l ON v.location_id = l.location_id
JOIN water_source ws ON v.source_id = ws.source_id
GROUP BY 1, 2
ORDER BY water_source_count DESC
LIMIT 5;

-- Which water sources serve the largest number of people in each region or town?
SELECT l.province_name, 
       ws.type_of_water_source,
       SUM(ws.number_of_people_served) AS total_people_served,
       RANK() OVER (PARTITION BY l.province_name ORDER BY SUM(ws.number_of_people_served) DESC) AS Rank_Distribution
FROM water_source ws
JOIN visits v ON ws.source_id = v.source_id
JOIN location l ON v.location_id = l.location_id
GROUP BY 1, 2
ORDER BY province_name, total_people_served DESC;

-- Which water source types are most frequently visited?
SELECT type_of_water_source, 
       COUNT(*) AS visit_count
FROM water_source ws 
JOIN visits v  ON ws.source_id = v.source_id
GROUP BY type_of_water_source
ORDER BY visit_count DESC
LIMIT 5;

-- ------- Well Pollution Table ----------------------
SELECT * FROM well_pollution;

-- Which pollutants (in ppm) are most prevalent in different regions over time?
SELECT l.province_name, 
       wp.pollutant_ppm, 
       wp.description, 
       COUNT(*) AS occurrences,
       YEAR(wp.date) AS pollution_year
FROM well_pollution wp
JOIN visits v ON wp.source_id = v.source_id
JOIN location l ON v.location_id = l.location_id
GROUP BY 1, 2, 3, 5
ORDER BY occurrences DESC
LIMIT 5;

-- What is the relationship between the level of pollution and the water quality rating in different locations?
SELECT l.province_name, 
       wp.pollutant_ppm, 
       wq.subjective_quality_score, 
       ROUND(AVG(wp.pollutant_ppm), 2) AS avg_pollution_ppm,
       ROUND(AVG(wq.subjective_quality_score), 2) AS avg_quality_score
FROM well_pollution wp
JOIN visits v ON wp.source_id = v.source_id
JOIN location l ON v.location_id = l.location_id
JOIN water_quality wq ON v.record_id = wq.record_id
GROUP BY 1, 2, 3
ORDER BY avg_pollution_ppm DESC
LIMIT 10;

-- Which towns or provinces report the most instances of biological pollution compared to chemical pollution?
SELECT l.province_name, 
       l.town_name,
       wp.biological, 
       COUNT(*) AS pollution_count
FROM well_pollution wp
JOIN visits v ON wp.source_id = v.source_id
JOIN location l ON v.location_id = l.location_id
GROUP BY 1, 2, 3
ORDER BY pollution_count DESC;

-- ------Visits + Water Source Table (Joins)
-- Which water sources have the highest visit counts in each town or province?
SELECT l.province_name, l.town_name,
       ws.type_of_water_source,
       COUNT(v.visit_count) as Total_visits
FROM location l JOIN visits v
ON l.location_id = v.location_id
JOIN water_source ws 
ON ws.source_id = v.source_id
GROUP BY 1, 2, 3
ORDER BY Total_visits DESC
LIMIT 5;

-- What is the average queue time for each type of water source across different locations?
 SELECT l.province_name,
		ws.type_of_water_source,
        ROUND(AVG(v.time_in_queue), 2) AS avg_time
FROM location l JOIN visits v
ON l.location_id = v.location_id
JOIN water_source ws
ON ws.source_id = v.source_id
GROUP BY 1, 2
ORDER BY avg_time DESC
LIMIT 5;

-- How do the number of visits and the population served correlate for each water source type? 
SELECT ws.type_of_water_source, 
       SUM(v.visit_count) AS total_visits, 
       SUM(ws.number_of_people_served) AS total_people_served,
       ROUND(SUM(v.visit_count) / SUM(ws.number_of_people_served), 2) AS utilization_ratio
FROM visits v
JOIN water_source ws ON v.source_id = ws.source_id
GROUP BY ws.type_of_water_source
ORDER BY utilization_ratio DESC
LIMIT 5;

-- How can we summarize the total number of visits managed by each employee, their average queue time, and rank them by visit count,
--  displaying only the top 10 employees?
WITH Employee_visit AS (
    SELECT e.assigned_employee_id,
           e.employee_name,
           COUNT(v.record_id) AS total_visits,
           AVG(v.time_in_queue) AS avg_queue_time,
           ROW_NUMBER() OVER (ORDER BY COUNT(v.record_id) DESC) AS visit_rank
    FROM employee e
    LEFT JOIN visits v ON e.assigned_employee_id = v.assigned_employee_id
    GROUP BY 1, 2)
SELECT *
FROM Employee_visit
WHERE visit_rank <= 10;

-- What are the yearly pollution trends categorized by pollutant levels (Low, Moderate, High) across different provinces,
-- and how many occurrences fall into each category?
WITH Pollution_trends AS (
    SELECT l.province_name,
           YEAR(wp.date) AS pollution_year,
           wp.pollutant_ppm,
           COUNT(*) AS occurrence_count,
           CASE 
               WHEN wp.pollutant_ppm < 5 THEN 'Low'
               WHEN wp.pollutant_ppm BETWEEN 5 AND 15 THEN 'Moderate'
               ELSE 'High'
           END AS pollution_level
    FROM well_pollution wp
    JOIN visits v ON wp.source_id = v.source_id
    JOIN location l ON v.location_id = l.location_id
    GROUP BY 1, 2, 3
)
SELECT province_name,
       pollution_year,
       pollution_level,
       SUM(occurrence_count) AS total_occurrences
FROM Pollution_trends
GROUP BY 1, 2, 3
ORDER BY province_name, pollution_year;

-- How can we analyze monthly visit trends, including the total number of visits and the average queue time for each town, 
-- and rank them to display the top 5 towns by visit count each month?
WITH Monthly_visits AS (
    SELECT 
        DATE_FORMAT(v.time_of_record, '%Y-%m') AS visit_month,
        l.province_name,
        l.town_name,
        COUNT(v.record_id) AS total_visits,
        AVG(v.time_in_queue) AS avg_queue_time,
        ROW_NUMBER() OVER (PARTITION BY l.province_name ORDER BY COUNT(v.record_id) DESC) AS month_visit_rank
    FROM visits v
    JOIN location l ON v.location_id = l.location_id
    GROUP BY 1, 2, 3 )
SELECT * FROM Monthly_Visits
WHERE month_visit_rank <= 5
ORDER BY visit_month, total_visits DESC;


-- What is the total number of people served by each type of water source, the total number of visits associated with each source,
-- and how can we rank the top 3 water sources based on the number of people served?
WITH Water_source_utilisation AS ( 
 SELECT ws.type_of_water_source,
           SUM(ws.number_of_people_served) AS total_people_served,
           COUNT(v.visit_count) AS total_visits,
           ROUND(SUM(ws.number_of_people_served) / NULLIF(COUNT(v.visit_count), 0), 2) AS utilization_ratio,
           RANK() OVER (ORDER BY SUM(ws.number_of_people_served) DESC) AS utilization_rank
    FROM water_source ws
    LEFT JOIN visits v ON ws.source_id = v.source_id
    GROUP BY ws.type_of_water_source
)
SELECT *
FROM Water_source_utilisation
WHERE utilization_rank <= 3;

-- How can we analyze the relationship between well pollution levels, water quality scores, and regions,
-- displaying the towns with the lowest average water quality scores while accounting for pollution levels?
WITH Quality_pollution AS (
    SELECT l.province_name,
           l.town_name,
           AVG(wp.pollutant_ppm) AS avg_pollution_ppm,
           AVG(wq.subjective_quality_score) AS avg_quality_score,
           COUNT(*) AS total_records,
           ROW_NUMBER() OVER (PARTITION BY l.province_name ORDER BY AVG(wq.subjective_quality_score) ASC) AS quality_rank
    FROM well_pollution wp
    JOIN visits v ON wp.source_id = v.source_id
    JOIN location l ON v.location_id = l.location_id
    JOIN water_quality wq ON v.record_id = wq.record_id
    GROUP BY 1, 2)
SELECT *
FROM Quality_pollution
WHERE quality_rank <= 5 
ORDER BY avg_quality_score ASC;       
       