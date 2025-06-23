use zomato;

-- who are the top two customers who spent a lot of money 

select * from (select monthname(date) as month_name, user_id, sum(amount) as total_amount,
				rank() over(partition by monthname(date) order by sum(amount) desc) as month_rank_customer
				from orders 
				group by user_id, monthname(date)
				order by monthname(date)) t
where t.month_rank_customer < 3 
order by month_rank_customer asc, month_name desc ;  
select *, sum(amount) over (partition by user_id order by sum(amount)) as total_amount
from orders
limit 2;

select * from orders ;

-- FIND THE M on M revenue growth of zomato

select * from orders;

select Monthname(date) , sum(amount) as total_amount, 
round(((sum(amount) - lag(sum(amount)) over (order by month(date)))/(lag(sum(amount)) over (order by month(date))))*100,2)
from orders
group by Monthname(date)  
order by Month(date) asc; 

use insurance_claim;

select * from insurance_data;

--  What are the top 5 patients who claimed the highest insurance amounts?

SELECT 
    PatientID, 
    SUM(claim) AS total_claims,
    RANK() OVER (ORDER BY SUM(claim) DESC) AS claim_rank
FROM insurance_data
GROUP BY patientID
ORDER BY total_claims DESC
LIMIT 5;

-- What is the average insurance claimed by patients based on the number of children they have?

WITH claim_avg AS (
    SELECT 
        children,
        AVG(claim) AS average_claim,
        COUNT(*) AS patient_count
    FROM 
        insurance_data
    GROUP BY 
        children
)
SELECT 
    children,
    average_claim,
    patient_count,
    DENSE_RANK() OVER(ORDER BY average_claim DESC) AS claim_rank
FROM 
    claim_avg
ORDER BY 
    claim_rank;
    
    
-- : What is the highest and lowest claimed amount by patients in each region?

    SELECT DISTINCT
    region,
    FIRST_VALUE(claim) OVER (
        PARTITION BY region 
        ORDER BY claim DESC
        
    ) AS highest_claim,
    LAST_VALUE(claim) OVER (
        PARTITION BY region 
        ORDER BY claim DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS lowest_claim,
    COUNT(*) OVER (PARTITION BY region) AS patient_count
FROM 
    insurance_data
ORDER BY 
    highest_claim DESC;
    
-- What is the percentage of smokers in each age group?
 -- if they ask you percentage, it always the no of subjects doing that task / total number of subjects * 100
 -- if the tuple is categorical use the case and when to count and window fucntions to partition accordingly.

SELECT 
    *,
    COUNT(CASE WHEN smoker = 'Yes' THEN 1 END) OVER (PARTITION BY age) AS smoker_count_per_age,
    COUNT(*) OVER (PARTITION BY age) AS total_in_age_group,
    ROUND(
        (COUNT(CASE WHEN smoker = 'Yes' THEN 1 END) OVER (PARTITION BY age) * 100.0) / 
        COUNT(*) OVER (PARTITION BY age), 
        2
    ) AS percentage_smokers_in_age_group
FROM 
    insurance_data;
    
-- What is the difference between the claimed amount of each patient and the first claimed amount of that patient?

select *,first_value(claim) over(partition by patientid) as first_calim,
sum(claim) over(partition by patientid) as count_claim,
round(
		claim - first_value(claim) over(partition by patientid order by `index`), 2
        ) as difference_claim,
        ROW_NUMBER() OVER(PARTITION BY PatientID ORDER BY `index`) AS claim_sequence_number
from insurance_data;

-- For each patient, calculate the difference between their claimed amount 
-- and the average claimed amount of patients with the same number of children.
SELECT 
    *,
    AVG(claim) OVER(PARTITION BY children) AS avg_claim_for_same_children,
    round(claim - AVG(claim) OVER(PARTITION BY children), 2) AS difference_from_avg
FROM insurance_data;

-- Show the patient with the highest BMI in each region and their respective rank.


with ranked_bmi as (
select *, 
dense_rank() over(partition by region order by bmi desc) as rank_bmi
from insurance_data )
select * from ranked_bmi
where rank_bmi = 1
order by region desc
;

--  Calculate the difference between the claimed amount of each patient 
-- and the claimed amount of the patient who has the highest BMI in their region.

with highest_region_bmi as(
						select region, claim as highest_claim from ( 
						select region, claim, DENSE_RANK() OVER (PARTITION BY region ORDER BY bmi DESC) AS bmi_rank
                        from insurance_data i
                        ) ranked  
                        where 
                        bmi_rank = 1
				)
	SELECT 
    i.*,
    h.highest_claim,
    (i.claim - h.highest_claim) AS claim_difference
FROM 
    insurance_data i
JOIN 
    highest_region_bmi h ON i.region = h.region
ORDER BY 
    i.region, 
    claim_difference;









