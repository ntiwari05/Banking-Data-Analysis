Use banking_data;

select * from banking_ml;

ALTER TABLE banking_ml
RENAME COLUMN `Client ID` TO Client_ID,
RENAME COLUMN `Name` TO Name,
RENAME COLUMN `Age` TO Age,
RENAME COLUMN `Joined Bank` TO Joined_Bank,
RENAME COLUMN `Nationality` TO Nationality,
RENAME COLUMN `Occupation` TO Occupation,
RENAME COLUMN `Fee Structure` TO Fee_Structure,
RENAME COLUMN `Loyalty Classification` TO Loyalty_Classification,
RENAME COLUMN `Estimated Income` TO Estimated_Income,
RENAME COLUMN `Superannuation Savings` TO Superannuation_Savings,
RENAME COLUMN `Amount of Credit Cards` TO Amount_of_Credit_Cards,
RENAME COLUMN `Credit Card Balance` TO Credit_Card_Balance,
RENAME COLUMN `Bank Loans` TO Bank_Loans,
RENAME COLUMN `Bank Deposits` TO Bank_Deposits,
RENAME COLUMN `Checking Accounts` TO Checking_Accounts,
RENAME COLUMN `Saving Accounts` TO Saving_Accounts,
RENAME COLUMN `Foreign Currency Account` TO Foreign_Currency_Account,
RENAME COLUMN `Business Lending` TO Business_Lending,
RENAME COLUMN `Properties Owned` TO Properties_Owned,
RENAME COLUMN `Risk Weighting` TO Risk_Weighting,
RENAME COLUMN `Gender` TO Gender,
RENAME COLUMN `Banking Relationship` TO Banking_Relationship,
RENAME COLUMN `Investment Advisor` TO Investment_Advisor,
RENAME COLUMN `Joined Year` TO Joined_Year,
RENAME COLUMN `Joined Month` TO Joined_Month,
RENAME COLUMN `Total Assets` TO Total_Assets,
RENAME COLUMN `Total Debt` TO Total_Debt,
RENAME COLUMN `Net Financial Position` TO Net_Financial_Position,
RENAME COLUMN `Deposit to Income Ratio` TO Deposit_to_Income_Ratio,
RENAME COLUMN `Loan to Income Ratio` TO Loan_to_Income_Ratio,
RENAME COLUMN `Customer Tenure (Years)` TO Customer_Tenure_Years,
RENAME COLUMN `Age_label` TO Age_Label;



SELECT
    AVG(CASE WHEN Joined_Year < 2019 THEN Clients END) AS mean_before_2019,
    AVG(CASE WHEN Joined_Year >= 2019 THEN Clients END) AS mean_after_2019
FROM (
    SELECT
        Joined_Year,
        COUNT(*) AS Clients
    FROM banking_ml
    GROUP BY Joined_Year
) t;   -- average client shifted from 107 to 209 . after 2019





-- Cusotmer Segmentation --

# Which age group has the highest average bank deposits and total assets?

select Age_label, Round(avg(Bank_Deposits) /1000000, 3) as 'avg_deposits(M)', Round(sum(Total_Assets) / 1000000,3) as 'total_assets(M)'
	from banking_ml
    group by age_label 
    order by 'avg_deposits(M)' desc, 'total_assets(M)' desc;
    
# Which occupations contribute the highest average income and net financial position?

select Occupation , round(avg(Estimated_Income),3) as Avg_Income , Round(avg(Net_Financial_Position),3) as Net_Financial_Position
	from banking_ml
    group by Occupation
    order by Avg_Income desc , Net_Financial_Position desc;
    
select Occupation ,Round(avg(Net_Financial_Position),3) as Net_Financial_Position
	from banking_ml
    group by Occupation
    order by Net_Financial_Position desc;

# Identify the top 10 high-value customers based on Total Assets and Net Financial Position.

select Client_ID , Name , round(avg(Total_Assets),3) as Avg_Assets , Round(avg(Net_Financial_Position),3) as Net_Financial_Position
	from banking_ml
    group by Client_ID, Name
    order by Avg_Assets desc , Net_Financial_Position desc limit 10;

# How does customer tenure differ across different loyalty classifications?

select Loyalty_Classification , Count(*) as Customer_Count 
from banking_ml
where 
Customer_Tenure_Years > (select avg(Customer_Tenure_Years) from banking_ml)
group by Loyalty_Classification
order by Count(*) desc
;

SELECT 
    Loyalty_Classification,
    
    COUNT(CASE 
        WHEN Customer_Tenure_Years > (SELECT AVG(Customer_Tenure_Years) FROM banking_ml)
        THEN 1 
    END) AS Above_Avg_Tenure_Count,

    COUNT(*) AS Total_Customers,

    ROUND(
        COUNT(CASE 
            WHEN Customer_Tenure_Years > (SELECT AVG(Customer_Tenure_Years) FROM banking_ml)
            THEN 1 
        END) * 100.0 / COUNT(*),
        2
    ) AS Above_Avg_Tenure_Percentage

FROM banking_ml
GROUP BY Loyalty_Classification
ORDER BY Above_Avg_Tenure_Percentage DESC;




select age_label , avg( Loan_to_Income_Ratio)as LI_Ratio from banking_ml
group by age_label
order by LI_Ratio desc ;



-- 2. Banking Relationship Analysis

# Which banking relationship type manages the highest total deposits and total assets?

