-- Video Games Data cleaning final stage.
-- The first stage of data cleaning is done in OpenRefine 
-- Since video games naming convention are usually identical and there are thousands of rows

SELECT * 
FROM video_game_sales.vg
ORDER BY title;

-- Trim trailing periods
SELECT *
FROM vg;

UPDATE vg
SET
	title = TRIM(TRAILING '.' FROM title),
    console = TRIM(TRAILING '.' FROM console),
    genre = TRIM(TRAILING '.' FROM genre),
    publisher = TRIM(TRAILING '.' FROM publisher),
    developer = TRIM(TRAILING '.' FROM developer);
	
SELECT DISTINCT title
FROM vg
GROUP BY title
ORDER BY title;
-- there are 1704 distinct titles

SELECT DISTINCT console
FROM vg
GROUP BY console
ORDER BY console;
-- there are 25 distinct consoles

SELECT DISTINCT genre
FROM vg
GROUP BY genre
ORDER BY genre;
-- there are 19 distinct genres

SELECT DISTINCT publisher
FROM vg
GROUP BY publisher
ORDER BY publisher;
-- there are 112 distinct publishers

SELECT DISTINCT developer
FROM vg
GROUP BY developer
ORDER BY developer;
-- there are 571 distinct publishers

-- The top sales by console globally
SELECT 
	console,
    SUM(total_sales) AS total_sales_in_millions,
    RANK() OVER(ORDER BY SUM(total_sales) DESC) AS rank_no
FROM vg
GROUP BY console;
-- PS3, X360, PS4 are the top 3 respectively


-- The top sales by console per region
SELECT 
	console,
    SUM(na_sales) AS na_sales_in_millions,
    RANK() OVER(ORDER BY SUM(na_sales) DESC) AS rank_no
FROM vg
GROUP BY console;
-- X360, PS3, and PS2 are the top 3 respectively in North America

SELECT 
	console,
    SUM(jp_sales) AS jp_sales_in_millions,
    RANK() OVER(ORDER BY SUM(jp_sales) DESC) AS rank_no
FROM vg
GROUP BY console;
-- PS3, PS and PS2 are the top 3 respectively in Japan

SELECT 
	console,
    SUM(pal_sales) AS pal_sales_in_millions,
    RANK() OVER(ORDER BY SUM(pal_sales) DESC) AS rank_no
FROM vg
GROUP BY console;
-- PS3, PS4 and X360 are the top 3 respectively in Europe/Africa region

SELECT 
	console,
    SUM(other_sales) AS other_sales_in_millions,
    RANK() OVER(ORDER BY SUM(other_sales) DESC) AS rank_no
FROM vg
GROUP BY console;
-- PS3, PS4 and PS2 are the top 3 respectively in other region 

-- Examine how different genres of games have risen or fallen in popularity over the years.

SELECT 
    genre, 
    YEAR(release_date) AS year, 
    COUNT(*) AS number_of_releases
FROM 
    vg
WHERE 
    release_date IS NOT NULL AND release_date <> ''
GROUP BY 
    genre, 
    YEAR(release_date)
ORDER BY 
    genre, 
    YEAR(release_date);
    
SELECT 
    genre, 
    YEAR(release_date) AS year, 
    COUNT(*) AS number_of_releases,
    RANK() OVER(PARTITION BY genre ORDER BY COUNT(*) DESC) AS rank_no
FROM 
    vg
WHERE 
    release_date IS NOT NULL AND release_date <> ''
GROUP BY 
    genre, 
    YEAR(release_date)
ORDER BY 
    genre, 
    YEAR(release_date);
-- Okay, so we can do a line graph to see the trend per genre over the years


-- Console preferences by genre
SELECT 
		genre,
		console
FROM vg;

SELECT 
		genre,
		console,
		COUNT(*) AS no_of_titles
FROM vg
GROUP BY genre, console;

SELECT 
	genre,
    console,
	no_of_titles,
    RANK() OVER(PARTITION BY genre ORDER BY no_of_titles DESC) As rank_no
FROM (
SELECT 
		genre,
		console,
		COUNT(*) AS no_of_titles
FROM vg
GROUP BY genre, console
)
AS subquery;

-- to see top 10 consoles per genre
WITH genre_console_rank AS (
SELECT 
	genre,
    console,
	no_of_titles,
    RANK() OVER(PARTITION BY genre ORDER BY no_of_titles DESC ) As rank_no
FROM (
SELECT 
		genre,
		console,
		COUNT(*) AS no_of_titles
FROM vg
GROUP BY genre, console
)
AS subquery
)
SELECT 
	genre,
    console,
    no_of_titles,
    rank_no
