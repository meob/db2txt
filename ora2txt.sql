select 'ora2txt: Oracle TXT-Report on: '|| value||' ' as title,
       to_char(sysdate,'DD-MON-YYYY HH24:MI:SS') as report_date,
       user as by_user,
       'v.1.0.3' as version
  from v$parameter
 where name like 'db_name';

 
select ' Database :' as summary_info,
           value as value
from v$parameter
where name like 'db_name'
union all
select ' Version :', 
           substr(banner,instr(banner, '.',1,1)-2,11)
from sys.v_$version
where banner like 'Oracle%'
union all
select ' Created :', 
       to_char(created,'DD-MON-YYYY HH24:MI:SS')
from v$database
union all
select ' Started :', 
            to_char(startup_time,'DD-MON-YYYY HH24:MI:SS')
from v$instance
union all
select ' DB Size (MB) :', 
           to_char(sum(bytes)/(1024*1024),'999,999,999,999')
from sys.dba_data_files
union all
select ' SGA (MB) :', 
           to_char(sum(value)/(1024*1024),'999,999,999,999')
from sys.v_$sga
union all
select ' Log archiving :', 
           log_mode
from v$database
union all
select ' Defined Users / OPEN:',
           to_char(count(*),'999999999')
 ||' / '|| to_char(sum(decode(account_status,'OPEN',1,0)),'999999999')
from sys.dba_users
union all
select ' Defined Schemata :', 
           to_char(count(distinct owner),'999999')
from dba_objects
where owner not in ('SYS', 'SYSTEM')
and object_type = 'TABLE'
union all
select ' Defined Tables :', 
           to_char(count(*),'999999999')
from dba_objects
where owner not in ('SYS', 'SYSTEM')
and object_type = 'TABLE'
union all
select ' Used Space (MB) :', 
           to_char(sum(bytes)/(1024*1024),'999,999,999,999')
from sys.dba_extents
union all
select ' Sessions / USER / ACTIVE:', 
           to_char(count(*),'999999999')||
  ' / ' || to_char(sum(decode(type, 'USER', 1, 0)),'999999999')||
  ' / ' || to_char(sum(decode(status, 'ACTIVE', 1, 0)),'999999999')
from gv$session
union all
select ' Active Users Sessions:', 
           to_char(count(*),'999999999999')
from gv$session
 where status='ACTIVE' and type='USER'
union all
select ' Character set :', 
            value$
from sys.props$
where name = 'NLS_CHARACTERSET'
union all
select ' Hostname :',
            host_name
from gv$instance
union all
select ' Instance :', 
           instance_name
from gv$instance
union all
select ' Archiver :', 
            archiver
from v$instance
union all
select ' RedoLog Day (#) :',
           to_char(count(*)/7,'999999999999')
from v$log_history
where first_time > sysdate-7;


select banner as version
 from v$version
 where banner like 'Oracle%'
union all
select ' Last Release Updates (12.2+): <b>23.26.0</b>, 21.20, <b>19.29</b>; 20.2, 18.14, 12.2.0.1.220118' from dual
union all
select ' Last Patch Set Updates (12.1-): 12.1.0.2.221018, 11.2.0.4.201020, 10.2.0.5.19; 9.2.0.8, 8.1.7.4, 7.3.4.5' from dual
union all
select 'Details: ' from dual
union all
select ' '||banner from sys.v_$version
union all
select comp_id||' '||comp_name||' '||version
  from dba_registry
union all
SELECT description ||' on '||TO_CHAR(action_time, 'DD-MON-YYYY HH24:MI:SS')|| ' with Patch ID: '||patch_id
  FROM sys.dba_registry_sqlpatch;

