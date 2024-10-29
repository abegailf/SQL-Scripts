-- Netflix data exploration

-- 1. How many movies vs. TV shows are available in the database?

-- Checking the table
SELECT *
FROM netflix.netflix_staging2;

-- Answering question 1: Counting types
SELECT 
	type, 
	COUNT(*) AS count
FROM netflix.netflix_staging2
GROUP BY type;

-- Computing for the percentage too
SELECT type, 
	COUNT(*) AS count,
	COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () AS percentage
FROM netflix.netflix_staging2
GROUP BY type;

-- 2. Who are the global top directors on Netflix based on the number of titles?
SELECT 
	director, 
	COUNT(*) AS no_of_titles,
    ROW_NUMBER() OVER(ORDER BY COUNT(*) DESC) As row_no
FROM netflix_staging2
WHERE director IS NOT NULL AND director <> ''
GROUP BY director
;

-- I know one of the directors, Cathy Garcia - Molina.
-- I want to check her 13 movies
SELECT *
FROM netflix_staging2
WHERE director = 'Cathy Garcia-Molina'
ORDER BY release_year;
-- yup, haha

-- 3. Who are the top directors for movies based on the number of titles?
SELECT 
	director, 
	COUNT(*) AS no_of_titles,
    ROW_NUMBER() OVER(ORDER BY COUNT(*) DESC) As row_no
FROM netflix_staging2
WHERE type = 'Movie' AND (director IS NOT NULL AND director <> '')
GROUP BY director
;

-- 3. Who are the worldwide top directors for tv shows based on the number of titles?
SELECT 
	director, 
	COUNT(*) AS no_of_titles,
    ROW_NUMBER() OVER(ORDER BY COUNT(*) DESC) As row_no
FROM netflix_staging2
WHERE type = 'TV show' AND (director IS NOT NULL AND director <> '')
GROUP BY director
;

-- Next question: Which countries produce the most content on Netflix?
SELECT 
	country,
    COUNT(*) AS no_of_titles
FROM netflix_staging2
WHERE country IS NOT NULL and country <> ''
GROUP BY country
ORDER BY no_of_titles DESC;

-- window function to find top countries based on no of titles
SELECT 
	country,
    COUNT(*) AS no_of_titles,
    RANK() OVER(ORDER BY COUNT(*) DESC) AS rank_no
FROM netflix_staging2
WHERE country IS NOT NULL and country <> ''
GROUP BY country
ORDER BY no_of_titles DESC;

-- Queston: Which countries produce the most movies on Netflix?
-- window function to find top countries based on no of movies
SELECT 
	country,
    COUNT(*) AS no_of_titles,
    RANK() OVER(ORDER BY COUNT(*) DESC) AS rank_no
FROM netflix_staging2
WHERE type = 'Movie' AND (country IS NOT NULL and country <> '')
GROUP BY country
ORDER BY no_of_titles DESC;


-- Queston:  Which countries produce the most TV shows on Netflix?
-- window function to find top countries based on number of tv shows
SELECT 
	country,
    COUNT(*) AS no_of_titles,
    RANK() OVER(ORDER BY COUNT(*) DESC) AS rank_no
FROM netflix_staging2
WHERE type = 'TV show' AND (country IS NOT NULL and country <> '')
GROUP BY country
ORDER BY no_of_titles DESC;


-- How does the distribution of movies vs. TV shows vary by country?

SELECT 
	country,
    type,
    COUNT(*) AS no_of_titles
FROM netflix_staging2
GROUP BY country, type
ORDER BY country
;

-- checking code up for ph
SELECT *
FROM netflix_staging2
WHERE country LIKE '%Philippines%';
                                                                                                                                                                                                     
-- How does the distribution of movies vs. TV shows vary by country?
-- Here we can choose the country 
SELECT 
	country,
    type,
    no_of_titles * 100 / SUM(no_of_titles) OVER(PARTITION BY country) AS percentage
FROM(
SELECT 
	country,
    type,
    COUNT(*) AS no_of_titles
FROM netflix_staging2
GROUP BY country, type
ORDER BY country)
AS aggregate_data
WHERE 
	COUNTRY = 'UNITED STATES'
