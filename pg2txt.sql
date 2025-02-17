select 'pg2txt: PostgreSQL TXT-Report on: '||current_database() as title,
       now() as report_date,
       user as by_user,
       'v.1.0.5' as version;


select 'Database :' as summary_info, current_database() as value
union all
select 'Version :', substring(version() for  position('on' in version())-1)
union all
select 'DB Size :', pg_size_pretty(sum(pg_database_size(datname)))
  from pg_database
union all
select 'Created :', (pg_stat_file('base/'||oid ||'/PG_VERSION')).modification::text
  from pg_database
 where datname='template0'
union all
select 'Started :', pg_postmaster_start_time()::text
union all
select 'Memory buffers (MB) :', trunc(sum(setting::int*8)/1024)::text
  from pg_settings
 where name in ('shared_buffers', 'wal_buffers', 'temp_buffers')
union all
select 'Work area (MB) :', trunc(sum(setting::int)/1024)::text
  from pg_settings
 where name like '%mem'
union all
select 'Wal Archiving :', setting
  from pg_settings
 where name like 'archive_mode'
union all
select 'Databases :', count(*)::text
  from pg_database
 where not datistemplate
union all
select 'Defined Users/Roles :', sum(case when rolcanlogin then 1 else 0 end)||
          ' / '|| sum(case when rolcanlogin then 0 else 1 end)
  from pg_roles
union all
select 'Defined Schemata :', count(distinct relowner)::text
  from pg_class
union all
select 'Defined Tables :', count(*)::text
  from pg_class
 where relkind='r'
union all
select 'Sessions :', count(*)::text
 from pg_stat_activity
union all
select 'Sessions (active) :', count(*)::text
  from pg_stat_activity
 where state = 'active'
union all
select 'Port  :', setting
  from pg_settings where name='port';

select version() as version
union all
select current_setting('server_version_num')
union all
select ' Latest Releases: 17.3, 16.7, 15.11, 14.16, 13.19'
union all
select ' Desupported:     12.21, 11.22, 10.23, 9.6.24, 9.5.25, 9.4.26, 9.3.25, 9.2.24,'
union all
select '                  9.1.24, 9.0.23,8.4.21, 8.3.23, 8.2.23, 8.1.23, 8.0.26, 7.4.30, 6.5.3';

select datname as database, oid::text, datdba::regrole::text,
 pg_database_size(datname) as size,
 pg_size_pretty(pg_database_size(datname)) as hr_size
  from pg_database
 where not datistemplate
union all
select 'TOTAL','', '',
 trunc(sum(pg_database_size(datname))),
 pg_size_pretty(sum(pg_database_size(datname))::int8)
from pg_database;

(select nspname as schema_matrix, rolname as owner,
 sum(case when relkind='r' THEN 1 ELSE 0 end) as table,
 sum(case when relkind='i' THEN 1 ELSE 0 end) as index,
 sum(case when relkind='p' THEN 1 ELSE 0 end) as p_tab,
 sum(case when relkind='I' THEN 1 ELSE 0 end) as p_idx,
 sum(case when relkind='v' THEN 1 ELSE 0 end) as view,
 sum(case when relkind='S' THEN 1 ELSE 0 end) as seq,
 sum(case when relkind='c' THEN 1 ELSE 0 end) as comp,
 sum(case when relkind='f' THEN 1 ELSE 0 end) as foreing,
 sum(case when relkind='t' THEN 1 ELSE 0 end) as toast,
 sum(case when relkind='m' THEN 1 ELSE 0 end) as mat_view,
 count(*) as TOTAL,
 sum(case when relkind in ('r','p') THEN case when relispartition then 1 else 0 end else 0 end) as part,
 sum(case when relkind in ('r','p') THEN case when relispartition then 0 else 1 end else 0 end) as n_part,
 sum(case when relpersistence='u' THEN 1 ELSE 0 end) as unlog,
 sum(case when relpersistence='t' THEN 1 ELSE 0 end) as temp
from pg_class, pg_roles, pg_namespace
where relowner=pg_roles.oid
  and relnamespace=pg_namespace.oid
  and rolname not in ('postgres', 'rdsadmin', 'enterprisedb')
group by rolname, nspname
order by nspname, rolname )
union all
select 'TOTAL', '',
 sum(case when relkind='r' THEN 1 ELSE 0 end),
 sum(case when relkind='i' THEN 1 ELSE 0 end),
 sum(case when relkind='p' THEN 1 ELSE 0 end),
 sum(case when relkind='I' THEN 1 ELSE 0 end),
 sum(case when relkind='v' THEN 1 ELSE 0 end),
 sum(case when relkind='S' THEN 1 ELSE 0 end),
 sum(case when relkind='c' THEN 1 ELSE 0 end),
 sum(case when relkind='f' THEN 1 ELSE 0 end),
 sum(case when relkind='t' THEN 1 ELSE 0 end),
 sum(case when relkind='m' THEN 1 ELSE 0 end),
 count(*),
 sum(case when relkind in ('r','p') THEN case when relispartition then 1 else 0 end else 0 end),
 sum(case when relkind in ('r','p') THEN case when relispartition then 0 else 1 end else 0 end),
 sum(case when relpersistence='u' THEN 1 ELSE 0 end),
 sum(case when relpersistence='t' THEN 1 ELSE 0 end)
from pg_class, pg_roles, pg_namespace
where relowner=pg_roles.oid
  and relnamespace=pg_namespace.oid
  and rolname not in ('postgres', 'rdsadmin', 'enterprisedb');

select nspname as schema_constraints,
 sum(case when contype ='p' THEN 1 ELSE 0 end) as primary,
 sum(case when contype ='u' THEN 1 ELSE 0 end) as unique,
 sum(case when contype ='f' THEN 1 ELSE 0 end) as foreign,
 sum(case when contype ='c' THEN 1 ELSE 0 end) as check,
 sum(case when contype ='t' THEN 1 ELSE 0 end) as trigger,
 sum(case when contype ='x' THEN 1 ELSE 0 end) as exclusion,
 count(*) as total
