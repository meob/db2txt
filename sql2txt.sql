select 'sql2txt: SQL Server TXT-Report on: ' as title, DB_NAME() as db,
       CURRENT_TIMESTAMP as report_date,
       CURRENT_USER as by_user,
       'v.1.0.1' as version;

select 'Server: ' as summary_info, name as value
 from sys.servers
union all
select 'Version :', substring(@@VERSION,1,25)
union all
select 'DB Size (MB):', cast(round(sum(size * 8.0 / 1024),0) as varchar)
  FROM sys.master_files
union all
select 'Created :', cast(create_date as varchar)
  FROM sys.server_principals
 WHERE sid = 0x010100000000000512000000
union all
select 'Started :', cast(sqlserver_start_time as varchar)
  FROM sys.dm_os_sys_info
union all
select 'CPU :', cast(cpu_count as varchar)
  FROM sys.dm_os_sys_info
union all
select 'Physical Memory (MB) :', cast(physical_memory_kb/1024 as varchar)
  FROM sys.dm_os_sys_info
union all
select 'Databases :', cast(count(*) as varchar)
  from sys.databases
union all
select 'Defined Users/Roles :', cast(count(*) as varchar)
  from sys.server_principals where type_desc in ('SQL_LOGIN', 'WINDOWS_LOGIN')
union all
select 'Sessions :', cast(count(*) as varchar)
  from sys.dm_exec_sessions
union all
select 'Sessions (active):', cast(count(*) as varchar)
  from sys.dm_exec_sessions s
  join sys.dm_exec_requests r ON s.session_id = r.session_id
 CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
union all
select 'Database :', DB_NAME()
union all
select 'Defined Schemata :', cast(count(*) as varchar)
  from sys.schemas
union all
select 'Defined Tables :', cast(count(*) as varchar)
  from information_schema.tables
 where TABLE_TYPE='BASE TABLE';

select cast(SERVERPROPERTY('productversion') as varchar)+' - '+
       cast(SERVERPROPERTY ('productlevel') as varchar)+' - '+ 
       cast(SERVERPROPERTY ('edition') as varchar) as version
union all
select substring(@@VERSION, 1, 120) 
union all
select ' Latest Releases: 16.0.4085.2, 15.0.4335.1, 14.0.3465.1, 13.0.5830.85'
union all
select ' Desupported:     12.0.6329.1, 11.0.7001.0,'
union all
select '                  10.50.6529.00, 10.00.6535.00, 9.00.5324, 8.00.2039, 7.00.1063, 6.50.479';

select d.database_id as id, d.name, suser_sname(owner_sid) as owner,
       compatibility_level as comp, sum(size*8/1024) size_MB, collation_name,
       snapshot_isolation_state_desc as snap, is_read_committed_snapshot_on as read_comm,
       recovery_model_desc as recovery_m, is_broker_enabled as broker, is_query_store_on as q_store,
       d.state_desc as status, create_date
  from sys.databases d, sys.master_files f
 where d.database_id=f.database_id
 group by d.database_id, d.name, owner_sid, create_date, compatibility_level, collation_name,
       snapshot_isolation_state_desc, is_read_committed_snapshot_on, recovery_model_desc,
       is_broker_enabled, is_query_store_on, d.state_desc
 order by d.database_id;

select s.name as schema_matrix,
 sum(case when o.type='U' THEN 1 ELSE 0 end) as tables,
 sum(case when o.type='PK' THEN 1 ELSE 0 end) as pk,
 sum(case when o.type='UQ' THEN 1 ELSE 0 end) as uniq,
 sum(case when o.type='F' THEN 1 ELSE 0 end) as fk,
 sum(case when o.type='C' THEN 1 ELSE 0 end) as chk,
 sum(case when o.type='D' THEN 1 ELSE 0 end) as def,
 sum(case when o.type='V' THEN 1 ELSE 0 end) as views,
 sum(case when o.type='P' THEN 1 ELSE 0 end) as sproc,
 sum(case when o.type='TR' THEN 1 ELSE 0 end) as trig,
-- sum(case when o.type='S' THEN 1 ELSE 0 end) as sys_tab,
-- sum(case when o.type='IT' THEN 1 ELSE 0 end) as int_tab,
 count(*) as TOTAL
  from sys.all_objects o, sys.schemas s
 where o.schema_id=s.schema_id
   and s.name not in ('sys', 'INFORMATION_SCHEMA')
 group by s.name
union
select 'TOTAL',
 sum(case when o.type='U' THEN 1 ELSE 0 end) as tables,
 sum(case when o.type='PK' THEN 1 ELSE 0 end) as pk,
 sum(case when o.type='UQ' THEN 1 ELSE 0 end) as uniq,
 sum(case when o.type='F' THEN 1 ELSE 0 end) as fk,
 sum(case when o.type='C' THEN 1 ELSE 0 end) as chk,
 sum(case when o.type='D' THEN 1 ELSE 0 end) as def,
 sum(case when o.type='V' THEN 1 ELSE 0 end) as views,
 sum(case when o.type='P' THEN 1 ELSE 0 end) as sproc,
 sum(case when o.type='TR' THEN 1 ELSE 0 end) as trig,