OR	COUNTRY = 'Philippines'	
OR COUNTRY = 'SOUTH KOREA';

-- Which actors appear in the most titles?
SELECT *
FROM netflix_staging2
WHERE cast LIKE '%leonardo%';

-- I only want to account for the first four cast, the main leads
-- That means I have to create a temp table where the first four cast is listed in their own rows
-- But first I'm curious how many cast are per title
 SELECT 
		type,
        title,
        (CHAR_LENGTH(cast) - CHAR_LENGTH(REPLACE(cast, ',', '')) + 1) AS num_cast
    FROM 
        netflix_staging2
    WHERE 
        cast IS NOT NULL AND TRIM(cast) != '';

-- It says that 2012 has 10 casts, double checking that        
SELECT *
FROM netflix_staging2
WHERE title = '2012';
-- correct

-- Curious to know the min and max number of casts
SELECT
	MIN(num_cast) AS min_cast,
    MAX(num_cast) AS max_cast
FROM (
SELECT 
		type,
        title,
        (CHAR_LENGTH(cast) - CHAR_LENGTH(REPLACE(cast, ',', '')) + 1) AS num_cast
    FROM 
        netflix_staging2
    WHERE 
        cast IS NOT NULL AND TRIM(cast) != ''
)
AS cast_counts;
-- So min is 1 and max is 50, I'm curious which is which

SELECT type, title, num_cast
FROM (
SELECT 
		type,
        title,
        (CHAR_LENGTH(cast) - CHAR_LENGTH(REPLACE(cast, ',', '')) + 1) AS num_cast
    FROM 
        netflix_staging2
    WHERE 
        cast IS NOT NULL AND TRIM(cast) != ''
) 
AS curiousity
WHERE num_cast = 1;

-- Let's double check one. A family affair has 1 cast, I want to look into it
SELECT *
FROM netflix_staging2
WHERE title = 'A Family Affair';

-- Now I want to create a temporary table where the title is listed four times accounting
-- for the top four casts
CREATE TEMPORARY TABLE top_four_cast AS
SELECT 
    show_id,
    type,
    title,
    director,
    TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(cast, ',', numbers.n), ',', -1)) AS cast_member,
    country,
    date_added,
    release_year,
    rating,
    duration,
    listed_in,
    description,
    duration_minutes,
    num_seasons
FROM 
    netflix_staging2
JOIN 
    (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4) AS numbers
ON 
    CHAR_LENGTH(cast) - CHAR_LENGTH(REPLACE(cast, ',', '')) >= numbers.n - 1
WHERE 
    cast IS NOT NULL AND TRIM(cast) != '';

-- checking the table
SELECT *
FROM top_four_cast;

SELECT 
	cast_member, 
	COUNT(*) AS no_of_titles
FROM top_four_cast
GROUP BY cast_member;

-- now finding the top actors
SELECT 
	cast_member, 
	COUNT(*) AS no_of_titles,
    RANK() OVER(ORDER BY COUNT(*) DESC) AS rank_no
FROM top_four_cast
GROUP BY cast_member;

-- double checking on Adam Sandler, he's on row 11 saying he has 20 titles
SELECT *
FROM netflix_staging2
Where cast LIKE '%Adam Sandler%';
-- Okay, correct

-- now finding the top actors for movies
SELECT 
	cast_member, 
	COUNT(*) AS no_of_titles,
    RANK() OVER(ORDER BY COUNT(*) DESC) AS rank_no
FROM top_four_cast
WHERE type = 'Movie'
GROUP BY cast_member;

-- now finding the top actors for tv show
SELECT 
	cast_member, 
	COUNT(*) AS no_of_titles,
    RANK() OVER(ORDER BY COUNT(*) DESC) AS rank_no
FROM top_four_cast
WHERE type = 'TV show'
GROUP BY cast_member;

-- now finding the top actors for all titles produced or coproduced by the United States
SELECT 
	cast_member, 
	COUNT(*) AS no_of_titles,
    RANK() OVER(ORDER BY COUNT(*) DESC) AS rank_no
FROM top_four_cast
WHERE country LIKE '%united states%'
GROUP BY cast_member;

