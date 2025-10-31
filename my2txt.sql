select 'my2txt: MySQL TXT-Report ' as title,
       now() as report_date,
       user() as by_user,
       'v.1.0.3' as version;

use information_schema;
select 'Version :' as summary_info, version() as value
union all
select 'Created :', min(create_time)
from tables
union all
select 'Started :', date_format(date_sub(now(), INTERVAL variable_value second),'%Y-%m-%d %T')
from performance_schema.global_status
where variable_name='UPTIME'
union all
select 'DB Size (MB):',
        format(sum(data_length+index_length)/(1024*1024),0)
from tables
union all
select 'Buffers Size (MB):',
	format(sum(variable_value+0)/(1024*1024),0)
from performance_schema.global_variables
where lower(variable_name) like '%buffer_size' or lower(variable_name) like '%buffer_pool_size'
union all
select 'Logging Bin. :', variable_value
from performance_schema.global_status
where variable_name='LOG_BIN'
union all
select 'Defined Users :', format(count(*),0)
from mysql.user
union all
select 'Defined Schemata :', count(*)
from schemata
where schema_name not in ('information_schema')
union all
select 'Defined Tables :', format(count(*),0)
from tables
union all
select 'Sessions :', format(count(*),0)
  from performance_schema.processlist
 union all
select 'Sessions (active) :', format(count(*),0)
  from performance_schema.processlist
 where command <> 'Sleep'
union all
select 'Questions (#/sec.) :', format(g1.variable_value/g2.variable_value,5)
  from performance_schema.global_status g1, performance_schema.global_status g2
 where g1.variable_name='QUESTIONS'
   and g2.variable_name='UPTIME'
union all
select 'BinLog Writes Day (MB) :', format((g1.variable_value*60*60*24)/(g2.variable_value*1024*1024),0)
  from performance_schema.global_status g1, performance_schema.global_status g2
 where g1.variable_name='INNODB_OS_LOG_WRITTEN'
   and g2.variable_name='UPTIME'
union all
select 'Hostname :', variable_value
  from performance_schema.global_variables
 where variable_name ='hostname'
union all
select 'Port :', variable_value
  from performance_schema.global_variables
 where variable_name ='port';

select version() as version
union all
select ' Latest Releases (MySQL):   9.5.0, 8.4.7, 8.0.44'
union all
select ' Latest Releases (MariaDB): 12.0, 11.8.3, 11.7.2, 11.6.2, 11.5.2, 11.4.8, 10.11.14, 10.6.22, 10.5.29'
union all
select ' Latest Releases (Aurora): 3.08.1-8.0.39, 2.12.4-5.7.44'
union all
select ' Desupported (MySQL):   8.4.0, 8.3.0, 8.2.0, 8.1.0; 5.7.44, 5.6.51, 5.5.62, 5.1.73, 5.0.96'
union all
select ' Desupported (MariaDB): 11.3.2, 11.2.6, 11.1.6, 11.0.6, 10.10.7, 10.9.8, 10.8.8, 10.7.8, 10.4.34, 10.3.39, 10.2.44, 10.1.48, 10.0.38, 5.5.68'
union all
select ' Desupported (Aurora):  1.23.4-5.6';

select sk as schema_matrix,
       sum(if(otype='T',1,0)) as tables,
       sum(if(otype='I',1,0)) as indexes,
       sum(if(otype='R',1,0)) as routines,
       sum(if(otype='E',1,0)) as triggers,
       sum(if(otype='V',1,0)) as views,
       sum(if(otype='P',1,0)) as primary_keys,
       sum(if(otype='F',1,0)) as foreign_keys,
       count(*) as all_objects
from ( select 'T' otype, table_schema sk, table_name name
  from tables
  union
 select 'I' otype, constraint_schema sk, concat(table_name,'.',constraint_name) name
  from key_column_usage
  where ordinal_position=1
  union
 select 'R' otype, routine_schema sk, routine_name name
  from routines
  union
 select 'E' otype, trigger_schema sk, trigger_name name
  from triggers
  union
 select 'V' otype, table_schema sk, table_name name
  from views 
  union
 select distinct 'P' otype, CONSTRAINT_SCHEMA sk, TABLE_NAME name
  from KEY_COLUMN_USAGE
  where  CONSTRAINT_NAME='PRIMARY'
  union
 select distinct 'F' otype, CONSTRAINT_SCHEMA sk, concat(TABLE_NAME,'-',CONSTRAINT_NAME) name
  from KEY_COLUMN_USAGE
  where REFERENCED_TABLE_NAME is not null
     ) a
group by sk with rollup;

select index_type,
       if(non_unique, 'Not Unique', 'UNIQUE') as uniqueness,
       count(distinct table_schema,table_name, index_name) as count_idx,
       avg(seq_in_index) as avg_keys,
       max(seq_in_index) as max_keys,
       count(*) as columns_idx
  from statistics
 group by index_type, non_unique;