from pg_constraint, pg_namespace
where connamespace=pg_namespace.oid
  and nspname NOT IN('information_schema', 'pg_catalog')
group by nspname
order by nspname;

select nspname as schema, rolname as owner, t.relkind::text as object_type,
   count(distinct t.relname) as partitioned_object,
   count(*) as partitions
  from pg_class t, pg_inherits i, pg_class p, pg_roles r, pg_namespace n
 where i.inhparent = t.oid 
   and p.oid = i.inhrelid
   and t.relowner=r.oid
   and t.relnamespace=n.oid
 group by rolname, nspname, t.relkind
 order by t.relkind desc, nspname, rolname;

(select nspname as schema, rolname as owner, 
  sum(case when prokind='p' THEN 0 ELSE 1 end) as functions,
  sum(case when prokind='p' THEN 1 ELSE 0 end) as procedures,
  count(*) as total
  from pg_proc, pg_roles, pg_language, pg_namespace n
 where proowner=pg_roles.oid
   and prolang=pg_language.oid
   and pronamespace=n.oid
   and rolname not in ('postgres', 'enterprisedb')
 group by nspname, rolname
 order by nspname, rolname)
union all
select 'TOTAL', '',
  sum(case when prokind='p' THEN 0 ELSE 1 end),
  sum(case when prokind='p' THEN 1 ELSE 0 end),
  count(*)
  from pg_proc, pg_roles, pg_language, pg_namespace n
 where proowner=pg_roles.oid
   and prolang=pg_language.oid
   and pronamespace=n.oid
   and rolname not in ('postgres', 'enterprisedb');

select trigger_schema,
 sum(case when event_manipulation='INSERT' THEN 1 ELSE 0 end) as insert,
 sum(case when event_manipulation='UPDATE' THEN 1 ELSE 0 end) as update,
 sum(case when event_manipulation='DELETE' THEN 1 ELSE 0 end) as delete,
 sum(case when action_orientation='ROW' THEN 1 ELSE 0 end) as row,
 sum(case when action_orientation='STATEMENT' THEN 1 ELSE 0 end) as statement,
 sum(case when action_timing='BEFORE' THEN 1 ELSE 0 end) as before,
 sum(case when action_timing='AFTER' THEN 1 ELSE 0 end) as after,
 sum(case when action_timing='INSTEAD OF' THEN 1 ELSE 0 end) as instead,
 count(*) as total
  from information_schema.triggers
 group by trigger_schema
 order by trigger_schema;

select evtevent as event_trigger, evtname as name,  evtowner::regrole::text as owner,  evtfoid::regproc::text as function,
        evtenabled as enabled, 
       case when evtenabled='A' then 'Always'
            when evtenabled='O' then 'Origin or Local'  
            when evtenabled='R' then 'Replica'  
            when evtenabled='D' then 'Disabled'
       end as evt_mode,
        evttags  as tags
  from pg_event_trigger
 order by evtevent, evtname;

select spcname as tablespace, pg_catalog.pg_get_userbyid(spcowner) as owner,
  pg_catalog.pg_tablespace_location(oid) as location,
  pg_tablespace_size (spcname) as size,
  pg_size_pretty (pg_tablespace_size (spcname)) as hr_size
  from pg_tablespace
 order by spcname;

select spcname as tablespace,
 sum(case when relkind='r' THEN 1 ELSE 0 end) as tables,
 sum(case when relkind='r' THEN greatest(reltuples,0) ELSE 0 end)::decimal(38,0) as rows,
 trunc(sum(case when relkind='r' THEN cast(1 as bigint)* relpages *8 ELSE 0 end)) as tab_KB,
 trunc(sum(case when relkind='i' THEN cast(1 as bigint)* relpages *8 ELSE 0 end)) as idx_KB,
 trunc(sum(case when relkind='t' THEN cast(1 as bigint)* relpages *8 ELSE 0 end)) as toast_KB,
 trunc(sum(cast(1 as bigint)* relpages *8)) as size_KB
from pg_class
left join pg_tablespace on reltablespace=pg_tablespace.oid
group by spcname
order by spcname;

(select nspname as schema, rolname as owner,
 sum(case when relkind='r' THEN 1 ELSE 0 end) as tables,
 sum(case when relkind='r' THEN greatest(reltuples,0) ELSE 0 end)::decimal(38,0) as rows,
 trunc(sum(case when relkind='r' THEN cast(1 as bigint)* relpages *8 ELSE 0 end))::decimal(38,0) as tab_KB,
 trunc(sum(case when relkind='i' THEN cast(1 as bigint)* relpages *8 ELSE 0 end))::decimal(38,0) as idx_KB,
 trunc(sum(case when relkind='t' THEN cast(1 as bigint)* relpages *8 ELSE 0 end))::decimal(38,0) as toast_KB,
 trunc(sum(cast(1 as bigint)* relpages *8))::decimal(38,0) as size_KB
from pg_class, pg_roles, pg_namespace
where relowner=pg_roles.oid
  and relnamespace=pg_namespace.oid
group by rolname, nspname
order by nspname, rolname)
union all
select 'TOTAL', '',
 sum(case when relkind='r' THEN 1 ELSE 0 end),
 sum(case when relkind='r' THEN reltuples ELSE 0 end)::decimal(38,0),
 trunc(sum(case when relkind='r' THEN cast(1 as bigint)* relpages *8 ELSE 0 end)),
 trunc(sum(case when relkind='i' THEN cast(1 as bigint)* relpages *8 ELSE 0 end)),
 trunc(sum(case when relkind='t' THEN cast(1 as bigint)* relpages *8 ELSE 0 end)),
 trunc(sum(cast(1 as bigint)* relpages *8))
from pg_class;

