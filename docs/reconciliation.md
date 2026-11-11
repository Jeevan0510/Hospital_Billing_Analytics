# Hospital Billing Analytics — Reconciliation Notes

The Gold SQL creates `hospital_billing.default.gold_reconciliation` to summarize record counts across Bronze and Silver.

## Metrics in the current view

| Metric | Current SQL definition |
|---|---|
| `bronze_rows` | Total rows in `bronze_hospital_billing` |
| `clean_rows` | Total rows in `silver_billing_clean` |
| `rejected_rows` | Total rows in `silver_billing_rejected` |
| `duplicates_removed` | Bronze rows minus clean rows minus rejected rows |
| `reconciliation_ok` | True when clean rows plus rejected rows are less than or equal to Bronze rows |

The Gold data-quality view also reports the same residual-style count under the label `Duplicate rows removed`.

## Important interpretation

The current reconciliation is a high-level count check, not a complete row-by-row reconciliation:

1. The clean view applies `SELECT DISTINCT`, so identical selected records may collapse.
2. The rejected view reads directly from Bronze and does not apply `DISTINCT`.
3. The residual count can include effects other than duplicates, including differences in filtering and distinctness.
4. The current `reconciliation_ok` condition checks only that clean plus rejected does not exceed Bronze; it does not prove that every Bronze record has been accounted for exactly once.
5. It does not compare financial totals such as total amount or insurance amount across layers.

For these reasons, treat `duplicates_removed` as a residual count and `reconciliation_ok` as a basic diagnostic indicator rather than proof of exact reconciliation.

## Recommended stronger reconciliation

For a more reliable reconciliation:

1. Define the record grain (for example, one billing line per unique `bill_id`, if that matches the source system).
2. Add a stable source-row identifier so repeated physical rows can be distinguished from repeated business IDs.
3. Classify each Bronze row into mutually exclusive groups: accepted unique records, rejected records, and duplicate records.
4. Ensure each source row belongs to exactly one group.
5. Verify that the mutually exclusive group counts sum to Bronze rows.
6. Compare financial totals across layers, accounting for intentionally rejected or deduplicated records.

Also validate the meaning of `total_amount` and `insurance_amount` with the hospital billing business rules before using the aggregates for financial reporting.
