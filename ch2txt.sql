select 'ch2txt: ClickHouse TXT-Report ' as title,
       now() as report_date,
       user() as by_user,
       'v.1.0.3' as version;

use system;
select 'Version :' as summary_info, version() as value
union all
select 'Created :', toString(min(metadata_modification_time))
  from system.tables
 where metadata_modification_time<>'0000-00-00 00:00:00'
union all
select 'Started :', toString(now()-uptime())
union all
select 'DB Size :', formatReadableSize(sum(bytes_on_disk))
  from system.parts
union all
select 'Max Memory (configured) :', formatReadableSize(toInt64(value))
  from system.settings
 where name='max_memory_usage'
union all
select 'Max Memory (used last week) :', formatReadableSize(max(memory_usage))
  from system.query_log
 where type=2
   and event_time > now() - interval 7 day
union all
select 'Logged Users (last week) :', toString(count(distinct initial_user))
  from system.query_log where event_time > now() - interval 7 day
union all
select 'Schemata :', toString(count())
  from system.databases
union all
select 'Tables :', toString(count())
  from system.tables
union all
select 'Sessions (TCP) :', toString(value)
  from system.metrics
 where metric='TCPConnection'
union all
select 'Sessions (HTTP) :', toString(value)
  from system.metrics
 where metric='HTTPConnection'
union all
select 'Sessions (Replica) :', toString(value)
  from system.metrics
 where metric='InterserverConnection'
union all
select 'Sessions (active) :', toString(count())
  from system.processes
union all
select 'Query (#/hour) :', toString(round(count(*)/24,5))
  from system.query_log
 where event_time > now() - interval 1 day
union all
select 'Merges/Day :', formatReadableSize(value/uptime()*60*60*24)
  from system.events
 where event = 'MergedUncompressedBytes'
union all
select 'Hostname :', hostName();

select version from (
select version() as version, 1 as ord
union all
select toString(value), 2
  from system.metrics
 where metric='VersionInteger'
union all
select ' Latest Releases:  26.1.2.11, 25.12.5.44, 25.8.16.34-lts, 25.3.14.14-lts; ', 3
union all
select ' Desupported:      24.8.14.39-lts, 24.3.18.7-lts, 23.8.16.40−lts, 23.3.22.3−lts, 22.8.21.38-lts, 22.3.20.29−lts, 21.8.15.7-lts', 4)
order by ord;

select  sk as schema_matrix,
	sum(if(otype='T',1,0)) as tables,
	sum(if(otype='C',1,0)) as columns,
	sum(if(otype='A',1,0)) as partitions,
	sum(if(otype='P',1,0)) as parts,
	sum(if(otype='R',1,0)) as replicas,
	sum(if(otype='D',1,0)) as dictionaries,
	count(*) as TOTAL
from ( select 'T' otype, database sk, name
  from system.tables
  union all
 select 'C' otype, database sk, concat(table,'.',name) name
  from system.columns
  union all
 select distinct 'A' otype, database sk, concat(table,'.',partition) name
  from system.parts
  union all
 select 'P' otype, database sk, concat(table,'.',name) name
  from system.parts
  union all
 select 'R' otype, database sk, table name
  from system.replicas
  union all
 select 'D' otype, database sk, name
  from system.dictionaries
     ) a
group by sk
order by sk
union all
select 'TOTAL',
	sum(if(otype='T',1,0)),
	sum(if(otype='C',1,0)),
	sum(if(otype='A',1,0)),
	sum(if(otype='P',1,0)),
	sum(if(otype='R',1,0)),
	sum(if(otype='D',1,0)),
	count(*)
from ( select 'T' otype, database sk, name
  from system.tables
  union all
 select 'C' otype, database sk, concat(table,'.',name) name
  from system.columns
  union all
 select distinct 'A' otype, database sk, concat(table,'.',partition) name
  from system.parts
  union all
 select 'P' otype, database sk, concat(table,'.',name) name
  from system.parts
  union all
 select 'R' otype, database sk, table name
  from system.replicas
  union all
 select 'D' otype, database sk, name
  from system.dictionaries
     ) a;