select count(*) as tables,
 max(to_char(last_autovacuum, 'YYYY-MM-DD HH24:MI:SS')) as last_autovacuum,
 max(to_char(last_vacuum, 'YYYY-MM-DD HH24:MI:SS')) as last_vacuum,
 max(to_char(last_autoanalyze, 'YYYY-MM-DD HH24:MI:SS')) as last_autoanalyze,
 max(to_char(last_analyze, 'YYYY-MM-DD HH24:MI:SS')) as last_analyze
 from pg_stat_user_tables;

select schemaname||'.'||relname as table_deads,
 n_live_tup, n_dead_tup,
 round(100*n_dead_tup/(n_live_tup+n_dead_tup)::float) as dead_pct,
 to_char(last_autovacuum, 'YYYY-MM-DD HH24:MI:SS') as last_autovacuum,
 to_char(last_vacuum, 'YYYY-MM-DD HH24:MI:SS') as last_vacuum,
 to_char(last_autoanalyze, 'YYYY-MM-DD HH24:MI:SS') as last_autoanalyze,
 to_char(last_analyze, 'YYYY-MM-DD HH24:MI:SS') as last_analyze
  from pg_stat_all_tables
 where n_dead_tup>1000
   and n_dead_tup>n_live_tup*0.05
 order by n_dead_tup desc
 limit 20;

SELECT schemaname||'.'||tblname as table_bloats,
    FILLFACTOR,
    bs * tblpages AS real_size,
    pg_size_pretty(bs * tblpages) AS HR_size,
    CASE 
        WHEN tblpages - est_tblpages_ff > 0
            THEN (tblpages - est_tblpages_ff) * bs
        ELSE 0
        END AS bloat_size,
    CASE 
        WHEN tblpages - est_tblpages_ff > 0
            THEN pg_size_pretty(((tblpages - est_tblpages_ff) * bs)::BIGINT)
        ELSE '0'
        END AS hr_bloat_size,
    CASE 
        WHEN tblpages > 0
            AND tblpages - est_tblpages_ff > 0
            THEN round(100 * (tblpages - est_tblpages_ff) / tblpages::FLOAT)
        ELSE 0
        END AS bloat_pct
FROM (
    SELECT ceil(reltuples / ((bs - page_hdr) * FILLFACTOR / (tpl_size * 100))) + ceil(toasttuples / 4) AS est_tblpages_ff,
        tblpages,
        FILLFACTOR,
        bs,
        tblid,
        schemaname,
        tblname,
        heappages,
        toastpages,
        is_na
    FROM (
        SELECT (
                4 + tpl_hdr_size + tpl_data_size + (2 * ma) - CASE 
                    WHEN tpl_hdr_size % ma = 0
                        THEN ma
                    ELSE tpl_hdr_size % ma
                    END - CASE 
                    WHEN ceil(tpl_data_size)::INT % ma = 0
                        THEN ma
                    ELSE ceil(tpl_data_size)::INT % ma
                    END
                ) AS tpl_size,
            bs - page_hdr AS size_per_block,
            (heappages + toastpages) AS tblpages,
            heappages,
            toastpages,
            reltuples,
            toasttuples,
            bs,
            page_hdr,
            tblid,
            schemaname,
            tblname,
            FILLFACTOR,
            is_na
        FROM (
            SELECT tbl.oid AS tblid,
                ns.nspname AS schemaname,
                tbl.relname AS tblname,
                tbl.reltuples,
                tbl.relpages AS heappages,
                coalesce(toast.relpages, 0) AS toastpages,
                coalesce(toast.reltuples, 0) AS toasttuples,
                coalesce(substring(array_to_string(tbl.reloptions, ' ') FROM 'fillfactor=([0-9]+)')::SMALLINT, 100) AS FILLFACTOR,
                current_setting('block_size')::NUMERIC AS bs,
                CASE 
                    WHEN version() ~ 'mingw32'
                        OR version() ~ '64-bit|x86_64|ppc64|ia64|amd64'
                        THEN 8
                    ELSE 4
                    END AS ma,
                24 AS page_hdr,
                23 + CASE 
                    WHEN MAX(coalesce(s.null_frac, 0)) > 0
                        THEN (7 + count(s.attname)) / 8
                    ELSE 0::INT
                    END + CASE 
                    WHEN bool_or(att.attname = 'oid'
                            AND att.attnum < 0)
                        THEN 4
                    ELSE 0
                    END AS tpl_hdr_size,
                sum((1 - coalesce(s.null_frac, 0)) * coalesce(s.avg_width, 0)) AS tpl_data_size,
                bool_or(att.atttypid = 'pg_catalog.name'::regtype)
                OR sum(CASE 
                        WHEN att.attnum > 0
                            THEN 1
                        ELSE 0
                        END) <> count(s.attname) AS is_na
            FROM pg_attribute AS att
            JOIN pg_class AS tbl ON att.attrelid = tbl.oid
            JOIN pg_namespace AS ns ON ns.oid = tbl.relnamespace
            LEFT JOIN pg_stats AS s ON s.schemaname = ns.nspname
                AND s.tablename = tbl.relname
                AND s.inherited = false
                AND s.attname = att.attname
            LEFT JOIN pg_class AS toast ON tbl.reltoastrelid = toast.oid
            WHERE NOT att.attisdropped
                AND tbl.relkind IN ('r', 'm')
            GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
            ORDER BY 2, 3
            ) AS s
        ) AS s2
    ) AS s3
WHERE NOT is_na
    AND tblpages - est_tblpages_ff > 0
ORDER BY 5 DESC limit 20;


SELECT datname as database,age(datfrozenxid) as max_xid_age, 
       (age(datfrozenxid)::numeric/2000000000*100)::numeric(4,2) as Wraparound_pct
  FROM pg_database
 ORDER BY 2 DESC;
SELECT  nspname as schema, relname as table, age(relfrozenxid) as xid_age
  FROM pg_class
  JOIN pg_namespace ON pg_class.relnamespace = pg_namespace.oid
 WHERE relkind = 'r'
   AND age(relfrozenxid)> 2^28
 ORDER by 2 DESC;

