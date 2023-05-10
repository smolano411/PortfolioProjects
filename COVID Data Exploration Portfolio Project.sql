-- Check to make sure tables loaded in correctly

SELECT *
FROM PortfolioProject.dbo.CovidDeaths
ORDER BY 3,4


SELECT *
FROM PortfolioProject.dbo.CovidVaccinations
ORDER BY 3,4


-- Select Data we are using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject.dbo.CovidDeaths
Order By 1,2

-- Total Deaths/Total Cases in US

SELECT location, date, total_cases, total_deaths, ROUND((total_deaths/total_cases)*100,2) as DeathPercentagePerTotalCases
FROM PortfolioProject.dbo.CovidDeaths
WHERE location = 'United States' AND total_cases <> 0
Order By 1,2


-- Percentage of Population reported to be infected with Covid in US

SELECT location, date, total_cases, population, ROUND((total_cases/population)*100,2) as InfectedPopulationRate
FROM PortfolioProject.dbo.CovidDeaths
WHERE location = 'United States'
Order By 1,2

-- Looking at Countries with Highest Infection Rate compared to their population

SELECT location, MAX(total_cases) AS HighestInfectionCount, population, MAX(ROUND((total_cases/population)*100,2)) as PercentPopulationInfected
FROM PortfolioProject.dbo.CovidDeaths
Group By location, population
Order By PercentPopulationInfected DESC

-- Countries with Highest Death Toll per Population
-- Added WHERE clause to filter out groupings of countries like "Asia","North America","World",etc.


SELECT location, Max(total_deaths) AS TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths
WHERE iso_code NOT LIKE 'OWID%'
Group By location
Order By TotalDeathCount DESC

-- Breakdown by Continent
-- Death count per continent

SELECT continent, Max(total_deaths) AS TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
Group By continent
Order By TotalDeathCount DESC

-- Global numbers, use new_cases and sum funtion to calculate total
-- Use NULLIF function in denominator to avoid 'divide by zero' error

SELECT date,SUM(new_cases) AS NewCases, SUM(total_cases) AS TotalCases, SUM(new_deaths) AS NewDeaths, SUM(total_deaths) AS TotalDeaths, 
      ROUND((SUM(total_deaths)/NULLIF(SUM(total_cases),0))*100,2) AS PercentDeathsPerCases
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1

-- Use Join statements to add CovidVaccinations table
-- Show new vaccinations per day for each country
-- Have a new column with a rolling count to keep track of vaccinated population
-- WHERE statement filters out where "location" included continents/income status

SELECT dea.continent,dea.location, dea.date, dea.population, vac.new_vaccinations,
  SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS RollingVaxCount
FROM PortfolioProject.dbo.CovidDeaths AS dea
JOIN PortfolioProject.dbo.CovidVaccinations AS vac
  ON dea.location = vac.location
  AND dea.date = vac.date
WHERE dea.iso_code NOT LIKE 'OWID%'
ORDER BY 2,3

-- Show vaccinated percentage of population
-- I need to use the newly formed column in the last query.
-- Option 1: Use CTE

WITH PopVax AS
(
SELECT dea.continent,dea.location, dea.date, dea.population, vac.new_vaccinations,
  SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS RollingVaxCount
FROM PortfolioProject.dbo.CovidDeaths AS dea
JOIN PortfolioProject.dbo.CovidVaccinations AS vac
  ON dea.location = vac.location
  AND dea.date = vac.date
WHERE dea.iso_code NOT LIKE 'OWID%'
)
SELECT *, ROUND((RollingVaxCount/population)*100,2) AS PopVaxPercent
FROM PopVax