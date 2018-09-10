-- Create foreign data wrapper for DPD
-- dbserver needs to be a connect string (w/o user/pass) that works with sqlplus
-- Make sure oracle_fdw is installed on postgres cluster


-- CREATE ROLE dpd_owner;
-- GRANT dpd_owner to [insert your user here];
-- CREATE DATABASE dpd with owner = dpd_owner template = template0 ENCODING = 'UTF-8' LC_CTYPE = 'en_US.utf8' LC_COLLATE = 'en_US.utf8';


CREATE EXTENSION oracle_fdw;
CREATE SERVER [replace_with_an_alias] FOREIGN DATA WRAPPER oracle_fdw OPTIONS (dbserver '[replace_with_oracle_host]:1521/[repalce_with_oracle_database_name]');
GRANT USAGE ON FOREIGN [replace_with_an_alias] TO dpd_owner;
CREATE USER MAPPING FOR PUBLIC SERVER [replace_with_an_alias] (user '[replace_with_real_oracle_user]', password '[replace_with_real_password]');
CREATE SCHEMA remote;
IMPORT FOREIGN SCHEMA "[replace_with_oracle_namespace]" FROM SERVER [replace_with_an_alias] INTO remote options(case 'lower', readonly 'true');

-- Adding prefetch can speed things up a lot, but not rquired for DPD
-- ALTER FOREIGN TABLE wqry_drug_product OPTIONS (ADD prefetch '10240');


