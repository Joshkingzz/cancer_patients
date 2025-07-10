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

* Most patients fall within the **41–70** age range with age range of 51 - 60 significantly standing out as the age range with highest number of cancer cases
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
* Insight: Could reflect both population size and reporting practices.

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
select b.cancer_stage, count(*) as Number, round((count(*)/890000.0)*100, 4) as percentage_distribution
from fact A
inner join cancer_stage B on A.cancer_stageID = b.cancer_stageID
	group by b.cancer_stage
	order by b.cancer_stage, Number desc
```
![Image](https://github.com/user-attachments/assets/5f311d2b-2b76-4359-9ac9-2d1d31643e0c)

* Despite almost having an even distribution among stages, **Stage III and IV** have a higher percentage.
* Insight: Late-stage (Stage III/IV) diagnosis remains prevalent, hence the need for cancer awareness and regular check ups to mitigate late stage disgnosis.

### 2. Diagnosis Trend Over Time
```
select year(d.diagnosis_date) as year, month (d.diagnosis_date) as month, count (*) as new_diagnosis
from fact A
inner join diagnosis_date d on a.diagnosis_dateID = d.diagnosis_dateID
	group by year(diagnosis_date), month (diagnosis_date)
	order by year(diagnosis_date), month (diagnosis_date)
```

![Image](https://github.com/user-attachments/assets/81f0df3b-bb5e-4744-901c-c4ab16e2cf35)
![Image](https://github.com/user-attachments/assets/0c7d5255-e70d-4bd8-b627-aa1d9c4bdd5c)
![Image](https://github.com/user-attachments/assets/7d3e5b19-f105-403b-94e8-cb2d4f611a54)

*Cancer diagnoses have remained relatively steady over the years, with the lowest numbers typically recorded in the first quarter, followed by a gradual rise in the second quarter. A notable spike occurs in the third quarter, especially in July, which, along with January, consistently records the highest number of diagnoses. In contrast, February shows a significant drop, after which the monthly figures fluctuate moderately throughout the rest of the year.

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
![Image](https://github.com/user-attachments/assets/06192ffd-7cb5-4d54-95e5-030e0a31fb98)

* Insight: Since most cancer diagnoses occur predominantly within the 51 to 60 age group, it’s no surprise that the average age at diagnosis falls between 55 and 60. This trend highlights the importance of early screening and proactive health monitoring as individuals approach their 50s, emphasizing the need to detect cancer in its early stages for better outcomes.

### 4. Countries with Higher Late-Stage Diagnosis
```
select Top 10 country, count(case when b.cancer_stage in ('stage III', 'stage IV') then 1 end) as Stage_III_and_IV_diagnosis 
from fact A
		  inner join cancer_stage B on A.cancer_stageID = b.cancer_stageID
		  inner join country c on a.countryId = c.countryID
	group by country
	order by Stage_III_and_IV_diagnosis desc
```
![Image](https://github.com/user-attachments/assets/950976f8-32d4-41cf-b6b3-4b6cb25c2159)

* Countries with a higher incidence of late-stage cancer diagnoses include Croatia, Greece, Malta, France, the Netherlands, and Italy. This pattern may point to potential gaps in early detection, screening programs, or healthcare access within these regions, emphasizing the need for improved awareness and diagnostic efforts.

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

![Image](https://github.com/user-attachments/assets/4ffd3e39-d7d8-4e88-bab8-7f55116caa08)

* Passive Smokers consistently have high diagnosis counts across all stages, often ranking highest or second-highest. This could imply that secondhand smoke exposure is a critical risk factor. The differences between categories are not drastic, but there is a gradual shift in distribution, especially in the later stages, where Never and Passive Smokers have slightly higher numbers. Current Smokers show a notable decrease in Stage IV, which may suggest earlier mortality, under-diagnosis, or healthcare avoidance in this group.


### 2. Family History
```
select count(id) as Patients_with_family_history_of_cancer
from fact a
inner join family_history f on a.family_historyID = f.family_historyID where family_history in (1)

```
![Image](https://github.com/user-attachments/assets/c85bc424-4c17-43d7-8f5c-ccda85171c87)

* **444819** patients out of 890000 reportedly have a family history of cancer.
* Insight: Genetic screening and family-based interventions are crucial.

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
![Image](https://github.com/user-attachments/assets/a73abb70-2cb1-4f07-9a45-484c8ac3608b)

* **Hypertension**: \~75%
* **Asthma**: \~47%
* **Cirrhosis**: \~23%
* Insight: This data highlights a strong prevalence of comorbid conditions in cancer patients, especially hypertension and asthma. These comorbidities may not only contribute to cancer risk but also complicate diagnosis, treatment, and recovery.  Hypertension is the most prevalent, followed by asthma, while cirrhosis, though less common, still affects a notable portion of the population. These conditions are highly relevant in the context of cancer, as they may influence both risk and treatment outcomes.

### 4. Cholesterol Levels
```
select a.Age_group, avg(cholesterol_level) as Average_cholestrol_level 
from Fact a

	group by a.Age_group 
	order by a.Age_group
