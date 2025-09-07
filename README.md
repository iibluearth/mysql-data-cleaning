# 📊 MySQL Data Cleaning Project – Layoffs Dataset

## 📌 Project Overview

This project demonstrates how to clean and prepare a raw dataset for analysis using MySQL.
The dataset contains information about company layoffs, including company name, industry, location, funds raised, and percentage of workforce laid off.

👉 **The main goals of this project:**

1. Remove duplicates.

2. Standardize text data (e.g., fix spelling, formatting issues).

3. Handle null/blank values.

4. Convert data types (e.g., text to date).

5. Remove irrelevant or unusable rows.

Final output: a cleaned version of the dataset (`layoffs_clean`) that’s ready for analysis.

## 📁 Project Structure

```
📂 mysql-data-cleaning
│── data/
│   ├── layoffs_raw.csv        # Original dataset
│   ├── layoffs_cleaned.csv    # Final cleaned version
│
│── sql/
│   ├── create_tables.sql      # Schema for loading raw data
│   ├── cleaning_steps.sql     # Full step-by-step cleaning process with comments
│
│── README.md                  # Tutorial + documentation
```

### ⚙️ Setup Instructions

1. Create a new schema

  - In MySQL Workbench (or your connected MySQL server), click Create a New Schema.
  - Name it `world_layoffs`.
  - Click Apply twice, keeping all options checked, and then click Create Table to start.

2. Upload the raw dataset

  - Import `layoffs_raw.csv` into a table in the `world_layoffs` schema.

3. Run the cleaning script

  - Open `cleaning_steps.sql` and execute the queries step by step.

4. View the final cleaned dataset

  - After running all queries, the cleaned table is available as `layoffs_clean` or via `layoffs_cleaned.sql`.

## 🧹 Data Cleaning Process

### 1. Remove Duplicates

In MySQL, you cannot delete directly from a CTE, so the workflow is:

#### 1. Create a second staging table (layoffs_staging2) that includes a row_num column. This lets you track duplicates safely.

```
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
  `row_num` INT 
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
```

#### 2. Insert data from the original staging table, adding row numbers to identify duplicates:

```
INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location,
industry, total_laid_off, percentage_laid_off, `date`, stage, 
country, funds_raised_millions) AS row_num
FROM layoffs_staging;
```

#### 3. Check which rows are duplicates (`row_num > 1`):

```
SELECT *
FROM layoffs_staging2
WHERE row_num > 1;
```
Example: For Casper, all duplicate rows will have row_num > 1.

#### 4. Safely delete duplicates:

```
DELETE 
FROM layoffs_staging2
WHERE row_num > 1;
```
⚠️ If you encounter a “safe update mode” error, disable safe mode in MySQL Workbench Preferences → SQL Editor and reconnect.

#### 5. Confirm duplicates are gone:

```
SELECT *
FROM layoffs_staging2;
```
✅ Result: Only unique rows remain, and you can continue cleaning other columns without affecting duplicates.

### 2. Standardize Text Data

- Removed extra spaces in `company` names

- Unified industry values (`Crypto Currency → Crypto`)

- Fixed country naming (`United States.` → `United States`)

```
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';
```

### 3. Handle Null / Blank Values

- Converted blank `industry` values to `NULL`

- Populated missing industries by joining with other records from the same company

- Removed rows where both `total_laid_off` and `percentage_laid_off` were NULL

```
DELETE 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;
```

### 4. Convert Data Types

Converted `date` column from text to proper MySQL `DATE`:

```
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging2 
MODIFY COLUMN `date` DATE;
```

## 📊 Results

✅ Duplicates removed

✅ Standardized industries and countries

✅ Dates properly formatted

✅ Blank/irrelevant rows dropped

The final dataset (layoffs_clean) is ready for analysis.