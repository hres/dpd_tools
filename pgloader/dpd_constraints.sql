CREATE INDEX companies_drug_code ON pgloader.companies USING btree (extract, drug_code);
CREATE INDEX packaging_drug_code ON pgloader.packaging USING btree (extract, drug_code);
CREATE INDEX pharmaceutical_form_drug_code ON pgloader.pharmaceutical_form USING btree (extract, drug_code);
CREATE INDEX pharmaceutical_std_drug_code ON pgloader.pharmaceutical_std USING btree (extract, drug_code);
CREATE INDEX schedule_drug_code ON pgloader.schedule USING btree (extract, drug_code);
CREATE INDEX status_drug_code ON pgloader.status USING btree (extract, drug_code);
CREATE INDEX active_ingredient_drug_code ON pgloader.active_ingredient USING btree (extract, drug_code);
CREATE INDEX therapeutic_class_drug_code ON pgloader.therapeutic_class USING btree (extract, drug_code);
CREATE INDEX route_drug_code ON pgloader.route USING btree (extract, drug_code);
CREATE INDEX vet_drug_code ON pgloader.vet_species USING btree (extract, drug_code);

ALTER TABLE pgloader.drug_product ADD CONSTRAINT drug_product_drug_code PRIMARY KEY (extract, drug_code);

ALTER TABLE pgloader.packaging ADD CONSTRAINT packaging_drug_code_fkey FOREIGN KEY (extract, drug_code) REFERENCES pgloader.drug_product(extract, drug_code) NOT DEFERRABLE;

ALTER TABLE pgloader.pharmaceutical_form ADD CONSTRAINT pharmaceutical_form_drug_code_fkey FOREIGN KEY (extract, drug_code) REFERENCES pgloader.drug_product(extract, drug_code) NOT DEFERRABLE;

ALTER TABLE pgloader.pharmaceutical_std ADD CONSTRAINT pharmaceutical_std_drug_code_fkey FOREIGN KEY (extract, drug_code) REFERENCES pgloader.drug_product(extract, drug_code) NOT DEFERRABLE;

ALTER TABLE pgloader.schedule ADD CONSTRAINT schedule_drug_code_fkey FOREIGN KEY (extract, drug_code) REFERENCES pgloader.drug_product(extract, drug_code) NOT DEFERRABLE;

ALTER TABLE pgloader.status ADD CONSTRAINT status_drug_code_fkey FOREIGN KEY (extract, drug_code) REFERENCES pgloader.drug_product(extract, drug_code) NOT DEFERRABLE;

ALTER TABLE pgloader.therapeutic_class ADD CONSTRAINT ther_drug_code_fkey FOREIGN KEY (extract, drug_code) REFERENCES pgloader.drug_product(extract, drug_code) NOT DEFERRABLE;

ALTER TABLE pgloader.vet_species ADD CONSTRAINT vet_drug_code_fkey FOREIGN KEY (extract, drug_code) REFERENCES pgloader.drug_product(extract, drug_code) NOT DEFERRABLE;

ALTER TABLE pgloader.active_ingredient ADD CONSTRAINT active_ingredient_drug_code_fkey FOREIGN KEY (extract, drug_code) REFERENCES pgloader.drug_product(extract, drug_code) NOT DEFERRABLE;

ALTER TABLE pgloader.companies ADD CONSTRAINT companies_drug_code_fkey FOREIGN KEY (extract, drug_code) REFERENCES pgloader.drug_product(extract, drug_code) NOT DEFERRABLE;

ALTER TABLE pgloader.route ADD CONSTRAINT route_drug_code_fkey FOREIGN KEY (extract, drug_code) REFERENCES pgloader.drug_product(extract, drug_code) NOT DEFERRABLE;

