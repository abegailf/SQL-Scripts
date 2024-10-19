-- Data cleaning
-- 1. Remove duplicates
-- 2. Standardize the data
-- 3. Null values or blank values
-- 4. Remove unnecessary columns

-- Looking at the table
SELECT * FROM netflix.netflix_titles;

-- First let's create a staging to keep the raw data.

CREATE TABLE netflix.netflix_staging
LIKE netflix.netflix_titles;

INSERT Netflix.netflix_staging
SELECT *
FROM netflix.netflix_titles;

SELECT *
FROM netflix.netflix_staging;

-- Identify duplicates
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY show_id, title, director) AS row_num
FROM netflix.netflix_staging;

-- We need to find all row_num > 1

WITH duplicate_cte AS
(SELECT *,
ROW_NUMBER() OVER(
PARTITION BY show_id, title, director) AS row_num
FROM netflix.netflix_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;
