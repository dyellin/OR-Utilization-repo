# 🏥 General Hospital Operating Room Utilization Analysis

**A data analytics project with SQL, Google Sheets, and Tableau**

![Operating Room Dashboard]([images/or_utilization_dashboard.png](https://github.com/dyellin/OR-Utilization-repo/blob/6ec0437a28ff2b84be5e71ded5363d49eb8d5672/Dashboard%202.png))

### 🔗 Project Links
- 📘 **Dataset:** [Operating Room Utilization on Kaggle]([https://www.kaggle.com/](https://www.kaggle.com/datasets/thedevastator/optimizing-operating-room-utilization))
- 🧾 **SQL Script:** [`OR_Utilization_Analysis.sql`]([OR_Utilization_Analysis.sql](https://github.com/dyellin/OR-Utilization-repo/blob/2c74ad42cde1c54663661de28f511195eacf7430/OR_Utilization_Analysis.sql))
- 📊 **Tableau Dashboard:** [Operating Room Utilization]([https://public.tableau.com/](https://public.tableau.com/views/OR_Utilization_17410373563560/OperatingRoomUtilization?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link))
- 💻 **GitHub Repository:** [OR-Utilization-repo]([https://github.com/yourusername/OR-Utilization-repo](https://github.com/dyellin/OR-Utilization-repo/tree/2c74ad42cde1c54663661de28f511195eacf7430))

---

## 🩺 Project Overview
This project analyzes **Operating Room (OR) utilization** at the fictional *General Hospital* during **Q1 of 2022**, covering more than **2,100 surgical cases** across **8 operating rooms**.  

Goal: identify scheduling inefficiencies, uncover trends, and make **data-driven recommendations** to help the hospital optimize operating room time, improve patient throughput, and reduce financial loss from underutilized resources.

> General Hospital is a fictional small regional healthcare provider — so improving OR scheduling efficiency can make a big difference in both patient satisfaction and financial sustainability.

---

## 📚 Key Terms
- **CPT Code:** Standardized code that identifies a medical procedure or service.
- **Wheels In/Out:** When a patient enters or exits the operating room.
- **Timing:** Difference (in minutes) between the booked and actual case durations.

---

## 💡 Executive Summary
Using SQL and Tableau, this project analyzed 2,100+ case records from Q1 2022, tracking the difference between **scheduled** and **actual** surgery times.  

### 🔍 Highlights:
- Only **42% of cases start on time**
- **Daily caseloads:** typically 32–38 cases, with peaks in February and March
- **Only 3 services** (Ophthalmology, Plastic Surgery, OBGYN) finish on time, on average  
- The dashboard visualizes **each OR’s daily schedule** — comparing booked slots vs. actual start and end times  

---

## 📊 Insights

### 🕓 Operating Room Utilization
- Avg. **4.4 cases per OR per day** over **8.4 hours**
- **March** saw the highest workload — ~102 cases per OR
- **Average turnover time:** 30 minutes (but cases booked only 15 minutes apart)
- **58%** of cases started late (≥15 minutes delay)
- When the *first* case of the day starts late, all subsequent cases tend to follow suit

### 🧬 Service Efficiency
- **Ophthalmology**: most active service (334 cases)
  - Cataract removals account for **98%** of long-running Ophthalmology cases
- **General Surgery**: fewest cases (117) but most consistent schedule
- Cases running long delay subsequent cases by ~**30 minutes**

### 📅 Cyclical Trends
- **Tuesdays–Thursdays**: 63% of all surgeries
- **Mondays**: slowest day (18% of total)
- **Orthopedics, Pediatrics, Ophthalmology**: most frequent late starts on Tue/Wed

---

## 🧠 Recommendations
1. **Adjust scheduled durations** for recurring procedures  
   - e.g., *Partial ostectomies* run 42 minutes longer than booked.
2. **Schedule efficient procedures earlier** in the day  
   - e.g., *Lapidus bunionectomies* end 68 minutes early — fewer ripple effects.
3. **Improve or adapt turnover time**
   - If turnover time can’t be reduced to 15 minutes, space out bookings more realistically.

---

## ⚙️ Data Preparation

**Source:** Kaggle — “Operating Room Utilization” dataset  
**License:** [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)  
**Storage:** Local + cloud copies  

The data **ROCCC** (Reliable, Original, Comprehensive, Current, and Cited) and includes columns for:
`date`, `or_suite`, `service`, `cpt_code`, `cpt_desc`, `booked_dur`, `or_sched`, `wheels_in`, `start_time`, `end_time`, `wheels_out`, etc.

---

## 🧹 Data Cleaning & Transformation

**Tool:** Google Sheets  

- Standardized column names (`snake_case`)
- Reformatted timestamps to `YYYY-MM-DD HH:MM:SS`
- Created calculated columns:
  - `actual_dur` → `wheels_out - wheels_in`
  - `timing` → `actual_dur - booked_dur`
- Example:
  - `(2022-01-03 07:05:00) - (2022-01-03 09:17:00)` → `132` minutes  
  - `132 - 90 = +42` → 42 minutes longer than scheduled

---

## 🧮 Analysis

**Tools:** Google Sheets, SQL, R  

### In Google Sheets:
- Added columns for:
  - `dotw` (day of the week)
  - `arrival_window`, `surgery_dur`, and `sched_end`
- Created pivot tables to explore:
  - Average `actual_dur` by `service`
  - Procedure counts by `service` and `cpt_desc`

### In SQL:
Explored:
- Total & average case durations  
- Case counts by service, OR, date, and day of week  
- Deviations between booked and actual durations  
- Delay chains (how long cases push back subsequent ones)
- “First case” punctuality rate (7am starts)

### In R:
- Data import, cleaning consistency checks, and descriptive summaries
- Exported Markdown summaries and visualizations

---

## 📈 Tableau Dashboard
The interactive dashboard visualizes:
- Daily OR utilization by room and service  
- % of cases starting on time  
- Average booked vs. actual duration per service  
- Turnover time between cases  

> [View the Tableau Dashboard →]([https://public.tableau.com/](https://public.tableau.com/views/OR_Utilization_17410373563560/OperatingRoomUtilization?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link))

---

## ⚖️ Assumptions & Caveats
- Data covers **only Q1 2022** — longer time spans could show seasonal patterns.
- Dataset excludes **case cancellations** and **double-bookings**.
- Lacks doctor and case outcome details — could reveal more if included.
- **Reasons for delays** not specified.
- Timing accuracy depends on input reliability.

---

## 🔭 Future Work
- Extend analysis with more months/years of OR data.
- Merge with other hospital data (revenue, patient satisfaction, or case outcomes).
- Build predictive scheduling models for delay risk assessment.

---

## ✅ Deliverables Summary
| Deliverable | Description |
|--------------|-------------|
| **Business Task** | Identify scheduling inefficiencies and improve on-time starts |
| **Data Sources** | Kaggle dataset (Q1 2022) |
| **Cleaning** | Verified integrity, standardized formats, created duration metrics |
| **Analysis** | SQL queries, pivot tables, summary stats, and Tableau visuals |
| **Recommendations** | Adjust procedure durations, scheduling order, and turnover gaps |

---

## 👩‍💻 Author
**Dov Yellin**  
📧 dyellin13@gmail.com  
🔗 [LinkedIn](https://www.linkedin.com/in/dovyellin)

---

## 🪪 License
This project is shared under the **MIT License**.  
Data licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).