SELECT t.TABLE_SCHEMA, t.TABLE_NAME as unindexed_tables, t.ENGINE, t.TABLE_ROWS
  FROM information_schema.TABLES t
 INNER JOIN information_schema.COLUMNS c ON t.TABLE_SCHEMA=c.TABLE_SCHEMA
            AND t.TABLE_NAME=c.TABLE_NAME
 WHERE t.TABLE_SCHEMA NOT IN ('performance_schema','information_schema','mysql','sys')
   AND t.TABLE_ROWS >100
   AND t.TABLE_TYPE in ('BASE TABLE')
 GROUP BY t.TABLE_SCHEMA,t.TABLE_NAME, t.ENGINE, t.TABLE_ROWS
   HAVING sum(if(column_key in ('PRI','UNI'), 1,0))=0
 ORDER BY 2, 4
 limit 100;

select TABLE_ID,
        NAME as orphaned_tables,
        FLAG,
        ROW_FORMAT
  from INNODB_TABLES
 where name like "%/#%"
 limit 100;

select table_schema,
       format(sum(table_rows),0) as rows_,
       format(sum(data_length),0) as data_size,
       format(sum(index_length),0) as index_size,
       format(sum(data_free),0) as free,
       format(sum(data_length+index_length),0) as total_size,
       format(sum((data_length+index_length)*
	if(engine='MyISAM',1,0)),0) as MyISAM_size,
       format(sum((data_length+index_length)*
	if(engine='InnoDB',1,0)),0) as InnoDB_size,
       format(sum((data_length+index_length)*
	if(engine='Memory',1,0)),0) as Memory_size,
       format(sum((data_length+index_length)*
	if(engine='Memory',0,if(engine='MyISAM',0,if(engine='InnoDB',0,1)))),0) as other_size,
       date_format(min(create_time),'%Y-%m-%d') as created
from tables
group by table_schema with rollup;

select SUBSTRING_INDEX(name,'/',1) as "tablespace",
	format(sum(FILE_SIZE),0) as size
  from information_schema.INNODB_TABLESPACES
 group by SUBSTRING_INDEX(name,'/',1) with rollup;

select table_schema,
  count(distinct table_name) as tables,  count(*) as partitions
 from information_schema.partitions
 where partition_name is not null
 group by table_schema;

select table_schema,
       table_name,
       partition_method, ifnull(subpartition_method,'') as subpartition_method,
       count(distinct partition_name) as partitions,
       count(distinct subpartition_name) as subpartitions,
       min(partition_name) min_partition,
       max(partition_name) max_partition,
       sum(table_rows) as "rows",
       sum(coalesce(DATA_LENGTH,0)+coalesce(INDEX_LENGTH,0)) as "size"
  from partitions
 where partition_name is not null
 group by table_schema, table_name, subpartition_name, partition_method, subpartition_method
 order by table_schema, table_name, subpartition_name
 limit 29;

SELECT user as user_list, 
       host,
       CONCAT(Select_priv, Lock_tables_priv,' ',
       Insert_priv, Update_priv, Delete_priv, ' ', Create_priv, Drop_priv,
       Grant_priv, References_priv, Index_priv, Alter_priv, ' ',
       Create_tmp_table_priv, Create_view_priv, Show_view_priv, ' ',
       Create_routine_priv, Alter_routine_priv, Execute_priv, ' ',
       Repl_slave_priv, Repl_client_priv, ' ',
       Super_priv, Shutdown_priv, Process_priv, File_priv, Show_db_priv, Reload_priv) AS grt,
       select_priv, 
       execute_priv, 
       grant_priv,
       if(authentication_string<>'','','NO PWD') pwd,
       password_expired as pwd_expired,
       password_lifetime as pwd_lifetime,
       account_locked,
       plugin
FROM mysql.user d
order by user,host;

SELECT user, 
       host, 
       db, 
       select_priv, 
       execute_priv, 
       grant_priv
FROM mysql.db d
order by user,host;

SELECT DISTINCT User, if(from_user is NULL, 0, 1) as role_edges
  FROM mysql.user LEFT JOIN mysql.role_edges ON from_user=user 
 WHERE account_locked='Y'
   AND password_expired='Y'
   AND authentication_string='';

(select distinct concat(user,'@',host) User, 'Admin' as virtual_role
  from mysql.user
 where insert_priv='Y' or delete_priv='Y'
 order by 1)
union all
(select distinct concat(user,'@',host), 'Operator' as role
  from mysql.user
 where select_priv='Y'
   and concat(user,'@',host) not in (
	select concat(user,'@',host)
	  from mysql.user
	 where insert_priv='Y' or delete_priv='Y')
 order by 1)
union all
(select distinct concat(user,'@',host), 'Schema Owner' as role
  from mysql.db
 where create_priv='Y')