```
![Image](https://github.com/user-attachments/assets/ddb0c9ed-7825-4eae-9933-b9b9f0674439)


```
select cancer_stage, (Total_cholestrol_level/Number) as Average_cholestrol_level 

from ( select b.cancer_stage, sum(a.cholesterol_level) as Total_cholestrol_level, count(a.cholesterol_level) as Number
		from Fact a
		inner join Cancer_stage b on a.cancer_stageID = b.cancer_stageID
		group by cancer_stage
		) as subquery 
		
order by cancer_stage asc
```
![Image](https://github.com/user-attachments/assets/3d07a0c2-ee76-4f32-ad4d-6918886fee26)

* Cholesterol levels remain constant (233 mg/dL) across all cancer stages, suggesting no link between cancer progression and cholesterol in this dataset.
* Across age groups, cholesterol is stable from ages 11 to 100, with slight variations: Lowest in ages 0–10 (228 mg/dL) & Highest in those aged 101+ (248 mg/dL).
* Insight : These patterns indicate that cholesterol levels are not a strong indicator of cancer stage or age, except at age extremes.

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
![Image](https://github.com/user-attachments/assets/f68cbad9-5e7b-4ed1-a386-607c40922051)

* The distribution of cancer treatment types is almost evenly spread among the four categories. **Chemotherapy** and **Surgery** are the most common treatments, each accounting for about 25.09% of patients, Combined treatments (likely multiple modalities) follow closely at 25.01%, Radiation therapy is slightly less common but still significant at 24.82%.

* Insight: The marginal differences suggest that treatment choice is likely influenced by individual patient profiles, cancer type, and stage, rather than a dominant standard approach.


### 2. Average Treatment Duration by Stage
```
select b.cancer_stage, avg(a.treatment_duration) as Average_treatment_duration_in_days
from fact a
	inner join Cancer_stage b on a.cancer_stageID = b.cancer_stageID
	group by b.cancer_stage
	order by b.cancer_stage
```
![Image](https://github.com/user-attachments/assets/b71e0cec-3a47-4a30-b25e-6cf5bdb52f5a)

* **Stage I** patients have the longest average treatment duration **(512 days)**, **Stage IV** patients have the shortest average treatment duration **(403 days)**. There is an inverse relationship between cancer stage and treatment duration, as the stage increases, the average duration of treatment decreases, reflecting differences in treatment goals and intensity.

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
![Image](https://github.com/user-attachments/assets/ef8753d7-2fe8-4150-b163-fce9043ceeab)

* **Surgery** is the most common treatment in early stages (Stage I and II), In Stage III, treatment shifts towards **Combined therapy and Chemotherapy**. Stage IV is dominated by **Chemotherapy**, reflecting its role in managing advanced cancers where curative surgery is often not viable.
* Insight: As cancer progresses, treatment becomes more systemic (Chemotherapy/Combined), while Surgery is more common in early, localized stages.

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
![Image](https://github.com/user-attachments/assets/d3126bbb-ec1e-4bfb-86ab-901dcdcfba0e)

* \~**25% received combined treatment**, showing personalized care in advanced cases.
* Remaining **75% received a single treatment modality**.

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
![Image](https://github.com/user-attachments/assets/6bb81284-eadb-4d18-8cee-11429345acdd)

### 2. Survival Rate per Country
```
select b.country, ((count(case when survived in (1) then 1 end)/890000.0)*100) as survival_rate
		from fact a
		inner join country b on a.countryID = b.countryID
	group by b.country
	order by survival_rate desc
```
![Image](https://github.com/user-attachments/assets/8c87c085-1d33-4c4c-b5f9-fcc338880d44)

* Survival varies from **\0.80% to 0.83%** by country.
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


![Image](https://github.com/user-attachments/assets/40d5288f-2144-4f6c-ad31-5e474cc76a96)
![Image](https://github.com/user-attachments/assets/96d8bb35-ad7b-4a25-88cc-1244b29ecc88)
![Image](https://github.com/user-attachments/assets/bbed9f32-32d3-4a15-8eaa-47e5188f7136)

* Yes, treatment type varies significantly by country, The data shows that different countries prioritize different treatment types for cancer, suggesting that medical practices, healthcare infrastructure, access to therapies, and national treatment guidelines influence cancer management strategies.
  
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

