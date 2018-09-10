# DPD Online analysis

library(dplyr)
library(dtplyr)
library(dbplyr)
library(data.table)
library(lubridate)
library(stringr)
library(magrittr)
library(testthat)
library(purrr)
library(tibble)


dpd_remote <- src_postgres(dbname = "dpd",
                         host = "rest.hc.local",
                         port = 5432,
                         user = Sys.getenv("rest_user"),
                         password = Sys.getenv("rest_password"),
                         options = "-c search_path=remote")

dpd_current <- src_postgres(dbname = "dpd",
                            host = "rest.hc.local",
                            port = 5432,
                            user = Sys.getenv("rest_user"),
                            password = Sys.getenv("rest_password"),
                            options = "-c search_path=dpd_current")

wqry_drug_product <- tbl(dpd_remote, "wqry_drug_product")
wqry_active_ingredients <- tbl(dpd_remote, "wqry_active_ingredients")
wqry_ahfs <- tbl(dpd_remote, "wqry_ahfs")
wqry_atc <- tbl(dpd_remote, "wqry_atc")
wqry_companies <- tbl(dpd_remote, "wqry_companies")
wqry_drug_veterinary_species <- tbl(dpd_remote, "wqry_drug_veterinary_species")
wqry_form <- tbl(dpd_remote, "wqry_form")
wqry_packaging <- tbl(dpd_remote, "wqry_packaging")
wqry_pm_drug <- tbl(dpd_remote, "wqry_pm_drug")
wqry_route <- tbl(dpd_remote, "wqry_route")
wqry_schedule <- tbl(dpd_remote, "wqry_schedule")
wqry_status <- tbl(dpd_remote, "wqry_status")
wqry_status_external <- tbl(dpd_remote, "wqry_status_external")
wqry_tc_for_atc <- tbl(dpd_remote, "wqry_tc_for_atc")
wqry_pharmaceutical_std <- tbl(dpd_remote, "wqry_pharmaceutical_std")

pm <- tbl(dpd_current, "product_monographs")

pm_max <- pm %>% 
          arrange(drug_code, desc(pm_date), desc(pm_english_fname)) %>%
          group_by(drug_code) %>%
          filter(if_else(n() == 1, TRUE, pm_english_fname == max(pm_english_fname, na.rm = TRUE))) %>%
          ungroup()

status <- tbl(dpd_current, "status")

drug_product <- wqry_drug_product %>% 
                left_join(wqry_status) %>%
                left_join(wqry_status_external) %>%
                select(extract = external_status_english,
                       drug_code,
                       class,
                       drug_identification_number,
                       brand_name,
                       descriptor,
                       number_of_ais,
                       ai_group_no,
                       class_f,
                       descriptor_f,
                       brand_name_f) %>%
                mutate(extract = case_when(extract == "Marketed" ~ "active",
                                           extract == "Dormant" ~ "dormant",
                                           extract == "Approved" ~ "approved",
                                           TRUE ~ "inactive")) %>%
                mutate(number_of_ais = as.integer(number_of_ais))

active_ingredients <- wqry_active_ingredients %>%
                      select(drug_code,
                             active_ingredient_code,
                             ingredient,
                             strength,
                             strength_unit,
                             dosage_value,
                             dosage_unit,
                             ingredient_f,
                             dosage_unit_f,
                             strength_unit_f) 

companies <- wqry_drug_product %>%
             select(drug_code, company_code) %>%
             left_join(wqry_companies) %>%
             select(drug_code,
                    mfr_code,
                    company_code,
                    company_name,
                    company_type,
                    suite_number = suite_numner,
                    city_name,
                    province,
                    country,
                    postal_code,
                    post_office_box,
                    street_name_f,
                    province_f,
                    country_f)
                    
