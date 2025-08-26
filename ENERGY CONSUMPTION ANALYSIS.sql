-- WORLD WIDE ENERGY CONSUMPTION
CREATE DATABASE ENERGYDB3;
USE ENERGYDB3;


-- 1. country table
CREATE TABLE country (
    CID VARCHAR(10) PRIMARY KEY,
    Country VARCHAR(100) UNIQUE
);

SELECT * FROM COUNTRY;

-- 2. emission_3 table
CREATE TABLE emission_3 (
    country VARCHAR(100),
    energy_type VARCHAR(50),
    year INT,
    emission INT,
    per_capita_emission DOUBLE,
    FOREIGN KEY (country) REFERENCES country(Country)
);

SELECT * FROM EMISSION_3;


-- 3. population table
CREATE TABLE population (
    countries VARCHAR(100),
    year INT,
    Value DOUBLE,
    FOREIGN KEY (countries) REFERENCES country(Country)
);

SELECT * FROM POPULATION;

-- 4. production table
CREATE TABLE production (
    country VARCHAR(100),
    energy VARCHAR(50),
    year INT,
    production INT,
    FOREIGN KEY (country) REFERENCES country(Country)
);


SELECT * FROM PRODUCTION;

-- 5. gdp_3 table
CREATE TABLE gdp_3 (
    Country VARCHAR(100),
    year INT,
    Value DOUBLE,
    FOREIGN KEY (Country) REFERENCES country(Country)
);

SELECT * FROM GDP_3;

-- 6. consumption table
CREATE TABLE consumption (
    country VARCHAR(100),
    energy VARCHAR(50),
    year INT,
    consumption INT,
    FOREIGN KEY (country) REFERENCES country(Country)
);

SELECT * FROM CONSUMPTION;

-- Data Analysis Questions
-- 1.What is the total emission per country for the most recent year available?
SELECT country,
       SUM(emission) AS total_emission
FROM emission_3
WHERE year = (SELECT MAX(year) FROM emission_3)
GROUP BY country
ORDER BY total_emission DESC;

-- 2.What are the top 5 countries by GDP in the most recent year?
SELECT Country,
       Value AS gdp
FROM gdp_3
WHERE year = (SELECT MAX(year) FROM gdp_3)
ORDER BY gdp DESC
LIMIT 5;

-- 3.Compare energy production and consumption by country and year. 
SELECT co.country, co.year,
       SUM(co.total_production) AS total_production,
       SUM(co.total_consumption) AS total_consumption
FROM (
  SELECT country, year, SUM(production) AS total_production, 0 AS total_consumption
  FROM production GROUP BY country, year
  UNION ALL
  SELECT country, year, 0 AS total_production, SUM(consumption) AS total_consumption
  FROM consumption GROUP BY country, year
) co
GROUP BY co.country, co.year
ORDER BY co.country, co.year;

-- 4.Which energy types contribute most to emissions across all countries?
SELECT energy_type,
       SUM(emission) AS total_emission
FROM emission_3
GROUP BY energy_type
ORDER BY total_emission DESC;

-- Trend Analysis Over Time
-- 5.How have global emissions changed year over year?
SELECT year,
       SUM(emission) AS global_emission
FROM emission_3
GROUP BY year
ORDER BY year;

-- 6.What is the trend in GDP for each country over the given years?
SELECT Country,
       year,
       Value AS gdp
FROM gdp_3
ORDER BY Country, year;

-- 7.How has population growth affected total emissions in each country?
-- Example: compute correlation (MySQL has no built-in corr; compute covariance/stddev)
-- Simpler: compute emissions per capita and show trend:
SELECT 
    e.country, 
    e.year,
    SUM(e.emission) / p.Value AS emission_per_capita
FROM emission_3 e
JOIN population p 
    ON e.country = p.countries 
   AND e.year = p.year
GROUP BY e.country, e.year, p.Value
ORDER BY e.country, e.year
LIMIT 0, 5000;

-- 8.Has energy consumption increased or decreased over the years for major economies?
-- Step 1: top 5 countries by latest GDP
WITH top5 AS (
  SELECT Country FROM gdp_3
  WHERE year = (SELECT MAX(year) FROM gdp_3)
  ORDER BY Value DESC LIMIT 5
)
SELECT c.country, c.year, SUM(c.consumption) AS total_consumption
FROM consumption c
JOIN top5 t ON c.country = t.Country
GROUP BY c.country, c.year
ORDER BY c.country, c.year;

-- 9.What is the average yearly change in emissions per capita for each country?
-- compute emission_per_capita then yearly change and average
SELECT 
    cur.country,
    AVG(cur.emission_per_capita - prev.emission_per_capita) AS avg_yearly_change
FROM (
    SELECT 
        e.country, 
        e.year,
        SUM(e.emission) / p.Value AS emission_per_capita
    FROM emission_3 e
    JOIN population p 
        ON e.country = p.countries 
       AND e.year = p.year
    GROUP BY e.country, e.year, p.Value
) AS cur
JOIN (
    SELECT 
        e.country, 
        e.year,
        SUM(e.emission) / p.Value AS emission_per_capita
    FROM emission_3 e
    JOIN population p 
        ON e.country = p.countries 
       AND e.year = p.year
    GROUP BY e.country, e.year, p.Value
) AS prev
ON cur.country = prev.country 
   AND cur.year = prev.year + 1
GROUP BY cur.country
ORDER BY avg_yearly_change DESC
LIMIT 0, 5000;

-- 10) What is the emission-to-GDP ratio for each country by year?
SELECT 
    e.country, 
    e.year,
    SUM(e.emission) AS total_emission,
    g.Value AS gdp,
    SUM(e.emission) / g.Value AS emission_to_gdp_ratio
