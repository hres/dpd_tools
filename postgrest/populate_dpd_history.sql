-- construct dpd history

DO
$$
DECLARE
  i integer;
  new_schema text;
  old_schema text;
  schema_array text[];
  
BEGIN 
DROP INDEX dpd_current.dpd_history_date_updated;
DROP INDEX dpd_current.dpd_history_table_name;
DROP INDEX dpd_current.dpd_history_drug_code;
DROP INDEX dpd_current.dpd_history_status;
DROP INDEX dpd_current.dpd_history_row;

select array_agg(table_schema::text) 
into schema_array
from 
(select distinct table_schema from information_schema.tables
where table_catalog = 'dpd' and table_schema like 'dpd_live_%' and right(table_schema, 10)::date < '2019-06-01' and right(table_schema, 10)::date > '2018-09-01'
order by table_schema desc) x ;
  FOR i in array_lower(schema_array, 1) .. (array_upper(schema_array, 1)-1)
    LOOP
      new_schema := schema_array[i];
      old_schema := schema_array[i+1];
      RAISE NOTICE 'Updating DPD history from schema % to schema %' , old_schema, new_schema;
      PERFORM dpd_update_history(new_schema, old_schema);              
                    END LOOP;
CREATE INDEX dpd_history_date_updated ON dpd_current.dpd_history USING btree(date_updated);
CREATE INDEX dpd_history_table_name ON dpd_current.dpd_history USING btree(table_name);
CREATE INDEX dpd_history_drug_code ON dpd_current.dpd_history USING btree(drug_code);
CREATE INDEX dpd_history_status ON dpd_current.dpd_history USING btree(status);
CREATE INDEX dpd_history_row ON dpd_current.dpd_history USING gin(row);
END;
$$