select Banking_Relationship , Round(sum(total_Assets) / 1000000 ,3)as total_assets_million from banking_ml 
group by Banking_Relationship 
order by total_assets_million  desc ;

# What is the average income, deposits, and loans for each banking relationship?

select Banking_Relationship ,count(*) as customer_count,Round(avg(Estimated_Income) / 1000000 ,3)as avg_income_million, Round(avg(total_Assets) / 1000000 ,3)as avg_deposits_million ,
 Round(avg(Bank_Loans) / 1000000 ,3)as avg_bank_loan_million  from banking_ml 
group by Banking_Relationship 
order by avg_income_million desc, avg_bank_loan_million asc ;

# 	Which banking relationship has the highest proportion of high-risk customers?
SELECT 
    Banking_Relationship,
    COUNT(*) AS Total_Clients,
    SUM(CASE WHEN Risk_Weighting > 3 THEN 1 ELSE 0 END) AS High_Risk_Clients,
    ROUND(
        100.0 * SUM(CASE WHEN Risk_Weighting > 3 THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS High_Risk_Percentage
FROM banking_ml
GROUP BY Banking_Relationship
ORDER BY High_Risk_Percentage DESC;


SELECT
    CASE
        WHEN Risk_Weighting > 3 THEN 'High Risk'
        ELSE 'Low/Medium Risk'
    END AS Risk_Category,
    COUNT(*) AS Total_Clients,
    ROUND(AVG(Net_Financial_Position) / 1000000, 2) AS Avg_Net_Financial_Position_Million,
    ROUND(MIN(Net_Financial_Position) / 1000000, 2) AS Min_Net_Financial_Position_Million,
    ROUND(MAX(Net_Financial_Position) / 1000000, 2) AS Max_Net_Financial_Position_Million
FROM banking_ml
GROUP BY Risk_Category;

SELECT
    CASE
        WHEN Net_Financial_Position < 0 THEN 'Negative'
        WHEN Net_Financial_Position < 100000 THEN 'Low'
        WHEN Net_Financial_Position < 500000 THEN 'Medium'
        WHEN Net_Financial_Position < 1000000 THEN 'High'
        ELSE 'Very High'
    END AS Financial_Position_Group,

    COUNT(*) AS Total_Clients,

    SUM(
        CASE
            WHEN Risk_Weighting > 3 THEN 1
            ELSE 0
        END
    ) AS High_Risk_Clients,

    ROUND(
        100.0 *
        SUM(CASE WHEN Risk_Weighting > 3 THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS High_Risk_Percentage

FROM banking_ml

GROUP BY
    CASE
        WHEN Net_Financial_Position < 0 THEN 'Negative'
        WHEN Net_Financial_Position < 100000 THEN 'Low'
        WHEN Net_Financial_Position < 500000 THEN 'Medium'
        WHEN Net_Financial_Position < 1000000 THEN 'High'
        ELSE 'Very High'
    END

ORDER BY High_Risk_Percentage DESC;

 # Despite having a Very High Net Financial Position, 25% of these customers are classified as high risk.
 
 SELECT
    CASE
        WHEN Net_Financial_Position < 0 THEN 'Negative'
        WHEN Net_Financial_Position < 100000 THEN 'Low'
        WHEN Net_Financial_Position < 500000 THEN 'Medium'
        WHEN Net_Financial_Position < 1000000 THEN 'High'
        ELSE 'Very High'
    END AS Financial_Position_Group,

    ROUND(AVG(Total_Debt), 2) AS Avg_Total_Debt,
    ROUND(AVG(Bank_Loans), 2) AS Avg_Bank_Loans,
    ROUND(AVG(Loan_to_Income_Ratio), 2) AS Avg_Loan_to_Income_Ratio,
    ROUND(AVG(Estimated_Income), 2) AS Avg_Income,
    COUNT(*) AS Total_Clients
FROM banking_ml

GROUP BY Financial_Position_Group
ORDER BY Avg_Total_Debt DESC;

SELECT
    Banking_Relationship,
    COUNT(*) AS Total_Clients,
    SUM(CASE WHEN Risk_Weighting > 3 THEN 1 ELSE 0 END) AS High_Risk_Clients,
    ROUND(
        100.0 * SUM(CASE WHEN Risk_Weighting > 3 THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS High_Risk_Percentage
FROM banking_ml
WHERE Net_Financial_Position >= 1000000   
GROUP BY Banking_Relationship
ORDER BY High_Risk_Percentage DESC;

SELECT
    CASE
        WHEN Risk_Weighting > 3 THEN 'High Risk'
        ELSE 'Low/Medium Risk'
    END AS Risk_Category,

    ROUND(AVG(Credit_Card_Balance),2) AS Avg_Credit_Card_Balance,
    ROUND(AVG(Amount_of_Credit_Cards),2) AS Avg_Credit_Cards
FROM banking_ml
GROUP BY Risk_Category;

SELECT
    Banking_Relationship,

    ROUND(AVG(Business_Lending),2) AS Avg_Business_Lending,
    min(Business_Lending) as Min_Business_Lending,
    max(Business_Lending) as Max_Business_Lending, 
    ROUND(
        100.0 * SUM(CASE WHEN Risk_Weighting > 3 THEN 1 ELSE 0 END)
        / COUNT(*), 2
    ) AS High_Risk_Percentage

FROM banking_ml
GROUP BY Banking_Relationship
ORDER BY High_Risk_Percentage DESC;