-- sum(case when o.type='S' THEN 1 ELSE 0 end) as sys_tab,
-- sum(case when o.type='IT' THEN 1 ELSE 0 end) as int_tab,
 count(*) as TOTAL
  from sys.all_objects o, sys.schemas s
 where o.schema_id=s.schema_id
   and s.name not in ('sys', 'INFORMATION_SCHEMA');

-- space_usage
SELECT (SUM(case when index_id=1 then reserved_page_count end) * 8192) / 1024.0 AS Cluster_KB,
       (SUM(case when index_id=0 then reserved_page_count end) * 8192) / 1024.0 AS HEAP_KB,      
       (SUM(case when index_id>1 then reserved_page_count end) * 8192) / 1024.0 AS idx_KB,
       (SUM(reserved_page_count) * 8192) / 1024.0 AS Total_KB
  FROM sys.dm_db_partition_stats, INFORMATION_SCHEMA.TABLES
 WHERE sys.dm_db_partition_stats.object_id =
         OBJECT_ID(INFORMATION_SCHEMA.TABLES.TABLE_SCHEMA + '.' + INFORMATION_SCHEMA.TABLES.TABLE_NAME)
   AND INFORMATION_SCHEMA.TABLES.TABLE_TYPE = 'BASE TABLE';
EXEC sp_spaceused;

-- user_list
-- EXEC sp_helpuser
SELECT name AS user_list, PRINCIPAL_ID, type, type_desc,
       default_database_name AS def_database, IIF(is_fixed_role LIKE 0, 'No', 'Yes') as active,
       create_date
  FROM master.sys.server_principals
 WHERE type LIKE 's' OR type LIKE 'u'
 ORDER BY name, default_database_name; 

SELECT name, type_desc, default_database_name, is_disabled,
       is_policy_checked, is_expiration_checked, create_date
  FROM sys.sql_logins;

