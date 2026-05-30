# this tab should be for organizing the tables for dashboarding in power bi
CREATE VIEW total_layoff AS
SELECT *
FROM layoffs_two
WHERE total_laid_off IS NOT NULL;

CREATE VIEW percentage_layoff AS
SELECT *
FROM layoffs_two
WHERE percentage_laid_off IS NOT NULL;

CREATE VIEW layoffs_by_year AS
SELECT 
  YEAR(`date`) AS year,
  SUM(total_laid_off) AS total_layoffs
FROM total_layoff
WHERE `date` IS NOT NULL
GROUP BY YEAR(`date`)
ORDER BY year;

CREATE VIEW layoffs_by_industry AS
SELECT 
  industry,
  SUM(total_laid_off) AS total_layoffs
FROM total_layoff
GROUP BY industry;

CREATE VIEW layoffs_by_country AS
SELECT 
  country,
  SUM(total_laid_off) AS total_layoffs
FROM total_layoff
GROUP BY country;

CREATE VIEW layoffs_by_company AS
SELECT 
  company,
  SUM(total_laid_off) AS total_layoffs
FROM total_layoff
GROUP BY company;

select * from total_layoff;
select * from percentage_layoff;
select * from layoffs_by_year;
select * from layoffs_by_industry;
select * from layoffs_by_country;
select * from layoffs_by_company;