union all
(select distinct concat(user,'@',host), 'CRUD' as role
  from mysql.db
 where insert_priv='Y'
   and concat(user,'@',host) not in (
	select concat(user,'@',host)
	  from mysql.db
	 where create_priv='Y')
 order by 1)
union all 
(select distinct concat(user,'@',host), 'Read Only' as role
  from mysql.db
 where select_priv='Y'
   and concat(user,'@',host) not in (
	select concat(user,'@',host)
	  from mysql.db
	 where insert_priv='Y')
 order by 1)
union all
(select distinct concat(user,'@',host), 'Other' as role
  from mysql.user
 where concat(user,'@',host) not in (
	select concat(user,'@',host)
	  from mysql.db
	 where select_priv='Y')
   and concat(user,'@',host) not in (
	select concat(user,'@',host)
	  from mysql.user
	 where select_priv='Y')
 order by 1);

SELECT user, 
       host, 
	'' as password,
	'Empty password' as note
FROM mysql.user
WHERE authentication_string = ''
  AND (account_locked<>'Y' OR password_expired<>'Y')
union all
SELECT user, 
       host, 
       authentication_string,
      'Same as username'
FROM mysql.user
WHERE authentication_string = UPPER(CONCAT('*', CAST(SHA1(UNHEX(SHA1(user))) AS CHAR)))
   OR authentication_string = UPPER(CONCAT('*', CAST(SHA2(UNHEX(SHA2(user,256)),256) AS CHAR)))
union all
SELECT host, 
       user, 
       authentication_string,
	'Weak password'
FROM mysql.user
WHERE authentication_string in ('*81F5E21E35407D884A6CD4A731AEBFB6AF209E1B', '*14E65567ABDB5135D0CFD9A70B3032C179A49EE7',
      '*2470C0C06DEE42FD1618BB99005ADCA2EC9D1E19', '*6C8989366EAF75BB670AD8EA7A7FC1176A95CEF4',
      '*A80082C9E4BB16D9C8E41B0D7EED46126DF4A46E', '*85BB02300F877EB061967510E83F68B1A7325252',
      '*A4B6157319038724E3560894F7F932C8886EBFCF', '*4ACFE3202A5FF5CF467898FC58AAB1D615029441',
      '*A36BA850A6E748679226B01E159EF1A7BF946195', '*196BDEDE2AE4F84CA44C47D54D78478C7E2BD7B7',
      '*E74858DB86EBA20BC33D0AECAE8A8108C56B17FA', '*AF35041D44DF3E88C9F97CC8D3ACAF4695E65B69',
      UPPER(CONCAT('*', CAST(SHA1(UNHEX(SHA1('prova'))) AS CHAR))),
      UPPER(CONCAT('*', CAST(SHA1(UNHEX(SHA1('test'))) AS CHAR))),
      UPPER(CONCAT('*', CAST(SHA1(UNHEX(SHA1('demo'))) AS CHAR))),
      UPPER(CONCAT('*', CAST(SHA1(UNHEX(SHA1('qwerty'))) AS CHAR))),
      UPPER(CONCAT('*', CAST(SHA1(UNHEX(SHA1('manager'))) AS CHAR))),
      UPPER(CONCAT('*', CAST(SHA1(UNHEX(SHA1('supervisor'))) AS CHAR))),
      UPPER(CONCAT('*', CAST(SHA1(UNHEX(SHA1('toor'))) AS CHAR))),
      UPPER(CONCAT('*', CAST(SHA1(UNHEX(SHA1('Qwerty'))) AS CHAR))),
      UPPER(CONCAT('*', CAST(SHA1(UNHEX(SHA1('xxx'))) AS CHAR))),
      UPPER(CONCAT('*', CAST(SHA1(UNHEX(SHA1('moodle'))) AS CHAR))),
      UPPER(CONCAT('*', CAST(SHA1(UNHEX(SHA1('drupal'))) AS CHAR))),
      UPPER(CONCAT('*', CAST(SHA1(UNHEX(SHA1('admin01'))) AS CHAR))),
      UPPER(CONCAT('*', CAST(SHA1(UNHEX(SHA1('joomla'))) AS CHAR))),
      UPPER(CONCAT('*', CAST(SHA1(UNHEX(SHA1('wp'))) AS CHAR))),
      UPPER(CONCAT('*', CAST(SHA1(UNHEX(SHA1('ilikerandompasswords'))) AS CHAR))),
      UPPER(CONCAT('*', CAST(SHA1(UNHEX(SHA1('changeme'))) AS CHAR))) )
union all
SELECT host, 
       user, 
       authentication_string,
	'Old [pre 4.1] password format'
FROM mysql.user
WHERE authentication_string not like '*%'
  AND authentication_string not like '$%'
  AND authentication_string <> ''
union all
SELECT host, 
       user, 
       authentication_string,
	'Suspected backdoor user'
FROM mysql.user
WHERE user in ('hanako', 'kisadminnew1', '401hk$', 'guest', 'Huazhongdiguo110');