select rolname as user_list,
    rolcanlogin as login,
    rolinherit as hinerit,
    rolsuper as superuser,
    rolvaliduntil as expiry_time,
    rolconnlimit as max_conn,
    rolconfig::text as config
from pg_roles
order by rolcanlogin desc, rolname;

select type hba_rule_type,
       database, user_name, address, netmask,
       auth_method  --, options, error
  from pg_hba_file_rules
 order by line_number;

(select 'Database' as object_type,  datname as name, datdba::regrole::text as owner
  from pg_database
 where not datistemplate
   and datdba::regrole::text not in ('postgres', 'rdsadmin', 'enterprisedb')
 order by datname)
union all
(select 'Schema',  nspname, nspowner::regrole::text
  from pg_namespace
 where nspowner::regrole::text not in ('postgres', 'rdsadmin', 'enterprisedb')
 order by nspname);

select member::regrole::text as grantee, admin_option, string_agg(roleid::regrole::text, ', ' order by roleid) as granted_roles
  from pg_auth_members
 where member::regrole::text not in ('postgres')
 group by member::regrole::text, admin_option
 order by member::regrole::text;

with grt as (
select grantee as gr, table_schema ts, privilege_type pt, count(*) as cnt
  from information_schema.table_privileges
 where grantee not in ('postgres', 'pg_monitor', 'rdsadmin', 'enterprisedb')
   and table_schema not in ('pg_catalog', 'information_schema', 'sys')
   and table_schema not like 'pg_temp_%'
 group by grantee, table_schema, privilege_type
 order by grantee, table_schema, privilege_type
) 
select gr as grantee, ts as schema, cnt as count, string_agg(pt, ', ' order by pt) as privileges
  from grt
 group by gr, ts, cnt;

select pid,
       datname as database,
       usename as user,
       client_addr,
       to_char(backend_start, 'YYYY-MM-DD HH24:MI:SS') as session_start,
       state,
       to_char(query_start, 'YYYY-MM-DD HH24:MI:SS') as start,
       now()-query_start as duration,
       backend_type,
       application_name as application,
       E''||replace(query, chr(10), ' ') as query
  from pg_stat_activity
 where pid<>pg_backend_pid()
 order by state, query_start, pid;

SELECT 'Blocking' as locks, blocked_locks.pid AS blocked_pid,
       blocked_activity.usename AS blocked_user,
       blocking_locks.pid AS blocking_pid,
       blocking_activity.usename AS blocking_user,
       blocked_activity.query AS blocked_statement,
       blocking_activity.query AS blocking_process_statement
  FROM pg_catalog.pg_locks blocked_locks
       JOIN pg_catalog.pg_stat_activity blocked_activity  ON blocked_activity.pid = blocked_locks.pid
       JOIN pg_catalog.pg_locks blocking_locks ON blocking_locks.locktype = blocked_locks.locktype
        AND blocking_locks.DATABASE IS NOT DISTINCT FROM blocked_locks.DATABASE
        AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
        AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
        AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
        AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
        AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
        AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
        AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
        AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
        AND blocking_locks.pid != blocked_locks.pid
       JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
 WHERE NOT blocked_locks.GRANTED;

(select pid::text, 
    locktype, 
     datname as database, 
     relname as relation, 
    mode, 
    granted
  from pg_locks l
  left join pg_catalog.pg_database d on d.oid = l.database
  left join pg_catalog.pg_class r on r.oid = l.relation
 order by granted, pid
 limit 50 )
union all
(select 'TOTAL',
    locktype, 
    datname, 
     count(*)::text,
    mode, 
    granted
  from pg_locks l
  left join pg_catalog.pg_database d on d.oid = l.database
  left join pg_catalog.pg_class r on r.oid = l.relation
 group by locktype, datname, mode, granted
 order by granted, datname, locktype, mode);

select name as cache_element,
    case when unit='kB'  then pg_size_pretty(setting::bigint*1024)
                when unit='8kB' then pg_size_pretty(setting::bigint*1024*8)
                when unit='B'   then pg_size_pretty(setting::bigint)
                when unit='MB'  then pg_size_pretty(setting::bigint*1024*1024)
                else setting||' '||coalesce(unit,'') end as value,
    short_desc
from pg_settings
where name like '%buffers'
union all
select name,
    case when unit='kB'  then pg_size_pretty(setting::bigint*1024)
                when unit='8kB' then pg_size_pretty(setting::bigint*1024*8)
                when unit='B'   then pg_size_pretty(setting::bigint)
                when unit='MB'  then pg_size_pretty(setting::bigint*1024*1024)
                else setting||' '||coalesce(unit,'') end,
    short_desc
from pg_settings
where name like '%mem';

select datname as database, 
    numbackends, 
    xact_commit, 
    round(xact_commit/EXTRACT( EPOCH FROM (now()-stats_reset))::decimal,2) as TPS,
    xact_rollback, 
    blks_read, 
    blks_hit, 
    round((blks_hit)*100.0/nullif(blks_read+blks_hit, 0),2) as hit_ratio, 
    tup_returned, 
    tup_fetched, 
    tup_inserted, 
    tup_updated, 
    tup_deleted,
    to_char(stats_reset, 'YYYY-MM-DD HH24:MI:SS') as stats_reset
from pg_stat_database
where datname not like 'template%'
order by datname;

-- Requires PG14+
select datname as database,
       sum(calls) as calls,
       round(sum(total_exec_time)) as total_exec_time,
       round(sum( (calls)/(EXTRACT(EPOCH FROM (now()-stats_reset))) )::numeric,3) Exec_sec,
       round(sum( (total_exec_time)/(EXTRACT(EPOCH FROM (now()-stats_reset))*1000) )::numeric,5) DBcpu,
       to_char(stats_reset, 'YYYY-MM-DD HH24:MI:SS') as stats_reset
  from pg_stat_statements, pg_database, pg_stat_statements_info
 where pg_stat_statements.dbid=pg_database.oid
   and pg_stat_statements.toplevel
   and datname not like 'template%'
 group by datname, stats_reset
