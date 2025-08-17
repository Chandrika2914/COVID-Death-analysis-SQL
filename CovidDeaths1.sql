-- =========================================================
-- Base data
-- =========================================================
SELECT *
FROM MyPortofolioProjects..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3, 4;
--


-- SELECT *
-- FROM MyPortofolioProjects..CovidVaccinations
-- ORDER BY 3, 4;
--


-- Select data that we are going to be using
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM MyPortofolioProjects..CovidDeaths
ORDER BY 1,2;
--


-- =========================================================
-- Looking at total cases & total deaths
-- Shows likelihood of dying if you contract covid in your country
-- =========================================================
SELECT
    Location,
    date,
    total_cases,
    total_deaths,
    -- FIX: use decimals + NULLIF to avoid integer division & divide-by-0
    CAST(total_deaths AS decimal(18,6))
      / NULLIF(CAST(total_cases AS decimal(18,6)), 0) * 100 AS DeathPercentage
FROM MyPortofolioProjects..CovidDeaths
WHERE location LIKE '%India%'
  AND continent IS NOT NULL
ORDER BY 1,2;
--


-- =========================================================
-- Looking at the total cases vs the population
-- Shows what percentage of population got covid
-- =========================================================
SELECT
    Location,
    date,
    population,
    total_cases,
    -- FIX: use decimals + NULLIF to avoid integer division & divide-by-0
    CAST(total_cases AS decimal(18,6))
      / NULLIF(CAST(population AS decimal(18,6)), 0) * 100 AS PercentPoputationInfected
FROM MyPortofolioProjects..CovidDeaths
-- Where location like '%states%'
ORDER BY 1,2;
--


-- =========================================================
-- Countries with Highest Infection rate compared to population
-- =========================================================
SELECT
    Location,
    population,
    MAX(total_cases) AS HighestInfectionCount,
    -- FIX: cast to decimal inside MAX expression
    MAX(
        CAST(total_cases AS decimal(18,6))
        / NULLIF(CAST(population AS decimal(18,6)), 0)
    ) * 100 AS PercentPoputationInfected
FROM MyPortofolioProjects..CovidDeaths
-- Where location like '%states%'
GROUP BY Location, population
ORDER BY PercentPoputationInfected DESC;
--


-- =========================================================
-- Let's break down things by continent
-- Showing countries with the highest death count per population
-- (this query is OK as-is; total_deaths cast to int is fine)
-- =========================================================
SELECT
    continent,
    MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM MyPortofolioProjects..CovidDeaths
-- Where location like '%states%'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;


-- (Duplicate of the above—kept as in your script)
SELECT
    continent,
    MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM MyPortofolioProjects..CovidDeaths
-- Where location like '%states%'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;


-- =========================================================
-- Global numbers
-- =========================================================
SELECT
    SUM(new_cases) AS total_casess,
    SUM(CAST(new_deaths AS int)) AS total_deaths,
    -- FIX: protect against integer division & divide-by-0
    CAST(SUM(CAST(new_deaths AS int)) AS decimal(18,6))
      / NULLIF(CAST(SUM(new_cases) AS decimal(18,6)), 0) * 100 AS Deathpercentage
FROM MyPortofolioProjects..CovidDeaths
WHERE continent IS NOT NULL
-- GROUP BY date
ORDER BY 1,2;
--


-- =========================================================
-- Total population Vs Vaccinations (basic join)
-- =========================================================
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations
FROM MyPortofolioProjects..CovidDeaths dea
JOIN MyPortofolioProjects..CovidVaccinations vac
    ON dea.location = vac.location
   AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;


-- (Duplicate of the above—kept as in your script)
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations
FROM MyPortofolioProjects..CovidDeaths dea
JOIN MyPortofolioProjects..CovidVaccinations vac
    ON dea.location = vac.location
   AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;


