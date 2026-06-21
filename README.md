# Emergency Room (ER) Operational & Satisfaction Analytics

## 📌 Project Overview
This project analyzes an Emergency Room performance dataset containing **9,216 patient records** to identify operational bottlenecks, department-specific wait-time drivers, and factors impacting patient satisfaction scores.

## 🛠️ Tech Stack & Skills Used
* **Database Engine:** MySQL Server
* **Interface Tool:** MySQL Workbench
* **SQL Advanced Concepts:** Window Functions (`OVER`, `PARTITION BY`), Common Table Expressions (CTEs), Conditional Logic (`CASE WHEN`), Data Type Casting, Database Views, Data Cleaning (`IFNULL`)

## 📊 Core Business Questions Answered
1. What is the hospital's overall patient admission rate and macro wait-time benchmark?
2. Which specific specialist departments face the worst delays and lowest satisfaction scores?
3. How does patient intake velocity build up chronologically across different units?
4. How can we isolate and quantify extreme service breakdowns (high wait times paired with low reviews)?

## 🧼 Data Cleaning Highlights
* **Handling Missing Values:** Discovered a high volume of missing data (`NULL` entries) within the satisfaction and department referral columns. Implemented defensive coding using `IFNULL()` to prevent mathematical aggregation crashes and stabilize metrics for downstream visualization dashboards (Tableau/Power BI).
