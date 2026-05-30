
#create new table for editting  
drop table if exists layoffs_one;
create table layoffs_one like layoffs;
insert into layoffs_one 
  select * from layoffs; 
  
 #inspected the duplicates, this shows both the duplicates and the rows we'll keep 
  
WITH cte AS (
  SELECT *,
         ROW_NUMBER() OVER (
           PARTITION BY company, location, `date`, total_laid_off, percentage_laid_off,
           stage, country, funds_raised_millions, industry
           ORDER BY company
         ) AS rn,
         COUNT(*) OVER (
           PARTITION BY company, location, `date`, total_laid_off, percentage_laid_off,
           stage, country, funds_raised_millions, industry
         ) AS cnt
  FROM layoffs_one
)
 SELECT *
FROM cte;
 
# create table where we can delete the inspected duplicates

CREATE TABLE `layoffs_two` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `rn` int,
  `cnt` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


#insert the cte data into the table 

insert into layoffs_two 
  SELECT *,
         ROW_NUMBER() OVER (
           PARTITION BY company, location, `date`, total_laid_off, percentage_laid_off,
           stage, country, funds_raised_millions, industry
           ORDER BY company
         ) AS rn,
         COUNT(*) OVER (
           PARTITION BY company, location, `date`, total_laid_off, percentage_laid_off,
           stage, country, funds_raised_millions, industry
         ) AS cnt
  FROM layoffs_one;  
    
 # delete   
    
delete 
  from layoffs_two
   where cnt > 1 and rn >= 1;
   
alter table layoffs_two
  drop column rn;
    
alter table layoffs_two
  drop column cnt;    
    
 # standardizing data - location
     
 select distinct location from layoffs_two
   order by location desc;
  
SELECT location, COUNT(*) AS times_seen
FROM layoffs_two
GROUP BY location
ORDER BY times_seen, location ASC;

UPDATE layoffs_two
  SET location = trim(location);

# standardizing data - industry
  
  UPDATE layoffs_two
  SET industry = trim(industry);
  
-- found crypto to standardize 
  
update layoffs_two
  set industry = 'Crypto'
  where industry like 'Crypto%';
  
# stand	ardizing data - country

SELECT country, COUNT(*) AS times_seen
FROM layoffs_two
GROUP BY country
ORDER BY times_seen, country ASC;     
   
update layoffs_two
  set country = 'United States'
  where country like '%United States%';    
  
# nulls

UPDATE layoffs_two
SET 
  company = NULLIF(TRIM(company), ''),
  location = NULLIF(TRIM(location), ''),
  industry = NULLIF(TRIM(industry), ''),
  percentage_laid_off = NULLIF(TRIM(percentage_laid_off), ''),
  stage = NULLIF(TRIM(stage), ''),
  country = NULLIF(TRIM(country), '');
  
 -- count nulls for each column  

SELECT 
  SUM(CASE WHEN company IS NULL THEN 1 ELSE 0 END) AS company_nulls,
  SUM(CASE WHEN location IS NULL THEN 1 ELSE 0 END) AS location_nulls,
  SUM(CASE WHEN industry IS NULL THEN 1 ELSE 0 END) AS industry_nulls,
  SUM(CASE WHEN total_laid_off IS NULL THEN 1 ELSE 0 END) AS total_laid_off_nulls,
  SUM(CASE WHEN percentage_laid_off IS NULL THEN 1 ELSE 0 END) AS percentage_laid_off_nulls,
  SUM(CASE WHEN `date` IS NULL THEN 1 ELSE 0 END) AS date_nulls,
  SUM(CASE WHEN stage IS NULL THEN 1 ELSE 0 END) AS stage_nulls,
  SUM(CASE WHEN country IS NULL THEN 1 ELSE 0 END) AS country_nulls,
  SUM(CASE WHEN funds_raised_millions IS NULL THEN 1 ELSE 0 END) AS funds_raised_nulls
FROM layoffs_two;

-- industry nulls 
    
 update layoffs_two t1 
   join layoffs_two t2 
     on t1.company = t2.company 
   set t1.industry = t2.industry
   where t1.industry is null
     and t2.industry is not null;
    
