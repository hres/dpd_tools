-- Create schema dpd_api
DROP SCHEMA IF EXISTS dpd_api CASCADE;
CREATE SCHEMA dpd_api;

CREATE TABLE dpd_api.drug_product AS (SELECT * FROM dpd_current.drug_product);
ALTER TABLE dpd_api.drug_product ADD PRIMARY KEY (drug_code);

CREATE TABLE dpd_api.active_ingredient AS (SELECT * FROM dpd_current.active_ingredients);
ALTER TABLE dpd_api.active_ingredient ADD PRIMARY KEY (active_ingredient_id);
ALTER TABLE dpd_api.active_ingredient ADD CONSTRAINT active_ingredient_drug_code_fkey FOREIGN KEY (drug_code) REFERENCES dpd_api.drug_product(drug_code) NOT DEFERRABLE;

CREATE TABLE dpd_api.companies AS (select distinct on (drug_code, company_code) *
from dpd_current.companies
order by drug_code, company_code, city_name nulls last);
-- DELETE FROM dpd_api.companies WHERE "company_code" = '17052' AND "street_name" IS NULL;
-- DELETE FROM dpd_api.companies WHERE "company_code" = '14412' AND "street_name" IS NULL;
ALTER TABLE dpd_api.companies ADD PRIMARY KEY (drug_code, company_code);
ALTER TABLE dpd_api.companies ADD CONSTRAINT companies_drug_code_fkey FOREIGN KEY (drug_code) REFERENCES dpd_api.drug_product(drug_code) NOT DEFERRABLE;

CREATE TABLE dpd_api.packaging AS (SELECT * FROM dpd_current.packaging);
ALTER TABLE dpd_api.packaging ADD CONSTRAINT packaging_drug_code_fkey FOREIGN KEY (drug_code) REFERENCES dpd_api.drug_product(drug_code) NOT DEFERRABLE;

CREATE TABLE dpd_api.pharmaceutical_form AS (SELECT * FROM dpd_current.form);
ALTER TABLE dpd_api.pharmaceutical_form ADD CONSTRAINT pharmaceutical_form_drug_code_fkey FOREIGN KEY (drug_code) REFERENCES dpd_api.drug_product(drug_code) NOT DEFERRABLE;

CREATE TABLE dpd_api.pharmaceutical_std AS (SELECT * FROM dpd_current.pharmaceutical_std);
-- ALTER TABLE dpd_api.pharmaceutical_std ADD CONSTRAINT pharmaceutical_std_drug_code_fkey FOREIGN KEY (drug_code) REFERENCES dpd_api.drug_product(drug_code) NOT DEFERRABLE;

CREATE TABLE dpd_api.product_monographs AS (SELECT * FROM dpd_current.product_monographs);
ALTER TABLE dpd_api.product_monographs ADD CONSTRAINT product_monographs_drug_code_fkey FOREIGN KEY (drug_code) REFERENCES dpd_api.drug_product(drug_code) NOT DEFERRABLE;

CREATE TABLE dpd_api.route AS (SELECT * FROM dpd_current.route);
ALTER TABLE dpd_api.route ADD CONSTRAINT route_drug_code_fkey FOREIGN KEY (drug_code) REFERENCES dpd_api.drug_product(drug_code) NOT DEFERRABLE;

CREATE TABLE dpd_api.schedule AS (SELECT * FROM dpd_current.schedule);
ALTER TABLE dpd_api.schedule ADD CONSTRAINT schedule_drug_code_fkey FOREIGN KEY (drug_code) REFERENCES dpd_api.drug_product(drug_code) NOT DEFERRABLE;

CREATE TABLE dpd_api.status AS (SELECT * FROM dpd_current.status);
ALTER TABLE dpd_api.status ADD CONSTRAINT status_drug_code_fkey FOREIGN KEY (drug_code) REFERENCES dpd_api.drug_product(drug_code) NOT DEFERRABLE;

CREATE TABLE dpd_api.therapeutic_class AS (SELECT * FROM dpd_current.therapeutic_class);
ALTER TABLE dpd_api.therapeutic_class ADD CONSTRAINT ther_drug_code_fkey FOREIGN KEY (drug_code) REFERENCES dpd_api.drug_product(drug_code) NOT DEFERRABLE;