order by datname;

select checkpoints_timed, 
     checkpoints_req, 
     buffers_checkpoint, 
     buffers_clean, 
     maxwritten_clean, 
     buffers_backend, 
     buffers_alloc,
     round(checkpoint_write_time/1000),
     round(checkpoint_sync_time/1000),
     to_char(stats_reset, 'YYYY-MM-DD HH24:MI:SS') as stats_reset
 from pg_stat_bgwriter;

select round(100.0*checkpoints_timed/nullif(checkpoints_req+checkpoints_timed,0),2) as timed_CP_ratio_pct,
       round((extract('epoch' from now() - stats_reset)/60)::numeric/nullif(checkpoints_req+checkpoints_timed,0),2) as minutes_between_CP,
       round(100.0*buffers_checkpoint/nullif(buffers_checkpoint + buffers_clean + buffers_backend,0),2) as clean_by_CP_pct,
       round(100.0*buffers_clean/nullif(buffers_checkpoint + buffers_clean + buffers_backend,0),2) as clean_by_BGW_pct,
       round(100.0*maxwritten_clean/nullif(buffers_clean,0),4) as BGW_alt_pct
 from pg_stat_bgwriter;

SELECT 'Table' as object_type,
  sum(heap_blks_read) as heap_read,
  sum(heap_blks_hit)  as heap_hit,
  trunc(100*sum(heap_blks_hit) / nullif(sum(heap_blks_hit) + sum(heap_blks_read),0),2) as ratio
FROM 
  pg_statio_user_tables
union all
SELECT 'Index',
  sum(idx_blks_read) as idx_read,
  sum(idx_blks_hit)  as idx_hit,
  trunc(100*(sum(idx_blks_hit) - sum(idx_blks_read)) / nullif(sum(idx_blks_hit),0),2) as ratio
FROM 
  pg_statio_user_indexes;

SELECT pg_postmaster_start_time() as istance_restart,
       stats_reset
  FROM pg_stat_statements_info;
SELECT pg_get_userbyid(userid) as user, calls,
  round((total_exec_time::numeric / nullif(calls::numeric, 0))/1000,3) as avg_sec,
  round((max_exec_time::numeric)/1000,3) as max_sec,
  round(total_exec_time) as total_time,
  rows,
  round((100.0 * shared_blks_hit / nullif(shared_blks_hit + shared_blks_read, 0)),2)  AS hit_percent,
  round((wal_bytes::numeric)/(1024*1024),0) as wals,
    CASE WHEN toplevel THEN 'T' ELSE 'F' END as top,
  E' '||replace(query, chr(10), ' ') as query_top20
  FROM pg_stat_statements 
 ORDER BY total_exec_time DESC LIMIT 20;

SELECT pg_get_userbyid(userid) as user, calls,
  round((total_exec_time::numeric / nullif(calls::numeric, 0))/1000,3) as avg_sec,
  round((max_exec_time::numeric)/1000,3) as max_sec,
  round(total_exec_time) as total_time,
  rows,
  round((100.0 * shared_blks_hit / nullif(shared_blks_hit + shared_blks_read, 0)),2)  AS hit_percent,
  round((wal_bytes::numeric)/(1024*1024),0) as wals,
    CASE WHEN toplevel THEN 'T' ELSE 'F' END as top,
  E' '||replace(query, chr(10), ' ') as query_slow
  FROM pg_stat_statements 
 WHERE pg_get_userbyid(userid) not in ('enterprisedb', 'efm')  -- Comment if needed
   AND calls>0
 ORDER BY (total_exec_time::numeric/nullif(calls::numeric, 0)) DESC
 LIMIT 5;

select schemaname  as schema,
  relname as table,
  n_live_tup,
  seq_tup_read,
  idx_tup_fetch,
  seq_scan,
  idx_scan,
  n_tup_ins,
  n_tup_upd,
  n_tup_hot_upd,
  n_tup_del,
  idx_scan*100/nullif(idx_scan+seq_scan,0) as idx_hit,
  n_tup_hot_upd*100/nullif(n_tup_upd,0) as hot_hit
 from pg_stat_user_tables
 order by (coalesce(seq_tup_read,0)+coalesce(idx_tup_fetch,0)) desc
 limit 20;

select schemaname as schema,
  relname as table,
  heap_blks_read,
  idx_blks_read,
  toast_blks_read,
  heap_blks_hit*100/nullif(heap_blks_read+heap_blks_hit,0) as tb_hit,
  idx_blks_hit*100/nullif(idx_blks_read+idx_blks_hit,0) as idx_hit,
  toast_blks_hit*100/nullif(toast_blks_read+toast_blks_hit,0) as toast_hit
 from pg_statio_user_tables
 where heap_blks_read>0
 order by heap_blks_read desc
 limit 10;

SELECT ns.nspname as schema, am.amname as type, count(*) as index_count,
       sum(case when idx.indisprimary then 1 else 0 end) pk,
       sum(case when idx.indisunique then 1 else 0 end) uq,
       round(avg(idx.indnkeyatts),2) as avg_keys, max(idx.indnkeyatts) as max_keys
  FROM pg_index idx 
  JOIN pg_class cls ON cls.oid=idx.indexrelid
  JOIN pg_class tbl ON tbl.oid=idx.indrelid
  JOIN pg_am am ON am.oid=cls.relam
  JOIN pg_namespace ns ON cls.relnamespace = ns.oid
 WHERE ns.nspname not in ('pg_catalog', 'sys')
   AND ns.nspname not like 'pg_toast_temp%'
 GROUP BY ns.nspname, am.amname
 ORDER BY ns.nspname, am.amname;

