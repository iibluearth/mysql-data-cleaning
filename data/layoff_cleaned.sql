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

-- Copy raw data into staging
INSERT layoffs_staging
SELECT *
FROM layoffs;

-- ✅ Work from layoffs_staging from here on
SELECT *
FROM layoffs_staging;

---------------------------------------------------
-- 1. Remove Duplicates
---------------------------------------------------

-- Use ROW_NUMBER to identify duplicates
SELECT *,
ROW_NUMBER() OVER(
    PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`
) AS row_num
FROM layoffs_staging;

-- Create a CTE to see duplicates clearly
WITH duplicate_cte AS (
    SELECT *,
    ROW_NUMBER() OVER(
        PARTITION BY company, location, industry, total_laid_off, 
                     percentage_laid_off, `date`, stage, country, funds_raised_millions
    ) AS row_num
    FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;
-- These rows are duplicates (row_num > 1)

-- ❌ You can’t delete directly from a CTE in MySQL
-- Solution: Create a second staging table with row_num included

CREATE TABLE layoffs_staging2 (
  company TEXT,
  location TEXT,
  industry TEXT,
  total_laid_off INT DEFAULT NULL,
  percentage_laid_off TEXT,
  date TEXT,
  stage TEXT,
  country TEXT,
  funds_raised_millions INT DEFAULT NULL,
  row_num INT
);

-- Insert staging + row numbers
INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
    PARTITION BY company, location, industry, total_laid_off, 
                 percentage_laid_off, `date`, stage, country, funds_raised_millions
) AS row_num
FROM layoffs_staging;

-- Now safely delete duplicates
DELETE 
FROM layoffs_staging2
WHERE row_num > 1;

-- ✅ Check that duplicates are gone
SELECT *
FROM layoffs_staging2;

---------------------------------------------------
-- 2. Standardizing Data
---------------------------------------------------

-- Trim extra spaces in company names
UPDATE layoffs_staging2
SET company = TRIM(company);

-- Fix inconsistent industry names (e.g., "Crypto" vs "Crypto Currency")
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Fix country names (remove trailing periods)
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- Convert date column from text → DATE format
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging2 
MODIFY COLUMN `date` DATE;
-- ✅ Now date is a proper DATE column

---------------------------------------------------
-- 3. Handling Null / Blank Values
---------------------------------------------------

-- Find rows with NULLs
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;

-- Fix blank industries by pulling from another row of the same company
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
    ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
  AND t2.industry IS NOT NULL;

-- Convert empty strings to NULLs for consistency
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

---------------------------------------------------
-- 4. Remove Irrelevant Rows/Columns
---------------------------------------------------

-- Remove rows where layoffs info is completely missing
DELETE 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;

-- Drop helper column
ALTER TABLE layoffs_staging2 
DROP COLUMN row_num;