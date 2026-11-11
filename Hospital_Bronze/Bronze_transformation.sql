CREATE OR REFRESH STREAMING TABLE hospital_billing.default.bronze_hospital_billing
(
    CONSTRAINT bill_id_loaded EXPECT (bill_id IS NOT NULL) ,
    CONSTRAINT visit_id_loaded EXPECT (visit_id IS NOT NULL),
    CONSTRAINT patient_id_loaded EXPECT (patient_id IS NOT NULL)
)
AS
SELECT *,
       _metadata.file_name AS file_path,
       current_timestamp() AS ingested_at
FROM STREAM read_files('/Volumes/hospital_billing/default/hospital_sales',
format => 'csv', header => true);