CREATE TABLE dpd_api.vet_species AS (SELECT * FROM dpd_current.vet_species);
ALTER TABLE dpd_api.vet_species ADD CONSTRAINT vet_drug_code_fkey FOREIGN KEY (drug_code) REFERENCES dpd_api.drug_product(drug_code) NOT DEFERRABLE;

CREATE TABLE dpd_api.special_identifier AS (SELECT * FROM dpd_current.special_identifier);
ALTER TABLE dpd_api.special_identifier ADD CONSTRAINT sp_drug_code_fkey FOREIGN KEY (drug_code) REFERENCES dpd_api.drug_product(drug_code) NOT DEFERRABLE;

CREATE INDEX companies_drug_code ON dpd_api.companies USING btree (drug_code);
CREATE INDEX packaging_drug_code ON dpd_api.packaging USING btree (drug_code);
CREATE INDEX pharmaceutical_form_drug_code ON dpd_api.pharmaceutical_form USING btree (drug_code);
CREATE INDEX pharmaceutical_std_drug_code ON dpd_api.pharmaceutical_std USING btree (drug_code);
CREATE INDEX schedule_drug_code ON dpd_api.schedule USING btree (drug_code);
CREATE INDEX status_drug_code ON dpd_api.status USING btree (drug_code);
CREATE INDEX active_ingredient_drug_code ON dpd_api.active_ingredient USING btree (drug_code);
CREATE INDEX active_ingredient_ingredient ON dpd_api.active_ingredient USING btree (ingredient);
CREATE INDEX therapeutic_class_drug_code ON dpd_api.therapeutic_class USING btree (drug_code);
CREATE INDEX route_drug_code ON dpd_api.route USING btree (drug_code);
CREATE INDEX vet_drug_code ON dpd_api.vet_species USING btree (drug_code);
CREATE INDEX product_monograph_drug_code ON dpd_api.product_monographs USING btree (drug_code);
CREATE INDEX product_monograph_pm_fname_eng ON dpd_api.product_monographs USING btree (pm_english_fname);
CREATE INDEX product_monograph_pm_fname_fr ON dpd_api.product_monographs USING btree (pm_french_fname);
CREATE INDEX sp_drug_code ON dpd_api.special_identifier USING btree (drug_code);


-- dpd_json

