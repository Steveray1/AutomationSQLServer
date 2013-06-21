USE [msdb]
GO

/****** Object:  Job [Every 12 Hr - Irdb Db Backup]    Script Date: 05/14/2013 01:49:59 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 05/14/2013 01:49:59 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Every 12 Hr - Irdb Db Backup', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'This job will creates DB dump and copied into network folder.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'useradm', 
		@notify_email_operator_name=N'IT-DBA', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Scheduled Job]    Script Date: 05/14/2013 01:49:59 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Scheduled Job', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'set nocount on
declare @dbname sysname
set @dbname =db_name()
--print @dbname
declare @cmd varchar(4000)
declare @backupFileName varchar(2000) 
create table #dbname (dbname sysname)
declare @backupdir varchar(200)


set @backupdir ='\\hdcbackup04.backup.hdc.mdsol.com\TRN_LOGSShared\HDCUNIPRDBSV021\TRN\'
set @cmd = 'insert into #dbname  select name from master..sysdatabases where name  = ''' +@dbname + ''' and status & 512 <> 512 order by name'
Exec(@cmd) 


     declare dbname_cur Cursor for select dbname from #dbname
     open dbname_cur
	     fetch next from dbname_cur into @dbname
		WHILE @@FETCH_STATUS = 0
		  BEGIN
			print ''-- BACKING UP Log '' + @dbname
                        set @backupFileName = @backupdir + @dbname + ''_TRN_''+ replace(convert(varchar(23),getdate(),121),'':'',''.'') 
			set @cmd =  ''exec sp_dboption  ['' + @dbname + '' ],''''trunc. log on chkpt.'''' ,false
                                    BACKUP LOG ['' + @dbname + ''] TO DISK = '''''' + @backupFileName + ''.bak'''' WITH NAME = '''''' + @dbname + '' Log backup'''',  SKIP '' 
                       exec (@cmd)
                        --- select @cmd
			  fetch next from dbname_cur into @dbname
		   end
		close dbname_cur
		DEALLOCATE  dbname_cur
		truncate table #dbname

drop table #dbname

set quoted_identifier on

PRINT ''COMPLETED ''
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Scheduled Time', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=12, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20070507, 
		@active_end_date=99991231, 
		@active_start_time=120000, 
		@active_end_time=115959, 
		@schedule_uid=N'd494d1ce-a4f9-475a-b05a-315fe1b7e06d'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO
---------------------------------------------------------------------------------------------------------------
USE [msdb]
GO

/****** Object:  Job [Transaction Log Backup - Every 15 Minutes]    Script Date: 05/14/2013 01:54:45 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 05/14/2013 01:54:45 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Transaction Log Backup - Every 15 Minutes', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'This job will creates DB dump and copied into network folder.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'useradm', 
		@notify_email_operator_name=N'IT-DBA', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Scheduled Job]    Script Date: 05/14/2013 01:54:46 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Scheduled Job', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'set nocount on
declare @dbname sysname
set @dbname =db_name()
--print @dbname
declare @cmd varchar(4000)
declare @backupFileName varchar(2000) 
create table #dbname (dbname sysname)
declare @backupdir varchar(200)


set @backupdir ='\\hdcbackup04.backup.hdc.mdsol.com\TRN_LOGSShared\HDCUNIPRDBSV021\TRN\'
set @cmd = 'insert into #dbname  select name from master..sysdatabases where name  = ''' +@dbname + ''' and status & 512 <> 512 order by name'
Exec(@cmd) 
     declare dbname_cur Cursor for select dbname from #dbname
     open dbname_cur
	     fetch next from dbname_cur into @dbname
		WHILE @@FETCH_STATUS = 0
		  BEGIN
			print ''-- BACKING UP Log '' + @dbname
                        set @backupFileName = @backupdir + @dbname + ''_TRN_''+ replace(convert(varchar(23),getdate(),121),'':'',''.'') 
			set @cmd =  ''exec sp_dboption  ['' + @dbname + '' ],''''trunc. log on chkpt.'''' ,false
                                    BACKUP LOG ['' + @dbname + ''] TO DISK = '''''' + @backupFileName + ''.bak'''' WITH NAME = '''''' + @dbname + '' Log backup'''',  SKIP '' 
                       exec (@cmd)
                        --- select @cmd
			  fetch next from dbname_cur into @dbname
		   end
		close dbname_cur
		DEALLOCATE  dbname_cur
		truncate table #dbname

drop table #dbname

set quoted_identifier on

PRINT ''COMPLETED ''
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Scheduled Time', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=15, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20070507, 
		@active_end_date=99991231, 
		@active_start_time=120000, 
		@active_end_time=115959, 
		@schedule_uid=N'd494d1ce-a4f9-475a-b05a-315fe1b7e06d'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO
Script for setting up Index job
     USE [msdb]
GO
------------------------------------------------------------------------------------------------------------------------------
/****** Object:  Job [Database Reindex]    Script Date: 05/16/2013 17:47:47 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 05/16/2013 17:47:47 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Database Reindex', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'useradm', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Step1 Index]    Script Date: 05/16/2013 17:47:49 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Step1 Index', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=3, 
		@retry_interval=15, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE [DatabaseName] --  DB Name
go

IF Not exists( select name from sys.objects where name =''IndexTableDetail'')
  create table  IndexTableDetail (TableId BigInt, TableName varchar(150), Indexid int, IndexName Varchar(250),FragmentValue float)
delete from  IndexTableDetail

Insert into IndexTableDetail (TableID, TableName, Indexid, IndexName,FragmentValue)
SELECT ps.OBJECT_ID, object_name(ps.OBJECT_ID) TableName,

            ps.index_id, b.name,

            ps.avg_fragmentation_in_percent

FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, NULL) AS ps

INNER JOIN sys.indexes AS b ON ps.OBJECT_ID = b.OBJECT_ID

        AND ps.index_id = b.index_id and b.name is not null

WHERE db_name(ps.database_id) = db_name()  and ps.avg_fragmentation_in_percent >=1 -- and ps.index_id =1

ORDER BY object_name(ps.OBJECT_ID)asc 


Declare @strsql nvarchar(255) 
Declare @tableid BigInt
Declare @TableName varchar(250)
Declare @IndexName varchar(250)
set nocount on

DECLARE TableCursor CURSOR FOR 
   SELECT TableID,TableName, IndexName FROM  IndexTableDetail WHERE Tablename not Like ''qs_%'' and Tablename not like ''%_backup'' and TableName not like ''BK_%''  order by Tablename Asc
OPEN TableCursor 

FETCH NEXT FROM TableCursor INTO @tableid, @TableName, @IndexName 

WHILE @@FETCH_STATUS = 0 
BEGIN 
	If not exists (select 1 from sys.all_columns where object_id = @tableid and user_type_id in (34, 35, 99, 165, 167,231, 241))
		begin
			set @strsql = ''alter index '' + @indexName + '' on '' + @TableName+ '' rebuild with (statistics_norecompute=on,ONLINE = ON,FILLFACTOR =90)''
			--set @strsql = ''alter index all on '' + @TableName+ '' rebuild with (statistics_norecompute=on,ONLINE = ON,FILLFACTOR =90)''
			Print @strsql  
			exec sp_executesql @strsql
    	End
     Else
        Begin

            
            set @strsql = ''alter index '' + @indexName + '' on '' + @TableName+ '' rebuild with (statistics_norecompute=on,ONLINE = OFF,FILLFACTOR =90)''
            --set @strsql = ''alter index all on '' + @TableName+ '' rebuild with (statistics_norecompute=on,ONLINE = OFF,FILLFACTOR =90)''
            print @strsql 
           exec sp_executesql @strsql
         End  

      FETCH NEXT FROM TableCursor INTO @tableid, @TableName, @IndexName
  END 
CLOSE TableCursor 
DEALLOCATE TableCursor', 
		@database_name=N'master', 
		@output_file_name=N'C:\ReindexOutput.txt', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Reindex Schedule', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=64, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20080421, 
		@active_end_date=99991231, 
		@active_start_time=10000, 
		@active_end_time=235959, 
		@schedule_uid=N'af1260aa-95ce-451d-8373-0c43e8309b7e'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO
-------------------------------------------------------------------------------------------------------------------------