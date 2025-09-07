-- 🧹 Data Cleaning Project in MySQL

SELECT *
FROM layoffs;
-- Look at the raw dataset

-- General cleaning steps:
-- 1. Remove Duplicates
-- 2. Standardize the Data (fix spelling/formatting errors)
-- 3. Handle Null or Blank Values
-- 4. Remove Irrelevant Columns/Rows
-- ⚠️ Never touch the raw table — always work on a staging copy.

-- 📌 Create a staging table (same schema as raw data)
CREATE TABLE layoffs_staging
LIKE layoffs;
# Refresh Schemas

SELECT *
FROM layoffs_staging;
# See empty columns

-- Copy raw data into staging
INSERT layoffs_staging
SELECT *
FROM layoffs; 
# Why? Will be alot of changes in the staging table 
# If we make a mistake, I want to have the raw data available

-- ✅ Work from layoffs_staging from here on
SELECT *
FROM layoffs_staging;
# See full table from layoffs

---------------------------------------------------
-- 1. Remove Duplicates
---------------------------------------------------
# (if there are 2 or above means its duplicate theres a issue)
# (Start over with the project again and now its showing row_num 1's for layoffs_staging)

-- Use ROW_NUMBER to identify duplicates
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`) AS row_num
FROM layoffs_staging; 
# Shows row_num 1's

-- Create a CTE to see duplicates clearly
WITH duplicate_cte AS 
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location,
industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;
-- These rows are duplicates (row_num > 1)
# Shows the duplicates on table all 2's on row_num 
# I want to get rid these exact rows

SELECT * 
FROM layoffs_staging
WHERE company = 'Oda'; 
# This table is NOT duplicate

SELECT * 
FROM layoffs_staging
WHERE company = 'Casper'; 
# This table is duplicate all 339's in funds_raised_millions

WITH duplicate_cte AS 
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location,
industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
DELETE
FROM duplicate_cte
WHERE row_num > 1;
-- ❌ You can’t delete directly from a CTE in MySQL

-- Solution: Create a second staging table with row_num included
# Right click layoffs_staging > Copy Clipboard > Create Statement
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT # Added row_num
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
# Create Table 'layoffs_staging2'

SELECT *
FROM layoffs_staging2;
# Shows an empty table

-- Insert staging + row numbers
INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location,
industry, total_laid_off, percentage_laid_off, `date`, stage, 
country, funds_raised_millions) AS row_num
FROM layoffs_staging;
# INSERT INTO layoffs_staging 2 SELECT 
# Go back to SELECT * (statement) FROM layoffs_staging2

SELECT *
FROM layoffs_staging2
WHERE row_num > 1;
# These the duplicates of 2's that needs to be remove

-- Now safely delete duplicates
DELETE 
FROM layoffs_staging2
WHERE row_num > 1;
# Error: You are using safe update mode and you tried to update a table without a WHERE that uses a KEY column.
# To disable safe mode, toggle the option in Preference -> SQL Editor and reconnect
# Click Query to reconnect to server
# Always go to the SELECT STATEMENT to see what you are deleting 

SELECT *
FROM layoffs_staging2
WHERE row_num > 1;
# Duplicate has been removed

-- ✅ Check that duplicates are gone
SELECT *
FROM layoffs_staging2;
# Shows no Duplicates

---------------------------------------------------
-- 2. Standardizing Data
---------------------------------------------------
SELECT DISTINCT(TRIM(company))
FROM layoffs_staging2;
# Check if there any fixes of spaces

SELECT company, TRIM(company)
FROM layoffs_staging2;

-- Trim extra spaces in company names
UPDATE layoffs_staging2
SET company = TRIM(company);
# Update and trim the left space
# Go back to SELECT company, TRIM(company) to FROM layoffs_staging2

SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;
# Crypto and Crypto Currency are the same 

SELECT * 
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';
# Shows alot of Crypto but a few Crypto Currency

-- Fix inconsistent industry names (e.g., "Crypto" vs "Crypto Currency")
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';
# Updated 3 rows
# Go back to SELECT * to WHERE above to check all is Crypto

SELECT DISTINCT industry 
FROM layoffs_staging2; 
# Show only Crypto now

SELECT DISTINCT location
FROM layoffs_staging2
ORDER BY 1;
# Checked if any errors theres none

SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;
# Sees United States. That need to be correct

SELECT *
FROM layoffs_staging2
WHERE country LIKE 'United States%' 
ORDER BY 1;
# Can't find the error using this query

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;

-- Fix country names (remove trailing periods)
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';
# Update layoffs_staging2 SET country 

-- Change Date column from Text into Date format
SELECT `date`
FROM layoffs_staging2;

SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging2;
# Error: Unknown column '`%m/%d/%Y' change '' instead ``
# Shows date month/date/year - the standard date format