select  database,
	sum(if(engine='MergeTree',1,0)) as MergeTree,
	sum(if(engine='AggregatingMergeTree',1,0)) as Agg_MTree,
	sum(if(engine='SummingMergeTree',1,0)) as Sum_MTree,
	sum(if(engine='ReplacingMergeTree',1,0)) as Repl_MTree,
	sum(if(engine='CollapsingMergeTree',1,0)) as Coll_MTree,
	sum(if(engine='VersionedCollapsingMergeTree',1,0)) as Ver_MTree,
	sum(if(engine like '%Log',1,0)) as _Log,
	sum(if(engine like 'Replicated%',1,0)) as Replicated,
	sum(if(engine like 'Distributed%',1,0)) as Distributed,
	sum(if(engine='View',1,0)) as View,
	sum(if(engine='Mat_View',1,0)) as MatView,
	sum(if(engine='Dictionary',1,0)) as Dictionary,
	sum(if(engine='Memory',1,0)) as Memory,
	sum(if(engine='Kafka',1,0)) as Kafka,
	sum(if(engine like 'System%',1,0)) as System,
	count(*) as TOTAL
  from system.tables
 group by database
 order by database
union all
select 'TOTAL',
	sum(if(engine='MergeTree',1,0)),
	sum(if(engine='AggregatingMergeTree',1,0)),
	sum(if(engine='SummingMergeTree',1,0)),
	sum(if(engine='ReplacingMergeTree',1,0)),
	sum(if(engine='CollapsingMergeTree',1,0)),
	sum(if(engine='VersionedCollapsingMergeTree',1,0)),
	sum(if(engine like '%Log',1,0)),
	sum(if(engine like 'Replicated%',1,0)),
	sum(if(engine like 'Distributed%',1,0)),
	sum(if(engine='View',1,0)),
	sum(if(engine='MaterializedView',1,0)),
	sum(if(engine='Dictionary',1,0)),
	sum(if(engine='Memory',1,0)),
	sum(if(engine='Kafka',1,0)),
	sum(if(engine like 'System%',1,0)),
	count(*)
  from system.tables;

select name as user_list, 
       auth_type,
       host_names, -- host_ip, host_names_regexp, host_names_like,
       default_roles_all, default_roles_list, default_roles_except,
       storage
  from system.users;
select name as role_name, storage
  from system.roles;
select name as user_directory, 
       type,
       params,
       precedence
 from system.user_directories
 order by precedence;

select user_name, role_name,
       access_type,
       database,
       table,
       column,
       is_partial_revoke,
       grant_option
 from system.grants;

SELECT database, sum(rows),
       sum(bytes_on_disk),
       formatReadableSize(sum(bytes_on_disk)) as hr_size,
       formatReadableSize(sum(data_compressed_bytes)) as hr_compressed, 
       formatReadableSize(sum(data_uncompressed_bytes)) as hr_uncompressed
  FROM system.parts
 GROUP BY database
 ORDER BY database
union all
SELECT 'TOTAL', sum(rows),
       sum(bytes_on_disk),
       formatReadableSize(sum(bytes_on_disk)),
       formatReadableSize(sum(data_compressed_bytes)), 
       formatReadableSize(sum(data_uncompressed_bytes))
  FROM system.parts;

SELECT name as disk_name, path,
       formatReadableSize(total_space) as total_space,
       formatReadableSize(free_space) as free_space,
       formatReadableSize(total_space-free_space) as used_space,
       total_space, 
       free_space, 
       total_space-free_space
  FROM system.disks
union all
SELECT 'TOTAL', '',
       formatReadableSize(sum(total_space)),
       formatReadableSize(sum(free_space)),
       formatReadableSize(sum(total_space-free_space)),
       sum(total_space), 
       sum(free_space), 
       sum(total_space-free_space)
  FROM system.disks;

SELECT database, count(distinct table) as tables,
       count(distinct partition) as partitions,
       minIf(partition, partition <>'tuple()') as min_partition,
       maxIf(partition, partition <>'tuple()') as max_partition,
       count(distinct name) as parts,
       sum(active) as active_parts,
       formatReadableSize(sum(bytes_on_disk)) as hr_size,
       sum(bytes_on_disk) as size
  FROM system.parts
 GROUP BY database
 ORDER BY database
union all
SELECT 'TOTAL', count(distinct table),
       count(distinct partition),
       minIf(partition, partition <>'tuple()'),
       maxIf(partition, partition <>'tuple()'),
       count(distinct name),
       sum(active),
       formatReadableSize(sum(bytes_on_disk)),
       sum(bytes_on_disk)
  FROM system.parts;

SELECT database, count(distinct table) as tables, count(distinct column) as columns, count(distinct type) as datatypes,
       formatReadableSize(sum(column_data_compressed_bytes)) compressed_hr,
       sum(column_data_compressed_bytes) compressed,
       sum(column_data_uncompressed_bytes) uncompressed,
       round( (sum(column_data_uncompressed_bytes)-sum(column_data_compressed_bytes))*100/sum(column_data_uncompressed_bytes), 2) as gain
  FROM system.parts_columns
 WHERE active
 GROUP BY database
 ORDER BY database
