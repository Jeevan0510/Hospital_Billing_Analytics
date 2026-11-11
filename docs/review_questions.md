# Hospital Billing Analytics — Review and Interview Questions

Use these questions to explain the project in technical reviews and data engineering interviews.

## Project overview

1. **What is the objective of this project?**  
   To build a repeatable hospital billing data pipeline that ingests raw CSV records, standardizes and validates them, and produces analytics-ready Gold views.

2. **Which architecture does the project use?**  
   Medallion Architecture: Bronze for raw ingestion, Silver for cleaning and validation, and Gold for business-level aggregations.

3. **Why use a medallion architecture?**  
   It separates ingestion, data quality, and reporting concerns, improves traceability, and makes transformations easier to maintain.

## Bronze layer

4. **What is stored in Bronze?**  
   Raw hospital billing fields plus source-file metadata and ingestion timestamp.

5. **Why add ingestion metadata?**  
   It helps trace records back to their source file and understand when they entered the pipeline.

6. **Which identifiers have Bronze expectations?**  
   `bill_id`, `visit_id`, and `patient_id` are expected to be non-null.

## Silver layer

7. **What cleaning is performed?**  
   The SQL trims and title-cases selected text fields, fills selected null descriptions with `Unknown`, derives missing total amounts, and defaults missing insurance amounts to zero.

8. **How are invalid billing records handled?**  
   The clean view drops rows with null/non-positive quantity or null/negative unit price through expectations. A separate rejected view records those conditions with a reason.

9. **Why use COALESCE?**  
   It returns the first non-null expression, allowing the transformation to provide a fallback value.

10. **Why use SELECT DISTINCT?**  
    It removes identical selected output rows. It should not be confused with business-key deduplication.

11. **How is total amount calculated when missing?**  
    The current SQL uses `quantity * unit_price` as a fallback when `total_amount` is null.

## Gold layer

12. **What does gold_monthly_billing provide?**  
    Monthly total revenue, insurance amount, and distinct visit counts.

13. **What does gold_department_performance provide?**  
    Revenue, distinct visits, and average revenue per visit by department.

14. **How is branch performance analyzed?**  
    By region, city, and hospital branch using revenue and distinct visit counts.

15. **What does payer analysis show?**  
    Revenue, insurance amount, and amounts associated with pending payment status by payer type.

16. **Why create Gold views?**  
    They present curated, aggregated metrics that are easier for dashboards and business users to consume.

## Data quality and reconciliation

17. **What is the difference between clean and rejected records?**  
    Clean records pass the current Silver quantity and unit-price rules; rejected records violate at least one of those rules.

18. **Does the current reconciliation prove exact record matching?**  
    No. It compares counts and calculates a residual. It does not prove that all Bronze rows are classified into mutually exclusive groups.

19. **How could duplicate detection be improved?**  
    Define the billing record grain and use a stable business key or source-row identifier, depending on whether the goal is to detect duplicate business records or repeated physical rows.

20. **What would you improve next?**  
    Add broader validation rules, automated SQL tests, stronger row-level reconciliation, pipeline monitoring, and a dashboard over the Gold views.

## Interview tip

When describing results, use actual counts and financial totals only after running the pipeline and validating the output. Do not quote sample metrics that have not been measured from the dataset.