-- Convert date column from text → DATE format
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');
# Update 2356 rows 
# Go back and run SELECT `date` FROM layoffs_staging2; 

# On the layoffs_staging2 > Drop down Columns > Date still definition as text, I need to change it
# Only do this on the staging table never in raw table
ALTER TABLE layoffs_staging2 
MODIFY COLUMN `date` DATE;
-- ✅ Now date is a proper DATE column
# Has been change to alter table
# Refresh Schemas and see Columns > Date definition as date format

SELECT * 
FROM layoffs_staging2; 
# Check to see everything has been set

---------------------------------------------------
-- 3. Handling Null / Blank Values
---------------------------------------------------
SELECT * 
FROM layoffs_staging2
WHERE total_laid_off = NULL;
# Will show a blank table 

SELECT * 
FROM layoffs_staging2
WHERE total_laid_off IS NULL;
# If it has two NULL's its useless from total_laid_off and percentage_laid_off
# Will be the ones to remove if both NULL

-- Find rows with NULLs
SELECT * 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT DISTINCT industry
FROM layoffs_staging2;

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL 
OR industry = '';
# Check industry is NULL or blank

SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb';
# Industry is blank and need to be Travel like the other Airbnb

SELECT * 
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
    AND t1.location = t2.location
WHERE t1.industry IS NULL 
AND t2.industry IS NOT NULL;
# Shows blank table

SELECT * 
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;
# Shows the entire table have to scroll to find it

-- Clear version only show t1 and t2
SELECT t1.industry, t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;
# if the t1.industry is blank the t2.industry will populate to t1.industry

-- Fix blank industries by pulling from another row of the same company
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;
# t1. industry is the blank one 
# Update layoff_staging2 t1 and go back to SELECT statement
# Found out it didn't update t1 still blank

-- Convert empty strings to NULLs for consistency
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';
# Went back to the SELECT Statement now it show NULLS in blank table

-- Retry to Update
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL 
AND t2.industry IS NOT NULL;
# Update layoffs_staging2 t1 JOIN layoffs_staging2 t2
# Go to SELECT Statement then shows none on the table
# Check Airbnb shows both industries Travel

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL 
OR industry = '';
# Only shows Bally's Interactove industry is NULL

SELECT *
FROM layoffs_staging2
WHERE company LIKE 'Bally%';
# Doesn't have another populated row
# Leave as it is

---------------------------------------------------
-- 4. Remove Irrelevant Rows/Columns
---------------------------------------------------
SELECT *
FROM layoffs_staging2;
# Total_laid_off and percentage_laid_off and funds_raised_millions we cannot populate with the data we have here
# I could populate the NULL role if I had the company exact company total original total of layoffs calculations
# Need to remove those

SELECT * 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;
# I don't know the total_laid_off nor percentage_laid_off
# I don't if it has been layoffs at all so we can remove them

-- Remove rows where layoffs info is completely missing
DELETE 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;
# They're deleted 361 rows
# Only deleted total_laid_off and percentage_laid_off that is both NULL

SELECT * 
FROM layoffs_staging2;

-- Drop helper column
ALTER TABLE layoffs_staging2 
DROP COLUMN row_num;
# Removing row_num 
# Go back to SELECT Statement
