select*
FROM customerchurn;
--DATA CLEANING

--1.Finding the Total number of customers  
SELECT COUNT(DISTINCT customerid) AS Total_Customers
FROM customerchurn;

--2.Checking for duplicate values
SELECT customerid, COUNT(customerid) AS Duplicated_count
FROM customerchurn
GROUP BY customerid
HAVING COUNT(customerid) > 1;

--3.Checking for Null values
SELECT 'Churn' AS Column_Name, COUNT(*) AS Null_Count
FROM customerchurn
WHERE 'Churn' IS NULL 
UNION
SELECT 'Tenure' AS Column_Name, COUNT(*) AS Null_Count
FROM customerchurn
WHERE 'Tenure' IS NULL
UNION
SELECT 'WarehouseToHome' AS ColumnName, COUNT(*) AS NullCount 
FROM customerchurn 
WHERE WarehouseToHome IS NULL
UNION
SELECT 'HourSpendonApp' AS ColumnName, COUNT(*) AS NullCount 
FROM customerchurn 
WHERE HourSpendonApp IS NULL
UNION
SELECT 'OrderAmountHikeFromLastYear' AS ColumnName, COUNT(*) AS NullCount 
FROM customerchurn 
WHERE OrderAmountHikeFromLastYear IS NULL
UNION
SELECT 'CouponUsed' AS ColumnName, COUNT(*) AS NullCount 
FROM customerchurn 
WHERE CouponUsed IS NULL
UNION
SELECT 'OrderCount' AS ColumnName, COUNT(*) AS NullCount 
FROM customerchurn 
WHERE OrderCount IS NULL
UNION
SELECT 'DaySinceLastOrder' AS ColumnName, COUNT(*) AS NullCount 
FROM customerchurn 
WHERE DaysinceLastOrder IS NULL;

-- 3.1 Handling the NUll Values
UPDATE customerchurn
SET tenure = (SELECT AVG(tenure) FROM customerchurn)
WHERE tenure IS NULL;

UPDATE customerchurn
SET CouponUsed = (SELECT AVG(CouponUsed) FROM customerchurn)
WHERE CouponUsed IS NULL;

UPDATE customerchurn
SET DaySinceLastOrder = (SELECT AVG(DaySinceLastOrder) FROM customerchurn)
WHERE DaySinceLastOrder IS NULL;

UPDATE customerchurn
SET HourSpendonApp = (SELECT AVG(HourSpendonApp) FROM customerchurn)
WHERE HourSpendonApp IS NULL;

UPDATE customerchurn
SET OrderAmountHikeFromLastYear = (SELECT AVG(OrderAmountHikeFromLastYear) FROM customerchurn)
WHERE OrderAmountHikeFromLastYear IS NULL;

UPDATE customerchurn
SET OrderCount = (SELECT AVG(OrderCount) FROM customerchurn)
WHERE OrderCount IS NULL;

UPDATE customerchurn
SET WarehouseToHome = (SELECT AVG(WarehouseToHome) FROM customerchurn)
WHERE WarehouseToHome IS NULL;

--4. Creating a new column from an already existing “churn” column
--Add a new column
ALTER TABLE  customerchurn ADD customerstatus VARCHAR(50);
--Add values to the new column
UPDATE customerchurn
SET customerstatus = CASE
	WHEN churn = 1 THEN 'churned'
	WHEN churn = 0 THEN 'stayed'
END;
SELECT DISTINCT(customerstatus)
FROM customerchurn;

--5.Creating a new column from an already existing “complain” column
ALTER TABLE customerchurn ADD complained VARCHAR(50);
UPDATE customerchurn
SET complained = CASE
	WHEN complain = 1 THEN 'YES'
	WHEN complain = 0 THEN 'NO'
END;
SELECT DISTINCT(complained)
FROM customerchurn;
--6.Fixing redundancy in “PreferedLoginDevice” Column
UPDATE customerchurn
SET PreferredLoginDevice = 'Mobile Phone'
WHERE PreferredLoginDevice = 'Phone';

SELECT DISTINCT(PreferredLoginDevice)
FROM customerchurn;
--7. Fixing redundancy in “PreferedOrderCat” Column
UPDATE customerchurn
SET PreferedOrderCat = 'Mobile Phone'
WHERE PreferedOrderCat = 'Mobile';
--8.Fixing redundancy in “PreferredPaymentMode” Column
UPDATE customerchurn
SET PreferredPaymentMode = 'Credit Card'
WHERE PreferredPaymentMode ='CC';