-- =========================================================
-- Total population Vs Vaccinations with running total
-- =========================================================
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    -- FIX: running total ordered by date inside each location
    SUM(CONVERT(int, vac.new_vaccinations))
        OVER (PARTITION BY dea.Location ORDER BY dea.Date)
        AS RollingPeopleVaccinated
    -- ,(RollingPeopleVaccinated/Population)*100
FROM MyPortofolioProjects..CovidDeaths dea
JOIN MyPortofolioProjects..CovidVaccinations vac
    ON dea.location = vac.location
   AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;


-- =========================================================
-- USE CTE
-- =========================================================
-- 
WITH PopVsVac AS (
    SELECT
        dea.continent,
        dea.location,
        dea.[date],
        dea.population,
        vac.new_vaccinations,
        SUM(CONVERT(int, vac.new_vaccinations))
            OVER (PARTITION BY dea.location ORDER BY dea.[date])
            AS RollingPeopleVaccinated
    FROM MyPortofolioProjects..CovidDeaths AS dea
    JOIN MyPortofolioProjects..CovidVaccinations AS vac
      ON dea.location = vac.location
     AND dea.[date]   = vac.[date]
    WHERE dea.continent IS NOT NULL
)
SELECT TOP (10)
    *
FROM PopVsVac
ORDER BY location, [date];



-- =========================================================
-- TEMP TABLE
-- =========================================================
-- Drop any leftover temp table in THIS session
IF OBJECT_ID('tempdb..#PercentPopulationVaccinated') IS NOT NULL
    DROP TABLE #PercentPopulationVaccinated;

-- Create temp table with the exact columns we need
CREATE TABLE #PercentPopulationVaccinated
(
    Continent                 nvarchar(255),
    Location                  nvarchar(255),
    [Date]                    datetime,
    Population                numeric(18,0),
    New_Vaccinations          numeric(18,0),
    RollingPeopleVaccinated   numeric(38,0)
);

-- Insert using explicit column list + running total
INSERT INTO #PercentPopulationVaccinated
(Continent, Location, [Date], Population, New_Vaccinations, RollingPeopleVaccinated)
SELECT
    dea.continent,
    dea.location,
    dea.[date],
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(bigint, vac.new_vaccinations))
        OVER (PARTITION BY dea.location ORDER BY dea.[date])
        AS RollingPeopleVaccinated
FROM MyPortofolioProjects..CovidDeaths AS dea
JOIN MyPortofolioProjects..CovidVaccinations AS vac
  ON dea.location = vac.location
 AND dea.[date]   = vac.[date]
-- WHERE dea.continent IS NOT NULL;

-- (Optional) Quick schema check: should list RollingPeopleVaccinated
EXEC tempdb..sp_help '#PercentPopulationVaccinated';

-- First peek (should SHOW RollingPeopleVaccinated values, some may be NULL early on)
SELECT TOP (10) * 
FROM #PercentPopulationVaccinated
ORDER BY Location, [Date];

-- Final percent (use decimals to avoid 0% from integer division)
SELECT
    *,
    CAST(RollingPeopleVaccinated AS decimal(18,6))
      / NULLIF(CAST(Population AS decimal(18,6)), 0) * 100 AS PercentPopulationVaccinated
FROM #PercentPopulationVaccinated
ORDER BY Location, [Date];

-- =========================================================
-- Creating view to store data for later visualizations
-- =========================================================

Create View PercentPopulationVaccinated as 
SELECT
    dea.continent,
    dea.location,
    dea.[date],
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(bigint, vac.new_vaccinations))
        OVER (PARTITION BY dea.location ORDER BY dea.[date])
        AS RollingPeopleVaccinated
FROM MyPortofolioProjects..CovidDeaths AS dea
JOIN MyPortofolioProjects..CovidVaccinations AS vac
  ON dea.location = vac.location
 AND dea.[date]   = vac.[date]
WHERE dea.continent IS NOT NULL;
-- order by 2,3

Select * 
From PercentPopulationVaccinated