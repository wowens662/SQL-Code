/*
Covid-19 Portfolio Project
The source .csv files were CovidVaccinations.csv and CovidDeaths.csv, both of
which were found on 'https://ourworldindata.org/covid-deaths' website.  Both
were then imported in MS SQL Server.  The project uses joins, CTEs, temp tables,
as well windows functions.
*/

--Checking to determine if both tables were imported
--successfully.
Select * 
From PortfolioProject..CovidDeaths
Order By 3,4


Select * 
From PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
Order By 3,4


Select * 
From PortfolioProject..CovidDeaths
Order By 3,4

--Determining data that I will use

Select Location, Date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
Order By 1,2


--Perform a comparison of Total Cases vs Total Deaths


Select Location, Date, total_cases, total_deaths, (total_deaths/total_cases) * 100 As DeathPercentage
FROM PortfolioProject..CovidDeaths
Order By 1,2

--Curious about the percentage in my country, the US
--Show the likehood of dying should one contract the virus 
--in the US.
Select Location, Date, total_cases, total_deaths, (total_deaths/total_cases) * 100 As DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE Location like '%states%'
Order By 1,2


--Looking at Total Cases vs Population
--Reveals the percentage of population 
--has contracted the virus

Select Location, Date, total_cases, population, (total_cases/population) * 100 As PopulationPercentage
FROM PortfolioProject..CovidDeaths
WHERE Location like '%states%'
Order By 1,2

Select Location, Date, total_cases, population, (total_cases/population) * 100 As PopulationPercentage
FROM PortfolioProject..CovidDeaths
--WHERE Location like '%states%'
Order By 1,2


--What countries have the highest infection rates relative to their population?
Select Location,  Population, MAX(total_cases) as HighestInfectionCount, MAX(total_cases/population) * 100 As PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
--WHERE Location like '%states%'
GROUP BY Location, Population
Order By PercentPopulationInfected Desc

--Which countries with highest Death Count per population?

Select Location,   MAX(CAST(total_deaths AS INT)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE Location like '%states%'
WHERE continent IS NOT NULL
GROUP BY Location
Order By TotalDeathCount Desc



--Breaking down the data by continent.

Select location, MAX(CAST(total_deaths AS INT)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE Location like '%states%'
WHERE continent IS NULL
GROUP BY location
Order By TotalDeathCount Desc


--Which continents with highest death count per population?
Select continent, MAX(CAST(total_deaths AS INT)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE Location like '%states%'
WHERE continent IS NOT NULL
GROUP BY continent
Order By TotalDeathCount Desc



--GLOBAL NUMBERS


Select date,SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS INTEGER)) AS total_deaths, SUM(CAST(new_deaths AS INTEGER))/SUM(new_cases) * 100  AS DeathPercentage--, total_deaths, (total_deaths/total_cases) * 100 As DeathPercentage
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%states%'
WHERE continent IS NOT NULL
GROUP BY date
Order By 1,2



Select SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS INTEGER)) AS total_deaths, SUM(CAST(new_deaths AS INTEGER))/SUM(new_cases) * 100  AS DeathPercentage--, total_deaths, (total_deaths/total_cases) * 100 As DeathPercentage
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%states%'
WHERE continent IS NOT NULL
--GROUP BY date
Order By 1,2


--Looking at Total Population vs Vaccinations

--First query will perform a rolling count of individuals vaccinations
--and will then compare the vaccinations vs population
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS running_count_vaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
  ON  dea.location = vac.location
  AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3



--Use of CTEs

With PopvsVac(Continent, Location, Date, Population, NewVaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS running_count_vaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
  ON  dea.location = vac.location
  AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
) 


--Using previous CTE to determine most percentage 
--of the population that has been vaccinated 
--by country and location.
SELECT Continent,Location, Max((RollingPeopleVaccinated/Population)*100)
FROM PopvsVac
GROUP BY Continent, Location
ORDER BY Continent ASC, Location ASC


--Viewing the increasing percentage of population vaccinated by population
--with the progression of time.
--SELECT * , (RollingPeopleVaccinated/Population)*100 AS Percentage
--FROM PopvsVac



--TEMP TABLE

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS running_count_vaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
  ON  dea.location = vac.location
  AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 1 ASC,2 ASC,3 ASC


SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated


--Creating View to store data for later visualizations
--Note: Views cannot contain the ORDER BY clause

--DROP VIEW IF EXISTS PercentPopulationVaccinated

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS running_count_vaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
  ON  dea.location = vac.location
  AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 1 ASC,2 ASC,3 ASC



SELECT *
FROM PercentPopulationVaccinated