-- now finding the top actors for movies produced or coproduced by the United States
SELECT 
	cast_member, 
	COUNT(*) AS no_of_titles,
    RANK() OVER(ORDER BY COUNT(*) DESC) AS rank_no
FROM top_four_cast
WHERE country LIKE '%united states%'
	AND type LIKE '%movie%'
GROUP BY cast_member;

-- now finding the top actors for TV show produced or coproduced by the United States
SELECT 
	cast_member, 
	COUNT(*) AS no_of_titles,
    RANK() OVER(ORDER BY COUNT(*) DESC) AS rank_no
FROM top_four_cast
WHERE country LIKE '%united states%'
	AND type LIKE '%TV show%'
GROUP BY cast_member;

-- What are the most common genres or categories listed in Netflix titles?
-- checking the table

SELECT *
FROM netflix_staging2;

-- So the thing is most of the titles are listed with multiple genres
-- checking for the unique genres

SELECT DISTINCT(listed_in)
FROM netflix_staging2;
-- there are 514 rows returned

-- I want to find min and max number of genres listed
SELECT 
    MIN(num_genres) AS min_genres,
    MAX(num_genres) AS max_genres
FROM (
    SELECT 
        (CHAR_LENGTH(listed_in) - CHAR_LENGTH(REPLACE(listed_in, ',', '')) + 1) AS num_genres
    FROM 
        netflix_staging2
    WHERE 
        listed_in IS NOT NULL AND TRIM(listed_in) != ''
) AS genre_counts;
-- so min is 1 and max is 3

SELECT listed_in
FROM netflix_staging2;


CREATE TEMPORARY TABLE account_genres AS
SELECT 
	show_id,
    type,
    title,
    director,
    cast,
    country,
    date_added,
    release_year,
    rating,
    duration,
    TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(listed_in, ',', numbers.n), ',', -1)) AS genre
FROM 
    netflix_staging2
JOIN
    (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3) numbers
ON 
    CHAR_LENGTH(listed_in) - CHAR_LENGTH(REPLACE(listed_in, ',', '')) >= numbers.n - 1
WHERE 
    listed_in IS NOT NULL AND listed_in <> '';
    
SELECT *
FROM account_genres;

-- double checking on the movie '#Alive'
SELECT *
FROM netflix_staging2
WHERE title = '#Alive';
-- okay good

-- I want to see the unique genre
SELECT DISTINCT genre
FROM account_genres
ORDER BY genre;
-- there are 42 distinct genres

-- now lets do genre analysis
SELECT 
	genre,
    COUNT(*) AS no_of_titles
FROM account_genres
GROUP BY genre;

-- The top genres for all titles
SELECT 
	genre,
    COUNT(*) AS no_of_titles,
    RANK() OVER(ORDER BY COUNT(*) DESC) AS rank_no
FROM account_genres
GROUP BY genre;

-- The top genres for movies
SELECT 
	genre,
    COUNT(*) AS no_of_titles,
    RANK() OVER(ORDER BY COUNT(*) DESC) AS rank_no
FROM account_genres
WHERE type = 'movie'
GROUP BY genre;

-- The top genres for TV shows
SELECT 
	genre,
    COUNT(*) AS no_of_titles,
    RANK() OVER(ORDER BY COUNT(*) DESC) AS rank_no
FROM account_genres
WHERE type = 'TV show'
GROUP BY genre;

-- The top genres for all titles produced or co-produced by the United States
SELECT 
	genre,
    COUNT(*) AS no_of_titles,
    RANK() OVER(ORDER BY COUNT(*) DESC) AS rank_no
FROM account_genres
WHERE country LIKE '%united states%'
GROUP BY genre;

-- The top genres for movies produced or coproduced by the United States
SELECT 
	genre,
    COUNT(*) AS no_of_titles,
    RANK() OVER(ORDER BY COUNT(*) DESC) AS rank_no
FROM account_genres
WHERE type = 'movie'
	AND country LIKE '%united states%'
GROUP BY genre;

-- The top genres for tV shows produced or coproduced by the United States
SELECT 
	genre,
    COUNT(*) AS no_of_titles,
    RANK() OVER(ORDER BY COUNT(*) DESC) AS rank_no
FROM account_genres
WHERE type = 'TV show'
	AND country LIKE '%united states%'
GROUP BY genre;