select 'Global Caches' as estimated_memory_usage,
       format(sum(variable_value)/(1024*1024),0) as size
from performance_schema.global_variables
where lower(variable_name) in (
'innodb_buffer_pool_size',
'query_cache_size',
'innodb_additional_mem_pool_size',
'innodb_log_file_size',
'innodb_log_buffer_size',
'key_buffer_size',
'table_open_cache',
'tmp_table_size')
union all
select 'Session Memory', sum(total_memory_allocated)  
  from sys.user_summary
union all
select concat('Estimated Client Alloc. (max conn:', max(g2.variable_value),')'),
       format(sum(g1.variable_value*g2.variable_value)/(1024*1024),0)
from performance_schema.global_variables g1, performance_schema.global_status g2
where lower(g1.variable_name) in (
'binlog_cache_size',
'binlog_stmt_cache_size',
'read_buffer_size',
'read_rnd_buffer_size',
'sort_buffer_size',
'join_buffer_size',
'thread_stack')
and lower(g2.variable_name)='max_used_connections';

SELECT  total_allocated as memory_total_allocated FROM sys.memory_global_total;

SELECT  variable_name as perf_tuning_parameter, variable_value as value, 'Query Cache' as type
from performance_schema.global_variables
where lower(variable_name) in ('query_cache_type')
union all
SELECT  variable_name, variable_value, 'Tuning and timeout'
from performance_schema.global_variables
where lower(variable_name) in (
'log_bin',
'slow_query_log')
union all
SELECT  variable_name, format(variable_value,0), 'Cache'
from performance_schema.global_variables
where lower(variable_name) in (
'innodb_buffer_pool_size',
'query_cache_size',
'innodb_additional_mem_pool_size',
'innodb_log_file_size',
'innodb_log_buffer_size',
'key_buffer_size',
'table_open_cache',
'tmp_table_size',
'max_heap_table_size',
'foo')
union all
SELECT  variable_name, format(variable_value,0), 'Tuning and timeout'
from performance_schema.global_variables
where lower(variable_name) in (
'innodb_flush_log_at_trx_commit',
'innodb_flush_log_at_timeout',
'innodb_log_files_in_group',
'innodb_lock_wait_timeout',
'innodb_thread_concurrency',
'skip-external-locking',
'wait_timeout',
'long_query_time',
'sync_binlog',
'foo')
union all
SELECT  variable_name, format(variable_value,0), 'Client Cache'
from performance_schema.global_variables
where lower(variable_name) in (
'binlog_cache_size',
'binlog_stmt_cache_size',
'max_connections',
'read_buffer_size',
'read_rnd_buffer_size',
'sort_buffer_size',
'join_buffer_size',
'thread_stack',
'foo')
order by 3, 1;

SELECT  engine,
       support,
       comment
from engines
order by support;

SELECT user, count(*) connections
from performance_schema.processlist
group by user
order by 2 desc;

SELECT id, user, host, db, command, time,
       state, substr(replace(info, '\n', ' ') ,1,64) as current_query
from performance_schema.processlist
order by id;

SELECT trx_mysql_thread_id, trx_id, trx_state, trx_started, trx_weight,
       trx_requested_lock_id, trx_query, trx_operation_state, trx_isolation_level
 from INFORMATION_SCHEMA.innodb_trx;

SELECT REQUESTING_ENGINE_TRANSACTION_ID, REQUESTING_ENGINE_LOCK_ID,
        BLOCKING_ENGINE_TRANSACTION_ID,  BLOCKING_ENGINE_LOCK_ID
  from performance_schema.data_lock_waits;

SELECT engine_transaction_id, engine_lock_id, lock_mode, lock_type, lock_status, lock_data
  from performance_schema.data_locks;

SELECT if(SPACE=0,'System','FilePerTable') TBS, ROW_FORMAT,
       count(*) TABS, sum(N_COLS-3) COLS
  FROM INFORMATION_SCHEMA.INNODB_TABLES
 group by ROW_FORMAT, if(SPACE=0,'System','FilePerTable');

select concat(variable_name, ' (days)') as statistic,
       round(variable_value/(3600*24),1) as value,
       '' as suggested_value,
       '' as action
from performance_schema.global_status
where variable_name='UPTIME'
union all
select 'Buffer Cache: MyISAM Read Hit Ratio', format(100-t1.variable_value*100/t2.variable_value,2), '>95', 'Increase KEY_BUFFER_SIZE'
from performance_schema.global_status t1, performance_schema.global_status t2
where t1.variable_name='KEY_READS' and t2.variable_name='KEY_READ_REQUESTS'
  and t2.variable_value>0