SELECT * FROM (
select rpad(owner,20) schema_matrix,
           sum(decode(object_type, 'TABLE',1,0))    tabs,
           sum(decode(object_type, 'TABLE PARTITION',1,0))    patrs,
           sum(decode(object_type, 'INDEX',1,0))    idxs,
           sum(decode(object_type, 'TRIGGER',1,0))  trgs,
           sum(decode(object_type, 'PACKAGE',1,0))  pkgs,
           sum(decode(object_type, 'PACKAGE BODY',1,0))  pbod,
           sum(decode(object_type, 'PROCEDURE',1,0))  proc,
           sum(decode(object_type, 'FUNCTION',1,0))  func,
           sum(decode(object_type, 'SEQUENCE',1,0)) seqs,
           sum(decode(object_type, 'SYNONYM',1,0))  syns,
           sum(decode(object_type, 'VIEW',1,0))  viws,
           sum(decode(object_type, 'MATERIALIZED VIEW',1,0))  mvs,
           sum(decode(object_type, 'JOB',1,0))  jbs,
           sum(decode(object_type, 'TYPE',1,0))  typ,
           sum(decode(object_type, 'OPERATOR',1,0))  oper,
           sum(decode(object_type, 'LOB',1,0))  lobb,
           sum(decode(object_type, 'XML SCHEMA',1,0))  xml,
           count(*) alls
from sys.dba_objects
group by owner
order by owner )
UNION ALL
select rpad('TOTAL',20) total,
           sum(decode(object_type, 'TABLE',1,0))    tabs,
           sum(decode(object_type, 'TABLE PARTITION',1,0))    patrs,
           sum(decode(object_type, 'INDEX',1,0))    idxs,
           sum(decode(object_type, 'TRIGGER',1,0))  trgs,
           sum(decode(object_type, 'PACKAGE',1,0))  pkgs,
           sum(decode(object_type, 'PACKAGE BODY',1,0))  pbod,
           sum(decode(object_type, 'PROCEDURE',1,0))  proc,
           sum(decode(object_type, 'FUNCTION',1,0))  func,
           sum(decode(object_type, 'SEQUENCE',1,0)) seqs,
           sum(decode(object_type, 'SYNONYM',1,0))  syns,
           sum(decode(object_type, 'VIEW',1,0))  viws,
           sum(decode(object_type, 'MATERIALIZED VIEW',1,0))  mvs,
           sum(decode(object_type, 'JOB',1,0))  jbs,
           sum(decode(object_type, 'TYPE',1,0))  typ,
           sum(decode(object_type, 'OPERATOR',1,0))  oper,
           sum(decode(object_type, 'LOB',1,0))  lobb,
           sum(decode(object_type, 'XML SCHEMA',1,0))  xml,
           count(*) alls
from sys.dba_objects;

select owner,
       to_char(sum(decode(segment_type, 'TABLE',bytes,0)),'999,999,999,999,999')    tabs,
       to_char(sum(decode(segment_type, 'INDEX', bytes,0)),'999,999,999,999,999')    idxs,
       to_char(sum(bytes),'999,999,999,999,999') tot
  from sys.dba_segments
 group by owner
 order by owner;

select TABLESPACE_NAME, USED_SPACE, TABLESPACE_SIZE, round(USED_PERCENT, -3) as USED_PERCENT
  from dba_tablespace_usage_metrics
 order by TABLESPACE_NAME;

SELECT df.tablespace_name TABLESPACE_NAME,                                                              
       df.bytes/(1024*1024) tot_ts_size,   
       round((df.bytes-sum(fs.bytes))/(1024*1024),0) used_MB,                                                   
       round(sum(fs.bytes)/(1024*1024),0) free_ts_size,                                                 
       round(sum(fs.bytes)*100/df.bytes) free_pct,                                               
       round((df.bytes-sum(fs.bytes))*100/df.bytes) used_pct,
       round((df.bytes-sum(fs.bytes))*100/df.max_sz) used_pct_of_max
  FROM (select tablespace_name, sum(bytes) bytes,sum(decode(autoextensible, 'YES', maxbytes, bytes)) max_sz
          from dba_data_files
         where tablespace_name in (select tablespace_name from dba_tablespaces where contents = 'PERMANENT')
         group by tablespace_name ) df,
       dba_free_space fs
 WHERE fs.tablespace_name = df.tablespace_name                                                  
 GROUP BY df.tablespace_name, df.bytes,df.max_sz
 ORDER BY 1;

