CREATE OR REFRESH MATERIALIZED VIEW hospital_billing.default.silver_billing_clean (
  CONSTRAINT valid_quantity   EXPECT (quantity > 0)    ON VIOLATION DROP ROW,
  CONSTRAINT valid_unit_price EXPECT (unit_price >= 0) ON VIOLATION DROP ROW
) AS
SELECT DISTINCT
  bill_id, visit_id, patient_id,
  COALESCE(INITCAP(TRIM(patient_gender)), 'Unknown')   AS patient_gender,
  patient_age,
  visit_date,
  COALESCE(INITCAP(TRIM(visit_type)), 'Unknown')      AS visit_type,
  COALESCE(INITCAP(TRIM(department)), 'Unknown')       AS department,
  COALESCE(INITCAP(TRIM(doctor_name)), 'Unknown')     AS doctor_name,
  COALESCE(INITCAP(TRIM(service_category)), 'Unknown') AS service_category,
  COALESCE(INITCAP(TRIM(service_name)), 'Unknown')    AS service_name,
  COALESCE(TRIM(hospital_branch), 'Unknown')          AS hospital_branch,
  COALESCE(INITCAP(TRIM(city)), 'Unknown')            AS city,
  COALESCE(INITCAP(TRIM(region)), 'Unknown')          AS region,
  COALESCE(INITCAP(TRIM(payer_type)), 'Unknown')      AS payer_type,
  quantity,
  unit_price,
  COALESCE(total_amount, quantity * unit_price)      AS total_amount,
  COALESCE(insurance_amount, 0)                       AS insurance_amount,
  COALESCE(INITCAP(TRIM(payment_status)), 'Unknown')  AS payment_status
FROM hospital_billing.default.bronze_hospital_billing;
 
CREATE OR REFRESH MATERIALIZED VIEW hospital_billing.default.silver_billing_rejected AS
SELECT *,
  CASE WHEN quantity IS NULL OR quantity <= 0 THEN 'Quantity is null, zero or negative'
       ELSE 'Unit price is null or negative' END AS reject_reason
FROM hospital_billing.default.bronze_hospital_billing
WHERE quantity IS NULL OR quantity <= 0
   OR unit_price IS NULL OR unit_price < 0;