select nspname as schema,
 sum(case when contype ='p' THEN 1 ELSE 0 end) as pk,
 sum(case when contype ='u' THEN 1 ELSE 0 end) as uniq,
 sum(case when contype ='f' THEN 1 ELSE 0 end) as foreign,
 sum(case when contype ='c' THEN 1 ELSE 0 end) as check,
 sum(case when contype ='t' THEN 1 ELSE 0 end) as trigger,
 sum(case when contype ='x' THEN 1 ELSE 0 end) as exclusion
from pg_constraint, pg_namespace
where connamespace=pg_namespace.oid
  and nspname NOT IN('information_schema', 'pg_catalog', 'sys')
group by nspname
order by nspname;

SELECT  n.nspname as schema, c1.relname as invalid_index, c2.relname as table
  FROM pg_class c1, pg_index i, pg_namespace n, pg_class c2
 WHERE c1.relnamespace = n.oid
   AND i.indexrelid = c1.oid
   AND c2.oid = i.indrelid
   AND i.indisvalid = false;

WITH fk_actions ( code, action ) AS (
    VALUES ( 'a', 'error' ),
        ( 'r', 'restrict' ),
        ( 'c', 'cascade' ),
        ( 'n', 'set null' ),
        ( 'd', 'set default' )
),
fk_list AS (
    SELECT pg_constraint.oid as fkoid, conrelid, confrelid as parentid,
        conname, relname, nspname,
        fk_actions_update.action as update_action,
        fk_actions_delete.action as delete_action,
        conkey as key_cols
    FROM pg_constraint
        JOIN pg_class ON conrelid = pg_class.oid
        JOIN pg_namespace ON pg_class.relnamespace = pg_namespace.oid
        JOIN fk_actions AS fk_actions_update ON confupdtype = fk_actions_update.code
        JOIN fk_actions AS fk_actions_delete ON confdeltype = fk_actions_delete.code
    WHERE contype = 'f'
),
fk_attributes AS (
    SELECT fkoid, conrelid, attname, attnum
    FROM fk_list
        JOIN pg_attribute
            ON conrelid = attrelid
            AND attnum = ANY( key_cols )
    ORDER BY fkoid, attnum
),
fk_cols_list AS (
    SELECT fkoid, array_agg(attname) as cols_list
    FROM fk_attributes
    GROUP BY fkoid
),
index_list AS (
    SELECT indexrelid as indexid,
        pg_class.relname as indexname,
        indrelid,
        indkey,
        indpred is not null as has_predicate,
        pg_get_indexdef(indexrelid) as indexdef
    FROM pg_index
        JOIN pg_class ON indexrelid = pg_class.oid
    WHERE indisvalid
),
fk_index_match AS (
    SELECT fk_list.*,
        indexid,
        indexname,
        indkey::int[] as indexatts,
        has_predicate,
        indexdef,
        array_length(key_cols, 1) as fk_colcount,
        array_length(indkey,1) as index_colcount,
        round(pg_relation_size(conrelid)/(1024^2)::numeric) as table_mb,
        cols_list
    FROM fk_list
        JOIN fk_cols_list USING (fkoid)
        LEFT OUTER JOIN index_list
            ON conrelid = indrelid
            AND (indkey::int2[])[0:(array_length(key_cols,1) -1)] @> key_cols
),
fk_perfect_match AS (
    SELECT fkoid
    FROM fk_index_match
    WHERE (index_colcount - 1) <= fk_colcount
        AND NOT has_predicate
        AND indexdef LIKE '%USING btree%'
),
fk_index_check AS (
    SELECT 'no index' as issue, *, 1 as issue_sort
    FROM fk_index_match
    WHERE indexid IS NULL
    UNION ALL
    SELECT 'questionable index' as issue, *, 2
    FROM fk_index_match
    WHERE indexid IS NOT NULL
        AND fkoid NOT IN (
            SELECT fkoid
            FROM fk_perfect_match)
),
parent_table_stats AS (
    SELECT fkoid, tabstats.relname as parent_name,
        (n_tup_ins + n_tup_upd + n_tup_del + n_tup_hot_upd) as parent_writes,
        round(pg_relation_size(parentid)/(1024^2)::numeric) as parent_mb
    FROM pg_stat_user_tables AS tabstats
        JOIN fk_list
            ON relid = parentid
),
fk_table_stats AS (
    SELECT fkoid,
        (n_tup_ins + n_tup_upd + n_tup_del + n_tup_hot_upd) as writes,
        seq_scan as table_scans
    FROM pg_stat_user_tables AS tabstats
        JOIN fk_list
            ON relid = conrelid
)
SELECT nspname as schema,
     relname as table_name,
     conname as fk_name,
     issue as index_issue,
     table_scans,
     parent_name,
     cols_list
FROM fk_index_check
    JOIN parent_table_stats USING (fkoid)
    JOIN fk_table_stats USING (fkoid)
WHERE table_mb > 5
    AND ( writes > 1000
        OR parent_writes > 1000
        OR parent_mb > 10 )
ORDER BY table_scans DESC, table_mb DESC, table_name, fk_name
 LIMIT 20;

SELECT s.schemaname as schema, s.relname as table,
       s.indexrelname as unused_index, pg_relation_size(s.indexrelid)
  FROM pg_catalog.pg_stat_user_indexes s
  JOIN pg_catalog.pg_index i ON s.indexrelid = i.indexrelid
 WHERE s.idx_scan = 0      
   AND 0 <>ALL (i.indkey)  
   AND NOT i.indisunique   
   AND NOT EXISTS (SELECT 1 FROM pg_catalog.pg_constraint c
          WHERE c.conindid = s.indexrelid)
 ORDER BY pg_relation_size(s.indexrelid) DESC
 LIMIT 10;
SELECT s.schemaname as schema, s.relname as table,
       s.indexrelname as most_used_index, pg_relation_size(s.indexrelid),
       s.idx_scan, s.idx_tup_fetch  
  FROM pg_catalog.pg_stat_user_indexes s
  JOIN pg_catalog.pg_index i ON s.indexrelid = i.indexrelid
 ORDER BY s.idx_scan DESC
 LIMIT 10;