select rpad(segment_type, 10) as segment_type,
       to_char(sum(bytes),'999,999,999,999,999') total
  from sys.dba_segments
 group by segment_type
 order by 2 desc;

SELECT TABLESPACE_NAME as temp_tablespace_name, TABLESPACE_SIZE, ALLOCATED_SPACE, FREE_SPACE 
  FROM dba_temp_free_space
 order by TABLESPACE_NAME;

select 
 owner,
 sum(decode(object_type, 'TABLE',1,0))   as invalid_table,
 sum(decode(object_type, 'INDEX',1,0))   as iindex,
 sum(decode(object_type, 'TRIGGER',1,0)) as itrigger,
 sum(decode(object_type, 'PACKAGE',1,0)) as ipackage,
 sum(decode(object_type, 'PACKAGE BODY',1,0)) as ibody,
 sum(decode(object_type, 'PROCEDURE',1,0)) as iprocedure,
 sum(decode(object_type, 'FUNCTION',1,0)) as ifunction,
 sum(decode(object_type, 'SEQUENCE',1,0)) as isequence,
 sum(decode(object_type, 'SYNONYM',1,0)) as isynonym,
 sum(decode(object_type, 'VIEW',1,0))  as iVIEW,
 count(*) as invalid_any
from sys.dba_objects
where status <> 'VALID'
group by owner
order by owner;

select tablespace_name tablespace,
           to_char(round(sum(bytes/1048576)),
		'999,999,999') as total,
           to_char(sum(decode(segment_type,'TABLE',round(bytes/1048576),0)),
		'99,999,999,999,999') as tables,
           to_char(sum(decode(segment_type,'TABLE PARTITION',round(bytes/1048576),0)),
		'99,999,999,999,999') as partitions,
           to_char(sum(decode(segment_type,'TABLE SUBPARTITION',round(bytes/1048576),0)),
		'99,999,999,999,999') as subpartitions,
           to_char(sum(decode(segment_type,'INDEX',round(bytes/1048576),0)),
		'99,999,999,999,999') as indexes,
           to_char(sum(decode(segment_type,'INDEX PARTITION',round(bytes/1048576),0)),
		'99,999,999,999,999') as index_partitions,
           to_char(sum(decode(substr(segment_type,1,3),'LOB',round(bytes/1048576),0)),
		'99,999,999,999,999') as lobs,
           to_char(sum(decode(segment_type,'CLUSTER',round(bytes/1048576),0)),
		'999,999,999,999') as clusters
  from sys.dba_extents
 group by tablespace_name
 order by tablespace_name;

select 'Recycle Bin' as obj, 
           to_char(sum(space*8)*1024,'999,999,999,999') as space_usage
from dba_recyclebin;

select table_owner as owner, count(distinct table_name) as partitioned_tables
 from dba_tab_partitions
 where table_owner not in ('SYS','SYSTEM','SYSMAN','WMSYS')
 group by table_owner
 order by table_owner;

select owner, degree, instances, count(*) as parallel_tables
 from dba_tables
 where owner not in ('SYS','SYSTEM','SYSMAN','WMSYS')
   and degree>1
 group by degree, instances, owner
 order by degree desc, instances desc;

select owner, compression, 'TABLE' as object_type, count(*) as compressed_objects
 from dba_tables
 where owner not in ('SYS','SYSTEM','SYSMAN','WMSYS')
   and compression='ENABLED'
 group by owner, compression
union all
select owner, compression, 'INDEX', count(*)
 from dba_indexes
 where owner not in ('SYS','SYSTEM','SYSMAN','WMSYS')
   and compression='ENABLED'
 group by owner, compression
order by object_type desc, owner, compression;

select substr(name,1,25) as SGA_element,
 to_char(value,'999,999,999,999') as bytes,
 to_char(value/(1024*1024),'999,999,999,999') as MB
from sys.v_$sga
order by value desc;

select  name, to_char(value,'999,999,999,999') as value, isdefault
  from v$parameter
 where name in ('sga_target', 'sga_max_size', 'db_cache_size', 'shared_pool_size', 'memory_target',
                'large_pool_size', 'java_pool_size', 'streams_pool_size', 'inmemory_size',
                'memory_max_target', 'log_buffer', 'db_keep_cache_size', 'db_recycle_cache_size')
