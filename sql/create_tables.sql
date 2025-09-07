CREATE SCHEMA world_layoffs;
USE layoffs;

CREATE TABLE layoffs (
  company TEXT,
  location TEXT,
  industry TEXT,
  total_laid_off INT,
  percentage_laid_off TEXT,
  date TEXT,
  stage TEXT,
  country TEXT,
  funds_raised_millions INT
);