select nspname as schema, rolname as owner,
    t.relname as table,
    count(distinct(p.relname)) as partition_count,
   to_char(sum( case when p.reltuples>0 then p.reltuples else 0 end ),'999G999G999G999G999G999') as tuples
  from pg_class t, pg_inherits i, pg_class p, pg_roles r, pg_namespace n
 where i.inhparent = t.oid 
   and p.oid = i.inhrelid
   and t.relowner=r.oid
   and t.relnamespace=n.oid
   and p.relkind in ('r', 'p')
 group by nspname, rolname, t.relname
 order by nspname, rolname, t.relname;

select name as tuning_parameter,
           case when unit='kB'  then pg_size_pretty(setting::bigint*1024)
                when unit='8kB' then pg_size_pretty(setting::bigint*1024*8)
                when unit='B'   then pg_size_pretty(setting::bigint)
                when unit='MB'  then pg_size_pretty(setting::bigint*1024*1024)
                else setting||' '||coalesce(unit,'') end as value,
   min_val, max_val as max_val,
   unit, context, 
   setting,
   source   --, short_desc
  from pg_settings
 where name in ('max_connections','shared_buffers','effective_cache_size','work_mem', 'temp_buffers', 'wal_buffers',
               'checkpoint_completion_target', 'checkpoint_segments', 'synchronous_commit', 'wal_writer_delay',
               'max_fsm_pages','fsync','commit_delay','commit_siblings','random_page_cost', 'synchronous_standby_names',
               'checkpoint_timeout', 'max_wal_size',
               'bgwriter_lru_maxpages', 'bgwriter_lru_multiplier', ' bgwriter_delay',
               'autovacuum_vacuum_cost_limit', 'autovacuum_vacuum_cost_delay') 
 order by name; 

select relname as table,
 case WHEN relkind='r' THEN 'Table' 
    WHEN relkind='i' THEN 'Index'
    WHEN relkind='t' THEN 'TOAST Table'
    ELSE relkind::text||'' end as object_type,
 rolname as owner,  n.nspname as schema,
 to_char(reltuples,'999G999G999G999G999G999') as rows,
 to_char(relpages::INT8*8*1024,'999G999G999G999G999G999') as bytes
  from pg_class, pg_roles, pg_catalog.pg_namespace n
 where relowner=pg_roles.oid
   and n.oid=pg_class.relnamespace
 order by relpages desc, reltuples desc
 limit 20;

select t.relname as toast_table,
 rolname as owner,  n.nspname||'.'||r.relname as table,
 to_char(t.reltuples,'999G999G999G999G999G999') as rows,
 to_char(pg_relation_size(t.oid),'999G999G999G999G999G999') as bytes
  from pg_class t, pg_roles, pg_catalog.pg_namespace n, pg_class r
 where t.relowner=pg_roles.oid
   and n.oid=r.relnamespace
   and r.reltoastrelid = t.oid
   and t.relkind='t'
   and t.reltuples>0
 order by pg_relation_size(t.oid) desc
 limit 10;

WITH RECURSIVE tabs AS (
     SELECT c.oid AS parent, c.oid AS relid, 1 AS level
       FROM pg_catalog.pg_class c
       LEFT JOIN pg_catalog.pg_inherits AS i ON c.oid = i.inhrelid
      WHERE c.relkind IN ('p', 'r')
        AND i.inhrelid IS NULL
      UNION ALL
     SELECT p.parent AS parent, c.oid AS relid, p.level + 1 AS level
       FROM tabs AS p
       LEFT JOIN pg_catalog.pg_inherits AS i ON p.relid = i.inhparent
       LEFT JOIN pg_catalog.pg_class AS c ON c.oid = i.inhrelid AND c.relispartition
      WHERE c.oid IS NOT NULL
)
SELECT parent ::REGCLASS AS table_name, 
       max(level)-1 AS hierarchy_level,
       count(*) AS partition_count,
       pg_size_pretty(sum(pg_total_relation_size(relid))) AS pretty_total_size,
       to_char(sum(pg_total_relation_size(relid)),'999G999G999G999G999G999') AS total_size
       -- array_agg(relid :: REGCLASS) AS all_partitions
  FROM tabs
 GROUP BY parent
 HAVING max(level)>1
 ORDER BY sum(pg_total_relation_size(relid)) DESC
 LIMIT 10;

select o.rolname as owner,
 case when f.prokind='f' then 'Function'
           when f.prokind='a' then 'Aggregate func.'
           when f.prokind='w' then 'Window func.'
           when f.prokind='p' then 'Procedure'
           else 'Other' end as pl_kind,
 l.lanname as language, count(*),
 sum(char_length(prosrc)) as source_size
  from pg_proc f, pg_roles o, pg_language l
 where f.proowner=o.oid
   and f.prolang=l.oid
   and o.rolname not in ('postgres', 'enterprisedb')
 group by o.rolname, l.lanname, prokind
 order by o.rolname, prokind, l.lanname;

select o.rolname as owner, n.nspname as schema, count(distinct r.relname||n.nspname) as tables_count,
       count(distinct r.relname||n.nspname||a.attname) as column_count
  from pg_attribute a, pg_class r, pg_roles o, pg_catalog.pg_namespace n
 where a.attrelid=r.oid
   and r.relowner=o.oid
   and n.oid=r.relnamespace
   and r.relkind in('r', 'p')
   and not r.relispartition
   and a.attnum > 0
   and not a.attisdropped
   and o.rolname not in ('postgres', 'rdsadmin', 'enterprisedb', 'admin')
   and n.nspname not in ('information_schema', 'pg_catalog')
 group by o.rolname, n.nspname
 order by o.rolname, n.nspname;