packaging <- wqry_packaging %>%
  left_join(wqry_status %>% select(drug_code, external_status_code)) %>%
  left_join(wqry_status_external %>% select(external_status_code, external_status_english)) %>%
  mutate(extract = case_when(external_status_english == "Marketed" ~ "active",
                             external_status_english == "Dormant" ~ "dormant",
                             external_status_english == "Approved" ~ "approved",
                             TRUE ~ "inactive")) %>%
  select(extract,
         everything(),
         -wqry_packaging_id,
         -external_status_code,
         -external_status_english)

pharmaceutical_form <- wqry_form %>%
  left_join(wqry_status %>% select(drug_code, external_status_code)) %>%
  left_join(wqry_status_external %>% select(external_status_code, external_status_english)) %>%
  mutate(extract = case_when(external_status_english == "Marketed" ~ "active",
                             external_status_english == "Dormant" ~ "dormant",
                             external_status_english == "Approved" ~ "approved",
                             TRUE ~ "inactive")) %>%
  select(extract,
         everything(),
         -inactive_date,
         -external_status_code,
         -external_status_english)

pharmaceutical_std <- wqry_pharmaceutical_std %>%
  left_join(wqry_status %>% select(drug_code, external_status_code)) %>%
  left_join(wqry_status_external %>% select(external_status_code, external_status_english)) %>%
  mutate(extract = case_when(external_status_english == "Marketed" ~ "active",
                             external_status_english == "Dormant" ~ "dormant",
                             external_status_english == "Approved" ~ "approved",
                             TRUE ~ "inactive")) %>%
  select(extract,
         everything(),
         -external_status_code,
         -external_status_english)

route <- wqry_route %>%
  left_join(wqry_status %>% select(drug_code, external_status_code)) %>%
  left_join(wqry_status_external %>% select(external_status_code, external_status_english)) %>%
  mutate(extract = case_when(external_status_english == "Marketed" ~ "active",
                             external_status_english == "Dormant" ~ "dormant",
                             external_status_english == "Approved" ~ "approved",
                             TRUE ~ "inactive")) %>%
  select(extract,
         everything(),
         -inactive_date,
         -external_status_code,
         -external_status_english)

schedule <- wqry_schedule %>%
  left_join(wqry_status %>% select(drug_code, external_status_code)) %>%
  left_join(wqry_status_external %>% select(external_status_code, external_status_english)) %>%
  mutate(extract = case_when(external_status_english == "Marketed" ~ "active",
                             external_status_english == "Dormant" ~ "dormant",
                             external_status_english == "Approved" ~ "approved",
                             TRUE ~ "inactive")) %>%
  select(extract,
         everything(),
         -inactive_date,
         -external_status_code,
         -external_status_english)

status <- wqry_status %>% 
  mutate(current_status_flag = "Y") %>%
  left_join(wqry_status_external) %>%
  select(drug_code,
         current_status_flag,
         status = external_status_english,
         history_date,
         status_f = external_status_french,
         lot_number,
         expiration_date,
         first_marketed_date, 
         original_market_date)

therapeutic_class <- wqry_atc %>%
  left_join(wqry_ahfs)


vet_species <- wqry_drug_veterinary_species %>%
  left_join(wqry_status %>% select(drug_code, external_status_code)) %>%
  left_join(wqry_status_external %>% select(external_status_code, external_status_english)) %>%
  mutate(extract = case_when(external_status_english == "Marketed" ~ "active",
                             external_status_english == "Dormant" ~ "dormant",
                             external_status_english == "Approved" ~ "approved",
                             TRUE ~ "inactive")) %>%
  select(extract,
         everything(),
         -external_status_code,
         -external_status_english,
         -vet_species_code)

product_monographs <- wqry_pm_drug %>%
  left_join(wqry_status %>% select(drug_code, external_status_code)) %>%
  left_join(wqry_status_external %>% select(external_status_code, external_status_english)) %>%
  mutate(extract = case_when(external_status_english == "Marketed" ~ "active",
                             external_status_english == "Dormant" ~ "dormant",
                             external_status_english == "Approved" ~ "approved",
                             TRUE ~ "inactive")) %>%
  select(extract,
         everything(),
         -external_status_code,
         -external_status_english)