CREATE TABLE dpd_api.dpd_json AS  
	(
	SELECT drug.extract, drug.drug_code, drug.drug_identification_number,
		
		JSONB_STRIP_NULLS(
		JSONB_BUILD_OBJECT(
			'extract', drug.extract,
			'drug_code', drug.drug_code,
			'class', class,
			'drug_identification_number', 
			  COALESCE((select desc_e from dpd_api.special_identifier where drug_code = drug.drug_code), 
			  drug_identification_number),
			'brand_name', brand_name,
			'descriptor', NULLIF(descriptor, ''),
			'number_of_ais', number_of_ais,
			'ai_group_no', ai_group_no,
      'class_f', class_f,
      'descriptor_f', NULLIF(descriptor_f, ''),
      'brand_name_f', brand_name_f,
      'risk_man_plan', risk_man_plan,
      'last_refresh', last_refresh,
			'company', (
			  SELECT TO_JSONB(c)
			  FROM (
			    SELECT
			      NULLIF(mfr_code, '') AS mfr_code,
			      company_code,
			      company_name,
			      company_type,
			      suite_number,
			      street_name,
			      city_name,
			      province,
			      country,
			      postal_code,
			      post_office_box,
                              street_name_f,
                              province_f,
                              country_f
			    FROM dpd_api.companies
					WHERE drug_code = drug.drug_code
					) c),
			'active_ingredients', (select to_jsonb(ais.ingredient)
			                            from (select drug_code, 
			                            array_agg(ingredient) as ingredient, 
			                            array_agg(ingredient_f) as ingredient_f
                                  from (
                                    select distinct on (drug_code, ingredient) drug_code, 
                                    ingredient, 
                                    ingredient_f
                                    from dpd_api.active_ingredient
                                    where drug_code = drug.drug_code
                                    order by drug_code, ingredient
                                ) i
                                group by drug_code
			                                  ) ais),
			'active_ingredients_f', (select to_jsonb(ais_f.ingredient_f)
			                            from (select drug_code, 
			                            array_agg(ingredient) as ingredient, 
			                            array_agg(ingredient_f) as ingredient_f
                                  from (
                                    select distinct on (drug_code, ingredient) drug_code, 
                                    ingredient, 
                                    ingredient_f
                                    from dpd_api.active_ingredient
                                    where drug_code = drug.drug_code
                                    order by drug_code, ingredient
                                ) i
                                group by drug_code
			                                  ) ais_f),
			'active_ingredients_detail', (
				SELECT JSONB_AGG(TO_JSONB(ai))
				FROM (
					SELECT
						active_ingredient_code,
						ingredient,
						strength,
						strength_unit,
						NULLIF(dosage_value, '') as dosage_value,
						NULLIF(dosage_unit, '') as dosage_unit,
                                                ingredient_f,
                                                dosage_unit_f,
                                                strength_unit_f
					FROM dpd_api.active_ingredient
					WHERE drug_code = drug.drug_code
					ORDER BY ingredient
					) ai),
				'dosage_form', (
				  SELECT DISTINCT TO_JSONB(ARRAY_AGG(pharmaceutical_form))
				  FROM dpd_api.pharmaceutical_form
				  WHERE drug_code = drug.drug_code
				    ),
				'route_f', (
				  SELECT DISTINCT TO_JSONB(ARRAY_AGG(route_of_administration_f))
				  FROM dpd_api.route
				  WHERE drug_code = drug.drug_code
				  ),
				  'dosage_form_f', (
				  SELECT DISTINCT TO_JSONB(ARRAY_AGG(pharmaceutical_form_f))
				  FROM dpd_api.pharmaceutical_form
				  WHERE drug_code = drug.drug_code
				    ),
				'route', (
				  SELECT DISTINCT TO_JSONB(ARRAY_AGG(route_of_administration))
				  FROM dpd_api.route
				  WHERE drug_code = drug.drug_code
				  ),
				'schedule', (
				  SELECT DISTINCT TO_JSONB(ARRAY_AGG(schedule))
				  FROM dpd_api.schedule
				    WHERE drug_code = drug.drug_code
				  ),
				  'schedule_f', (
				  SELECT DISTINCT TO_JSONB(ARRAY_AGG(schedule_f))
				  FROM dpd_api.schedule
				    WHERE drug_code = drug.drug_code
				  ),
				'pharmaceutical_std', (
				  SELECT COALESCE(jsonb_AGG(distinct to_jsonb(pharmaceutical_std)) FILTER (WHERE NOT (pharmaceutical_std = 'null')),
                                                    null)
				  FROM dpd_api.pharmaceutical_std
				    WHERE drug_code = drug.drug_code
				  ), 
				  'pm_date', (
				  SELECT pm_date
				  FROM (
				      SELECT "drug_code", 
				      "pm_date", 
				      "pm_english_fname", 
				      "pm_french_fname"
              FROM (SELECT "drug_code", 
                "pm_date", 
                "pm_english_fname", 
                "pm_french_fname", 
                COUNT(*) OVER (PARTITION BY "drug_code") AS pm_count, 
                max("pm_english_fname") OVER (PARTITION BY "drug_code") AS max_eng_pm
                FROM dpd_api.product_monographs
              ORDER BY "drug_code", "pm_date" DESC, "pm_english_fname" DESC) sub_query
              WHERE (CASE WHEN (pm_count = 1.0) THEN (TRUE) 
                          WHEN NOT(pm_count = 1.0) THEN ("pm_english_fname" = max_eng_pm) 
                          END)) super_sub 
				    WHERE drug_code = drug.drug_code
				  ),
				  'product_monograph_en_url', (
				  SELECT 'https://pdf.hres.ca/dpd_pm/' || pm_english_fname || '.PDF'
				  FROM (
				      SELECT "drug_code", 
				      "pm_date", 
				      "pm_english_fname", 
				      "pm_french_fname"
              FROM (SELECT "drug_code", 
                "pm_date", 
                "pm_english_fname", 
                "pm_french_fname", 
                COUNT(*) OVER (PARTITION BY "drug_code") AS pm_count, 
                max("pm_english_fname") OVER (PARTITION BY "drug_code") AS max_eng_pm
                FROM dpd_api.product_monographs
              ORDER BY "drug_code", "pm_date" DESC, "pm_english_fname" DESC) sub_query
              WHERE (CASE WHEN (pm_count = 1.0) THEN (TRUE) 
                          WHEN NOT(pm_count = 1.0) THEN ("pm_english_fname" = max_eng_pm) 
                          END)) super_sub 
				    WHERE drug_code = drug.drug_code
				  ),
				   'product_monograph_fr_url', (
				  SELECT 'https://pdf.hres.ca/dpd_pm/' || pm_french_fname || '.PDF'
				  FROM (
				      SELECT "drug_code", 
				      "pm_date", 
				      "pm_english_fname", 
				      "pm_french_fname"
              FROM (SELECT "drug_code", 
                "pm_date", 
                "pm_english_fname", 
                "pm_french_fname", 
                COUNT(*) OVER (PARTITION BY "drug_code") AS pm_count, 
                max("pm_english_fname") OVER (PARTITION BY "drug_code") AS max_eng_pm
                FROM dpd_api.product_monographs
              ORDER BY "drug_code", "pm_date" DESC, "pm_english_fname" DESC) sub_query
              WHERE (CASE WHEN (pm_count = 1.0) THEN (TRUE) 
                          WHEN NOT(pm_count = 1.0) THEN ("pm_english_fname" = max_eng_pm) 
                          END)) super_sub
				    WHERE drug_code = drug.drug_code
				  ),
				'packaging', (
				  SELECT coalesce(JSONB_AGG(TO_JSONB(pa)) FILTER (WHERE pa IS NOT NULL),
                                                  null)
				  FROM (
					  SELECT
					    NULLIF(upc, '') as upc,
					    NULLIF(package_size_unit, '') as package_size_unit,
					    NULLIF(package_type, '') as package_type,
					    NULLIF(package_size, '') as package_size,
					    NULLIF(product_information, '') as product_information
					  FROM dpd_api.packaging
					  WHERE drug_code = drug.drug_code
				    ) pa),
				'status_current', (select to_jsonb(s.status)
			                            from (select drug_code, status
			                                  from dpd_api.status
			                                  where drug_code = drug.drug_code AND current_status_flag = 'Y'
			                                  
			                                  ) s),
			   'status_current_f', (select to_jsonb(s.status_f)
			                            from (select drug_code, status_f
			                                  from dpd_api.status
			                                  where drug_code = drug.drug_code AND current_status_flag = 'Y'
			                                  
			                                  ) s),
			  'status_approved_date', (select to_jsonb(s.history_date)
			                            from (select drug_code, array_agg(history_date) as history_date
			                                  from dpd_api.status
			                                  where drug_code = drug.drug_code AND status = 'Approved'
			                                  group by drug_code
			                                  ) s),
			  'status_marketed_date', (select to_jsonb(s.history_date)
			                            from (select drug_code, array_agg(history_date) as history_date
			                                  from dpd_api.status
			                                  where drug_code = drug.drug_code AND status = 'Marketed'
			                                  group by drug_code
			                                  ) s),
			   'status_dormant_date', (select to_jsonb(s.history_date)
			                            from (select drug_code, array_agg(history_date) as history_date
			                                  from dpd_api.status
			                                  where drug_code = drug.drug_code AND status = 'Dormant'
			                                  group by drug_code
			                                  ) s),
			    'status_cancelled_premarket_date', (select to_jsonb(s.history_date)
			                            from (select drug_code, array_agg(history_date) as history_date
			                                  from dpd_api.status
			                                  where drug_code = drug.drug_code AND status = 'Cancelled Pre Market'
			                                  group by drug_code
			                                  ) s),
			     'status_cancelled_postmarket_date', (select to_jsonb(s.history_date)
			                            from (select drug_code, array_agg(history_date) as history_date
			                                  from dpd_api.status
			                                  where drug_code = drug.drug_code AND status = 'Cancelled Post Market'
			                                  group by drug_code
			                                  ) s),
				'status_detail', (
				  SELECT JSONB_AGG(TO_JSONB(st))
				  FROM (
					  SELECT
					    current_status_flag,
					    status,
					    history_date,
                                            status_f,
                                            lot_number,
                                            expiration_date,
                                            first_marketed_date,
                                            original_market_date
					  FROM dpd_api.status
					  WHERE drug_code = drug.drug_code
				    ) st),
				'therapeutic_class', (
				  SELECT JSONB_AGG(TO_JSONB(tc))
				  FROM (
					  SELECT
					    NULLIF(tc_atc_number, '') as tc_atc_number,
					    NULLIF(tc_atc, '') as tc_atc,
					    NULLIF(tc_atc_f, '') as tc_atc_f,
					    NULLIF(tc_ahfs_number, '') as tc_ahfs_number,
					    NULLIF(tc_ahfs, '') as tc_ahfs,
					    NULLIF(tc_ahfs_f, '') as tc_ahfs_f
					  FROM dpd_api.therapeutic_class
					  WHERE drug_code = drug.drug_code
				    ) tc),
				'vet_species', (
				  SELECT DISTINCT TO_JSONB(ARRAY_AGG(vet_species))
				  FROM dpd_api.vet_species
				    WHERE drug_code = drug.drug_code
				  )
		)) AS drug_product
		FROM dpd_api.drug_product drug
		); 
