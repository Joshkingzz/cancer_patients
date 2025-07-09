# 🧬 Cancer Patient Data Analysis Report

## 📘 Project Overview

This project analyzes a large dataset of 890,000 cancer patients to uncover patterns in diagnosis, demographics, treatment types, and survival outcomes. It aims to help healthcare professionals and researchers identify high-risk groups, treatment performance, and demographic insights to improve patient care and resource allocation.

> **Tools Used**: SQL Server for analysis, Power BI for visualization.
![Image](https://github.com/user-attachments/assets/aac56d1b-06f6-48db-a6d7-6ee70789193e)

![Image](https://github.com/user-attachments/assets/d7d0cc6c-a0e8-4892-a077-e665b16a8ac1)

![Image](https://github.com/user-attachments/assets/4c25db58-8270-4dbc-8ecb-3ccb4bfe3348)


---

## 🧰 Methodology

### Key Tables Joined:
```
select * from fact A
inner join cancer_stage B on A.cancer_stageID = b.cancer_stageID
inner join country c on a.countryId = c.countryID
inner join diagnosis_date d on a.diagnosis_dateID = d.diagnosis_dateID
inner join end_treatment_date e on a.end_treatment_dateID = e.end_treatment_dateID
inner join family_history f on a.family_historyID = f.family_historyID
inner join gender g on a.genderid = g.genderid
inner join smoking_status h on a.smoking_statusID = h.smoking_statusID
inner join treatment_type i on a .treatment_typeID = i.treatment_typeID
```

* `fact`: Main patient-level dataset
* Dimension tables: `cancer_stage`, `country`, `diagnosis_date`, `end_treatment_date`, `gender`, `smoking_status`, `treatment_type`, `family_history`, etc.

### Data Preparation Steps:
```
alter table fact add Treatment_duration smallint; -- added a new column named treatment duration (days)
update Fact 
	set Treatment_duration = DATEDIFF(day, b.diagnosis_date,c.end_treatment_date) 
		from fact as a
		inner join diagnosis_date as b on a.diagnosis_dateid = b.diagnosis_dateid
		inner join end_treatment_date as c on a.end_treatment_dateid = c.end_treatment_dateid
```
```
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
```
1. **Joined all necessary tables** for a complete view.
2. **Created `Age_group` column** to segment patients by age brackets.
3. **Created `Treatment_duration`** as days between diagnosis and treatment end.
4. Performed **grouping, aggregation**, and **percentile calculations** for insights.

---

## 🧍 A. Patient Demographics

### 1. Age Group Distribution
```
select age_group, count(*) as Distribution from fact
group by age_group
order by age_group
```

![Image](https://github.com/user-attachments/assets/299ebf5e-1cad-42b3-8627-c77b1e699d40)

* Most patients fall within the **41–70** age range.
* Insight: Cancer incidence increases with age, particularly after 40.

### 2. Gender Distribution Across Stages
```
select b.cancer_stage, g.gender, count(*) as gender_count
from fact A
inner join cancer_stage B on A.cancer_stageID = b.cancer_stageID
inner join gender g on a.genderid = g.genderid
group by  g.gender, b.cancer_stage
order by b.cancer_stage
```
![Image](https://github.com/user-attachments/assets/6cdb494d-6550-4633-9ddf-bbe378a5de9c)

* Gender representation varies slightly by stage, but both genders are affected similarly although it is slightly dominant in the male gender across all stages with stage III being an exception

### 3. Countries with Highest Cases
```
select top 10 c.country, count(*) as Number_of_cases from fact A
inner join country c on a.countryId = c.countryID
group by c.country
order by Number_of_cases desc
```
![Image](https://github.com/user-attachments/assets/6c4f29ea-2895-4411-8b50-0be0043b0d56)

* **Top countries**: Malta, Ireland, Portugal, and France lead in case numbers.
* Could reflect both population size and reporting practices.

### 4. Average BMI by Gender and Age Group
```
select a.age_group, g.gender, avg(a.bmi) as average_BMI from fact A
inner join gender g on a.genderid = g.genderid
group by  g.gender, a.age_group
order by a.age_group
```
![Image](https://github.com/user-attachments/assets/dd40c8e2-0029-4a9d-b5e3-2e431589e962)

* BMI is higher in older groups and slightly higher in males with the highest BMI being a male preschooler.
* Monitoring weight/BMI could inform preventive strategies.

---

## 🧪 B. Diagnosis and Staging

### 1. Stage Distribution at Diagnosis
```
select b.cancer_stage, d.diagnosis_date, count(*) as Number, round((count(*)/890000.0)*100, 4) as percentage_distribution
from fact A
inner join cancer_stage B on A.cancer_stageID = b.cancer_stageID
inner join diagnosis_date d on a.diagnosis_dateID = d.diagnosis_dateID
	group by b.cancer_stage, d.diagnosis_date
	order by b.cancer_stage
```

* **Stage II and III** dominate, with 40% of cases.
* Late-stage (Stage III/IV) diagnosis remains high in many countries.

### 2. Diagnosis Trend Over Time
```
select year(d.diagnosis_date) as year, month (d.diagnosis_date) as month, count (*) as new_diagnosis
from fact A
inner join diagnosis_date d on a.diagnosis_dateID = d.diagnosis_dateID
	group by year(diagnosis_date), month (diagnosis_date)
	order by year(diagnosis_date), month (diagnosis_date)
```
* Diagnoses have grown steadily over time, peaking in recent years.
* Suggests increased awareness or improved diagnostics.

### 3. Average Diagnosis Age by Stage
```
with age_frequency as (
						select b.cancer_stage, a.age, count(*) as frequency, row_number() over (partition by b.cancer_stage order by count(*) desc) as row_num 
						from fact A
						inner join cancer_stage B on A.cancer_stageID = b.cancer_stageID
						group by b.cancer_stage, a.age
						)
select cancer_stage, age as mode_age from age_frequency where row_num = 1
```

* **Mode age** of diagnosis is between 60–65 for most stages.
* Stage I diagnoses occur slightly earlier than advanced stages.

### 4. Countries with Higher Late-Stage Diagnosis
```
select Top 10 country, count(case when b.cancer_stage in ('stage III', 'stage IV') then 1 end) as Stage_III_and_IV_diagnosis 
from fact A
		  inner join cancer_stage B on A.cancer_stageID = b.cancer_stageID
		  inner join country c on a.countryId = c.countryID
	group by country
	order by Stage_III_and_IV_diagnosis desc
```

* Certain countries show a disproportionate number of **Stage III/IV** cases.
* Could indicate late presentation or limited screening access.

---

## 🚬 C. Risk Factors

### 1. Smoking Status by Cancer Stage
```
select b.cancer_stage, h.smoking_status, count(*) as Numbers 
from fact A 
	inner join smoking_status h on a.smoking_statusID = h.smoking_statusID
	inner join cancer_stage B on A.cancer_stageID = b.cancer_stageID
	group by cancer_stage, smoking_status
	order by cancer_stage, smoking_status
```

* Strong correlation between **smoking** and late-stage cancers.
* **Current and former smokers** make up a significant share of Stage III and IV diagnoses.

### 2. Family History
```
select count(id) as Patients_with_family_history_of_cancer
from fact a
inner join family_history f on a.family_historyID = f.family_historyID where family_history in (1)

```

* Over **35% of patients** reported a family history of cancer.
* Genetic screening and family-based interventions are crucial.

### 3. Comorbidity Prevalence
```
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
```

* **Hypertension**: \~28%
* **Asthma**: \~10%
* **Cirrhosis**: \~4%
* Insight: Comorbid conditions may affect treatment tolerance and outcomes.

### 4. Cholesterol Levels
```
select b.cancer_stage, a.Age_group, avg(cholesterol_level) as Average_cholestrol_level 
from Fact a
inner join Cancer_stage b on a.cancer_stageID = b.cancer_stageID
	group by  b.cancer_stage, a.Age_group 
	order by b.cancer_stage
```
```
select cancer_stage, (Total_cholestrol_level/Number) as Average_cholestrol_level 

from ( select b.cancer_stage, sum(a.cholesterol_level) as Total_cholestrol_level, count(a.cholesterol_level) as Number
		from Fact a
		inner join Cancer_stage b on a.cancer_stageID = b.cancer_stageID
		group by cancer_stage
		) as subquery 
		
order by cancer_stage asc
```

* Cholesterol increases with **age** and is higher in **Stage I–II**, suggesting better health at earlier stages.

---

## 💊 D. Treatment Patterns

### 1. Distribution of Treatment Types
```
select b.treatment_type, count(*) as Number, ((count(*)/890000.0)*100) as percentage 
from Fact a
	inner join Treatment_type b on a.treatment_typeID = b.treatment_typeID
	group by b.treatment_type
	order by Number asc
```

* **Surgery and chemotherapy** are most common, followed by **combined treatment** options.
* Combined therapies are more frequent in advanced stages.

### 2. Average Treatment Duration by Stage
```
select b.cancer_stage, avg(a.treatment_duration) as Average_treatment_duration_in_days
from fact a
	inner join Cancer_stage b on a.cancer_stageID = b.cancer_stageID
	group by b.cancer_stage
	order by b.cancer_stage
```
* **Stage IV** patients undergo longer treatments (avg. >250 days).
* Duration is shorter in **early stages** (\~100–150 days).

### 3. Most Common Treatment by Stage
```
select b.cancer_stage, c.treatment_type, count(c.treatment_type) as treatment_occurence,  row_number() over ( partition by b.cancer_stage order by count(*) desc
        ) as rank
from fact a
	inner join Cancer_stage b on a.cancer_stageID = b.cancer_stageID
	inner join Treatment_type c on a.treatment_typeID = c.treatment_typeID
	group by b.cancer_stage, c.treatment_type
	order by b.cancer_stage asc
```
* Stage I: Surgery dominates
* Stage III/IV: Chemotherapy and combined treatments are more common.

### 4. Combined vs Single Treatment
```
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
```

* \~**36% received combined treatment**, showing personalized care in advanced cases.
* Remaining **64% received a single treatment modality**.

---

## 🌍 E. Country-Level Insights

### 1. Number of Patients per Country
```
select b.country, count(a.id) as number_of_patients, ((count(a.id)/890000.0)*100) as percentage
from fact a
		inner join country b on a.countryID = b.countryID
	group by b.country
	order by number_of_patients desc
```
* High numbers in **developed countries** due to better reporting and diagnostics.
* Emerging economies also show increasing data.

### 2. Survival Rate per Country
```
select b.country, ((count(case when survived in (1) then 1 end)/890000.0)*100) as survival_rate
		from fact a
		inner join country b on a.countryID = b.countryID
	group by b.country
	order by survival_rate desc
```

* Survival varies from **\~65% to 85%** by country.
* Indicates disparities in treatment access, quality of care, and early detection.

### 3. Treatment Variation Across Countries
```
select distinct b.country, c.treatment_type, count(treatment_type) as count,  row_number() over ( partition by b.country order by count(*) desc
        ) as rank
	from fact a
		inner join country b on a.countryID = b.countryID
		inner join Treatment_type c on a.treatment_typeID = c.treatment_typeID
	group by b.country, c.treatment_type
	order by b.country asc
``` 

* Some countries favor **non-invasive treatments**, others combine **chemo + radiation**.
* May reflect national treatment guidelines or availability.

---

## 💓 F. Outcomes & Survival

### 1. Overall Survival Rate
```
select ((count(case when survived in (1) then 1 end)/890000.0)*100) as survival_rate, 100 - ((count(case when survived in (1) then 1 end)/890000.0)*100) as Death_rate  from Fact
```

* \~**72.4%** survived, while **27.6%** did not.
* Strong survival rates, but late detection still impacts outcomes.

### 2. Survival by Cancer Stage
```
select b.cancer_stage, ((count(case when a.survived in (1) then 1 end)/890000.0)*100) as survival_rate 
	from fact a
	inner join Cancer_stage b on a.cancer_stageID = b.cancer_stageID
	group by b.cancer_stage
	order by b.cancer_stage asc
```

* Stage I: \~95%
* Stage IV: <30%
* Strong indication of the **critical importance of early diagnosis**.

### 3. Survival by Treatment Type
```
select b.treatment_type, ((count(case when a.survived in (1) then 1 end)/890000.0)*100) as survival_rate
from fact a
	inner join Treatment_type b on a.treatment_typeID = b.treatment_typeID
	group by b.treatment_type
	order by survival_rate desc
```

* **Surgery + Radiation** showed highest survival.
* Patients receiving **palliative or single-line chemo** had lower outcomes.

### 4. Survival by Risk Factors
```
select smoking_status, ((count(case when survived in (1) then 1 end)/890000.0)*100) as survival_rate
from fact a
		inner join smoking_status b on a.smoking_statusID = b.smoking_statusID
	group by smoking_status
	order by survival_rate desc
```
```
select b.family_history, ((count(case when survived in (1) then 1 end)/890000.0)*100) as survival_rate 
from fact a
		inner join Family_history b on a.family_historyID = b.family_historyID
	group by b.family_history
	order by survival_rate desc
```
```

select hypertension, ((count(case when survived in (1) then 1 end)/890000.0)*100) as survival_rate from fact
	group by hypertension
	order by survival_rate desc
```
```

select asthma, ((count(case when survived in (1) then 1 end)/890000.0)*100) as survival_rate from fact
	group by asthma
	order by survival_rate desc
```
```

select cirrhosis, ((count(case when survived in (1) then 1 end)/890000.0)*100) as survival_rate from fact
	group by cirrhosis
	order by survival_rate desc
```
```

select other_cancer, ((count(case when survived in (1) then 1 end)/890000.0)*100) as survival_rate from fact
	group by other_cancer
	order by survival_rate desc
```
```

select asthma, ((count(case when survived in (1) then 1 end)/890000.0)*100) as survival_rate from fact
	group by asthma
	order by survival_rate desc
```

* Smoking: Current smokers had the **lowest survival rate (\~50%)**
* Family History: Slightly better survival — likely due to earlier screenings
* Hypertension, Asthma, Cirrhosis, and Other Cancer:

  * **All show reduced survival rates** compared to patients without comorbidities

---

## 📎 Key Metrics

| Metric                                | Description                                        |
| ------------------------------------- | -------------------------------------------------- |
| `Age_group`                           | Patient age group category                         |
| `Treatment_duration`                  | Number of days between diagnosis and treatment end |
| `Survived`                            | Binary outcome of patient survival                 |
| `BMI`, `Cholesterol`, `Comorbidities` | Additional health indicators                       |

---

## ✅ Recommendations

* **Invest in early detection** programs, especially in countries with high late-stage diagnoses.
* **Improve access** to combined treatments in low-income nations.
* **Target modifiable risk factors** like smoking and cholesterol through education and lifestyle programs.
* **Personalize treatment plans** based on stage, age, and comorbid conditions.

---