union all
SELECT 'TOTAL', count(distinct table), count(distinct column), count(distinct type),
       formatReadableSize(sum(column_data_compressed_bytes)) compressed_hr,
       sum(column_data_compressed_bytes) compressed,
       sum(column_data_uncompressed_bytes) uncompressed,
       round( (sum(column_data_uncompressed_bytes)-sum(column_data_compressed_bytes))*100/sum(column_data_uncompressed_bytes), 2)
  FROM system.parts_columns
 WHERE active;

select name as tuning_parameter, value
  from system.settings
 WHERE changed != 0
    OR name in ('max_memory_usage', 'max_memory_usage_for_all_queries', 'max_memory_usage_for_user',
         'max_bytes_before_external_group_by', 'max_bytes_before_external_sort',
         'max_bytes_before_remerge_sort')
 order by name;

SELECT user, client_hostname AS host, client_name AS client,
       query_start_time AS started, query_duration_ms/1000 AS sec,
       memory_usage, type,
       query as query_top_memory
  FROM system.query_log
 WHERE memory_usage<>0
   and event_time > now() - interval 7 day
 ORDER BY memory_usage DESC
 LIMIT 5 BY type;

select 'TCP' as connection_type, value as current_connections, 'clickhouse-client and native connections' as usage_notes
  from system.metrics
 where metric='TCPConnection'
union all
select 'HTTP', value, 'drivers and programs'
  from system.metrics
 where metric='HTTPConnection'
union all
select 'Interserver', value, 'replica and cluster'
  from system.metrics
 where metric='InterserverConnection';

select query_id,
	user,
	address,
	elapsed,
	substring(query,1,128) current_query
  from system.processes
 where query not like ('% current_query%')
 order by query_id;

SELECT user, client_hostname AS host, client_name AS client,
       query_start_time AS started, query_duration_ms/1000 AS sec,
       round(memory_usage/1048576) AS MEM_MB, result_rows AS RES_CNT,
       toDecimal64(result_bytes/1048576, 6) AS RES_MB, read_rows AS R_CNT,
       round(read_bytes/1048576) AS R_MB, written_rows AS W_CNT,
       round(written_bytes/1048576) AS W_MB,
       query
  FROM system.query_log
 WHERE user <> 'my2'
   AND user <> user()
   and event_time > now() - interval 1 day
 ORDER BY query_start_time DESC
 LIMIT 20;

SELECT toStartOfInterval(event_time, INTERVAL 3600 SECOND) AS t,
       round(avg(ProfileEvent_Query),2) as Query_sec,
       round(avg(CurrentMetric_Query),2) as Running_query,
       round(avg(CurrentMetric_Merge),2) as Running_merge,
       round(avg(ProfileEvent_SelectedBytes),2) as Selected_bytes,
       round(avg(CurrentMetric_MemoryTracking),2) as memory_track,
       round(avg(ProfileEvent_SelectedRows),2) as row_sel_sec,
       round(avg(ProfileEvent_InsertedRows),2) as row_ins_sec,
       round(avg(ProfileEvent_OSCPUVirtualTimeMicroseconds) / 1000000,1) as CPU,
       round(avg(ProfileEvent_OSCPUWaitMicroseconds) / 1000000,2) as CPU_wait,
       round(avg(ProfileEvent_OSIOWaitMicroseconds) / 1000000,2) as IO_wait,
       round(avg(ProfileEvent_OSReadBytes),2) as disk_read,
       round(avg(ProfileEvent_OSReadChars),2) as FS_read
  FROM system.metric_log
 WHERE event_date >= toDate(now() - 86400) AND event_time >= now() - 86400
 GROUP BY t
 ORDER BY t WITH FILL STEP 3600;

SELECT  toStartOfInterval(event_time, INTERVAL 3600*24 SECOND) AS t,
       round(avg(value),2) as load_avg
  FROM system.asynchronous_metric_log
 WHERE event_date >= toDate(now() - 3600*24*31) AND event_time >= now() - 3600*24*31
   AND metric = 'LoadAverage15'
 GROUP BY t
 ORDER BY t WITH FILL STEP 3600*24;