order by isdefault, name;

select tablespace_name,
 file_name data_file,
 to_char(bytes,'999,999,999,999,999') as bytes, 
 to_char(phyrds,'999,999,999,999') as reads, 
 to_char(phywrts,'999,999,999,999') as writes
from sys.dba_data_files, v$filestat
where file_id=file#
order by tablespace_name,file_name;

select substr(a.segment_name,1,25) rollback_segment,
 substr(a.tablespace_name,1,25) tablespace,
 to_char(sum(bytes),'999,999,999,999') bytes,
 substr(max(extent_id)+1,1,7) extents,
 substr(status,1,7) status
from sys.dba_extents a, sys.dba_rollback_segs b
where a.segment_name = b.segment_name
and   segment_type='ROLLBACK'
group by a.tablespace_name,a.segment_name,status
order by a.tablespace_name,a.segment_name;

select name as undo_parameter, value
from v$parameter
where name like 'undo%'
order by name; 

select tablespace_name as undo_tablespace_name,
 file_name data_file,
 to_char(bytes,'999,999,999,999,999') as bytes, 
 autoextensible
from sys.dba_data_files
where tablespace_name like 'UNDO%'
order by tablespace_name,file_name;

select tablespace_name,
 status, count(*) as undo_extents,
 to_char(sum(BYTES),'999,999,999,999,999') as bytes
from sys.DBA_UNDO_EXTENTS
group by tablespace_name,status
order by tablespace_name,status;

select sys.v_$logfile.group# group_id, member log_file, sys.v_$log.status as status, sys.v_$logfile.status group_status,
            to_char(bytes,'999,999,999,999') bytes, thread#
from sys.v_$logfile, sys.v_$log
where sys.v_$logfile.group# = sys.v_$log.group#
order by thread#, 1;

select trunc(first_time) log_switch_date,
            to_char(count(*),'999,999,999,999') counter
from sys.v_$log_history
where first_time > sysdate -31
group by trunc(first_time)
order by trunc(first_time) desc;

select to_char(first_time, 'YYYY-MM-DD HH24')||':00:00' log_switch_hour,
            to_char(count(*),'999,999,999,999') counter
from sys.v_$log_history
where first_time > sysdate -1.3
group by to_char(first_time, 'YYYY-MM-DD HH24')
order by to_char(first_time, 'YYYY-MM-DD HH24') desc;

select 'Archived Logs' object, creator, registrar, status, archived,
       to_char(count(*),'999,999,999,999') counter
from v$archived_log
where deleted='NO'
group by creator, registrar, archived, status
order by status,creator,registrar;

select name, value files
 from v$parameter
 where name='control_files';
select *
 from v$controlfile_record_section;

select substr(name||': '||value||'  ('||round(value/(1024*1024*1024))||'GB)',1,60) Recovery_Dest_Size 
from v$parameter where name='db_recovery_file_dest_size';
select * from v$flash_recovery_area_usage;
select trunc(100-sum(PERCENT_SPACE_USED)-sum(PERCENT_SPACE_RECLAIMABLE))||'%' Free_Recovery_pct  from v$flash_recovery_area_usage;

select username,
       default_tablespace,
       temporary_tablespace,
       account_status,
       profile,
       created,
       expiry_date,
       last_login
  from sys.dba_users
ORDER BY account_status desc, last_login DESC;

select resource_name default_profile_resource, limit
  from sys.dba_profiles
 where profile='DEFAULT'
 order by resource_name;

select 'Enterprise ' Detected_license
  from sys.v_$version
 where banner like '%Enterprise%' and banner like 'Oracle%'
union all
select 'XE (Express) '
  from sys.v_$version
 where banner like '%Express%' and banner like 'Oracle%'
union all
select 'Free (Developer-Release) '
  from sys.v_$version
 where banner like '%Developer-Release%' and banner like 'Oracle%'