SELECT u.name AS [Name],
       CAST(CASE dp.state WHEN N'G' THEN 1 WHEN 'W' THEN 1 ELSE 0 END AS bit) as DBA,
       'Server[@Name=' + quotename(CAST( serverproperty(N'Servername') AS sysname),'''') + ']' + '/Database[@Name=' + quotename(db_name(),'''') + ']' + '/User[@Name=' + quotename(u.name,'''') + ']' AS Urn,
       u.create_date AS CreateDate
  FROM sys.database_principals AS u
  LEFT OUTER JOIN sys.database_permissions AS dp ON dp.grantee_principal_id = u.principal_id and dp.type = 'CO'
 WHERE (u.type in ('U', 'S', 'G', 'C', 'K' ,'E', 'X'))
 ORDER BY Name;


SELECT s.session_id, r.command as current_query, s.login_name, s.host_name, s.program_name, s.cpu_time, s.memory_usage, r.status
       -- , r.sql_handle
  FROM sys.dm_exec_sessions s
  LEFT JOIN sys.dm_exec_requests r ON s.session_id = r.session_id
 WHERE s.session_id <> @@SPID
 ORDER BY s.session_id desc;

SELECT s.session_id, s.login_name, s.host_name, substring(s.program_name,1,20) as program_name, r.status,
       r.command as current_query, t.text AS query_text
  FROM sys.dm_exec_sessions s
  INNER JOIN sys.dm_exec_requests r ON s.session_id = r.session_id
  CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
 WHERE r.session_id <> @@SPID;

WITH cteBL (session_id, blocking_these) AS 
(SELECT s.session_id, blocking_these = x.blocking_these FROM sys.dm_exec_sessions s 
CROSS APPLY (SELECT isnull(convert(varchar(6), er.session_id),'') + ', '  
               FROM sys.dm_exec_requests as er
              WHERE er.blocking_session_id = isnull(s.session_id ,0)
                AND er.blocking_session_id <> 0
                FOR XML PATH('') ) AS x (blocking_these) )
SELECT 'LOCKED' as locks, s.session_id, blocked_by = r.blocking_session_id, bl.blocking_these,
       batch_text = t.text, input_buffer = ib.event_info    -- , * 
  FROM sys.dm_exec_sessions s 
  LEFT OUTER JOIN sys.dm_exec_requests r on r.session_id = s.session_id
  INNER JOIN cteBL as bl on s.session_id = bl.session_id
  OUTER APPLY sys.dm_exec_sql_text (r.sql_handle) t
  OUTER APPLY sys.dm_exec_input_buffer(s.session_id, NULL) AS ib
 WHERE blocking_these is not null or r.blocking_session_id > 0
 ORDER BY len(bl.blocking_these) desc, r.blocking_session_id desc, r.session_id;

SELECT TOP 20 q.query_id as query_top20, t.query_sql_text, rts.avg_cpu_time
  FROM sys.query_store_query AS q
  JOIN sys.query_store_plan p on q.query_id = p.query_id
  JOIN sys.query_store_query_text AS t ON q.query_text_id = t.query_text_id
  JOIN sys.query_store_runtime_stats AS rts ON p.plan_id = rts.plan_id
ORDER BY rts.avg_cpu_time DESC;

-- system/memory settings
select cpu_count as CPU, virtual_machine_type_desc as machine_type, physical_memory_kb, virtual_memory_kb,
       physical_memory_in_use_kb, memory_utilization_percentage, sqlserver_start_time
  from sys.dm_os_sys_info, sys.dm_os_process_memory;

-- most intresting tuning parameters
select name as tuning_parameters, value, value_in_use, is_dynamic, is_advanced
  from sys.configurations
 where name in ('max server memory (MB)', 'cost threshold for parallelism', 'max degree of parallelism', 'recovery interval',
                'optimize for ad hoc workloads', 'min server memory (MB)', 'clr enabled', 'backup compression default',
                'default trace enabled', 'remote access')
 order by name;
                      
-- database statistics (eg. hit ratio, TPS) temporary, fragmentation
SELECT substring(object_name, 1,30) as object_name, substring(counter_name, 1,30) as counter_name,
       cntr_value, instance_name, cntr_type
  FROM sys.dm_os_performance_counters
 WHERE -- object_name LIKE '%Buffer Manager%' AND
       counter_name in ('Buffer cache hit ratio', 'Page life expectancy', 'SQL Compilations/sec', 'Transactions/sec',
              'Number of Deadlocks/sec', 'Page Reads/Sec', 'Page Writes/Sec');

-- table/index usage
-- partitioning

-- missing, invalied indexes
SELECT DISTINCT TOP 20 CONVERT(decimal(18,2),
 migs.user_seeks * migs.avg_total_user_cost * (migs.avg_user_impact * 0.01)) AS index_advantage,
 migs.last_user_seek, mid.statement AS db_schema_table,
 mid.equality_columns, mid.inequality_columns, migs.user_seeks
 -- mid.included_columns,
 -- migs.avg_total_user_cost, migs.avg_user_impact,
 -- OBJECT_NAME(mid.object_id) AS table_name, p.rows AS table_rows
FROM sys.dm_db_missing_index_group_stats AS migs WITH (NOLOCK)
INNER JOIN sys.dm_db_missing_index_groups AS mig WITH (NOLOCK) ON migs.group_handle = mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details AS mid WITH (NOLOCK) ON mig.index_handle = mid.index_handle
INNER JOIN sys.partitions AS p WITH (NOLOCK) ON p.object_id = mid.object_id
WHERE mid.database_id = DB_ID()
  AND p.index_id < 2
ORDER BY index_advantage DESC OPTION (RECOMPILE);

-- biggest objects
SELECT TOP 20 TABLE_SCHEMA, TABLE_NAME as biggest_objects, (SUM(reserved_page_count) * 8192) / 1024.0 AS Size_KB
  FROM sys.dm_db_partition_stats, INFORMATION_SCHEMA.TABLES
 WHERE sys.dm_db_partition_stats.object_id =
         OBJECT_ID(INFORMATION_SCHEMA.TABLES.TABLE_SCHEMA + '.' + INFORMATION_SCHEMA.TABLES.TABLE_NAME)
   AND INFORMATION_SCHEMA.TABLES.TABLE_TYPE = 'BASE TABLE'
 GROUP BY TABLE_SCHEMA, TABLE_NAME
 ORDER BY Size_KB desc;

-- number and size of stored procedures
-- tables, columns, datatype usage

-- log management/archiving
select * from sys.dm_db_log_space_usage;

-- backups
SELECT database_name as db_backups
        , full_last_date = MAX(CASE WHEN type = 'D' THEN backup_finish_date END)
        , full_size = MAX(CASE WHEN type = 'D' THEN backup_size END)
        , log_last_date = MAX(CASE WHEN type = 'L' THEN backup_finish_date END)
        , log_size = MAX(CASE WHEN type = 'L' THEN backup_size END)
    FROM (
        SELECT s.database_name, s.type, s.backup_finish_date, backup_size =
                        CAST(CASE WHEN s.backup_size = s.compressed_backup_size
                                    THEN s.backup_size
                                    ELSE s.compressed_backup_size
                        END / 1048576.0 AS DECIMAL(18,2)),
                RowNum = ROW_NUMBER() OVER (PARTITION BY s.database_name, s.type ORDER BY s.backup_finish_date DESC)
        FROM msdb.dbo.backupset s
        WHERE s.type IN ('D', 'L')
    ) f
    WHERE f.RowNum = 1
    GROUP BY f.database_name;

-- replication /cluster/HA
-- extensions, options, additional modules
-- NLS settings 

-- all tuning/configuration parameters
select name as all_parameters, value, minimum, maximum, value_in_use, is_dynamic, is_advanced,
       substring(description, 1, 20) as description
  from sys.configurations
 order by name;

-- global_status
SELECT TOP 29 substring(object_name, 1,30) as object_name, substring(counter_name, 1,30) as counter_name,
       cntr_value, instance_name, cntr_type
  FROM sys.dm_os_performance_counters
 ORDER BY object_name, counter_name;

select 'Copyright 2025 meob' as copyright, 'Apache-2.0' as license, 'https://github.com/meob/db2txt' as sources;
select CURRENT_TIMESTAMP as report_date;


