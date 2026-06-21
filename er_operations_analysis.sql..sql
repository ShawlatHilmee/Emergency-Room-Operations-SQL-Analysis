-- =========================================================================
-- PROJECT TITLE: Emergency Room (ER) Operational & Satisfaction Analytics
-- Dataset: Hospital ER Performance Logs (9,216 entries)
-- Platform: MySQL Workbench / MySQL Server
-- Objective: Identify operational bottlenecks, wait-time drivers, and satisfaction drops.
-- Skills Used: Window Functions, CTEs, Aggregations, Data Type Handling, Conditional Logic, Views
-- =========================================================================

-- 1. Initial Data Audit
-- Reviewing a small snapshot to understand the shape of our ER traffic

SELECT * FROM HospitalER LIMIT 100;


-- 2. Macro Metrics: ER Benchmarks
-- Calculating total volume, overall admission rates, and average wait time across the hospital

SELECT 
    COUNT(`Patient Id`) AS TotalPatientsSeen,
    AVG(`Patient Waittime`) AS AvgWaittimeMinutes,
    SUM(CASE WHEN `Patient Admission Flag` = 'True' THEN 1 ELSE 0 END) AS TotalAdmissions,
    ROUND((SUM(CASE WHEN `Patient Admission Flag` = 'True' THEN 1 ELSE 0 END) * 1.0) / COUNT(`Patient Id`) * 100, 2) AS AdmissionRatePercentage
FROM HospitalER;


-- 3. Granular Analysis: Where are the Bottlenecks?
-- Breaking metrics down by Department Referral to find out which unit is lagging

SELECT 
    IFNULL(`Department Referral`, 'No Referral / Discharged') AS Department,
    COUNT(`Patient Id`) AS `Patient Volume`,
    AVG(`Patient Waittime`) AS `Avg Wait time`,
    MAX(`Patient Waittime`) AS `Max Wait time`,
    ROUND(AVG(`Patient Satisfaction Score`), 2) AS `Avg Satisfaction`
FROM HospitalER
GROUP BY `Department Referral`
ORDER BY `Avg Wait time` DESC
LIMIT 1000;


-- 4. Demographics & Vulnerable Populations
-- Segmenting patient age into brackets to see if elderly or pediatric patients wait longer

SELECT 
    CASE 
        WHEN `Patient Age` < 18 THEN 'Pediatric (<18)'
        WHEN `Patient Age` BETWEEN 18 AND 64 THEN 'Adult (18-64)'
        ELSE 'Geriatric (65+)'
    END AS AgeGroup,
    COUNT(`Patient Id`) AS `Patient Volume`,
    AVG(`Patient Waittime`) AS `Avg Wait time`,
    AVG(`Patient Satisfaction Score`) AS `Avg Satisfaction`
FROM HospitalER
GROUP BY 
    CASE 
        WHEN `Patient Age` < 18 THEN 'Pediatric (<18)'
        WHEN `Patient Age` BETWEEN 18 AND 64 THEN 'Adult (18-64)'
        ELSE 'Geriatric (65+)'
    END
ORDER BY `Avg Wait time` DESC;


-- 5. Running Timeline Impact (Window Function)
-- Creating a running total of patients processed per department over time to map peak traffic velocity

SELECT 
    `Patient Id`,
    `Department Referral`,
    `Patient Admission Date`,
    `Patient Waittime`,
    COUNT(`Patient Id`) OVER(
        PARTITION BY `Department Referral` 
        ORDER BY `Patient Admission Date`
    ) AS CumulativeDailyDepartmentVolume
FROM HospitalER
WHERE `Department Referral` IS NOT NULL;


-- 6. Isolating Operational Failure Modes (CTE)
-- Finding "Critical Exceptions": Patients who waited over an hour and gave a low satisfaction score (<= 4)

WITH ERCriticalExceptionsCTE AS (
    SELECT 
        `Patient Id`,
        `Department Referral`,
        `Patient Waittime`,
        `Patient Satisfaction Score`,
        `Patient Admission Flag`
    FROM HospitalER
)
SELECT 
    IFNULL(`Department Referral`, 'General ER') AS Department,
    COUNT(`Patient Id`) AS ExtremeDissatisfactionCount,
    SUM(CASE WHEN `Patient Admission Flag` IN ('True', 'true', '1') THEN 1 ELSE 0 END) AS AdmittedCount
FROM ERCriticalExceptionsCTE
-- Changed from AND to OR to capture data safely
WHERE `Patient Waittime` > 60  
   OR `Patient Satisfaction Score` <= 4
GROUP BY `Department Referral`
ORDER BY ExtremeDissatisfactionCount DESC;


-- 7. Creating a Production-Ready View for Visualization
-- Packaging our clean data so it can be seamlessly dragged into Tableau or Power BI

CREATE OR REPLACE VIEW v_CleanedEROperations AS
SELECT 
    `Patient Id`,
    `Patient Gender`,
    `Patient Age`,
    IFNULL(`Department Referral`, 'General ER Unit') AS DepartmentReferral,
    `Patient Admission Flag`,
    `Patient Waittime`,
    -- This ensures your dashboard charts don't crash from missing satisfaction data
    IFNULL(`Patient Satisfaction Score`, 0) AS `Patient Satisfaction Score`,
    CASE 
        WHEN `Patient Waittime` <= 30 THEN 'Target Met'
        WHEN `Patient Waittime` BETWEEN 31 AND 60 THEN 'Delayed'
        ELSE 'Severe Delay'
    END AS OperationalStatus
FROM HospitalER;

-- Test the newly built view
SELECT * FROM v_CleanedEROperations LIMIT 100;

-- Simple test query to verify the View successfully created
SELECT * FROM v_CleanedEROperations LIMIT 100;