UPDATE customerchurn
SET  PreferredPaymentMode = 'Cash on Delivery'
WHERE PreferredPaymentMode ='COD';

SELECT DISTINCT(PreferredPaymentMode)
FROM customerchurn;
--9.Fixing wrongly entered values in “WarehouseToHome” column
UPDATE customerchurn
SET WarehouseToHome = '27'
WHERE WarehouseToHome = '127';

UPDATE customerchurn
SET WarehouseToHome = '26'
WHERE WarehouseToHome = '126';

--DATA EXPLORATION
--1. What is the overall customer churn rate?
SELECT
	Total_Number_of_customers,
	Total_number_of_churned_customers,
	CAST(
		(Total_number_of_churned_customers *1.0/Total_Number_of_customers *1.0)*100
		AS DECIMAL(10,2)
	)AS Churn_rate
FROM
	(SELECT COUNT(*) AS Total_Number_of_customers
	FROM customerchurn) AS Total,
	(SELECT COUNT(*) AS Total_number_of_churned_customers
	FROM customerchurn
	WHERE customerstatus = 'churned') AS churned;

--2. How does the churn rate vary based on the preferred login device?
SELECT 
	PreferredLoginDevice,
	COUNT(*) AS Total_Number_of_Customers,
	SUM(churn) AS  churnedcustomers,
	CAST((SUM(churn)*1.0/ COUNT(*)*1.0)*100 AS DECIMAL(10,2)) AS Churn_rate
FROM customerchurn
GROUP BY PreferredLoginDevice;
--3. What is the distribution of customers across different city tiers?
SELECT
	CityTier,
	COUNT(*) AS Total_customers,
	SUM(churn) As Churned_customers,
	CAST((SUM(churn)*1.0/COUNT(*)*1.0)*100 AS DECIMAL(10,2)) AS churn_rate
FROM customerchurn
GROUP BY CityTier
ORDER BY churn_rate DESC;
--4. Is there any correlation between the warehouse-to-home distance and customer churn?	
--Adding a new column to group the distance
ALTER TABLE customerchurn
ADD warehousehomerange VARCHAR(50)

UPDATE customerchurn
SET  warehousehomerange = CASE
		WHEN WarehouseToHome <=10 THEN 'very_close_distance'
		WHEN WarehouseToHome >10 AND WarehouseToHome <=20 THEN 'close_distance'
		WHEN WarehouseToHome >20 AND WarehouseToHome <=30 THEN 'moderate_distnace'
		WHEN WarehouseToHome >30 THEN 'far_distance'
END;

SELECT
	warehousehomerange,
	COUNT(*) AS total_customers,
	SUM(churn) AS churnedcustomers,
	CAST(((SUM(churn)*1.0)/COUNT(*)*1.0)*100 AS DECIMAL(10,2)) AS churn_rate
FROM customerchurn
GROUP BY warehousehomerange
ORDER BY churn_rate DESC;
--5. Which is the most preferred payment mode among churned customers?
SELECT 
	PreferredPaymentMode,
	COUNT(*) AS totalcustomers,
	SUM(churn) AS churnedcustomers,
	CAST(((SUM(churn)*1.0)/COUNT(*)*1.0)*100 AS DECIMAL(10,2)) AS churn_rate
FROM customerchurn
GROUP BY PreferredPaymentMode
ORDER BY churn_rate DESC;
--6. What is the typical tenure for churned customers?
ALTER TABLE customerchurn
ADD tenurerange VARCHAR(50)

UPDATE customerchurn
SET TenureRange =
CASE 
    WHEN tenure <= 6 THEN '6 Months'
    WHEN tenure > 6 AND tenure <= 12 THEN '1 Year'
    WHEN tenure > 12 AND tenure <= 24 THEN '2 Years'
    WHEN tenure > 24 THEN 'more than 2 years'
END


SELECT 
   tenurerange,
   COUNT(*) AS totalcustomers,
   SUM(churn) AS churnedcustomers,
   CAST(((SUM(churn)*1.0)/COUNT(*)*1.0)*100 AS DECIMAL(10,2)) AS churnedrate
FROM customerchurn
GROUP BY  TenureRange
ORDER BY  churnedrate DESC;