union all
select 'Standard '
  from (select banner from sys.v_$version where banner like 'Oracle%') a
 where banner not like '%Enterprise%' and banner not like '%Express%' and banner not like '%Developer-Release%';

select users_max, sessions_max, sessions_current, sessions_highwater
from v$license;
select cpu_count_current, cpu_count_highwater,
       cpu_core_count_current, cpu_core_count_highwater,
       cpu_socket_count_current, cpu_socket_count_highwater
from v$license;

select 'Diagnostic and tuning pack enabled' as metric, value as value
from v$parameter
where name in ('control_management_pack_access')
union all
select 'In-Memory enabled (12c)', value
from v$parameter
where name in ('inmemory_query')
union all
select 'Max PDBS (12cR2)', value
from v$parameter
where name in ('max_pdbs');

select  name,            HIGHWATER,            DESCRIPTION
  from DBA_HIGH_WATER_MARK_STATISTICS;
 
select s.sid||','||s.serial# sid_serial,
       s.schemaname username,  
       s.osuser os_user,
       p.spid process,
       s.type type,
       s.status status,
       decode(s.command, 1,'Create table',2,'Insert',3,'Select',
   4,'Create cluster',5,'Alter cluster',6,'Update',7,'Delete',
   8,'Drop',9,'Create index',10,'Drop index',11,'Alter index',
   12,'Drop table',15,'Alter table', 16, 'Drop Seq.', 17,'Grant',18,'Revoke',
   19,'Create synonym',20,'Drop synonym',21,'Create view',
   22,'Drop view',23,'Validate index',24,'Create procedure',25,'Alter procedure',
   26,'Lock table',27,'No operation',28,'Rename',
   29,'Comment',30,'Audit',31,'Noaudit',32,'Create ext. database',
   33,'Drop ext. database',34,'Create database',35,'Alter database',
   36,'Create rollback segment',37,'Alter rollback segment',
   38,'Drop rollback segment',39,'Create tablespace',
   40,'Alter tablespace',41,'Drop tablespace',42,'Alter session',
   43,'Alter user',44,'Commit',45,'Rollback',46,'Savepoint', 
   47,'PL/SQL Exec',48,'Set Transaction',
   60,'Alter trigger',62,'Analyze Table',
   63,'Analyze index',71,'Create Snapshot Log',
   72,'Alter Snapshot Log',73,'Drop Snapshot Log',
   74,'Create Snapshot',75,'Alter Snapshot',
   76,'Drop Snapshot',79,'Alter Role',
   85,'Truncate table',86,'Truncate Cluster', 
   88,'Alter View',91,'Create Function',92,'Alter Function',93,'Drop Function', 
   94,'Create Package',95,'Alter Package',96,'Drop Package', 
   97,'Create PKG Body',98,'Alter PKG Body',99,'Drop PKG Body',
   0,'No command',
   'Other') Command,
       substr(s.program,1,30) program,
       substr(module,1,30) module,
       s.inst_id,
       to_char(logon_time, 'YYYY-MM-DD HH24:MI:SS') as logon,
       s.client_identifier
  from gv$process p, gv$session s
 where s.paddr = p.addr
   and s.inst_id = p.inst_id
 order by s.type desc, s.status, s.inst_id, s.sid;

select s.sid||','||s.serial# sid_serial,
       s.username,
       q.executions exec,
       q.parse_calls parse,
       q.disk_reads read,
       q.buffer_gets get  ,   
       replace(replace(q.sql_text,'<','&lt;'),'>','&gt;') sql
from gv$session s, gv$sql q
where s.sql_address=q.address
and   s.type <> 'BACKGROUND'
and   s.status = 'ACTIVE'
and   s.username <> 'SYS'
and   s.inst_id = q.inst_id
order by s.sid;

select l.sid, l.type as lock_type, decode(l.lmode, 0, 'WAITING', 1,'Null', 2, 'Row Share', 
  3, 'Row Exclusive', 4, 'Share',
  5, 'Share Row Exclusive', 6,'Exclusive', l.lmode) lock_mode, 
           decode(l.request, 0,'HOLD', 1,'Null', 2, 'Row Share',
  3, 'Row Exclusive', 4, 'Share', 5, 'Share Row Exclusive',
  6,'Exclusive', l.request) request, 
  count(*) lock_id