SELECT  toStartOfInterval(event_time, INTERVAL 3600 SECOND) AS t,
       round(avg(value),2) as load_avg
  FROM system.asynchronous_metric_log
 WHERE event_date >= toDate(now() - 3600*24) AND event_time >= now() - 3600*24
   AND metric = 'LoadAverage15'
 GROUP BY t
 ORDER BY t WITH FILL STEP 3600;

select max(CurrentMetric_TCPConnection) as max_tcp_conn,
       max(CurrentMetric_HTTPConnection) as max_http_conn, 
       max(CurrentMetric_InterserverConnection) as max_inter_conn
  from system.metric_log;

select user, count(*) as query_count, round(sum(query_duration_ms)/1000) as total_duration,
       round(sum(query_duration_ms)/1000/count(*),3) as avg_duration,
       countIf(exception <> '') as error_count
  from system.query_log 
 where  event_time > now() - interval 7 day
 group by user
 order by user
union all
select 'TOTAL', count(*), round(sum(query_duration_ms)/1000),
       round(sum(query_duration_ms)/1000/count(*),3),
       countIf(exception <> '')
  from system.query_log 
 where  event_time > now() - interval 7 day;

SELECT 'MERGE' as activity, database, table, result_part_name,
       progress,
       elapsed, 
       num_parts
  FROM system.merges;
SELECT 'MUTATION' as activity, database, table, mutation_id,
       command, create_time,
       is_done, 
       parts_to_do,
       latest_fail_reason
  FROM system.mutations
 ORDER BY is_done, create_time desc
 LIMIT 20;

SELECT user, client_hostname AS host, client_name AS client,
       query_start_time AS started, query_duration_ms/1000 AS sec,
       round(memory_usage/1048576) AS MEM_MB, result_rows AS RES_CNT,
       toDecimal64(result_bytes/1048576, 6) AS RES_MB, read_rows AS R_CNT,
       round(read_bytes/1048576) AS R_MB, written_rows AS W_CNT,
       round(written_bytes/1048576) AS W_MB,
       query
  FROM system.query_log
 where event_time > now() - interval 7 day
 ORDER BY query_duration_ms DESC
 LIMIT 20;

SELECT user, client_hostname AS host, client_name AS client,
       query_start_time AS started, query_duration_ms/1000 AS sec,
       round(memory_usage/1048576) AS MEM_MB, result_rows AS RES_CNT,
       substring(query,1,128) query,
       exception
  FROM system.query_log
 WHERE exception <> ''
   AND user <> 'haproxy'
   and event_time > now() - interval 1 day
 ORDER BY query_start_time DESC
 LIMIT 20;

select *
 from (SELECT user, client_hostname AS host, client_name AS client,
       query_start_time AS started, query_duration_ms/1000 AS sec,
       round(memory_usage/1048576) AS MEM_MB, result_rows AS RES_CNT,
       toDecimal64(result_bytes/1048576, 6) AS RES_MB, read_rows AS R_CNT,
       round(read_bytes/1048576) AS R_MB, written_rows AS W_CNT,
       round(written_bytes/1048576) AS W_MB,
       substring(query,1,128) query
  FROM system.query_log
 WHERE type=2
   AND user <> 'my2'
   AND event_time > now() - interval 1 day
 ORDER BY query_duration_ms DESC
 LIMIT 3 BY user)
order by user, sec DESC;

select *
 from (SELECT user, client_hostname AS host, client_name AS client,
       query_start_time AS started, query_duration_ms/1000 AS sec,
       round(memory_usage/1048576) AS MEM_MB, result_rows AS RES_CNT,
       substring(query, 1, 128) query,
       exception
  FROM system.query_log
 WHERE exception <> ''
   AND event_time > now() - interval 1 day
 ORDER BY query_start_time DESC
 LIMIT 3 BY user)
order by user, started DESC;

SELECT database, table, any(engine),
       sum(rows),
       formatReadableSize(sum(bytes_on_disk)) as hr_size,
       sum(bytes_on_disk),
       formatReadableSize(sum(data_uncompressed_bytes)) as hr_uncompressed
  FROM system.parts
 GROUP BY database, table
 ORDER BY sum(bytes_on_disk) desc
 LIMIT 32;

SELECT database, name as dictionary_name, status,
       source, attribute.names,
       element_count,
       bytes_allocated,
       lifetime_min, lifetime_max,
       last_successful_update_time,
       loading_duration,
       last_exception
  FROM system.dictionaries
 ORDER BY last_successful_update_time desc;

SELECT cluster, shard_num, shard_weight,
       replica_num,
       host_name,
       host_address,
       port,
       is_local,
       user,
       default_database
  FROM system.clusters;

