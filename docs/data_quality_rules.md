# Hospital Billing Analytics — Data Quality Rules

This document describes the rules implemented in the repository's Bronze and Silver SQL scripts. It reflects the current code, not an idealized future design.

## Bronze layer

Source files are read from:

`/Volumes/hospital_billing/default/hospital_sales`

The streaming table is:

`hospital_billing.default.bronze_hospital_billing`

The Bronze SQL retains source columns and adds:

- `file_path`: source file name from Databricks file metadata.
- `ingested_at`: ingestion timestamp.

It defines expectations that `bill_id`, `visit_id`, and `patient_id` are not null. Confirm the pipeline's expectation behavior and metrics in the Databricks pipeline run.

## Silver clean layer

The `silver_billing_clean` materialized view:

- Uses `SELECT DISTINCT`.
- Trims and title-cases selected text fields.
- Replaces null values in selected descriptive fields with `Unknown`.
- Calculates `total_amount` as `quantity * unit_price` when the source total is null.
- Replaces null `insurance_amount` with zero.
- Applies expectations for `quantity > 0` and `unit_price >= 0`, each with `ON VIOLATION DROP ROW`.

Fields standardized include patient gender, visit type, department, doctor name, service category, service name, city, region, payer type, and payment status. Hospital branch is trimmed and null-filled but is not title-cased in the current SQL.

## Silver rejected layer

The `silver_billing_rejected` view reads from Bronze and includes rows meeting any of these conditions:

| Field | Rejection condition |
|---|---|
| `quantity` | Null, zero, or negative |
| `unit_price` | Null or negative |

The `reject_reason` CASE expression reports the quantity issue first when both conditions are present; otherwise it reports the unit-price issue.

## Current implementation notes

- `SELECT DISTINCT` removes identical selected rows; it does not establish a unique business key for billing records.
- The rejected view reads directly from Bronze and does not apply `DISTINCT`.
- The Silver clean expectations also require positive quantity and non-negative unit price. The rejected view uses corresponding invalid-value filters.
- The current SQL does not explicitly validate patient age, visit date, insurance amount sign, missing bill/visit/patient IDs in Silver, or allowed payment-status values.
- A missing `total_amount` is derived from quantity and unit price. If either input is null, the derived value can remain null.
- Replacing null insurance amount with zero is a business assumption; confirm that it matches the source system's meaning.
- The Gold data-quality label `Duplicate rows removed` is calculated as a residual count after subtracting clean and rejected counts. It is not a direct duplicate-key count.

## Suggested additional checks

Consider adding checks for valid patient-age ranges, valid visit dates, non-negative insurance amounts, allowed payment statuses, and completeness of critical billing identifiers. Define the record grain before introducing business-key duplicate checks.