from gv$lock l
group by l.sid, l.type, l.lmode, l.request
order by l.sid, l.type, l.lmode, l.request;

select 'A)  Hit ratio buffer cache (>80%): '||
  to_char(round(1-(
   sum(decode(name,'physical reads',1,0)*value) 
   /(sum(decode(name,'db block gets',1,0)*value) 
   +sum(decode(name,'consistent gets',1,0)*value))
  ), 3)*100) || '%'  statistic
 from v$sysstat
 where name in ('db block gets', 'consistent gets', 'physical reads')
 union
select 'B1) Misses library cache (<1%): '
  ||to_char(round(sum(reloads)/sum(pins)*100, 3)) || '%' 
 from v$librarycache
 union
select 'B1.'||ROWNUM||') Detailed misses library cache ('
  ||namespace || '-' ||to_char(pins)
  ||'): '||to_char(round(decode(pins,0,0,reloads/pins*100), 3))
  || '%' Statistica
 from v$librarycache
 union
select 'B2) Misses dictionary cache (<10%): '
  ||to_char(round(sum(getmisses)/sum(gets)*100, 3)) || '%' 
 from v$rowcache
 union
select 'C1) System undo header frequence (<1%): '
  ||to_char(round(avg(count)/sum(value)*100, 3)) || '%' 
 from v$waitstat w, v$sysstat s
 where w.class='system undo header' and
  name in ('db_block_gets', 'consistent gets')
 union
select 'C2) System undo block frequence (<1%): '
  ||to_char(round(avg(count)/sum(value)*100, 3)) || '%' 
 from v$waitstat w, v$sysstat s
 where w.class='system undo block' and
  name in ('db_block_gets', 'consistent gets')
 union
select 'C3) Undo header frequence (<1%): '
  ||to_char(round(avg(count)/sum(value)*100, 3)) || '%' 
 from v$waitstat w, v$sysstat s
 where w.class='undo header' and
  name in ('db_block_gets', 'consistent gets')
 union
select 'C4) Undo block frequence (<1%): '
  ||to_char(round(avg(count)/sum(value)*100, 3)) || '%' 
 from v$waitstat w, v$sysstat s
 where w.class='undo block' and
  name in ('db_block_gets', 'consistent gets')
 union
select 'D)  Redo log space req. (near 0): '||to_char(value)  
 from v$sysstat
 where name ='redo log space requests'
 union
select 'E1) Hit ratio redo alloc (<1%): '
  ||decode(gets,0,'NA',to_char(round(misses/gets*100, 3)) || '%' )
 from v$latch
 where latch#=15
 union
select 'E2) Hit ratio immediate redo alloc (<1%): '
  ||decode(immediate_gets,0,'NA',
   to_char(round(immediate_misses/immediate_gets*100, 3)) || '%' )
 from v$latch
 where latch#=15
 union
select 'E3) Hit ratio redo copy (<1%): '
  ||decode(gets,0,'NA',to_char(round(misses/gets*100, 3)) || '%') 
 from v$latch
 where latch#=16
 union
select 'E4) Hit ratio immediate redo copy (<1%): '
  ||decode(immediate_gets,0,'NA',
   to_char(round(immediate_misses/immediate_gets*100, 3)) || '%' )
 from v$latch
 where latch#=16
 union
select 'F)  Free list contention (<1%): '
  || to_char(round(count/value*100, 3)) || '%' 
 from v$waitstat w, v$sysstat s
 where w.class='free list' and
  name in ('consistent gets')
 union
select 'G1) Sorts in memory: '||to_char(value)  
 from v$sysstat
 where name in ('sorts (memory)')
 union
select 'G2) Sorts on disk: '||to_char(value)  
 from v$sysstat
 where name in ('sorts (disk)')
 union
select 'H1) Short tables full scans: '||to_char(value)  
 from v$sysstat
 where name in ('table scans (short tables)')
 union
