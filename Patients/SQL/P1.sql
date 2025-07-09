create database patients

use Patients

select * from fact A
inner join cancer_stage B on A.cancer_stageID = b.cancer_stageID
inner join country c on a.countryId = c.countryID
inner join diagnosis_date d on a.diagnosis_dateID = d.diagnosis_dateID
inner join end_treatment_date e on a.end_treatment_dateID = e.end_treatment_dateID
inner join family_history f on a.family_historyID = f.family_historyID
inner join gender g on a.genderid = g.genderid
inner join smoking_status h on a.smoking_statusID = h.smoking_statusID
inner join treatment_type i on a .treatment_typeID = i.treatment_typeID

alter table fact
add Age_group varchar(50)

update fact
set Age_group =   case 
        when age between 0 and 10 then '0-10'
        when age between 11 and 20 then '11-20'
        when age between 21 and 30 then '21-30'
        when age between 31 and 40 then '31-40'
        when age between 41 and 50 then '41-50'
        when age between 51 and 60 then '51-60'
        when age between 61 and 70 then '61-70'
        when age between 71 and 80 then '71-80'
        when age between 81 and 90 then '81-90'
        when age between 91 and 100 then '91-100'
        else '101+'
    end

--A) Patient Demographics
--what is the age distribution among patients
select age_group, count(*) as Distribution from fact
group by age_group
order by age_group

--2) How does gender distribution vary across cancer stages?
select b.cancer_stage, g.gender, count(*) as gender_count
from fact A
inner join cancer_stage B on A.cancer_stageID = b.cancer_stageID
inner join gender g on a.genderid = g.genderid
group by  g.gender, b.cancer_stage
order by b.cancer_stage

--3) Which countries have the highest number of cancer cases?
select top 10 c.country, count(*) as Number_of_cases from fact A
inner join country c on a.countryId = c.countryID
group by c.country
order by Number_of_cases desc

--4) What is the average BMI by gender and age group?
select a.age_group, g.gender, avg(a.bmi) as average_BMI from fact A
inner join gender g on a.genderid = g.genderid
group by  g.gender, a.age_group
order by a.age_group

--B) Diagnosis & Staging
--1) What is the distribution of cancer stages at diagnosis?
select b.cancer_stage, count(*) as Number, round((count(*)/890000.0)*100, 4) as percentage_distribution
from fact A
inner join cancer_stage B on A.cancer_stageID = b.cancer_stageID
	group by b.cancer_stage
	order by b.cancer_stage, Number desc

--2)What is the trend of new diagnoses over time? 
select year(d.diagnosis_date) as year, month (d.diagnosis_date) as month, count (*) as new_diagnosis
from fact A
inner join diagnosis_date d on a.diagnosis_dateID = d.diagnosis_dateID
	group by year(diagnosis_date), month (diagnosis_date)
	order by year(diagnosis_date), month (diagnosis_date)

--3)  What is the average diagnosis age per cancer stage?
with age_frequency as (
						select b.cancer_stage, a.age, count(*) as frequency, row_number() over (partition by b.cancer_stage order by count(*) desc) as row_num 
						from fact A
						inner join cancer_stage B on A.cancer_stageID = b.cancer_stageID
						group by b.cancer_stage, a.age
						)
select cancer_stage, age as mode_age from age_frequency where row_num = 1

--4)  Which countries report higher proportions of late-stage diagnoses (Stage III & IV)?
select Top 10 country, count(case when b.cancer_stage in ('stage III', 'stage IV') then 1 end) as Stage_III_and_IV_diagnosis 
from fact A
		  inner join cancer_stage B on A.cancer_stageID = b.cancer_stageID
		  inner join country c on a.countryId = c.countryID
	group by country
	order by Stage_III_and_IV_diagnosis desc

--C) RISK FACTORS
--1) how does smoking relate to cancer stage
select b.cancer_stage, h.smoking_status, count(*) as Numbers 
from fact A 
	inner join smoking_status h on a.smoking_statusID = h.smoking_statusID
	inner join cancer_stage B on A.cancer_stageID = b.cancer_stageID
	group by cancer_stage, smoking_status
	order by cancer_stage, smoking_status

--2) how many patients have a family history of cancer? 
select count(id) as Patients_with_family_history_of_cancer
from fact a
inner join family_history f on a.family_historyID = f.family_historyID where family_history in (1)

--3)  how prevalent is hypertension, asthma and cirrhosis  
select 
	(Hyp/890000.0) * 100 as Hypertension_percentage, 
	(Ast/890000.0) * 100 as Asthma_percentage, 
	(cirr/890000.0) * 100 as Cirrhosis_percentage
from ( select 
		count(case when hypertension in (1) then 1 end) as Hyp,
		count(case when asthma in (1) then 1 end) as Ast,
		count(case when cirrhosis in (1) then 1 end) as cirr
		from Fact
		 ) 
as subquery

--4) What is the average cholesterol level across different age groups? 
select a.Age_group, avg(cholesterol_level) as Average_cholestrol_level 
from Fact a

	group by a.Age_group 
	order by a.Age_group

--5) What is the average cholesterol level across different stages?
select cancer_stage, (Total_cholestrol_level/Number) as Average_cholestrol_level 

from ( select b.cancer_stage, sum(a.cholesterol_level) as Total_cholestrol_level, count(a.cholesterol_level) as Number
		from Fact a
		inner join Cancer_stage b on a.cancer_stageID = b.cancer_stageID
		group by cancer_stage
		) as subquery 
		
order by cancer_stage asc

--D) TREATMENT PATTERNS
--1) distribution of treatment types
select b.treatment_type, count(*) as Number, ((count(*)/890000.0)*100) as percentage 
from Fact a
	inner join Treatment_type b on a.treatment_typeID = b.treatment_typeID
	group by b.treatment_type
	order by Number asc

