Select *
From PortfolioProject..['owid-covid-data-(Deaths-Cleaned$']
where continent is not null 
order by 3,4


--Select *
--From PortfolioProject..['owid-covid-data-(Vaccination-Cl$']
--order by 3,4

-- Select data to be used

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..['owid-covid-data-(Deaths-Cleaned$']
order by 1,2 -- Location and date 


-- Looking at Total Cases vs Total Deaths 
--Shows the likelihood of dying if contracting Covid in your country 

Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..['owid-covid-data-(Deaths-Cleaned$']
Where location like '%state%' 
order by 1,2 -- Location and date 

-- Looking at Total Cases vs Population 

Select Location, date, population, total_cases, (total_cases/population)*100 as PositiveCasePercentage
From PortfolioProject..['owid-covid-data-(Deaths-Cleaned$']
Where location like '%state%' 
order by 1,2 -- Location and date 
-- Note: 18.5% of US population tested positive as of 10/01/2022 --

Select Location, date, population, total_cases, (total_cases/population)*100 as PercentagePopulationInfected
From PortfolioProject..['owid-covid-data-(Deaths-Cleaned$']
Where location like '%kingdom%' 
order by 1,2 -- Location and date 
-- Note: 21.5% of UK population tested positive as of 10/01/2022 --

-- Looking at countries with the highst infection rate compared to population

Select Location, Population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentagePopulationInfected
From PortfolioProject..['owid-covid-data-(Deaths-Cleaned$']
Group By population, location
order by PercentagePopulationInfected desc 
-- Highest Percentage Infected is Andorra as of 10/02/2022

-- Highest Death count per % population
Select Location, Population, MAX(total_deaths) as HighestTotalDeaths, MAX((total_deaths/population))*100 as PercentageDeathsPerPopulationInfected
From PortfolioProject..['owid-covid-data-(Deaths-Cleaned$']
Group By population, location
order by PercentageDeathsPerPopulationInfected desc 

-- Highest Death count per population (Wrong)
Select Location, MAX(cast(total_deaths as INT)) as TotalDeathCount
From PortfolioProject..['owid-covid-data-(Deaths-Cleaned$']
where continent is null AND Location is "Europe"
Group By location
order by TotalDeathCount desc 
-- includes Country groupings, add group by continent to the avove queries 

-- Highest Death count per Continent (Correct)
Select continent, MAX(cast(total_deaths as INT)) as TotalDeathCount
From PortfolioProject..['owid-covid-data-(Deaths-Cleaned$']
where continent is not null
group by continent
order by TotalDeathCount desc 

-- Global Numbers 

Select date, SUM(new_cases) as Total_Cases, SUM(cast(new_deaths as int))as Total_Deaths,  (SUM(cast(new_deaths as int))/SUM(new_cases))*100 as DeathPercentage
From PortfolioProject..['owid-covid-data-(Deaths-Cleaned$']
where continent is not null
Group By date
order by 1,2 -- Date and cases 

--Looking at Total Population vs Vaccinations

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations as NewVaccinationsPerDay
from PortfolioProject..['owid-covid-data-(Deaths-Cleaned$'] dea
Join PortfolioProject..['owid-covid-data-(Vaccination-Cl$'] vac
   on dea.location = vac.location
   and dea.date = vac.date
   where dea.continent is not null
   order by 2,3 --location and date

-- Cumulative vaccinations per country

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations as NewVaccinationsPerDay,
sum(Convert(bigint, vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingVaccinationCount
from PortfolioProject..['owid-covid-data-(Deaths-Cleaned$'] dea
Join PortfolioProject..['owid-covid-data-(Vaccination-Cl$'] vac
   on dea.location = vac.location
   and dea.date = vac.date
   where dea.continent is not null
   order by 2,3 --location and date

 --Number of people within country vaccinated (Total Rolling Count/population using temp table)
--Using CTE to include RollingPeopleVaccinated
-- Doesnt account for double jabbed 

With PopvsVac (Continent, Location, Date, Population, New_vaccinations, RollingPeopleVaccinated)
as 
(Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations as NewVaccinationsPerDay,
sum(Convert(bigint, vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingVaccinationCount
from PortfolioProject..['owid-covid-data-(Deaths-Cleaned$'] dea
Join PortfolioProject..['owid-covid-data-(Vaccination-Cl$'] vac
   on dea.location = vac.location
   and dea.date = vac.date
   where dea.continent is not null
   -- order by 2,3 location and date not valid
)
Select *, (RollingPeopleVaccinated/Population)*100 as PercentageVaccinated
From PopvsVac

-- Temp Table format 

Drop Table if exists #PercentPopulationVaccinated --If needed to rerun 
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255), 
Date datetime,
Population numeric,
New_vaccinations numeric, 
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations as NewVaccinationsPerDay,
sum(Convert(bigint, vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingVaccinationCount
from PortfolioProject..['owid-covid-data-(Deaths-Cleaned$'] dea
Join PortfolioProject..['owid-covid-data-(Vaccination-Cl$'] vac
   on dea.location = vac.location
   and dea.date = vac.date
   where dea.continent is not null
   -- order by 2,3 location and date not valid

Select *, (RollingPeopleVaccinated/Population)*100 as PercentageVaccinated
From #PercentPopulationVaccinated

--Creating View to store for lated ata visualisations 

Alter View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations as NewVaccinationsPerDay,
sum(Convert(bigint, vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingVaccinationCount
from PortfolioProject..['owid-covid-data-(Deaths-Cleaned$'] dea
Join PortfolioProject..['owid-covid-data-(Vaccination-Cl$'] vac
   on dea.location = vac.location
   and dea.date = vac.date
   where dea.continent is not null
