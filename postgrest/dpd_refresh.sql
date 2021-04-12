-- refresh script for DPD api

create schema dpd_previous;

create table dpd_previous.active_ingredients as select * from dpd_current.active_ingredients;
create table dpd_previous.companies as select * from dpd_current.companies;
create table dpd_previous.drug_product as select * from dpd_current.drug_product;
create table dpd_previous.form as select * from dpd_current.form;
create table dpd_previous.packaging as select * from dpd_current.packaging;
create table dpd_previous.pharmaceutical_std as select * from dpd_current.pharmaceutical_std;
create table dpd_previous.product_monographs as select * from dpd_current.product_monographs;
create table dpd_previous.route as select * from dpd_current.route;
create table dpd_previous.schedule as select * from dpd_current.schedule;
create table dpd_previous.status as select * from dpd_current.status;
create table dpd_previous.therapeutic_class as select * from dpd_current.therapeutic_class;
create table dpd_previous.vet_species as select * from dpd_current.vet_species;
create table dpd_previous.special_identifier as select * from dpd_current.special_identifier;


refresh materialized view dpd_current.active_ingredients;
refresh materialized view dpd_current.companies;
refresh materialized view dpd_current.drug_product;
refresh materialized view dpd_current.form;
refresh materialized view dpd_current.packaging;
refresh materialized view dpd_current.pharmaceutical_std;
refresh materialized view dpd_current.product_monographs;
refresh materialized view dpd_current.route;
refresh materialized view dpd_current.schedule;
refresh materialized view dpd_current.status;
refresh materialized view dpd_current.therapeutic_class;
refresh materialized view dpd_current.vet_species;
refresh materialized view dpd_current.special_identifier;

truncate dpd_api.drug_product cascade;
insert into dpd_api.drug_product (SELECT * FROM dpd_current.drug_product);


insert into dpd_api.active_ingredient SELECT a.* FROM dpd_current.active_ingredients a
JOIN dpd_api.drug_product b using (drug_code)
on conflict do nothing;


insert into dpd_api.companies SELECT a.* FROM dpd_current.companies a
JOIN dpd_api.drug_product b using (drug_code)
on conflict do nothing;


insert into dpd_api.packaging SELECT a.* FROM dpd_current.packaging a
JOIN dpd_api.drug_product b using (drug_code)
on conflict do nothing;


insert into dpd_api.pharmaceutical_form SELECT a.* FROM dpd_current.form a
JOIN dpd_api.drug_product b using (drug_code)
on conflict do nothing;


insert into dpd_api.pharmaceutical_std SELECT a.* FROM dpd_current.pharmaceutical_std a
JOIN dpd_api.drug_product b using (drug_code)
on conflict do nothing;


insert into dpd_api.product_monographs SELECT a.* FROM dpd_current.product_monographs a
JOIN dpd_api.drug_product b using (drug_code)
on conflict do nothing;


insert into dpd_api.route SELECT a.* FROM dpd_current.route a
JOIN dpd_api.drug_product b using (drug_code)
on conflict do nothing;


insert into dpd_api.schedule SELECT a.* FROM dpd_current.schedule a
JOIN dpd_api.drug_product b using (drug_code)
on conflict do nothing;


insert into dpd_api.status SELECT a.* FROM dpd_current.status a
JOIN dpd_api.drug_product b using (drug_code)
on conflict do nothing;


insert into dpd_api.therapeutic_class SELECT a.* FROM dpd_current.therapeutic_class a
JOIN dpd_api.drug_product b using (drug_code)
on conflict do nothing;


insert into dpd_api.vet_species SELECT a.* FROM dpd_current.vet_species a
JOIN dpd_api.drug_product b using (drug_code)
on conflict do nothing;

insert into dpd_api.special_identifier SELECT a.* dpd_current.special_identifier a
JOIN dpd_api.drug_product b using (drug_code)
on conflict do nothing;

truncate dpd_api.dpd_json;
insert into dpd_api.dpd_json   
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
			                            from (select drug_code, array_agg(distinct(ingredient)) as ingredient
			                                  from dpd_api.active_ingredient
			                                  where drug_code = drug.drug_code
			                                  group by drug_code
			                                  ) ais),
			'active_ingredients_f', (select to_jsonb(ais_f.ingredient_f)
			                            from (select drug_code, array_agg(distinct(ingredient_f)) as ingredient_f
			                                  from dpd_api.active_ingredient
			                                  where drug_code = drug.drug_code
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
		

-- dpd_search

truncate dpd_api.dpd_search;
insert into dpd_api.dpd_search 
(SELECT extract, 
drug_code,
drug_identification_number,
drug_product, 
to_tsvector('english', drug_product::text) as search
FROM dpd_api.dpd_json);

--dpd_lookup
truncate dpd_api.dpd_lookup;
insert into dpd_api.dpd_lookup (
  SELECT
        drug_product.drug_code,
        drug_product.drug_identification_number,
        drug_product.brand_name,
        companies.company_name,
        active_ingredient.ingredient
   FROM dpd_api.drug_product
    JOIN dpd_api.companies USING (drug_code)
    JOIN dpd_api.active_ingredient USING (drug_code));

do $$ begin execute format('alter schema dpd_previous rename to "dpd_live_%s"',now()::date); end; $$;
insert into dpd_current.update_history default values;