CREATE OR REPLACE FUNCTION dpd_update_history(new_schema text, old_schema text) RETURNS VOID
LANGUAGE plpgsql AS
$$
DECLARE
  current_table text;
  cte_new text;
  cte_old text;
  insert_qry text;
  full_query text;
  row_count integer;
  
BEGIN 
RAISE NOTICE 'Updating DPD history table from schema % to schema %', old_schema, new_schema;

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
   WHERE  schemaname = old_schema
   AND    tablename  = current_table
   ));
      cte_new = format($sql$
          WITH new AS (SELECT last_refresh::timestamptz as date_updated, 
               %1$L::text as table_name,
                    drug_code::integer,
                    CASE WHEN to_json(s.*)::jsonb ? 'active_ingredient_id'
                    THEN (to_json(s.*)::jsonb - 'last_refresh' - 'active_ingredient_id')::jsonb 
                    WHEN to_json(s.*)::jsonb ? 'id'
                    THEN (to_json(s.*)::jsonb - 'last_refresh' - 'id')::jsonb
                    WHEN to_json(s.*)::jsonb ? 'wqry_packaging_id'
                    THEN (to_json(s.*)::jsonb - 'last_refresh' - 'wqry_packaging_id')::jsonb
                    ELSE (to_json(s.*)::jsonb - 'last_refresh')::jsonb
                    END as row
                    FROM %2$I.%1$I s),
                    $sql$, current_table, new_schema);
cte_old = format($sql$
            old AS (
                    SELECT MAX(new.last_refresh)::timestamptz as date_updated, 
               %1$L::text as table_name,
                    drug_code::integer,
                    CASE WHEN to_json(s.*)::jsonb ? 'active_ingredient_id'
                    THEN (to_json(s.*)::jsonb - 'last_refresh' - 'active_ingredient_id')::jsonb 
                    WHEN to_json(s.*)::jsonb ? 'id'
                    THEN (to_json(s.*)::jsonb - 'last_refresh' - 'id')::jsonb
                    WHEN to_json(s.*)::jsonb ? 'wqry_packaging_id'
                    THEN (to_json(s.*)::jsonb - 'last_refresh' - 'wqry_packaging_id')::jsonb
                    ELSE (to_json(s.*)::jsonb - 'last_refresh')::jsonb
                    END as row
                    FROM %2$I.%1$I s
                    JOIN %3$I.%1$I new using (drug_code)
                    GROUP BY drug_code, row)
                    $sql$,
                     current_table, old_schema, new_schema);
insert_qry = format($sql$
              INSERT INTO dpd_current.dpd_history (date_updated, table_name, drug_code, row, status)
                      (select new.date_updated,
                              new.table_name,
                              new.drug_code,
                              x.row,
                              'Added' as status from
                              (select row from new
                              except select row from old) x
                              join new using (row)
                        )
                        union
                        (select old.date_updated,
                          old.table_name,
                          old.drug_code,
                          x.row,
                          'Deleted' as status from
                          (select row from old
                            except select row from new) x
                            join old using (row))
                            $sql$);
                            
full_query = cte_new || cte_old || insert_qry;

      EXECUTE full_query;
      GET DIAGNOSTICS row_count = ROW_COUNT;
      RAISE NOTICE 'Inserted % rows into %', row_count, current_table;
  END LOOP;
END;
$$