select o.rolname as owner, n.nspname as schema, t.typname as type_name, count(*)
  from pg_attribute a, pg_class r, pg_roles o, pg_type t, pg_catalog.pg_namespace n
 where a.attrelid=r.oid
   and a.atttypid=t.oid
   and r.relowner=o.oid
   and n.oid=r.relnamespace
   and r.relkind in('r', 'p')
   and not r.relispartition
   and a.attnum > 0
   and not a.attisdropped
   and o.rolname not in ('postgres', 'rdsadmin', 'enterprisedb', 'admin')
   and n.nspname not in ('information_schema', 'pg_catalog')
 group by o.rolname, n.nspname, t.typname
 order by o.rolname, n.nspname, t.typname;

select archived_count, last_archived_wal,
 to_char(last_archived_time, 'YYYY-MM-DD HH24:MI:SS') as last_archived_time, failed_count,
 last_failed_wal,
 to_char(last_failed_time, 'YYYY-MM-DD HH24:MI:SS') as last_failed_time,
 to_char(stats_reset, 'YYYY-MM-DD HH24:MI:SS') as stats_reset,
        current_setting('archive_mode')::BOOLEAN
                 AND (last_failed_wal IS NULL
                  OR last_failed_wal <= last_archived_wal) as archiving,
        round((CAST (archived_count AS NUMERIC)*60 / EXTRACT (EPOCH FROM age(now(), stats_reset)))::numeric,6) as wals_pm
  from pg_stat_archiver;
select name as replication_parameter, substring(setting, 1,80) as setting
 from pg_settings
 where name in ('wal_level', 'archive_command', 'hot_standby', 'max_wal_senders', 'checkpoint_segments', 'max_wal_size', 'archive_mode', 
                'max_standby_archive_delay', 'max_standby_streaming_delay', 'hot_standby_feedback', 'synchronous_commit',
                'wal_keep_segments', 'wal_keep_size', 'synchronous_standby_names', 'recovery_target_timeline',
                'wal_receiver_create_temp_slot', 'max_slot_wal_keep_size', 'ignore_invalid_pages',
                'primary_slot_name', 'primary_conninfo', 'max_slot_wal_keep_size',
                'vacuum_defer_cleanup_age')
 order by name; 
select client_addr,  state,  sync_state,  txid_current_snapshot() as txid_current,
        sent_lsn,      write_lsn, flush_lsn, replay_lsn,
        to_char(backend_start, 'YYYY-MM-DD HH24:MI:SS') as backend_start,
        write_lag, flush_lag, replay_lag
  from pg_stat_replication;
select slot_name,  slot_type,  active,
        xmin,  catalog_xmin,  restart_lsn
  from pg_replication_slots;

select now() - pg_last_xact_replay_timestamp() as last_replica,
        CASE WHEN pg_last_wal_receive_lsn() = pg_last_wal_replay_lsn() THEN 0
                    ELSE EXTRACT (EPOCH FROM now() - pg_last_xact_replay_timestamp()) END as repl_delay,
        case when pg_is_in_recovery() then txid_current_snapshot() else null end as curren_snapshot,
        pg_last_wal_receive_lsn(),  
        pg_last_wal_replay_lsn();
select pid as wal_receiver_PID,  status,  conninfo,
        latest_end_lsn,  latest_end_time
  from pg_stat_wal_receiver;

select subname as logical_subscriptions, pid, relid, received_lsn, last_msg_send_time,     
       last_msg_receipt_time, latest_end_lsn, latest_end_time
  from pg_stat_subscription
 order by subname;
select pubname, rolname,
       puballtables,  pubinsert,  pubupdate,  pubdelete 
  from pg_publication p, pg_roles a
 where a.oid=p.pubowner
 order by pubname;
select pubname, schemaname, tablename
  from pg_publication_tables
 order by pubname, tablename;
select subname, datname, rolname,
       subenabled,  subsynccommit,  subslotname,  subconninfo
  from pg_subscription s, pg_database d, pg_roles a
 where d.oid=s.subdbid
   and a.oid=s.subowner
 order by subname;
select subname,  relname,
       srsubstate,  srsublsn 
  from pg_subscription_rel r, pg_subscription s, pg_class c
 where s.oid=r.srsubid
   and c.oid=r.srrelid
 order by subname, relname;

select name as extension_name, default_version, installed_version, substring(comment, 1,60) as comment
  from pg_available_extensions
 order by case when installed_version is null then 1 else 0 end, name;

select name as nls_parameter, setting,
   short_desc
from pg_settings
where name like 'lc%'
order by name; 
select  oid, datname as database, 
       datcollate
from pg_database;
select  table_schema, 
        table_name, 
        column_name,
        collation_name
  from information_schema.columns
 where collation_name is not null
   and table_schema not in ('information_schema', 'pg_catalog', 'sys')
 order by table_schema,
          table_name,
          ordinal_position;

select name as configured_parameters, 
           case when unit='kB'  then pg_size_pretty(setting::bigint*1024)
                when unit='8kB' then pg_size_pretty(setting::bigint*1024*8)
                when unit='B'   then pg_size_pretty(setting::bigint)
                when unit='MB'  then pg_size_pretty(setting::bigint*1024*1024)
                else setting||' '||coalesce(unit,'') end as value,
    source,  
    substring(setting, 1,60) as setting --, short_desc
from pg_settings
where source not in ('default', 'override', 'client')
order by name; 
select name as all_parameters,
           case when unit='kB'  then pg_size_pretty(setting::bigint*1024)
                when unit='8kB' then pg_size_pretty(setting::bigint*1024*8)
                when unit='B'   then pg_size_pretty(setting::bigint)
                when unit='MB'  then pg_size_pretty(setting::bigint*1024*1024)
                else setting||' '||coalesce(unit,'') end as value,
   min_val, max_val,
   context,
   unit, source,
   setting, substring(category,1,40)  as category --, short_desc
from pg_settings
order by name
limit 29; 

select 'Copyright 2025 meob' as copyright, 'Apache-2.0' as license, 'https://github.com/meob/db2txt' as sources;
select concat('Report terminated on: ', now()) as report_date;