FROM genre_console_rank
where rank_no <= 10;

-- Determine which publishers have the most successful titles in terms of sales and critic scores.
SELECT 
	publisher,
    COUNT(*) AS no_of_titles,
    SUM(total_sales) as total_sales
FROM vg
GROUP BY publisher;

SELECT 
	publisher,
	COUNT(*) AS no_of_titles,
    SUM(total_sales) As total_sales,
    RANK() OVER(ORDER BY SUM(total_sales) DESC) As rank_no
FROM vg
GROUP BY publisher;
-- Activision has most sales

SELECT 
	publisher,
    COUNT(*) AS no_of_titles,
    AVE(critic_score) as ave_critic
FROM vg
GROUP BY publisher;


SELECT
	publisher,
    AVG(CAST(critic_score AS DECIMAL(5,2))) AS avg_critic_score,
    RANK() OVER(ORDER BY AVG(CAST(critic_score AS DECIMAL(5,2))) DESC) AS rank_by_avg_score
FROM vg
WHERE critic_score IS NOT NULL AND critic_score != ''
GROUP BY publisher;
--  Telltale Games has the highest average critic score which is 9.7

SELECT 
	release_date,
    MONTHNAME(release_date) as release_month
FROM vg;

-- Analyze if there is a best time of year to release certain types of games based on past sales data.
SELECT 
    MONTHNAME(release_date) as release_month,
    SUM(total_sales) AS month_total_sales
FROM vg
WHERE total_sales IS NOT NULL
GROUP BY release_month
ORDER BY month_total_sales DESC;

SELECT 
    MONTHNAME(release_date) as release_month,
    AVG(total_sales) AS ave_total_sales
FROM vg
WHERE total_sales IS NOT NULL
GROUP BY release_month
ORDER BY ave_total_sales DESC;

-- To compare
SELECT 
    MONTHNAME(release_date) as release_month,
    SUM(total_sales) AS month_total_sales,
    AVG(total_sales) AS month_ave_sales,
    COUNT(*) AS no_of_titles
FROM vg
WHERE total_sales IS NOT NULL
GROUP BY release_month
ORDER BY month_total_sales DESC;
-- November has the highest sale

-- to see season sales
SELECT 
	CASE
		WHEN MONTH(release_date) IN (12,1,2) then 'Winter'
        WHEN MONTH(release_date) IN (3,4,5) then 'Sping'
        WHEN MONTH(release_date) IN (6,7,8) then 'Summer'
        WHEN MONTH(release_date) IN (9,10,11) then 'Fall'
	END AS season,
    SUM(total_sales) AS season_total_sales,
    AVG(total_sales) AS season_avg_sales,
    COUNT(*) AS no_of_titles
FROM vg
GROUP BY season
ORDER BY season_total_sales;
-- Summer has the highest sale

-- analyze by genre
SELECT 
    genre,
    MONTHNAME(release_date) AS release_month,
    SUM(total_sales) AS month_total_sales,
    AVG(total_sales) AS avg_total_sales,
    COUNT(*) AS games_released
FROM vg
WHERE total_sales IS NOT NULL
GROUP BY genre, release_month
ORDER BY genre, month_total_sales DESC;

-- to identify seasonal trend per genre
SELECT 
    genre,
    CASE 
        WHEN MONTH(release_date) IN (12, 1, 2) THEN 'Winter'
        WHEN MONTH(release_date) IN (3, 4, 5) THEN 'Spring'
        WHEN MONTH(release_date) IN (6, 7, 8) THEN 'Summer'
        WHEN MONTH(release_date) IN (9, 10, 11) THEN 'Fall'
    END AS season,
    SUM(total_sales) AS season_total_sales,
    AVG(total_sales) AS season_avg_sales,
    COUNT(*) AS games_released
FROM vg
WHERE total_sales IS NOT NULL
GROUP BY genre, season
ORDER BY genre, season_total_sales DESC;

-- to see trend over the years per genre
SELECT 
    YEAR(release_date) AS release_year,
    MONTHNAME(release_date) AS release_month,
    SUM(total_sales) AS month_total_sales,
    AVG(total_sales) AS avg_total_sales,
    COUNT(*) AS games_released
FROM vg
WHERE total_sales IS NOT NULL
GROUP BY release_year, release_month
ORDER BY release_year, month_total_sales DESC; 