CREATE INDEX dpd_json_drug_code ON dpd_api.dpd_json USING BTREE (drug_code);
CREATE INDEX dpd_json_drug_identification_number ON dpd_api.dpd_json USING BTREE (drug_identification_number);


-- dpd_search

CREATE TABLE dpd_api.dpd_search AS 
(SELECT extract, 
drug_code,
drug_identification_number,
drug_product, 
to_tsvector('english', drug_product::text) as search
FROM dpd_api.dpd_json);
CREATE INDEX dpd_json_search ON dpd_api.dpd_search USING GIN (search);
CREATE INDEX dpd_jsonb ON dpd_api.dpd_search USING GIN(drug_product jsonb_path_ops);

--dpd_lookup
CREATE TABLE dpd_api.dpd_lookup AS (
  SELECT
        drug_product.drug_code,
        drug_product.drug_identification_number,
        drug_product.brand_name,
        companies.company_name,
        active_ingredient.ingredient,
        status.status,
        status.status_f
   FROM dpd_api.drug_product
    JOIN dpd_api.companies USING (drug_code)
    JOIN dpd_api.active_ingredient USING (drug_code)
    JOIN dpd_api.status USING (drug_code));

--dpd_history and dpd_temporal

CREATE VIEW dpd_api.dpd_history as (select * from dpd_current.dpd_history);
CREATE VIEW dpd_api.dpd_temporal as (sleect * from dpd_current.dpd_temporal);
-- Constraints



CREATE INDEX dpd_lookup_drug_code ON dpd_api.dpd_lookup USING btree (drug_code);
CREATE INDEX dpd_lookup_drug_identification_number ON dpd_api.dpd_lookup USING btree (drug_identification_number);
CREATE INDEX dpd_lookup_brand_name ON dpd_api.dpd_lookup USING btree (brand_name);
CREATE INDEX dpd_lookup_company_name ON dpd_api.dpd_lookup USING btree (company_name);
CREATE INDEX dpd_lookup_ingredient ON dpd_api.dpd_lookup USING btree (ingredient);
CREATE INDEX dpd_lookup_status ON dpd_api.dpd_lookup USING btree (status);
CREATE INDEX dpd_lookup_status_f ON dpd_api.dpd_lookup USING btree (status_f);

GRANT USAGE ON SCHEMA dpd_api TO anon;
GRANT USAGE ON SCHEMA dpd_api to dpd_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA dpd_api TO anon;
GRANT SELECT ON ALL TABLES IN SCHEMA dpd_api TO dpd_reader;










