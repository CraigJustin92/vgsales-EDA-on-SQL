-- 1. Get the total sales for each publisher
SELECT "Publisher", 
       SUM("NA_Sales" + "EU_Sales" + "JP_Sales" + "Other_Sales") AS total_sales
FROM vgsales
GROUP BY "Publisher"
ORDER BY total_sales DESC;

-- 2. Which Genres sell the most for each Platform?
WITH genre_count AS (
    SELECT DISTINCT "Platform" AS platform, "Genre" AS genre, 
           SUM("NA_Sales" + "EU_Sales" + "JP_Sales" + "Other_Sales") 
           OVER (PARTITION BY "Genre" ORDER BY "Platform", "Genre") AS sales_per_genre
    FROM vgsales
    ORDER BY "Platform", "Genre", sales_per_genre DESC
), max_genres AS (
    SELECT *, 
           MAX(sales_per_genre) OVER (PARTITION BY platform ORDER BY platform) AS max_genre
    FROM genre_count
)
SELECT platform, genre, max_genre
FROM max_genres
WHERE sales_per_genre = max_genre;

-- 3. Check top selling genres for a specific platform (e.g., 2600)
SELECT "Platform", "Genre", 
       SUM("NA_Sales" + "EU_Sales" + "JP_Sales" + "Other_Sales") AS total_sales
FROM vgsales
WHERE "Platform" = '2600'
GROUP BY "Platform", "Genre"
ORDER BY total_sales DESC;

-- 4. Which Genres sold the least for each Platform?
WITH genre_count AS (
    SELECT DISTINCT "Platform" AS platform, "Genre" AS genre, 
           SUM("NA_Sales" + "EU_Sales" + "JP_Sales" + "Other_Sales") 
           OVER (PARTITION BY "Genre" ORDER BY "Platform", "Genre") AS sales_per_genre
    FROM vgsales
    ORDER BY "Platform", "Genre", sales_per_genre
), min_genres AS (
    SELECT *, 
           MIN(sales_per_genre) OVER (PARTITION BY platform ORDER BY platform) AS min_genre
    FROM genre_count
)
SELECT platform, genre, min_genre
FROM min_genres
WHERE sales_per_genre = min_genre;

-- 5. Find the year with the highest-earning racing games
SELECT "Year" AS year, 
       SUM("NA_Sales" + "EU_Sales" + "JP_Sales" + "Other_Sales") AS total_sales
FROM vgsales
WHERE "Genre" = 'Racing'
  AND "Year" != 'N/A'
GROUP BY year
ORDER BY total_sales DESC
LIMIT 1;

-- 6. Best and worst performing Pokemon game
SELECT "Name", 
       SUM("NA_Sales" + "EU_Sales" + "JP_Sales" + "Other_Sales") AS total_sales
FROM vgsales
WHERE "Name" LIKE '%Pokemon%'
GROUP BY "Name"
ORDER BY total_sales DESC
LIMIT 1;  -- For best game, remove DESC for worst game.

-- 7. Platforms with the most and least games
SELECT DISTINCT "Platform", 
                COUNT(*) OVER (PARTITION BY "Platform") AS count_of_games
FROM vgsales
ORDER BY count_of_games DESC;

-- 8. Year with the most games per Publisher
WITH year_count AS (
    SELECT "Publisher", "Year", 
           COUNT("Name") OVER (PARTITION BY "Publisher" ORDER BY "Year") AS count
    FROM vgsales
    ORDER BY "Publisher", count
), max_games AS (
    SELECT *, 
           MAX(count) OVER (PARTITION BY "Publisher") AS max_games
    FROM year_count
)
SELECT DISTINCT "Publisher", "Year" AS year_with_most_games, max_games AS total_games_released
FROM max_games
WHERE count = max_games
  AND "Year" != 'N/A'
ORDER BY total_games_released DESC;

-- 9. Count of Sonic, Mega Man, or Mario games
SELECT CASE
           WHEN "Name" LIKE '%Sonic%' THEN 'Sonic'
           WHEN "Name" ILIKE '%Mega Man%' OR "Name" ILIKE '%Mega-Man%' THEN 'Mega Man'
           WHEN "Name" ILIKE '%Mario%' OR "Name" ILIKE '%Super Mario%' THEN 'Mario'
       END AS mascot,
       COUNT("Name")
FROM vgsales
WHERE CASE
          WHEN "Name" LIKE '%Sonic%' THEN 'Sonic'
          WHEN "Name" ILIKE '%Mega Man%' OR "Name" ILIKE '%Mega-Man%' THEN 'Mega Man'
          WHEN "Name" ILIKE '%Mario%' OR "Name" ILIKE '%Super Mario%' THEN 'Mario'
      END IN ('Mario', 'Sonic', 'Mega Man')
GROUP BY mascot
ORDER BY count DESC;

-- 10. List all games containing 'Mario' in the name
SELECT *
FROM vgsales
WHERE "Name" ILIKE '%mario%' AND "Name" IS NOT NULL;

-- 11. Do platforms favor a particular genre?
WITH genre_count AS (
    SELECT DISTINCT "Platform" AS platform, "Genre" AS genre, 
           COUNT("Genre") OVER (PARTITION BY "Genre" ORDER BY "Platform", "Genre") AS count_per_genre
    FROM vgsales
    ORDER BY "Platform", count_per_genre DESC
), max_genres AS (
    SELECT *, 
           MAX(count_per_genre) OVER (PARTITION BY platform ORDER BY platform) AS max_genre
    FROM genre_count
)
SELECT platform, genre, max_genre AS max_games
FROM max_genres
WHERE count_per_genre = max_genre;

-- 12. Do platforms prioritize games releases of the Genre that generates the most sales?
WITH genre_sales AS (
    SELECT DISTINCT 
        "Platform" AS platform, 
        "Genre" AS genre, 
        SUM("NA_Sales" + "EU_Sales" + "JP_Sales" + "Other_Sales") 
        OVER (PARTITION BY "Genre" ORDER BY "Platform", "Genre") AS total_sales_per_genre
    FROM vgsales
    ORDER BY "Platform", total_sales_per_genre DESC
),
max_sales AS (
    SELECT *, 
        MAX(total_sales_per_genre) 
        OVER (PARTITION BY platform ORDER BY platform) AS max_sales_per_genre
    FROM genre_sales
),
top_sales_genres AS (
    SELECT *
    FROM max_sales
    WHERE max_sales_per_genre = total_sales_per_genre
),
genre_count AS (
    SELECT DISTINCT 
        "Platform" AS platform, 
        "Genre" AS genre, 
        COUNT(*) 
        OVER (PARTITION BY "Genre" ORDER BY "Platform", "Genre") AS total_count_per_genre
    FROM vgsales
    ORDER BY "Platform", total_count_per_genre DESC
),
max_count AS (
    SELECT *, 
        MAX(total_count_per_genre) 
        OVER (PARTITION BY platform ORDER BY platform) AS max_count_per_genre
    FROM genre_count
),
top_count_genres AS (
    SELECT *
    FROM max_count
    WHERE max_count_per_genre = total_count_per_genre
)
SELECT 
    s.platform, 
    s.genre AS genre_with_max_sales, 
    c.genre AS genre_with_max_count,
    CASE 
        WHEN s.genre = c.genre THEN 'Yes' 
        ELSE 'No' 
    END AS platform_favors_top_seller
FROM top_sales_genres AS s
JOIN top_count_genres AS c
    ON s.platform = c.platform;