union all
select 'Buffer Cache: InnoDB Read Hit Ratio', format(100-t1.variable_value*100/t2.variable_value,2), '>95', 'Increase INNODB_BUFFER_SIZE'
from performance_schema.global_status t1, performance_schema.global_status t2
where t1.variable_name='INNODB_BUFFER_POOL_READS' and t2.variable_name='INNODB_BUFFER_POOL_READ_REQUESTS'
union all
select 'Buffer Cache: MyISAM Write Hit Ratio',
 format(100-t1.variable_value*100/t2.variable_value,2), '>95', 'Increase KEY_BUFFER_SIZE'
from performance_schema.global_status t1, performance_schema.global_status t2
where t1.variable_name='KEY_WRITES' and t2.variable_name='KEY_WRITE_REQUESTS'
  and t2.variable_value>0
union all
select 'Log Cache: InnoDB Log Write Ratio',
 format(100-t1.variable_value*100/t2.variable_value,2), '>95', 'Increase INNODB_LOG_BUFFER_SIZE'
from performance_schema.global_status t1, performance_schema.global_status t2
where t1.variable_name='INNODB_LOG_WRITES' and t2.variable_name='INNODB_LOG_WRITE_REQUESTS' and t2.variable_value>0
union all
select 'Query Cache: Efficiency (Hit/Select)',
 format(t1.variable_value*100/(t1.variable_value+t2.count_star),2), ' >30', ''
from performance_schema.global_status t1, performance_schema.events_statements_summary_global_by_event_name t2
where t1.variable_name='QCACHE_HITS'
  and t2.event_name='statement/sql/select'
  and t1.variable_value+t2.count_star>0
union all
select 'Query Cache: Hit ratio (Hit/Query Insert)',
 format(t1.variable_value*100/(t1.variable_value+t2.variable_value),2), ' >80', ''
from performance_schema.global_status t1, performance_schema.global_status t2
where t1.variable_name='QCACHE_HITS'
  and t2.variable_name='QCACHE_INSERTS'
  and t1.variable_value+t2.variable_value>0
union all
select s.variable_name, concat(s.variable_value, ' /', v.variable_value),
 'Far from maximum', 'Increase MAX_CONNECTIONS'
from performance_schema.global_status s, performance_schema.global_variables v
where s.variable_name='THREADS_CONNECTED'
and v.variable_name='MAX_CONNECTIONS'
union all
select variable_name, variable_value, 'LOW', 'Check user load'
from performance_schema.global_status
where variable_name='THREADS_RUNNING'
union all
select variable_name, format(variable_value,0), 'LOW', 'Check application'
from performance_schema.global_status
where variable_name='SLOW_QUERIES'
union all
select concat(g1.variable_name, ' #/sec.'), format(g1.variable_value/g2.variable_value,5), '', ''
from performance_schema.global_status g1, performance_schema.global_status g2
where g1.variable_name='QUESTIONS'
  and g2.variable_name='UPTIME'
union all
select 'SELECT    #/sec. ', format(g1.count_star/g2.variable_value,5), '', ''
from performance_schema.events_statements_summary_global_by_event_name g1, performance_schema.global_status g2
where g1.EVENT_NAME = 'statement/sql/select'
  and g2.variable_name='UPTIME'
union all
select 'COMMIT    #/sec. (TPS) ', format(g1.count_star/g2.variable_value,5), '', ''
from performance_schema.events_statements_summary_global_by_event_name g1, performance_schema.global_status g2
where g1.EVENT_NAME = 'statement/sql/commit'
  and g2.variable_name='UPTIME'
union all
select 'COM DML   #/sec.',
       format((g2.count_star+g3.count_star+g4.count_star+g5.count_star+g6.count_star
               +g7.count_star+g8.count_star+g9.count_star)/g1.variable_value,5),
       '', ''
from performance_schema.global_status g1, performance_schema.events_statements_summary_global_by_event_name g2,
     performance_schema.events_statements_summary_global_by_event_name g3, performance_schema.events_statements_summary_global_by_event_name g4,
     performance_schema.events_statements_summary_global_by_event_name g5, performance_schema.events_statements_summary_global_by_event_name g6,
     performance_schema.events_statements_summary_global_by_event_name g7, performance_schema.events_statements_summary_global_by_event_name g8,
     performance_schema.events_statements_summary_global_by_event_name g9
where g1.variable_name='UPTIME'
  and g2.event_name='statement/sql/insert'
  and g3.event_name ='statement/sql/update'
  and g4.event_name ='statement/sql/delete'
  and g5.event_name ='statement/sql/select'
  and g6.event_name ='statement/sql/update_multi'
  and g7.event_name ='statement/sql/delete_multi'
  and g8.event_name ='statement/sql/replace'
  and g9.event_name ='statement/sql/replace_select'
union all
select concat(g1.variable_name, ' #/sec. '), format(g1.variable_value/g2.variable_value,5), '', ''
from performance_schema.global_status g1, performance_schema.global_status g2
where g1.variable_name='CONNECTIONS'
  and g2.variable_name='UPTIME'
union all
select concat(g1.variable_name, ' Mb/sec. '),
       format(g1.variable_value*8/(g2.variable_value*1024*1024),5), '', ''
