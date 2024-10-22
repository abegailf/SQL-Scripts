-- Data cleaning process
-- 1. Remove duplicates
-- 2. Standardize the data
-- 3. Decide on null values or blank values
-- 4. Remove unnecessary columns

-- Looking at the table
SELECT * FROM netflix.netflix_titles;

-- First, I need to create a staging to keep the raw data.
CREATE TABLE netflix.netflix_staging
LIKE netflix.netflix_titles;

INSERT Netflix.netflix_staging
SELECT *
FROM netflix.netflix_titles;

SELECT *
FROM netflix.netflix_staging;

-- IDENTIFY DUPLICATES
-- I chose the four (type, title, country, release_year) because there might be a duplicate title 
-- but could be both a movie and a tv show or a duplicate title that is a remake of another country 
-- or a duplicate title that is a remake on a later year
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY type, title, country, release_year) AS row_num
FROM netflix.netflix_staging;

-- need to find all row_num > 1
WITH duplicate_cte AS
(SELECT *,
ROW_NUMBER() OVER(
PARTITION BY type, title, country, release_year) AS row_num
FROM netflix.netflix_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- 3 rows are returned. I want to see all the three titles.
SELECT *
FROM netflix.netflix_staging
WHERE title = 'Esperando La Carroza' or title = 'Love in a Puff' or title = 'Sin senos si hay paraiso'
ORDER BY title;

-- The three movies were added multiple times. 
-- Most likely, they were added on an earier date, and then got removed 
-- and then added again on a later date
-- I have to remove the duplicate because 
-- if duplicates represent the same title added at different times, 
-- keeping them might inflate the count of total movies and TV shows, etc
-- need to create a new table for that then copying all columns with an added row_number column
CREATE TABLE netflix_staging2 (
  `show_id` text,
  `type` text,
  `title` text,
  `director` text,
  `cast` text,
  `country` text,
  `date_added` text,
  `release_year` int DEFAULT NULL,
  `rating` text,
  `duration` text,
  `listed_in` text,
  `description` text,
  `row_number` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- need to insert the code above
INSERT INTO netflix_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY type, title, country, release_year) AS row_num
FROM netflix.netflix_staging;

-- Need to see the 3 rows returned earlier are the same with the results below
SELECT * FROM netflix.netflix_staging2
WHERE `row_number` > 1;

-- now since the three rows are the same, the duplicate can now be deleted
DELETE 
FROM netflix.netflix_staging2
WHERE `row_number` > 1;

-- need to check if there is still row_number that is greater than 1
SELECT * FROM netflix.netflix_staging2
WHERE `row_number` > 1;

-- there's none so I need to check the three titles with duplicates earlier 
-- and see if their row_number is equal to 1
SELECT *
FROM netflix.netflix_staging2
WHERE title = 'Esperando La Carroza' or title = 'Love in a Puff' or title = 'Sin senos si hay paraiso'
ORDER BY title;
-- It is a success. I can now move to the next step

-- NEXT STEP 2. STANDARDIZING THE DATA
-- I want to see how many distinct types there are
SELECT DISTINCT type
FROM netflix.netflix_staging2;
-- there are two: movie and tv show

-- need to trim space before and after titles
UPDATE netflix.netflix_staging2
SET title = TRIM(title);

-- need to also trim space before and after director, cast, country. I should have done it above haha
UPDATE netflix.netflix_staging2
SET director = TRIM(director),
	cast = TRIM(cast),
    country = TRIM(country)
;
-- I want to see distinct director
SELECT DISTINCT director
FROM netflix.netflix_staging2;
-- I can see that there are titles with multiple directors. Sample is below.
SELECT *
FROM netflix.netflix_staging2
WHERE director = 'Conrad Helten, Ezekiel Norton, Michael Goguen';

-- I want to see distinct country
SELECT DISTINCT country
FROM netflix.netflix_staging2;
-- I can see that there are titles with multiple countries. sample is below.
SELECT * 
FROM netflix.netflix_staging2
WHERE country ='Canada, United States, United Kingdom, France, Luxembourg';

-- I want to see distinct rating
SELECT DISTINCT rating
FROM netflix.netflix_staging2;
-- I can see that there are misplaced info where time duration like 74 min is in there 
-- need to identify those titles
SELECT DISTINCT title,rating,duration
FROM netflix.netflix_staging2
WHERE rating = '74 min' OR rating = '84 min' OR rating = '66 min';
-- I need to move the misplaced values into the duration and set ratings to null
UPDATE netflix.netflix_staging2
SET duration = rating,
	rating = NULL
WHERE rating IN ('74 min', '84 min', '66 min');
-- need to check if they are corrected
SELECT *
FROM netflix.netflix_staging2
WHERE title LIKE 'Louis%';
-- Yes, they are now corrected

-- I want to see distinct categories
SELECT DISTINCT listed_in
FROM netflix.netflix_staging2;
-- I can see that there are titles listed in multiple categories

SELECT DISTINCT *
FROM netflix.netflix_staging2;

-- I also want to trim release_year and duration
UPDATE netflix.netflix_staging2
	SET release_year = TRIM(release_year)		
   ;   
UPDATE netflix.netflix_staging2
	SET duration = TRIM(duration)		
   ;
-- I want to add two columns for duration type each for movie and tv shows
ALTER TABLE netflix.netflix_staging2
ADD COLUMN duration_minutes INT,
ADD COLUMN num_seasons INT;

-- double checking
SELECT *
FROM netflix.netflix_staging2;

-- now i need to populate the values
UPDATE netflix.netflix_staging2
SET duration_minutes = CAST(REPLACE(duration, ' min', '') AS UNSIGNED)
WHERE duration LIKE '%min';

UPDATE netflix.netflix_staging2
SET num_seasons = CASE
    WHEN duration LIKE '%Season%' THEN CAST(REPLACE(REPLACE(duration, ' Seasons', ''), ' Season', '') AS UNSIGNED)
    ELSE num_seasons
END
WHERE duration LIKE '%Season%';

-- double checking
SELECT type,title,duration,duration_minutes,num_seasons
FROM netflix.netflix_staging2
WHERE type = 'TV show';

SELECT type,title,duration,duration_minutes,num_seasons
FROM netflix.netflix_staging2
WHERE type = 'movie';

SELECT *
FROM netflix.netflix_staging2;

-- I am now in step 3 of data cleaning. That is, deciding what to do with null or blank values
-- Need to see where the null or blank values are
SELECT *
FROM netflix.netflix_staging2
WHERE title IS NULL
OR title = '';
-- zero rows returned

SELECT *
FROM netflix.netflix_staging2
WHERE director IS NULL
OR director = '';
-- 2630 rows have null or blank values for director

SELECT *
FROM netflix.netflix_staging2
WHERE cast IS NULL
OR cast = '';
-- 825 rows have null or blank values for cast

SELECT *
FROM netflix.netflix_staging2
WHERE country IS NULL
OR country = '';
-- 830 rows have null or blank values for country


SELECT *
FROM netflix.netflix_staging2
WHERE release_year IS NULL
OR release_year = '';
-- zero rows returned

SELECT *
FROM netflix.netflix_staging2
WHERE rating IS NULL
OR rating = '';
-- 7 rows have null or blank values for rating

SELECT *
FROM netflix.netflix_staging2
WHERE listed_in IS NULL
OR listed_in = '';
-- zero rows returned

SELECT *
FROM netflix.netflix_staging2
WHERE listed_in IS NULL
OR listed_in = '';
-- no rows returned

SELECT *
FROM netflix.netflix_staging2
WHERE type = 'movie' AND (duration_minutes IS NULL
OR duration_minutes = '');
-- zero rows returned

SELECT *
FROM netflix.netflix_staging2
WHERE type = 'tv show' AND (num_seasons IS NULL
OR num_seasons = '');
-- zero rows returned

-- I will decide later as I do the data exploration what to do with nulls. 
-- As I see it, I just cant delete any of them as they will affect some of the questions

-- The last part of the data cleaning is to delete unnecessary column. 
-- I will delete the row_number column

ALTER TABLE netflix.netflix_staging2
DROP COLUMN `row_number`;

SELECT *
FROM netflix.netflix_staging2;
-- That's it for data cleaning