update layoffs_two 
  set industry = 'Entertainment'
    where industry is null;
    
-- date nulls 

ALTER TABLE layoffs_two
ADD COLUMN date_clean DATE;

UPDATE layoffs_two
SET date_clean = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_two
DROP COLUMN `date`;

ALTER TABLE layoffs_two
CHANGE date_clean `date` DATE;
  
# snapshot of data quality   
  
SELECT 
  COUNT(*) AS total_rows,

  SUM(CASE 
    WHEN total_laid_off IS NOT NULL AND percentage_laid_off IS NOT NULL 
    THEN 1 ELSE 0 
  END) AS complete_layoff_data,

  SUM(CASE 
    WHEN total_laid_off IS NULL AND percentage_laid_off IS NULL 
    THEN 1 ELSE 0 
  END) AS no_layoff_data,

  SUM(CASE 
    WHEN total_laid_off IS NULL XOR percentage_laid_off IS NULL 
    THEN 1 ELSE 0 
  END) AS partial_layoff_data,

  SUM(CASE WHEN date IS NULL THEN 1 ELSE 0 END) AS missing_date,
  SUM(CASE WHEN funds_raised_millions IS NULL THEN 1 ELSE 0 END) AS missing_funding,
  SUM(CASE WHEN stage IS NULL THEN 1 ELSE 0 END) AS missing_stage
FROM layoffs_two;  
    

# number of nulls per column

SELECT 
  SUM(CASE WHEN company IS NULL THEN 1 ELSE 0 END) AS company_nulls,
  SUM(CASE WHEN location IS NULL THEN 1 ELSE 0 END) AS location_nulls,
  SUM(CASE WHEN industry IS NULL THEN 1 ELSE 0 END) AS industry_nulls,
  SUM(CASE WHEN total_laid_off IS NULL THEN 1 ELSE 0 END) AS total_laid_off_nulls,
  SUM(CASE WHEN percentage_laid_off IS NULL THEN 1 ELSE 0 END) AS percentage_laid_off_nulls,
  SUM(CASE WHEN `date` IS NULL THEN 1 ELSE 0 END) AS date_nulls,
  SUM(CASE WHEN stage IS NULL THEN 1 ELSE 0 END) AS stage_nulls,
  SUM(CASE WHEN country IS NULL THEN 1 ELSE 0 END) AS country_nulls,
  SUM(CASE WHEN funds_raised_millions IS NULL THEN 1 ELSE 0 END) AS funds_raised_nulls
FROM layoffs_two;

# summarized data quality snapshot - exported 
    
select
  SUM(CASE 
    WHEN total_laid_off IS NOT NULL AND percentage_laid_off IS NOT NULL 
    THEN 1 ELSE 0 
  END) AS complete_layoff_data,

  SUM(CASE 
    WHEN total_laid_off IS NULL AND percentage_laid_off IS NULL 
    THEN 1 ELSE 0 
  END) AS no_layoff_data,

  SUM(CASE 
    WHEN total_laid_off IS NULL XOR percentage_laid_off IS NULL 
    THEN 1 ELSE 0 
  END) AS partial_layoff_data,

  SUM(CASE WHEN funds_raised_millions IS NULL THEN 1 ELSE 0 END) AS missing_funding,

# count total vs percent layoffs

  SUM(CASE 
        WHEN total_laid_off IS NOT NULL 
         AND percentage_laid_off IS NULL 
        THEN 1 ELSE 0 
      END) AS total_only,
  SUM(CASE 
        WHEN total_laid_off IS NULL 
         AND percentage_laid_off IS NOT NULL 
        THEN 1 ELSE 0 
      END) AS percentage_only,
   sum(
    case when total_laid_off is not null
         then 1 else 0
     end    
      ) as with_total_layoff,
   sum(
    case when percentage_laid_off is not null
         then 1 else 0
     end    
      ) as with_percent_layoff
 from layoffs_two;     

delete 
  from layoffs_two
    where total_laid_off is null
      and percentage_laid_off is null;

# complete_layoff_data 1190, partial_layoff_data 801, total 1991 of which 165 missing_funding
    



  








    



  
