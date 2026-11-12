CREATE DATABASE zomato_project;
USE zomato_project;
SHOW DATABASES;
SHOW TABLES;
DESCRIBE country_map;
SELECT *
FROM country_map;
SELECT COUNT(*) AS country_count
FROM country_map;
DESCRIBE country_map;
CREATE DATABASE IF NOT EXISTS zomato_project;
USE zomato_project;

-- 1. Country Code Table
CREATE TABLE country_code (
    country_code INT PRIMARY KEY,
    country_name VARCHAR(100)
);

-- 2. Main Zomato Restaurant Data Table
CREATE TABLE zomato_restaurant_data (
    restaurant_id INT PRIMARY KEY,
    restaurant_name VARCHAR(150),
    country_code INT,
    city VARCHAR(100),
    address VARCHAR(255),
    locality VARCHAR(100),
    locality_verbose VARCHAR(150),
    longitude DECIMAL(10, 6),
    latitude DECIMAL(10, 6),
    cuisines VARCHAR(255),
    currency VARCHAR(50),
    has_table_booking VARCHAR(5),
    has_online_delivery VARCHAR(5),
    is_delivering_now VARCHAR(5),
    switch_to_order_menu VARCHAR(5),
    price_range INT,
    votes INT,
    average_cost_for_two INT,
    rating DECIMAL(3, 1),
    datekey_opening VARCHAR(15)
);
SHOW VARIABLES LIKE 'local_infile';
TRUNCATE TABLE zomato_restaurant_data;

LOAD DATA LOCAL INFILE 'C:/Users/Dell/OneDrive/Desktop/zomato_restaurant_data.csv'
INTO TABLE zomato_restaurant_data
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

SELECT COUNT(*) FROM zomato_restaurant_data;
SET SQL_SAFE_UPDATES = 0;
UPDATE zomato_restaurant_data 
SET Datekey_Opening = STR_TO_DATE(Datekey_Opening, '%Y_%c_%e')
WHERE Datekey_Opening IS NOT NULL AND Datekey_Opening != '';
ALTER TABLE zomato_restaurant_data 
MODIFY COLUMN Datekey_Opening DATE;
-- Question 2
-- 1. Create structure
CREATE TABLE IF NOT EXISTS calendar_table (
    DateKey DATE PRIMARY KEY,
    Year INT,
    MonthNo INT,
    MonthFullName VARCHAR(20),
    Quarter VARCHAR(5),
    YearMonth VARCHAR(10),
    WeekdayNo INT,
    WeekdayName VARCHAR(20),
    FinancialMonth VARCHAR(5),
    FinancialQuarter VARCHAR(5)
);

-- 2. Insert distinct dates
INSERT IGNORE INTO calendar_table (DateKey)
SELECT DISTINCT Datekey_Opening 
FROM zomato_restaurant_data 
WHERE Datekey_Opening IS NOT NULL;
-- 3. Update calculated columns
UPDATE calendar_table
SET 
    Year = YEAR(DateKey),
    MonthNo = MONTH(DateKey),
    MonthFullName = MONTHNAME(DateKey),
    Quarter = CONCAT('Q', QUARTER(DateKey)),
    YearMonth = DATE_FORMAT(DateKey, '%Y-%b'),
    WeekdayNo = WEEKDAY(DateKey) + 1, -- 1 = Monday, 7 = Sunday
    WeekdayName = DAYNAME(DateKey),
    FinancialMonth = CONCAT('FM', IF(MONTH(DateKey) >= 4, MONTH(DateKey) - 3, MONTH(DateKey) + 9)),
    FinancialQuarter = CASE 
        WHEN MONTH(DateKey) BETWEEN 4 AND 6 THEN 'FQ1'
        WHEN MONTH(DateKey) BETWEEN 7 AND 9 THEN 'FQ2'
        WHEN MONTH(DateKey) BETWEEN 10 AND 12 THEN 'FQ3'
        ELSE 'FQ4'
    END;
-- Question 3
 SELECT 
    c.Country,
    z.city,
    COUNT(z.restaurant_id) AS Total_Restaurants
FROM zomato_restaurant_data z
LEFT JOIN country_map c 
    ON z.country_code = c.`Country Code`
GROUP BY c.Country, z.city
ORDER BY Total_Restaurants DESC;
Describe zomato_restaurant_data;
-- Question 4
SELECT 
    cal.Year,
    cal.Quarter,
    cal.MonthNo,
    cal.MonthFullName,
    COUNT(z.restaurant_id) AS Restaurants_Opened
FROM zomato_restaurant_data z
JOIN calendar_table cal 
    ON z.Datekey_Opening = cal.DateKey
GROUP BY 
    cal.Year, 
    cal.Quarter, 
    cal.MonthNo, 
    cal.MonthFullName
ORDER BY cal.Year, cal.MonthNo;
-- Question 5
SELECT 
    ROUND(rating, 1) AS Average_Rating,
    COUNT(restaurant_id) AS Total_Restaurants
FROM zomato_restaurant_data
GROUP BY ROUND(rating, 1)
ORDER BY Average_Rating DESC;
-- Question 6
SELECT 
    CASE 
        WHEN average_cost_for_two <= 300 THEN '0 - 300 (Budget)'
        WHEN average_cost_for_two BETWEEN 301 AND 800 THEN '301 - 800 (Mid-Range)'
        WHEN average_cost_for_two BETWEEN 801 AND 1500 THEN '801 - 1500 (Premium)'
        ELSE '1501+ (Luxury)'
    END AS Price_Bucket,
    COUNT(restaurant_id) AS Total_Restaurants,
    ROUND(COUNT(restaurant_id) * 100.0 / (SELECT COUNT(*) FROM zomato_restaurant_data), 2) AS Percentage
FROM zomato_restaurant_data
GROUP BY Price_Bucket
ORDER BY MIN(average_cost_for_two);
-- Question 7
SELECT 
    has_table_booking,
    COUNT(restaurant_id) AS Total_Restaurants,
    ROUND((COUNT(restaurant_id) * 100.0) / (SELECT COUNT(*) FROM zomato_restaurant_data), 2) AS Percentage
FROM zomato_restaurant_data
GROUP BY has_table_booking;
-- Question 8
SELECT 
    has_online_delivery,
    COUNT(restaurant_id) AS Total_Restaurants,
    ROUND((COUNT(restaurant_id) * 100.0) / (SELECT COUNT(*) FROM zomato_restaurant_data), 2) AS Percentage
FROM zomato_restaurant_data
GROUP BY has_online_delivery;
-- Question 9.1
SELECT 
    TRIM(cuisines) AS Cuisine,
    COUNT(restaurant_id) AS Total_Restaurants
FROM zomato_restaurant_data
GROUP BY TRIM(cuisines)
ORDER BY Total_Restaurants DESC
LIMIT 10;
-- Question 9.2
SELECT 
    city,
    COUNT(restaurant_id) AS Total_Restaurants
FROM zomato_restaurant_data
GROUP BY city
ORDER BY Total_Restaurants DESC
LIMIT 10;
-- Question 9.3
SELECT 
    ROUND(rating, 1) AS Rating_Score,
    COUNT(restaurant_id) AS Frequency
FROM zomato_restaurant_data
GROUP BY ROUND(rating, 1)
ORDER BY Rating_Score DESC;