from performance_schema.global_status g1, performance_schema.global_status g2
where g1.variable_name='BYTES_SENT'
  and g2.variable_name='UPTIME'
union all
select concat(g1.variable_name, ' Mb/sec. '),
       format(g1.variable_value*8/(g2.variable_value*1024*1024),5), '', ''
from performance_schema.global_status g1, performance_schema.global_status g2
where g1.variable_name='BYTES_RECEIVED'
  and g2.variable_name='UPTIME'
union all
select 'DBcpu (SUM_TIMER_WAIT)', 
       format((sum(SUM_TIMER_WAIT)/1000000000000)/variable_value, 5), '', ''
  from performance_schema.global_status, performance_schema.events_statements_summary_global_by_event_name
 where variable_name='UPTIME'
 group by variable_value
union all
select concat( g1.variable_name, ' #/hour ') as KPI,
       format((g1.variable_value*60*60)/g2.variable_value,5) as Value,  '', 'Increase TABLE_OPEN_CACHE' as Suggestion
from performance_schema.global_status g1, performance_schema.global_status g2
where g1.variable_name='OPENED_TABLES'
  and g2.variable_name='UPTIME'
  and g1.variable_value*60*60/g2.variable_value>12
union all
select concat(g1.variable_name, ' #/hour '),
       format((g1.variable_value*60*60)/g2.variable_value,5), '', 'Increase SORT_BUFFER_SIZE'
from performance_schema.global_status g1, performance_schema.global_status g2
where g1.variable_name='SORT_MERGE_PASSES'
  and g2.variable_name='UPTIME'
  and g1.variable_value*60*60/g2.variable_value>12
union all
select concat( g1.variable_name, ' % '),
       format(g1.variable_value*100/(g1.variable_value+g2.variable_value),5),  'LOW', 'Increase MAX_HEAP_TABLE_SIZE and TMP_TABLE_SIZE'
from performance_schema.global_status g1, performance_schema.global_status g2
where g1.variable_name='CREATED_TMP_DISK_TABLES'
  and g2.variable_name='CREATED_TMP_TABLES'
  and g1.variable_value/g2.variable_value>0.1
union all
select concat( g1.variable_name, ' % '),
       format(g1.variable_value*100/(g2.variable_value),5), '', 'Increase BINLOG_CACHE_SIZE'
from performance_schema.global_status g1, performance_schema.global_status g2
where g1.variable_name='BINLOG_CACHE_DISK_USE'
  and g2.variable_name='BINLOG_CACHE_USE'
  and g1.variable_value/g2.variable_value>0.2
union all
select concat( g1.variable_name, ' #/hour '),
       format((g1.variable_value*60*60)/g2.variable_value,5),  '', 'Increase INNODB_LOG_BUFFER_SIZE'
from performance_schema.global_status g1, performance_schema.global_status g2
where g1.variable_name='INNODB_LOG_WAITS'
  and g2.variable_name='UPTIME'
  and g1.variable_value*60*60/g2.variable_value>1
union all
select concat( g1.variable_name, ' MB/hour '),
       format((g1.variable_value*60*60)/(g2.variable_value*1024*1024),5),  '', 'Tune INNODB_LOG_FILE_SIZE'
from performance_schema.global_status g1, performance_schema.global_status g2
where g1.variable_name='INNODB_OS_LOG_WRITTEN'
  and g2.variable_name='UPTIME'
  and (g1.variable_value*60*60)/(g2.variable_value*1024*1024)>5;

SELECT EVENT_NAME,  COUNT_STAR,  SUM_TIMER_WAIT,
         SEC_TO_TIME(SUM_TIMER_WAIT/1000000000000) hr_time
  from performance_schema.events_statements_summary_global_by_event_name
 where count_star > 0 
 order by SUM_TIMER_WAIT desc 
 limit 10;
SELECT EVENT_NAME,  COUNT_STAR,  SUM_TIMER_WAIT,
         SEC_TO_TIME(SUM_TIMER_WAIT/1000000000000)  hr_time
  from performance_schema.events_waits_summary_global_by_event_name  
 where count_star > 0 
   and event_name != 'idle'
 order by SUM_TIMER_WAIT desc 
 limit 10;
SELECT OBJECT_TYPE,  OBJECT_SCHEMA,  OBJECT_NAME,
         COUNT_STAR,   SUM_TIMER_WAIT,
         SEC_TO_TIME(SUM_TIMER_WAIT/1000000000000) hr_time
  from performance_schema.table_lock_waits_summary_by_table
 where count_star > 0 
 order by SUM_TIMER_WAIT desc 
 limit 10;
SELECT EVENT_NAME, COUNT_STAR, SUM_TIMER_WAIT,
         SEC_TO_TIME(SUM_TIMER_WAIT/1000000000000) hr_time
  from performance_schema.file_summary_by_event_name order by SUM_TIMER_WAIT desc limit 10;

