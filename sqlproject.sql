SELECT *
From portfolioproject..CovidDeaths -- use . instead of dbo.   xxx..yyy = xxx.dbo.yyy
WHERE continent is not null --data duplicate in location and continent, when congtinent is null, location is indicating the continent data
ORDER BY 3,4

--SELECT *
--From portfolioproject..CovidVaccination
--ORDER BY 3,4



------- Select Data that going to use
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM portfolioproject..CovidDeaths
ORDER BY 1,2 -- ORDER BY  Location and date



------- Looking at Total Cases with Total Deaths: the death rate
-- shows the likelyhood of dying if infected civod
ALTER TABLE CovidDeaths
ALTER COLUMN total_deaths decimal;
-- change varchar into decimal or folat to calculate, one of the column need to be the type or the return will be 0
-- or use cast to convert


SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as Deathpercentage 
FROM portfolioproject..CovidDeaths
WHERE location LIKE '%Canada'  -- select a specific country
ORDER BY 1,2



------- looking at total cases with population, shows the infection rate

SELECT Location, date, total_cases, population, (total_cases/population)*100 as infectionrate 
FROM portfolioproject..CovidDeaths
WHERE location LIKE '%Canada'  -- select a specific country
ORDER BY 1,2


------- looking at Countries with highest infetion rate compare to population overall
SELECT Location, Population, MAX(total_cases) as HighestinfectionCount, MAX(total_cases/population)*100 as	PercentPopulationInfected
FROM portfolioproject..CovidDeaths
--WHERE location LIKE '%Canada'  -- select a specific country
GROUP BY location, Population
ORDER BY PercentPopulationInfected DESC


-- Showing the country with highest death count per population
SELECT Location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM portfolioproject..CovidDeaths
WHERE continent is not null
--WHERE location LIKE '%Canada'  -- select a specific country
GROUP BY location
ORDER BY TotalDeathCount desc



------- BREAK DOWN BY CONTINENT
SELECT continent, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM portfolioproject..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount desc 

-- NorthAmerica data only contains US`s data, not include Canada`s
-- fix the problem by using the continent is null. when continent is null, location showing the continent data

SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM portfolioproject..CovidDeaths
WHERE continent is null
GROUP BY location
ORDER BY TotalDeathCount desc 


------- showing the continent with highest death count per population
SELECT continent, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM portfolioproject..CovidDeaths
WHERE continent is not null
--WHERE location LIKE '%Canada'  -- select a specific country
GROUP BY continent
ORDER BY TotalDeathCount desc

------- GLOBAL NUMBERS
-- SUM(new_cases) can give us the total cases in each day across the wrold, as we didnt include any continent or location
-- SUM(new_deaths) work the same way. equal to the daily eath count across the world. and the new_death is varchar, use cast to transfer to int
-- only int, decimal, and float can do the calculation 
-- NULLIF(B,0): if B = 0, AÉB returns null
SET ANSI_WARNINGS OFF
SELECT date, SUM(new_cases) AS total_case, SUM(new_deaths) AS total_death, nullif(SUM(new_deaths),0)/ nullif(SUM(new_cases),0)*100 as Deathpercentage 
FROM portfolioproject..CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1,2


------- JOIN
-- looking at total population with population: how many people in the world has vaccinated
-- some of the country starts the vaccination until end of 2020 like Canada.
-- use partition by, to see to total vaccination amount by each location and date
-- order by location and date shows the daily cumulative number in each location

SELECT DEA.continent, DEA.location, DEA.date, DEA.population, VAC.new_vaccinations
, SUM(cast(VAC.new_vaccinations as bigint))OVER (Partition by DEA.location Order by DEA.location, DEA.date) as RollingPeopleVaccinated
FROM portfolioproject..CovidDeaths DEA
JOIN portfolioproject..CovidVaccination VAC
	ON DEA.location = VAC.location
	AND DEA.date = VAC.date
WHERE DEA.continent is not null
ORDER BY 1,2,3 -- ORDER BY continent, location and date

-- use (RollingPeopleVaccintaed)/Total Population to see the percentage of people get vaccinated in each location
-- applied CTE in this situation, as the  RollingPeopleVaccinated cannot be use in the subqury
-- note # of column in CTE = # of column we selected from obd

with PopvsVac (continent, locstion, date, population, new_vaccinations, RollingPeopleVaccinated)
as(
SELECT DEA.continent, DEA.location, DEA.date, DEA.population, VAC.new_vaccinations
, SUM(cast(VAC.new_vaccinations as bigint))OVER (Partition by DEA.location Order by DEA.location, DEA.date) as RollingPeopleVaccinated
FROM portfolioproject..CovidDeaths DEA
JOIN portfolioproject..CovidVaccination VAC
	ON DEA.location = VAC.location
	AND DEA.date = VAC.date
WHERE DEA.continent is not null
)

SELECT *,( RollingPeopleVaccinated /population) *100 as VaccinationPercentage
FROM PopvsVac



------- Temp Table
DROP TABLE IF exists  #PercentPopulationVaccinated

CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(250),
Location nvarchar(250),
Date datetime,
Population numeric,
New_Vaccination numeric,
RollingPeopleVaccinated numeric
)
insert into #PercentPopulationVaccinated
SELECT DEA.continent, DEA.location, DEA.date, DEA.population, VAC.new_vaccinations
, SUM(cast(VAC.new_vaccinations as bigint))OVER (Partition by DEA.location Order by DEA.location, DEA.date) as RollingPeopleVaccinated
FROM portfolioproject..CovidDeaths DEA
JOIN portfolioproject..CovidVaccination VAC
	ON DEA.location = VAC.location
	AND DEA.date = VAC.date
WHERE DEA.continent is not null


SELECT *,( RollingPeopleVaccinated /population) *100 as VaccinationPercentage
FROM #PercentPopulationVaccinated


------- CREATING VIEW TO STORE DATA FOR VISUALIZATION
CREATE view PercentPopulationVaccinated as 
SELECT DEA.continent, DEA.location, DEA.date, DEA.population, VAC.new_vaccinations
, SUM(cast(VAC.new_vaccinations as bigint))OVER (Partition by DEA.location Order by DEA.location, DEA.date) as RollingPeopleVaccinated
FROM portfolioproject..CovidDeaths DEA
JOIN portfolioproject..CovidVaccination VAC
	ON DEA.location = VAC.location
	AND DEA.date = VAC.date
WHERE DEA.continent is not null

select *
from PercentPopulationVaccinated

