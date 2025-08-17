# COVID-Death-analysis-SQL

# COVID-19 Data Exploration — SQL + Tableau

**Goal:** Explore COVID-19 global dataset using SQL for analysis, then visualize insights in Tableau.

---

## 1) Problem
The COVID-19 pandemic generated large volumes of case, death, and vaccination data. The challenge is to:
- Calculate meaningful health KPIs (fatality rate, infection rate, vaccination coverage).
- Compare metrics across countries and time.
- Provide dashboards for stakeholders to monitor the pandemic.

---

## 2) Data
- Source: [Our World in Data – COVID-19 dataset](https://ourworldindata.org/covid-deaths)  
- Tables: `CovidDeaths`, `CovidVaccinations`  
- Columns: cases, deaths, population, vaccinations, dates, locations  

---

## 3) Key SQL Analysis
- **Fatality Rate** = deaths ÷ cases × 100  
- **Infection Rate** = cases ÷ population × 100  
- **Vaccination Coverage** = people vaccinated ÷ population × 100  

### Sample Query (Fatality Rate by Country)
```sql
SELECT
    Location,
    date,
    total_cases,
    total_deaths,
    CAST(total_deaths AS decimal(18,6))
      / NULLIF(CAST(total_cases AS decimal(18,6)), 0) * 100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
  AND location LIKE '%India%'
ORDER BY 1, 2;


## Tableau Dashboard
![Overview](tableau/dashboard_screenshots/covid-death-percentage-dashboard.png)

👉 Live (interactive): < https://public.tableau.com/views/Covid_Deaths_Dashboard1/Dashboard1?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link >