SELECT FILE_NAME,EVENT_NAME, COUNT_STAR, SUM_TIMER_WAIT, 
 SEC_TO_TIME(SUM_TIMER_WAIT/1000000000000) hr_time, 
 COUNT_READ, SUM_TIMER_READ, SUM_NUMBER_OF_BYTES_READ, 
 COUNT_WRITE, SUM_TIMER_WRITE, SUM_NUMBER_OF_BYTES_WRITE
  from performance_schema.file_summary_by_instance order by SUM_TIMER_WAIT desc limit 10;

SELECT SCHEMA_NAME, COUNT_STAR, 
 SUM_TIMER_WAIT, SEC_TO_TIME(SUM_TIMER_WAIT/1000000000000) hr_time, 
 round(AVG_TIMER_WAIT/1000000000000,3) AVG_TIMER_WAIT, 
 SUM_ROWS_SENT, concat('\n', substring(DIGEST_TEXT, 1, 128)) as query_top20
  from performance_schema.events_statements_summary_by_digest order by SUM_TIMER_WAIT desc limit 20;
SELECT SCHEMA_NAME, COUNT_STAR, 
 SUM_TIMER_WAIT, SEC_TO_TIME(SUM_TIMER_WAIT/1000000000000) hr_time, 
 round(AVG_TIMER_WAIT/1000000000000,3) AVG_TIMER_WAIT, 
 SUM_ROWS_SENT, concat('\n', substring(DIGEST_TEXT, 1, 128)) as query_slow
  from performance_schema.events_statements_summary_by_digest order by AVG_TIMER_WAIT desc limit 5;

SELECT table_schema,
       table_name,
	'T',engine,
	format(data_length+index_length,0),
	format(table_rows,0)
from  information_schema.tables
order by data_length+index_length desc
limit 32;

SELECT HOST,  CURRENT_CONNECTIONS,  TOTAL_CONNECTIONS
  from performance_schema.hosts
 order by CURRENT_CONNECTIONS desc, TOTAL_CONNECTIONS desc;

select count(distinct HOST) as total_hosts,  sum(CURRENT_CONNECTIONS),  sum(TOTAL_CONNECTIONS)
  from performance_schema.hosts;

SELECT host,  ip,  host_validated,
       SUM_CONNECT_ERRORS ERR,
       FIRST_SEEN,  LAST_SEEN,  LAST_ERROR_SEEN,
       COUNT_HANDSHAKE_ERRORS,
       COUNT_AUTHENTICATION_ERRORS,
       COUNT_HOST_ACL_ERRORS
from performance_schema.host_cache;

select @@global.max_connect_errors;

SHOW BINARY LOG STATUS;
SHOW VARIABLES LIKE 'rpl_semi_sync_master_%';
SHOW STATUS LIKE 'rpl_semi_sync_master_status';

show binary logs;
SHOW VARIABLES LIKE '%READ_ONLY%';
SHOW VARIABLES LIKE 'rpl_semi_sync_slave_enabled';
SHOW STATUS LIKE 'rpl_semi_sync_slave_status';
show status where variable_name in ('wsrep_cluster_size', 'wsrep_cluster_status', 'wsrep_flow_control_paused', 'wsrep_ready', 'wsrep_connected', 'wsrep_local_state_comment');
show status where variable_name in ('wsrep_local_state', 'wsrep_local_recv_queue', 'wsrep_reject_queries', 'wsrep_sst_donor_rejects_queries', 'wsrep_cluster_status', 'wsrep_desync');

SELECT CHANNEL_NAME, HOST, PORT, USER, AUTO_POSITION,
       SSL_ALLOWED, HEARTBEAT_INTERVAL
  from performance_schema.replication_connection_configuration;

SELECT CHANNEL_NAME, GROUP_NAME, SOURCE_UUID, THREAD_ID,
       SERVICE_STATE, COUNT_RECEIVED_HEARTBEATS,
       LAST_HEARTBEAT_TIMESTAMP, RECEIVED_TRANSACTION_SET, LAST_ERROR_NUMBER,
       LAST_ERROR_MESSAGE, LAST_ERROR_TIMESTAMP 
  from performance_schema.replication_connection_status;

SELECT CHANNEL_NAME, THREAD_ID, SERVICE_STATE, LAST_ERROR_NUMBER,
       LAST_ERROR_MESSAGE, LAST_ERROR_TIMESTAMP
  from performance_schema.replication_applier_status_by_coordinator;

SELECT CHANNEL_NAME, WORKER_ID, THREAD_ID,
       SERVICE_STATE, LAST_APPLIED_TRANSACTION,
       LAST_ERROR_NUMBER, LAST_ERROR_MESSAGE, LAST_ERROR_TIMESTAMP 
  from performance_schema.replication_applier_status_by_worker;

SELECT MEMBER_HOST, MEMBER_PORT, MEMBER_ID, MEMBER_STATE
  from performance_schema.replication_group_members;