select 'H2) Long tables full scans: '||to_char(value)  
 from v$sysstat
 where name in ('table scans (long tables)')
 union
select 'I1 @'||inst_id||') Logon: '||to_char(value)  
 from gv$sysstat
 where name in ('logons cumulative')
 union
select 'I2 @'||gv$sysstat.inst_id||') Commit: '||to_char(value) ||
       ' TPS: '|| to_char( round(value/((sysdate-startup_time)*24*60*60),5) )
 from gv$sysstat,gv$instance
 where name in ('user commits') and gv$sysstat.inst_id=gv$instance.inst_id
 union
select 'I3 @'||inst_id||') Rollback: '||to_char(value)  
 from gv$sysstat
 where name in ('user rollbacks')
 union
select 'I4 @'||gv$sysstat.inst_id||') Exec: '||to_char(value) ||
       ' SQL/sec: '|| to_char( round(value/((sysdate-startup_time)*24*60*60),5) )
 from gv$sysstat,gv$instance
 where name in ('execute count') and gv$sysstat.inst_id=gv$instance.inst_id
 union
select 'L1 @'||gv$sysstat.inst_id||') DBcpu: '||to_char( round((value/100)/((sysdate-startup_time)*24*60*60),5) )  
 from gv$sysstat,gv$instance
 where name in ('DB time') and gv$sysstat.inst_id=gv$instance.inst_id;


select * from 
(select buffer_gets, disk_reads, executions, round(elapsed_time/executions/1000000,3) avg_duration,
        parsing_schema_name, sql_id, substr(sql_text,1,80) sql_text
   from v$sqlarea a
  where parsing_schema_name NOT IN ('SYS', 'SYSTEM', 'RDSADMIN')
    and executions>0
  order by 1 desc)
where  rownum <=10;
select * from 
(select disk_reads, buffer_gets, executions, round(elapsed_time/executions/1000000,3) avg_duration,
        parsing_schema_name, sql_id, substr(sql_text,1,80) sql_text
   from v$sqlarea a
  where parsing_schema_name NOT IN ('SYS', 'SYSTEM', 'RDSADMIN')
    and executions>0
  order by 1 desc)
where  rownum <=10;

select * from 
(select cpu_time, elapsed_time, executions, round(elapsed_time/executions/1000000,3) avg_duration, 
        parsing_schema_name, sql_id, substr(sql_text,1,80) sql_text
   from v$sqlarea a
  where parsing_schema_name NOT IN ('SYS', 'SYSTEM', 'RDSADMIN')
    and executions>0
  order by 1 desc)
where  rownum <=10;
select * from 
(select elapsed_time, cpu_time, executions, round(elapsed_time/executions/1000000,3) avg_duration, 
        parsing_schema_name, sql_id, substr(sql_text,1,80) sql_text
   from v$sqlarea a
  where parsing_schema_name NOT IN ('SYS', 'SYSTEM', 'RDSADMIN')
    and executions>0
  order by 1 desc)
where  rownum <=10;

select OWNER, count(*) as stale_stat_count, max(to_char(LAST_ANALYZED, 'YYYY-MM-DD HH24:MI:SS')) as last_analyzed
from dba_tab_statistics
where STALE_STATS='YES'
group by owner
order by owner;
select OWNER, count(*) as stale_idx_count, max(to_char(LAST_ANALYZED, 'YYYY-MM-DD HH24:MI:SS'))
from dba_ind_statistics
where STALE_STATS='YES'
group by owner
order by owner;

select 
  sum(decode(name,'physical read total IO requests',value,0)-
  decode(name,'physical read total multi block requests',value,0)) as small_reads,
  sum(decode(name,'physical write total IO requests',value,0)-
  decode(name,'physical write total multi block requests',value,0)) as small_writes,
  sum(decode(name,'physical read total multi block requests',value,0)) as large_reads,
  sum(decode(name,'physical write total multi block requests',value,0)) as large_writes,          
  round(sum(decode(name,'physical read total IO requests',value,'physical write total IO requests',value,
                        'physical read total multi block requests',value,'physical write total multi block requests',value,0)-
  decode(name,'physical read total multi block requests',value,'physical write total multi block requests',value,0))
     /((sysdate-startup_time)*24*60*60),5) as iop_s,
  trunc(sum(decode(name,'physical read total bytes',value,0))/(1024*1024)) as mb_read,         
  round(sum(decode(name,'physical read total bytes',value,0))/(1024*1024)
     /((sysdate-startup_time)*24*60*60),5) as mb_s,
  trunc(sum(decode(name,'physical write total bytes',value,0))/(1024*1024)) as mb_write