FROM emission_3 e
JOIN gdp_3 g 
    ON e.country = g.Country 
   AND e.year = g.year
GROUP BY e.country, e.year, g.Value
ORDER BY e.country, e.year
LIMIT 0, 5000;

-- 11) What is the energy consumption per capita for each country over the last decade?
-- adjust the decade window as needed; example: last 10 years in dataset
SELECT 
    c.country, 
    c.year,
    SUM(c.consumption) AS total_consumption,
    p.Value AS population,
    (SUM(c.consumption) / p.Value) AS consumption_per_capita
FROM consumption c
JOIN population p 
    ON c.country = p.countries 
   AND c.year = p.year
WHERE c.year >= (SELECT MAX(year) FROM consumption) - 9
GROUP BY c.country, c.year, p.Value
LIMIT 0, 5000;


-- 12) How does energy production per capita vary across countries?
SELECT 
    pr.country, 
    pr.year,
    SUM(pr.production) AS total_production,
    p.Value AS population,
    (SUM(pr.production) / p.Value) AS production_per_capita
FROM production pr
JOIN population p 
    ON pr.country = p.countries 
   AND pr.year = p.year
GROUP BY pr.country, pr.year, p.Value
ORDER BY production_per_capita DESC;


-- 13) Which countries have the highest energy consumption relative to GDP?
SELECT 
    c.country, 
    c.year,
    (SUM(c.consumption) / g.Value) AS consumption_per_gdp
FROM consumption c
JOIN gdp_3 g 
    ON c.country = g.Country 
   AND c.year = g.year
GROUP BY c.country, c.year, g.Value
ORDER BY consumption_per_gdp DESC
LIMIT 20;


-- 14) What is the correlation between GDP growth and energy production growth?
WITH gdp_cte AS (
  SELECT Country as country, year, Value AS gdp
  FROM gdp_3
),
prod_cte AS (
  SELECT country, year, SUM(production) AS production
  FROM production
  GROUP BY country, year
),
joined AS (
  SELECT g.country, g.year, g.gdp, p.production
  FROM gdp_cte g
  LEFT JOIN prod_cte p ON g.country = p.country AND g.year = p.year
)
SELECT j.country, j.year,
       (j.gdp - prev.gdp)/prev.gdp * 100 AS gdp_pct_change,
       (j.production - prev.production)/prev.production * 100 AS prod_pct_change
FROM joined j
LEFT JOIN joined prev ON j.country = prev.country AND j.year = prev.year + 1
WHERE prev.gdp IS NOT NULL AND prev.production IS NOT NULL;

-- 15) What are the top 10 countries by population and how do their emissions compare?
-- top 10 by latest population
WITH latest_pop AS (
  SELECT countries AS country, Value AS population
  FROM population
  WHERE year = (SELECT MAX(year) FROM population)
)
SELECT lp.country, lp.population,
       COALESCE(e.total_emission,0) AS emission_latest_year
FROM latest_pop lp
LEFT JOIN (
  SELECT country, SUM(emission) AS total_emission
  FROM emission_3
  WHERE year = (SELECT MAX(year) FROM emission_3)
  GROUP BY country
) e ON lp.country = e.country
ORDER BY lp.population DESC
LIMIT 10;

-- 16) Which countries have improved (reduced) their per capita emissions the most over the last decade?
-- compute change in emission_per_capita between start and end of last 10-year window
SELECT 
    start_data.country,
    start_data.emission_per_capita AS start_epc,
    end_data.emission_per_capita AS end_epc,
    (end_data.emission_per_capita - start_data.emission_per_capita) AS epc_change
FROM (
    SELECT 
        e.country, 
        e.year,
        SUM(e.emission) / p.Value AS emission_per_capita
    FROM emission_3 e
    JOIN population p 
        ON e.country = p.countries 
       AND e.year = p.year
    GROUP BY e.country, e.year, p.Value
) AS start_data
JOIN (
    SELECT 
        e.country, 
        e.year,
        SUM(e.emission) / p.Value AS emission_per_capita
    FROM emission_3 e
    JOIN population p 
        ON e.country = p.countries 
       AND e.year = p.year
    GROUP BY e.country, e.year, p.Value
) AS end_data
ON start_data.country = end_data.country
WHERE start_data.year = (SELECT MAX(year) - 9 FROM emission_3)
  AND end_data.year = (SELECT MAX(year) FROM emission_3)
ORDER BY epc_change ASC
LIMIT 20;



-- 17) What is the global share (%) of emissions by country?


WITH total AS (
  SELECT SUM(emission) AS global_emission
  FROM emission_3
  WHERE year = (SELECT MAX(year) FROM emission_3)
)
SELECT 
    e.country,
    SUM(e.emission) AS country_emission,
    SUM(e.emission) / MAX(t.global_emission) * 100 AS pct_share
FROM emission_3 e
CROSS JOIN total t
WHERE e.year = (SELECT MAX(year) FROM emission_3)
GROUP BY e.country
ORDER BY country_emission DESC;



-- 18) What is the global average GDP, emission, and population by year?
SELECT year,
       AVG(g.Value) AS avg_gdp,
       (SELECT AVG(total_emission) FROM (
           SELECT year, SUM(emission) AS total_emission
           FROM emission_3
           GROUP BY year
       ) AS t2 WHERE t2.year = g.year) AS avg_total_emission,
       (SELECT AVG(pop) FROM (
           SELECT year, SUM(Value) AS pop FROM population GROUP BY year
       ) AS t3 WHERE t3.year = g.year) AS avg_population
FROM gdp_3 g
GROUP BY year
ORDER BY year;







