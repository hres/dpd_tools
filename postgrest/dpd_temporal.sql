-- Create dpd_temporal from dpd_history
drop table dpd_current.dpd_temporal;
create table dpd_current.dpd_temporal as (
with t as (
select *, 
      dense_rank() over (partition by table_name, drug_code order by date_updated) as status_order 
      from (select * from dpd_current.dpd_history
            union all
            (select distinct on (table_name, drug_code)
'-infinity'::timestamptz as date_updated, table_name, drug_code, row, 'Added' as status
from dpd_current.dpd_history a
where status = 'Deleted'
order by table_name, drug_code, a.status desc, a.date_updated)
           union all
            (select distinct on (table_name, drug_code)
'infinity'::timestamptz as date_updated, table_name, drug_code, row, 'Deleted' as status
from dpd_current.dpd_history b
where status = 'Added'
order by table_name, drug_code, b.status, b.date_updated desc)) h
)
select t.table_name, t.drug_code, t.row, 
tstzrange(t.date_updated, t2.date_updated, '[)') as systime
from t left join t t2 on t.table_name = t2.table_name and t.drug_code = t2.drug_code and t.status_order = t2.status_order -1
where t.status = 'Added' and t2.status = 'Deleted');


-- Update newest
-- deletions -> set upper range to date_updated
-- additions -> create new row with date_updated, infinity when row already exists, create new row 

-- UPDATE dpd_current.dpd_temporal t
-- SET systime = tstzrange(lower(systime), date_updated, '[)')
-- FROM (SELECT MAX(date_updated) as date_updated, table_name, drug_code, row, status
--       FROM dpd_current.dpd_history
--       WHERE status = 'Deleted'
--       GROUP BY table_name, drug_code, row, status) x
-- WHERE t.table_name = x.table_name
-- AND t.drug_code = x.drug_code
-- AND t.row = x.row
-- AND upper(t.systime) = 'infinity'::timestamptz
-- AND lower(t.systime) < x.date_updated;

-- INSERT INTO dpd_current.dpd_temporal
-- (SELECT table_name,
--         drug_code,
--         row,
--         tstzrange(date_updated, 'infinity'::timestamptz, '[)') as systime
--  FROM dpd_current.dpd_history h
--  inner join dpd_current.dpd_temporal t using (table_name, drug_code, row)
--  WHERE status = 'Added'
--  AND date_updated = upper(systime));
--  
-- INSERT INTO dpd_current.dpd_temporal
-- (SELECT table_name,
--         drug_code,
--         row,
--         tstzrange(date_updated, 'infinity'::timestamptz, '[)') as systime
--  FROM dpd_current.dpd_history h
--  WHERE status = 'Added'
--  AND NOT EXISTS (SELECT 1 FROM dpd_current.dpd_temporal t
-- where h.table_name = t.table_name AND h.drug_code =t.drug_code AND h.row = t.row)
-- );
 
 


-- Update previous records from earliest schema
DO
$$
DECLARE
 current_table text;
  row_count integer;
BEGIN
FOREACH current_table in ARRAY array['drug_product', 
                                  'active_ingredients', 
                                  'companies',
                                  'form',
                                  'packaging',
                                  'pharmaceutical_std',
                                  'product_monographs',
                                  'route',
                                  'schedule',
                                  'special_identifier',
                                  'status',
                                  'therapeutic_class',
                                  'vet_species']
    LOOP
      RAISE NOTICE 'Updating table %' , current_table;
      CONTINUE WHEN (SELECT NOT EXISTS (
   SELECT FROM pg_tables
   WHERE  schemaname = 'dpd_live_2018-09-10'
   AND    tablename  = current_table
   ));
   EXECUTE format($sql$
   INSERT INTO dpd_current.dpd_temporal 
          (SELECT 
               %1$L::text as table_name,
                    drug_code::integer,
                    CASE WHEN to_json(s.*)::jsonb ? 'active_ingredient_id'
                    THEN (to_json(s.*)::jsonb - 'last_refresh' - 'active_ingredient_id')::jsonb 
                    WHEN to_json(s.*)::jsonb ? 'id'
                    THEN (to_json(s.*)::jsonb - 'last_refresh' - 'id')::jsonb
                    WHEN to_json(s.*)::jsonb ? 'wqry_packaging_id'
                    THEN (to_json(s.*)::jsonb - 'last_refresh' - 'wqry_packaging_id')::jsonb
                    ELSE (to_json(s.*)::jsonb - 'last_refresh')::jsonb
                    END as row,
                    tstzrange(st.history_date::timestamptz,
                              'infinity'::timestamptz,
                              '[)') as systime
                    FROM "dpd_live_2018-09-10".%1$I s
                    INNER JOIN "dpd_live_2018-09-10".status st USING (drug_code)
                    WHERE drug_code NOT IN (SELECT DISTINCT drug_code from dpd_current.dpd_temporal 
                    where table_name = %1$L))
                    $sql$, current_table);
   GET DIAGNOSTICS row_count = ROW_COUNT;
      RAISE NOTICE 'Inserted % rows into %', row_count, current_table;
  END LOOP;
END;
$$;
                   
CREATE INDEX dpd_temporal_table_name ON dpd_current.dpd_temporal USING btree(table_name);
CREATE INDEX dpd_temporal_drug_code ON dpd_current.dpd_temporal USING btree(drug_code);
CREATE INDEX dpd_temporal_row ON dpd_current.dpd_temporal USING gin(row);
CREATE INDEX dpd_temporal_systime ON dpd_current.dpd_temporal USING gist(systime);