-- What are the longest movies?
SELECT *
FROM netflix_staging2;

SELECT 
    title,
    duration_minutes,
    RANK() OVER(ORDER BY duration_minutes DESC) AS rank_no
FROM netflix_staging2
WHERE type = 'movie';

-- What are the longest TV shows?
SELECT 
    title,
    num_seasons,
    RANK() OVER(ORDER BY num_seasons DESC) AS rank_no
FROM netflix_staging2
WHERE type = 'TV show';

-- What are the longest movies produced and coproduced by the united states?
SELECT 
    title,
    duration_minutes,
    RANK() OVER(ORDER BY duration_minutes DESC) AS rank_no
FROM netflix_staging2
WHERE 
	type = 'movie'
	AND country LIKE '%United states%';
    
    -- What are the longest TV shows produced and coproduced by the united states?
SELECT 
    title,
    num_seasons,
    RANK() OVER(ORDER BY num_seasons DESC) AS rank_no
FROM netflix_staging2
WHERE 
	type = 'tv show'
	AND country LIKE '%United states%';

-- Let's now go to ratings analysis
SELECT DISTINCT rating
FROM netflix_staging2;

SELECT 
	rating,
    COUNT(*) AS no_of_titles
FROM netflix_staging2
GROUP BY rating;

-- Top ratings for all titles
SELECT 
	rating,
    COUNT(*) AS no_of_titles,
    RANK() OVER(ORDER BY COUNT(*) DESC) AS rank_no
FROM netflix_staging2
GROUP BY rating;
-- we can see that there are 4 titles with blank ratings and 3 titles with null ratings

-- Top ratings for movies
SELECT 
	rating,
    COUNT(*) AS no_of_movies,
    RANK() OVER(ORDER BY COUNT(*) DESC) AS rank_no
FROM netflix_staging2
WHERE type = 'movie'
GROUP BY rating;

-- Top ratings for TV shows
SELECT 
	rating,
    COUNT(*) AS no_of_tv_shows,
    RANK() OVER(ORDER BY COUNT(*) DESC) AS rank_no
FROM netflix_staging2
WHERE type = 'TV show'
GROUP BY rating;

-- release year analysis
SELECT 
	release_year,
    COUNT(*) AS no_of_titles,
	RANK() OVER(ORDER BY COUNT(*) DESC) AS rank_no
FROM netflix_staging2
GROUP BY release_year;

-- release year analysis for movies
SELECT 
	release_year,
    COUNT(*) AS no_of_movies,
	RANK() OVER(ORDER BY COUNT(*) DESC) AS rank_no
FROM netflix_staging2
WHERE type = 'movie'
GROUP BY release_year;

-- release year analysis for tv shows
SELECT 
	release_year,
    COUNT(*) AS no_of_tv_shows,
	RANK() OVER(ORDER BY COUNT(*) DESC) AS rank_no
FROM netflix_staging2
WHERE type = 'tv show'
GROUP BY release_year;

-- release month analysis
SELECT *
FROM netflix_staging2
WHERE date_added IS NULL or date_added = '';
-- there 10 titles with no date added

SELECT
	title,
	SUBSTRING_INDEX(date_added, ' ', 1) AS release_month
FROM 
    netflix_staging2
WHERE date_added IS NOT NULL AND TRIM(date_added) != '';
    
SELECT 
	release_month,
    COUNT(*) AS no_of_titles
FROM(
	SELECT
		title,
		SUBSTRING_INDEX(date_added, ' ', 1) AS release_month
	FROM 
		netflix_staging2
	WHERE date_added IS NOT NULL AND TRIM(date_added) != '')
AS month_release
WHERE release_month IS NOT NULL and release_month != ''
GROUP BY release_month;


SELECT 
	release_month,
    COUNT(*) AS no_of_titles,
    RANK() OVER(ORDER BY COUNT(*) DESC) AS rank_no 
FROM(
	SELECT
		title,
		SUBSTRING_INDEX(date_added, ' ', 1) AS release_month
	FROM 
		netflix_staging2
	WHERE date_added IS NOT NULL AND TRIM(date_added) != '')
AS month_release
WHERE release_month IS NOT NULL and release_month != ''
GROUP BY release_month;