--7.Is there any difference in churn rate between male and female customers?
SELECT 
	Gender,
	COUNT(*) AS totalcustomers,
	SUM(churn) as churnedcustomers,
	CAST(((SUM(churn)*1.0)/COUNT(*)*1.0)*100 AS DECIMAL(10,2)) AS churnedrate
FROM customerchurn
GROUP BY Gender
ORDER BY churnedrate DESC;
--8. How does the average time spent on the app differ for churned and non-churned customers?
SELECT 
	customerstatus,
	ROUND(AVG(HourSpendOnApp),2) AS average_time_spent_on_the_App
FROM customerchurn
GROUP BY customerstatus;

--9. Does the number of registered devices impact the likelihood of churn?
SELECT 
	 NumberOfDeviceRegistered,
	 COUNT(*) AS totalcustomers,
	 SUM(churn) AS churnedcustomers,
	 CAST(((SUM(churn)*1.0)/COUNT(*)*1.0)*100 AS DECIMAL(10,2)) AS churnrate
FROM customerchurn
GROUP BY NumberOfDeviceRegistered
ORDER BY churnrate DESC;

--10. Which order category is most preferred among churned customers?
SELECT 
	 PreferedOrderCat,
	 COUNT(*) AS totalcustomers,
	 SUM(churn) AS churnedcustomers,
	 CAST(((SUM(churn)*1.0)/COUNT(*)*1.0)*100 AS DECIMAL(10,2)) AS churnrate
FROM customerchurn
GROUP BY PreferedOrderCat
ORDER BY churnrate DESC;

--11. Is there any relationship between customer satisfaction scores and churn?
SELECT 
	SatisfactionScore,
	 COUNT(*) AS totalcustomers,
	 SUM(churn) AS churnedcustomers,
	 CAST(((SUM(churn)*1.0)/COUNT(*)*1.0)*100 AS DECIMAL(10,2)) AS churnrate
FROM customerchurn
GROUP BY SatisfactionScore
ORDER BY churnrate DESC;

--12.Does the marital status of customers influence churn behavior?
SELECT 
	 MaritalStatus,
	 COUNT(*) AS totalcustomers,
	 SUM(churn) AS churnedcustomers,
	 CAST(((SUM(churn)*1.0)/COUNT(*)*1.0)*100 AS DECIMAL(10,2)) AS churnrate
FROM customerchurn
GROUP BY MaritalStatus
ORDER BY churnrate DESC;
--13. How many addresses do churned customers have on average?
SELECT
	Round(AVG(NumberOfAddress),2) AS Address_AVG
FROM customerchurn
WHERE customerstatus = 'stayed';

--14.  Do customer complaints influence churned behavior?
SELECT 
	Complain,
	 COUNT(*) AS totalcustomers,
	 SUM(churn) AS churnedcustomers,
	 CAST(((SUM(churn)*1.0)/COUNT(*)*1.0)*100 AS DECIMAL(10,2)) AS churnrate
FROM customerchurn
GROUP BY Complain
ORDER BY churnrate DESC;

--15.  How does the use of coupons differ between churned and non-churned customers?
SELECT 
	customerstatus,
	SUM(CouponUsed) AS coupons
FROM customerchurn
GROUP BY customerstatus;

--16. What is the average number of days since the last order for churned customers?
SELECT ROUND(AVG(daysincelastorder),2) AS AverageNumofDaysSinceLastOrder
FROM customerchurn
WHERE customerstatus = 'churned'

--17.Is there any correlation between cashback amount and churn rate?
ALTER TABLE customerchurn
ADD cashbackrange VARCHAR(50)

UPDATE customerchurn
SET cashbackrange = CASE
	WHEN CashbackAmount <=100 THEN 'Low_Cashback'
	WHEN CashbackAmount >100 AND CashbackAmount <=200 THEN 'Moderate_cashback'
	WHEN CashbackAmount >200 AND CashbackAmount <=300 THEN 'High_cashback'
	WHEN CashbackAmount >300 THEN 'very_high_cashback'
END;

SELECT 
	cashbackrange,
	 COUNT(*) AS totalcustomers,
	 SUM(churn) AS churnedcustomers,
	 CAST(((SUM(churn)*1.0)/COUNT(*)*1.0)*100 AS DECIMAL(10,2)) AS churnrate
FROM customerchurn
GROUP BY cashbackrange
ORDER BY churnrate DESC;