from v$sysstat,v$instance
group by startup_time;

select segment_name,
       segment_type,
       owner,
       tablespace_name,
       to_char(bytes,'999,999,999,999,999')
  from (select segment_name, segment_type,
        tablespace_name, owner, sum(bytes) bytes
        from sys.dba_extents
        group by segment_name, segment_type, tablespace_name, owner order by bytes desc)
where rownum <= 30
order by bytes desc;

select owner, type,
	to_char(count(distinct name), '999,999,999') as object_count,
	to_char(count(*), '999,999,999') as lines
  from dba_source
 group by owner, type
 order by owner, type;
select owner, library_name, file_spec, status, dynamic
  from all_libraries
 where owner not in ('SYS','XDB','MDSYS','ORDSYS');
select owner,  data_type,
	 to_char(count(*), '999,999,999') as count,
	 to_char(max(DATA_LENGTH), '999,999,999') as data_length,
	 to_char(max(DATA_PRECISION), '999,999,999') as data_precision
  from all_tab_columns
 where owner not in ('SYS','XDB','MDSYS','ORDSYS')
 group by owner, data_type
 order by owner, data_type;


select job, schema_user, interval, what, total_time
  from dba_jobs;
select job_name, owner, repeat_interval, start_date,
            job_action, program_name,
            run_count, last_run_duration, enabled
  from dba_scheduler_jobs;
select /*+ rule */ job, sid, last_date,failures
  from dba_jobs_running;
select * from
(SELECT l.log_id,           l.job_name, 
            TO_CHAR (l.log_date, 'YYYY/MM/DD HH24:MI:SS.FF TZH:TZM') as log_date, 
            TO_CHAR (r.actual_start_date,'YYYY/MM/DD HH24:MI:SS.FF TZH:TZM') as start_date,
            r.status,           r.errors
  FROM dba_scheduler_job_log l, dba_scheduler_job_run_details r 
 WHERE l.log_id = r.log_id(+)
 ORDER BY l.log_date DESC)
where rownum <20;
select owner_name, job_name as datapump_job, state
  from dba_datapump_jobs;

select name as RMAN_parameter, value
  from v$rman_configuration
 order by conf#; 
 
select owner, db_link, username, host
from dba_db_links
order by host, username, owner, db_link;
select owner, directory_name, directory_path
 from dba_directories
 order by owner, directory_name;
 
select name as nls_setting, value$ as value
from sys.props$
where name like 'NLS%CHARACTER%'
order by name; 

select stat_name OS_statistic, to_char(value, '999,999,999,990.0') as value
from v$osstat
where stat_name in ('LOAD','PHYSICAL_MEMORY_BYTES','NUM_CPUS')
order by stat_name;
select platform_name
from v$database;

SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI') sys_date
      , TO_CHAR(CURRENT_DATE, 'YYYY-MM-DD HH24:MI') cur_date
      , DBTIMEZONE DB_TZ
      , SESSIONTIMEZONE SESS_TZ
      , TO_CHAR(SYSTIMESTAMP, 'TZR') OS_TZ
FROM DUAL;

select name as configured_parameter, value
from v$parameter
where isdefault ='FALSE'
order by name; 

SELECT * FROM
(select name as all_parameters, value
from v$parameter
order by name)
WHERE ROWNUM <=29;


select 'Copyright 2025 meob' as copyright, 'Apache-2.0' as license, 'https://github.com/meob/db2txt' as sources
  from dual;
select 'Report terminated on: '|| to_char(sysdate,'DD-MON-YYYY HH24:MI:SS') as report_date
  from dual;
