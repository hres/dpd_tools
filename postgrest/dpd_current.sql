-- Create dpd_current schema and materialized views

DROP SCHEMA IF EXISTS dpd_current CASCADE;
CREATE SCHEMA dpd_current;

CREATE TABLE "update_history" (
  "update_id" serial NOT NULL,
  "update_date" timestamptz NOT NULL DEFAULT now()
);

CREATE MATERIALIZED VIEW dpd_current.drug_product AS (
  SELECT CASE
                  WHEN (se."external_status_english" = 'Marketed') THEN ('active')
                  WHEN (se."external_status_english" = 'Dormant') THEN ('dormant')
                  WHEN ("external_status_english" = 'Approved') THEN ('approved')
                  WHEN (TRUE) THEN ('inactive')
                  END 
                  AS "extract", 
        dp."drug_code", 
        dp."class", 
        dp."drug_identification_number", 
        dp."brand_name", 
        dp."descriptor", 
        CAST(dp."number_of_ais" AS INTEGER) AS "number_of_ais", 
        dp."ai_group_no", 
        dp."class_f", 
        dp."descriptor_f", 
        dp."brand_name_f",
        dp."risk_man_plan",
        NOW() as "last_refresh"
        FROM remote."wqry_drug_product" as dp
        LEFT JOIN remote."wqry_status" AS s ON (dp."drug_code" = s. "drug_code")
        LEFT JOIN remote."wqry_status_external" AS se ON (s."external_status_code" = se."external_status_code")  
);

CREATE MATERIALIZED VIEW dpd_current.active_ingredients AS (
  SELECT "drug_code", 
          "id" AS active_ingredient_id,
          "active_ingredient_code", 
          "ingredient", 
          "strength", 
          "strength_unit", 
          "dosage_value", 
          "dosage_unit", 
          "ingredient_f", 
          "dosage_unit_f", 
          "strength_unit_f",
          NOW() as "last_refresh"
FROM remote."wqry_active_ingredients");

CREATE MATERIALIZED VIEW dpd_current.companies AS (
   SELECT dp."drug_code", 
    c."mfr_code", 
    c."company_code", 
    c."company_name", 
    c."company_type", 
    c."suite_numner" AS "suite_number",
    c."street_name",
    c."city_name", 
    c."province", 
    c."country", 
    c."postal_code", 
    c."post_office_box", 
    c."street_name_f", 
    c."province_f", 
    c."country_f",
    NOW() as "last_refresh"
FROM remote."wqry_drug_product" dp
LEFT JOIN remote."wqry_companies" c
  ON (dp."company_code" = c."company_code")
);

CREATE MATERIALIZED VIEW dpd_current.packaging AS (
  SELECT "drug_code",
        "upc",
        "package_size",
        "package_size_unit",
        "package_type",
        "product_information",
        "wqry_packaging_id",
        NOW() as "last_refresh"
  FROM remote.wqry_packaging);
  
CREATE MATERIALIZED VIEW dpd_current.form AS (
  SELECT "drug_code",
        "pharmaceutical_form",
        "pharmaceutical_form_code",
        "pharmaceutical_form_f",
        NOW() as "last_refresh"
  FROM remote.wqry_form);
  
CREATE MATERIALIZED VIEW dpd_current.pharmaceutical_std AS (
  SELECT "drug_code",
        "pharmaceutical_std",
        NOW() as "last_refresh"
  FROM remote.wqry_pharmaceutical_std);
  
CREATE MATERIALIZED VIEW dpd_current.route AS (
  SELECT "drug_code",
        "route_of_administration",
        "route_of_administration_code",
        "route_of_administration_f",
        NOW() as "last_refresh"
  FROM remote.wqry_route);
  
CREATE MATERIALIZED VIEW dpd_current.schedule AS (
  SELECT "drug_code",
        "schedule",
        "schedule_code",
        "schedule_f",
        NOW() as "last_refresh"
  FROM remote.wqry_schedule);
  
  
CREATE MATERIALIZED VIEW dpd_current.status AS (
  SELECT s."drug_code", 
  'Y'::text AS "current_status_flag", 
  se."external_status_english" AS "status", 
  s."history_date", 
  se."external_status_french" AS "status_f", 
  s."lot_number", 
  s."expiration_date", 
  s."first_marketed_date", 
  s."original_market_date",
  NOW() as "last_refresh"
FROM remote.wqry_status s
  LEFT JOIN remote.wqry_status_external se
  ON (s."external_status_code" = se."external_status_code")
); 

CREATE MATERIALIZED VIEW dpd_current.therapeutic_class AS (
SELECT atc."drug_code",
atc."tc_atc_number", 
atc."tc_atc", 
atc."tc_atc_f",
ahfs."tc_ahfs_number",
ahfs."tc_ahfs",
ahfs."tc_ahfs_f",
NOW() as "last_refresh"
FROM remote."wqry_atc" atc
  LEFT JOIN remote."wqry_ahfs" ahfs
  ON (atc."drug_code" = ahfs."drug_code"));
  
CREATE MATERIALIZED VIEW dpd_current.vet_species AS (
  SELECT "drug_code",
        "vet_species",
        "vet_species_f",
        NOW() as "last_refresh"
  FROM remote.wqry_drug_veterinary_species);
  
CREATE MATERIALIZED VIEW dpd_current.product_monographs AS (
  SELECT "drug_code",
        "pm_number",
        "pm_ver_number",
        "pm_control_number",
        "pm_date",
        "pm_english_fname",
        "pm_french_fname",
        NOW() as "last_refresh"
  FROM remote.wqry_pm_drug);
  
CREATE MATERIALIZED VIEW dpd_current.special_identifer AS (
  SELECT "id",
        "drug_code",
        "si_code",
        "desc_e",
        "desc_f",
        "date_assigned",
        NOW() as "last_refresh"
  FROM remote.wqry_special_identifier);
  
CREATE INDEX companies_drug_code ON dpd_current.companies USING btree (drug_code);
CREATE INDEX packaging_drug_code ON dpd_current.packaging USING btree (drug_code);
CREATE INDEX pharmaceutical_form_drug_code ON dpd_current.form USING btree (drug_code);
CREATE INDEX pharmaceutical_std_drug_code ON dpd_current.pharmaceutical_std USING btree (drug_code);
CREATE INDEX schedule_drug_code ON dpd_current.schedule USING btree (drug_code);
CREATE INDEX status_drug_code ON dpd_current.status USING btree (drug_code);
CREATE INDEX active_ingredient_drug_code ON dpd_current.active_ingredients USING btree (drug_code);
CREATE INDEX therapeutic_class_drug_code ON dpd_current.therapeutic_class USING btree (drug_code);
CREATE INDEX route_drug_code ON dpd_current.route USING btree (drug_code);
CREATE INDEX vet_drug_code ON dpd_current.vet_species USING btree (drug_code);
CREATE INDEX sp_id ON dpd_current.special_identifier USING btree (id);
CREATE INDEX sp_drug_code ON dpd_current.special_identifier USING btree (drug_code);





GRANT USAGE ON SCHEMA dpd_current TO dpd_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA dpd_current TO dpd_reader;
GRANT USAGE ON SCHEMA dpd_current TO anon;
GRANT SELECT ON ALL TABLES IN SCHEMA dpd_current TO anon;