--2)  Average treatment duration by stage
alter table fact add Treatment_duration smallint; -- added a new column named treatment duration (days)
update Fact 
	set Treatment_duration = DATEDIFF(day, b.diagnosis_date,c.end_treatment_date) 
		from fact as a
		inner join diagnosis_date as b on a.diagnosis_dateid = b.diagnosis_dateid
		inner join end_treatment_date as c on a.end_treatment_dateid = c.end_treatment_dateid

select b.cancer_stage, avg(a.treatment_duration) as Average_treatment_duration_in_days
from fact a
	inner join Cancer_stage b on a.cancer_stageID = b.cancer_stageID
	group by b.cancer_stage
	order by b.cancer_stage

--3) Which treatment types are most common in each cancer stage?
select b.cancer_stage, c.treatment_type, count(c.treatment_type) as treatment_occurence,  row_number() over ( partition by b.cancer_stage order by count(*) desc
        ) as rank
from fact a
	inner join Cancer_stage b on a.cancer_stageID = b.cancer_stageID
	inner join Treatment_type c on a.treatment_typeID = c.treatment_typeID
	group by b.cancer_stage, c.treatment_type
	order by b.cancer_stage asc

--4) What percentage of patients receive combined treatment vs. single treatments?
select 
	(Number_combined_treatment/890000.0) * 100 as combined_percentage, 
	(Number_single_treatment/890000.0) * 100 as single_percentage

from  (select 
			count(case when treatment_type in ('combined') then 1 end) as Number_combined_treatment,
			count(case when treatment_type not in ('combined') then 1 end) as Number_single_treatment
			from fact a
	inner join Cancer_stage b on a.cancer_stageID = b.cancer_stageID
	inner join Treatment_type c on a.treatment_typeID = c.treatment_typeID
	) 

as subquery 

--E) COUNTRY LEVEL
--1) How many patients are represented from each country?
select b.country, count(a.id) as number_of_patients, ((count(a.id)/890000.0)*100) as percentage
from fact a
		inner join country b on a.countryID = b.countryID
	group by b.country
	order by number_of_patients desc

--2) What is the survival rate in each country?
select b.country, ((count(case when survived in (1) then 1 end)/890000.0)*100) as survival_rate
		from fact a
		inner join country b on a.countryID = b.countryID
	group by b.country
	order by survival_rate desc

--3) Does the type of treatment vary across countries?
select distinct b.country, c.treatment_type, count(treatment_type) as count,  row_number() over ( partition by b.country order by count(*) desc
        ) as rank
	from fact a
		inner join country b on a.countryID = b.countryID
		inner join Treatment_type c on a.treatment_typeID = c.treatment_typeID
	group by b.country, c.treatment_type
	order by b.country asc

--f) OUTCOMES AND SURVIVAL
--1) What is the overall survival rate?
select ((count(case when survived in (1) then 1 end)/890000.0)*100) as survival_rate, 100 - ((count(case when survived in (1) then 1 end)/890000.0)*100) as Death_rate  from Fact


--2) How does survival rate vary by cancer stage?
select b.cancer_stage, ((count(case when a.survived in (1) then 1 end)/890000.0)*100) as survival_rate 
	from fact a
	inner join Cancer_stage b on a.cancer_stageID = b.cancer_stageID
	group by b.cancer_stage
	order by b.cancer_stage asc

--3) Which treatment types have the highest survival rates?
select b.treatment_type, ((count(case when a.survived in (1) then 1 end)/890000.0)*100) as survival_rate
from fact a
	inner join Treatment_type b on a.treatment_typeID = b.treatment_typeID
	group by b.treatment_type
	order by survival_rate desc 

--4) --4) Do survival rates differ by smoking status, family history, or comorbidities?
select b.smoking_status, ((count(case when a.survived in (1) then 1 end)/890000.0)*100) as survival_rate 
from fact A
	inner join smoking_status b on a.smoking_statusID = b.smoking_statusID
	group by b.smoking_status
	order by survival_rate desc

select b.family_history, ((count(case when survived in (1) then 1 end)/890000.0)*100) as survival_rate
from fact a
	inner join Family_history b on a.family_historyID = b.family_historyID
	group by b.family_history
	order by survival_rate desc

--4) Do survival rates differ by smoking status, family history, or comorbidities?
select smoking_status, ((count(case when survived in (1) then 1 end)/890000.0)*100) as survival_rate
from fact a
		inner join smoking_status b on a.smoking_statusID = b.smoking_statusID
	group by smoking_status
	order by survival_rate desc

select b.family_history, ((count(case when survived in (1) then 1 end)/890000.0)*100) as survival_rate 
from fact a
		inner join Family_history b on a.family_historyID = b.family_historyID
	group by b.family_history
	order by survival_rate desc

select hypertension, ((count(case when survived in (1) then 1 end)/890000.0)*100) as survival_rate from fact
	group by hypertension
	order by survival_rate desc

select asthma, ((count(case when survived in (1) then 1 end)/890000.0)*100) as survival_rate from fact
	group by asthma
	order by survival_rate desc

select cirrhosis, ((count(case when survived in (1) then 1 end)/890000.0)*100) as survival_rate from fact
	group by cirrhosis
	order by survival_rate desc

select other_cancer, ((count(case when survived in (1) then 1 end)/890000.0)*100) as survival_rate from fact
	group by other_cancer
	order by survival_rate desc

select asthma, ((count(case when survived in (1) then 1 end)/890000.0)*100) as survival_rate from fact
	group by asthma
	order by survival_rate desc









