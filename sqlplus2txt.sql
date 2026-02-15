set colsep ' '
set pagesize 9999
set linesize 240
set feedback off
set define off
set trimout on
set trimspool on

column TITLE format a40                                                                        
column VALUE  format a50                                                                                                              
column BY_USER  format a20   
column USERNAME  format a24  
column OS_USER  format a20  
column PROFILE  format a20 
column LIMIT  format a20 
column SCHEMA_MATRIX   format a20                                                                              
column OWNER  format a30   
column NAME    format a30 
column SEGMENT_NAME format a30
column TABLESPACE   format a20                                                                                                                       
column DATA_FILE   format a50                                                                                                                          
column ROLLBACK_SEGMENT  format a30                                                                                                                    
column LOG_FILE   format a40                                                                                                                                                                                                                                                   
column FILES   format a80                                                                                                                                                                                                                                                          
column DESCRIPTION   format a60                                                                                                                        
column NLS_SETTING  format a30                                                                                                                         
column SESS_TZ   format a10                                                                                   
column CONFIGURED_PARAMETER format a30  
column LIBRARY_NAME format a40 
column FILE_SPEC format a30 
column DATA_TYPE format a30  
column LAST_LOGIN format a40  
column SID_SERIAL format a20 
column PROGRAM format a40 
column MODULE format a40  
column DIRECTORY_NAME format a30
column DIRECTORY_PATH format a80
column RECOVERY_DEST_SIZE format a60
column REPEAT_INTERVAL format a20
column PROGRAM_NAME format a30
column JOB_ACTION format a80
column JOB_NAME format a30
column ERRORS format a30
column STATISTIC format a80
column START_DATE format a40
column LAST_RUN_DURATION format a30 

spool ora2txt.txt
@ora2txt.sql