SELECT  VARIABLE_VALUE,  concat(member_host, ':', member_port) as member
  FROM performance_schema.global_status
  JOIN performance_schema.replication_group_members
 WHERE VARIABLE_NAME= 'group_replication_primary_member'
   AND member_id=variable_value;

SELECT  variable_name,  variable_value
  from performance_schema.global_variables
 where variable_name = 'server_uuid'
 order by variable_name;
SELECT  variable_name,  variable_value
  from performance_schema.global_variables
 where variable_name like '%gtid%'
 order by variable_name;

SELECT concat(table_schema,'.',table_name) as check4replica, engine, table_rows, 
       round((index_length+data_length)/1024/1024,2), 'Check Engine' as note
  FROM information_schema.tables 
 WHERE (engine != 'InnoDB')
   AND table_schema NOT IN ('information_schema', 'mysql', 'performance_schema')
 ORDER BY table_schema, table_name;
SELECT concat(tables.table_schema,'.',tables.table_name) as check4replica, tables.engine, 'Check PK' as note
  FROM information_schema.tables 
  LEFT JOIN (SELECT table_schema, table_name 
               FROM information_schema.statistics 
              GROUP BY table_schema, table_name, index_name
             HAVING SUM(case when non_unique = 0 and nullable != 'YES' then 1 else 0 end) = count(*) ) puks 
         ON tables.table_schema = puks.table_schema and tables.table_name = puks.table_name 
 WHERE puks.table_name is null 
   AND tables.table_type = 'BASE TABLE' AND Engine="InnoDB";
SELECT event_name check4replica, count_star, sum_errors, 'Check SAVEPOINT' as note
  FROM performance_schema.events_statements_summary_global_by_event_name 
 WHERE event_name  like '%savepoint%'
   AND count_star>0;
SELECT event_name check4replica, count_star, sum_errors, 'Check DDLs' as note
  FROM performance_schema.events_statements_summary_global_by_event_name 
 WHERE event_name  REGEXP '.*sql/(create|drop|alter).*' 
   AND event_name NOT REGEXP '.*user'
   AND count_star>0;

 SELECT routine_schema, 
   routine_type, 
   count(*)
 from routines
 group by routine_schema, routine_type;
 SELECT table_schema, 
   data_type, 
   count(*)
 from columns
 where table_schema not in ('mysql', 'performance_schema', 'information_schema', 'sys')
 group by table_schema, data_type
 order by table_schema, data_type;

SELECT  variable_value as scheduler_variable
  from performance_schema.global_variables
 where variable_name='EVENT_SCHEDULER';
SELECT concat(event_schema,'.',event_name) as event_name, 
   status,
   event_type,
   ifnull(execute_at,'') as exec_at,
   ifnull(interval_value,'') as interval_value, ifnull(interval_field,'') as interval_unit,
   event_definition
  from events;

SELECT schema_name,  DEFAULT_CHARACTER_SET_NAME,  DEFAULT_COLLATION_NAME
  FROM information_schema.SCHEMATA
 where schema_name not in ('mysql', 'information_schema', 'sys', 'performance_schema', 'test', 'tmpdir')
   and schema_name not like '%lost+found'
 order by schema_name;
SELECT table_schema,  CHARACTER_SET_NAME,  COLLATION_NAME,  count(*)
  FROM information_schema.COLUMNS
 where table_schema not in ('mysql', 'information_schema', 'sys', 'performance_schema', 'test')
   and CHARACTER_SET_NAME is not null
 group by table_schema, CHARACTER_SET_NAME, COLLATION_NAME
union
SELECT  'TOTAL',  CHARACTER_SET_NAME,  COLLATION_NAME,  count(*)
  FROM information_schema.COLUMNS
 where table_schema not in ('mysql', 'information_schema', 'sys', 'performance_schema', 'test')
   and CHARACTER_SET_NAME is not null
 group by CHARACTER_SET_NAME , COLLATION_NAME;

SELECT  variable_name as global_status, variable_value as value
  from performance_schema.global_variables
 where variable_name not in('server_audit_loc_info', 'Caching_sha2_password_rsa_public_key', 'optimizer_switch', 'sql_mode', 'wsrep_provider_options')
 order by variable_name
 limit 29;
SELECT  variable_name as global_status, variable_value as value
  from performance_schema.global_variables
 where variable_name in('server_audit_loc_info', 'optimizer_switch', 'sql_mode', 'wsrep_provider_options')
 order by variable_name
 limit 29;
SELECT  variable_name as status_variable, variable_value as value
  from performance_schema.global_status
 where variable_name not in('Caching_sha2_password_rsa_public_key','Rsa_public_key')
 order by variable_name;

select 'Copyright 2025 meob' as copyright, 'Apache-2.0' as license, 'https://github.com/meob/db2txt' as sources;
select concat('Report terminated on: ', now()) as report_date;