SELECT database, table, engine,
       total_replicas,
       is_leader, is_readonly,
       is_session_expired,
       future_parts,
       parts_to_check,
       inserts_in_queue,
       log_max_index,
       log_pointer,
       queue_size,
       active_replicas,
       queue_oldest_time,
       inserts_oldest_time,
       last_queue_update
  FROM system.replicas;

select database, table, replica_name,
       position, node_name, type, create_time, required_quorum,
       source_replica, new_part_name, parts_to_merge, is_detach,
       is_currently_executing, num_tries, last_exception,
       last_attempt_time, num_postponed, postpone_reason, last_postpone_time
  from system.replication_queue
 order by is_currently_executing desc, create_time;

select  database,
	count(*) as kafka_objects
  from system.tables
 where engine='Kafka'
 group by database
 order by database
union all
select 'TOTAL', count(*)
  from system.tables
 where engine='Kafka';

SELECT database, table as kafka_table, assignments.topic,
       num_commits, num_messages_read,
       last_commit_time, last_poll_time, 
       if(consumer_id='', 0,1) as assigned, is_currently_used, 
       if(empty(exceptions.time), '', toString(exceptions.time[-1])) as last_exception_time     
  FROM system.kafka_consumers
 ORDER BY last_commit_time desc, last_poll_time desc, database, table;

SELECT database, table as kafka_table,
       exceptions.time[-1], consumer_id,
       exceptions.time, exceptions.text    
  FROM system.kafka_consumers
 WHERE notEmpty(exceptions.time)
 ORDER BY exceptions.time[-1] desc, database, table limit 10;

SELECT name as zookeeper_name, value, ctime, path
  FROM system.zookeeper
 WHERE path IN ('/', '/clickhouse')
 ORDER BY path;

SELECT name, engine,
       data_path, metadata_path,
       uuid, comment, engine_full
  FROM system.databases
 ORDER BY name;

SELECT database, table,sum(rows),
       toUInt32((max(max_time) - min(min_time)) / 86400) as days,
       sum(bytes_on_disk) as size,
       sum(if(active,0, bytes_on_disk)) as not_active,
       formatReadableSize(sum(if(active,bytes_on_disk,0))) as hr_size,
       formatReadableSize(sum(data_compressed_bytes)) as hr_compressed, 
       formatReadableSize(sum(data_uncompressed_bytes)) as hr_uncompressed
  FROM system.parts
 GROUP BY database, table
 ORDER BY database, table;

SELECT database, name,
       formatReadableSize(total_bytes),
       engine, 
       substring(substring(create_table_query,
                 position(create_table_query, 'TTL'),
                 position(create_table_query, 'SETTING')-position(create_table_query, 'TTL') ),1,32) as ttl_def
  FROM system.tables
 where engine not in ('View','MaterializedView', 'Kafka', 'Dictionary')
   and engine not like 'System%'
 ORDER BY database, name;

SELECT database, table,
       count(distinct partition) as partitions, min(partition) as min_partt, max(partition) as max_partt,
       count(distinct name) as parts, min(name) as min_part, max(name) as max_part,
       sum(active) as active, sum(bytes_on_disk) as bytes
  FROM system.parts
 GROUP BY database, table
 ORDER BY database, table;

SELECT database, table, partition_id as detached_partition_id, name,
       disk, reason, 
       min_block_number,
       max_block_number,
       level
  FROM system.detached_parts
 ORDER BY database, table, partition_id, name;

select  database, engine,
	count(*)
  from system.tables
 where database not in ('system', 'INFORMATION_SCHEMA', 'information_schema')
 group by database, engine
 order by database, engine;

select  database, type as datatype,  count()
  from system.columns
 where database not in ('system', 'INFORMATION_SCHEMA', 'information_schema')
 group by database, type
 order by database, type;

select name, code, value,
       last_error_time, last_error_message, last_error_trace, 
       remote
  from system.errors;

select name as all_parameters, value, changed
  from system.settings
 order by changed desc, name
 limit 29;

select metric as global_status, value,  description
  from system.metrics
 order by metric
 limit 29;

select metric, value
  from system.asynchronous_metrics
 order by metric
 limit 29;

select event, value, description
  from system.events
 order by event
 limit 29;


select 'Copyright 2026 meob' as copyright, 'Apache-2.0' as license, 'https://github.com/meob/db2txt' as sources;
select concat('Report terminated on: ', toString(now())) as report_date;

