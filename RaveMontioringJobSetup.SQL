USE [master]
GO

/****** Object:  StoredProcedure [dbo].[cspDetectPDFIssue]    Script Date: 07/29/2011 18:56:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[cspDetectPDFIssue] 
	@SendTo nvarchar(4000),
	@CC nvarchar(4000) = null,
	@waittime int = 15,
	@reemailtime int = 6,
    @SMTP varchar(1000) = 'smtp.mdsol.com'
as
Begin
	declare @CMD int

	If not exists (select null from msdb.dbo.sysmail_account where name = 'PDFMonitor')
	Begin
		declare @ReturnAdress nvarchar(1000)
		set @ReturnAdress = 'Rave@mdsol.com'

		-- Create a Mail
		EXEC msdb.dbo.sysmail_add_account_sp
			@account_name = 'PDFMonitor',
			@description = 'Mail account for use by all database users.',
			@email_address = @ReturnAdress,
			@replyto_address = @ReturnAdress,
			@display_name = 'Rave Support',
			@mailserver_name = @SMTP

		-- Create a Database Mail profile

		EXEC msdb.dbo.sysmail_add_profile_sp
			@profile_name = 'PDFMonitor',
			@description = 'Profile used for Rave mail.' ;

		-- Add the account to the profile

		EXEC msdb.dbo.sysmail_add_profileaccount_sp
			@profile_name = 'PDFMonitor',
			@account_name = 'PDFMonitor',
			@sequence_number =1 ;

		-- Grant access to the profile to all users in the msdb database

		EXEC msdb.dbo.sysmail_add_principalprofile_sp
			@profile_name = 'PDFMonitor',
			@principal_name = 'public',
			@is_default = 1 ;
	End
------------------------Setup Done --------------------------------------------------

	declare @dbname varchar(50), @sql nvarchar(2000), @BodyTxt varchar(4000), @TimeDetected varchar(20)
	set @BodyTxt = ''
	create table #temp (databasename varchar(50), RaveVersion varchar(15), MinScheduledExecution datetime)
	declare cDbs cursor for select name from master.sys.databases where state_desc ='ONLINE' and name not in ('distribution','ASPState','master', 'msdb','tempdb','model') 	and name not like 'irdb_%' and name not like 'ReportServer%' order by name 
	open cDBs
	fetch cDBs into @dbname
	while @@fetch_status = 0
	begin
	  set @sql = 'insert into #temp select '''+@dbname+''', configvalue, null from "'+@dbname+'".dbo.configuration where tag=''databaseversion'''
	  exec sp_executesql @sql
	  
	  if exists (select null from #temp where databasename = @dbname and (RaveVersion like '5.5.%' or RaveVersion like '5.6.%'))
	  Begin
		 set @sql = 'update #temp set MinScheduledExecution = a.ScheduledDate from (select min(ScheduledExecution) as ScheduledDate from  [' + @dbname + '].dbo.PDFFileRequests where status like ''Scheduled'' and isactive =1 and datediff(d,ScheduledExecution,getutcdate()) <= 7) a where databasename = '''+ @dbname + ''''
		 exec sp_executesql @sql
		 set @TimeDetected = null
		 select @TimeDetected = cast(MinScheduledExecution as varchar) from #temp where databasename = @dbname
		 -- Origional script --- if(DATEDIFF(hh,@TimeDetected,getutcdate())%@reemailtime = 0 and DATEDIFF(n,@TimeDetected,getutcdate())%60 >= @waittime and 
		--	DATEDIFF(n,@TimeDetected,getutcdate())%60 <= @waittime*2)
         if(DATEDIFF(n,@TimeDetected,getutcdate())%60 >= @waittime and 
			DATEDIFF(n,@TimeDetected,getutcdate())%60 <= @waittime*2)
		 Begin
             set @BodyTxt = @BodyTxt + 'The database: ''' + @dbname + ''' has had a PDF File request scheduled but not processed since: ''' + @TimeDetected + ''' UTC on ' + @@servername

             set @BodyTxt = char(13)+ @BodyTxt 
		 End
	  End
	fetch cDBs into @dbname
	end
	close cDBs
	deallocate cDBs
	select * from #temp
	drop table #temp

if len(@BodyTxt) > 0
    EXEC msdb.dbo.sp_send_dbmail
			@profile_name = 'PDFMonitor',
			@copy_recipients = @CC,
			@recipients = @SendTo,
			@body = @BodyTxt,
			@subject = 'Automated Rave Message - PDF Not Running Detected' ;
End
GO
USE [master]
GO
/****** Object:  StoredProcedure [dbo].[cspDetectTimestampIssue]    Script Date: 07/29/2011 18:57:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create procedure [dbo].[cspDetectTimestampIssue] 
	@SendTo nvarchar(4000),
	@CC nvarchar(4000) = null,
    @threshhold varchar(3) = '2',
    @SMTP varchar(1000) = 'smtp.mdsol.com'
as
Begin
	declare @CMD int, @CurrentStatus int, @BodyTxt nvarchar(2000)

	If not exists (select null from msdb.dbo.sysmail_account where name = 'TimestampMonitor')
	Begin
		declare @ReturnAdress nvarchar(1000)
		set @ReturnAdress = 'Rave@mdsol.com'

		-- Create a Mail
		EXEC msdb.dbo.sysmail_add_account_sp
			@account_name = 'TimestampMonitor',
			@description = 'Mail account for use by all database users.',
			@email_address = @ReturnAdress,
			@replyto_address = @ReturnAdress,
			@display_name = 'Rave Support',
			@mailserver_name = @SMTP

		-- Create a Database Mail profile

		EXEC msdb.dbo.sysmail_add_profile_sp
			@profile_name = 'TimestampMonitor',
			@description = 'Profile used for Rave mail.' ;

		-- Add the account to the profile

		EXEC msdb.dbo.sysmail_add_profileaccount_sp
			@profile_name = 'TimestampMonitor',
			@account_name = 'TimestampMonitor',
			@sequence_number =1 ;

		-- Grant access to the profile to all users in the msdb database

		EXEC msdb.dbo.sysmail_add_principalprofile_sp
			@profile_name = 'TimestampMonitor',
			@principal_name = 'public',
			@is_default = 1 ;
	End

	if not exists (select null from master.information_schema.tables where table_name='TimestampAlertLog')
	  create table master.dbo.Timestampalertlog (rundate datetime not null, dbname varchar(50) not null)
	declare @dbname varchar(50), @sql nvarchar(4000), @start datetime
	--truncate table master.dbo.Timestampalertlog
	set nocount on
	set @start = getutcdate()
	declare cDBs cursor for select name from master.sys.databases where name <> 'master'
	and name not like'irdb%' order by 1
	open cDBs
	fetch cDBs into @dbname
	while @@fetch_status=0
	begin
	 -- if exists (select null from information_schema.tables where table_name='datapoints')
	  begin
		set @sql=
        'if exists (select null from ['+@dbname+'].information_schema.tables where table_name=''datapoints'')'+
        ' if exists (select null from ['+@dbname+'].dbo.queries q join ['+@dbname+'].dbo.datapoints dp on q.datapointid=dp.datapointid '+
		' where (datediff(ss,q.created,isnull(q.resolved,q.answered)) <=-60 or datediff(ss,dp.created,q.created) <=-60) '+ 
          ' and q.created between dateadd(day,-'+@threshhold+', getutcdate()) and getutcdate())'+
        ' or exists (select null from ['+@dbname+'].dbo.datapoints where datediff(ss,created,updated) <=-60'+
          ' and created between dateadd(day,-'+@threshhold+', getutcdate()) and getutcdate())'+
        ' or exists (select null from ['+@dbname+'].dbo.comments c join ['+@dbname+'].dbo.datapoints dp on c.datapointid=dp.datapointid '+
		' where (datediff(ss,c.created,c.updated) <=-60 or datediff(ss,dp.created,c.created) <=-60) '+ 
          ' and c.created between dateadd(day,-'+@threshhold+', getutcdate()) and getutcdate())'+
        ' or exists (select null from ['+@dbname+'].dbo.stickies s join ['+@dbname+'].dbo.datapoints dp on s.datapointid=dp.datapointid '+
		' where (datediff(ss,s.created,s.updated) <=-60 or datediff(ss,dp.created,s.created) <=-60) '+ 
          ' and s.created between dateadd(day,-'+@threshhold+', getutcdate()) and getutcdate())'+
        ' or exists (select null from ['+@dbname+'].dbo.protocolDeviations pd join ['+@dbname+'].dbo.datapoints dp on pd.datapointid=dp.datapointid '+
		' where (datediff(ss,pd.created,pd.updated) <=-60 or datediff(ss,dp.created,pd.created) <=-60) '+ 
          ' and pd.created between dateadd(day,-'+@threshhold+', getutcdate()) and getutcdate())'+ 
          ' insert into master.dbo.TimestampAlertlog values(getutcdate(),'''+@dbname+''')'
		exec sp_executesql @sql
	  end
	  fetch cDBs into @dbname
	end
	close cDBS
	deallocate cDBs
	 declare cTrouble cursor for
	 select dbname from master.dbo.TimestampAlertlog where rundate > @start order by 1
	 open cTrouble
	 fetch cTrouble into @dbname
	 if @@fetch_status = 0
	 begin
	   set @BodyTxt = 'The following database(s) have a timestamp problem within the last '+@threshhold+' days:'
	   set @BodyTxt = @BodyTxt + char(13)
	   while @@fetch_status=0
	   begin
		 set @BodyTxt = @BodyTxt + @dbname + char(13)
		 fetch cTrouble into @dbname
	   end
	   EXEC msdb.dbo.sp_send_dbmail
				@profile_name = 'TimestampMonitor',
				@copy_recipients = @CC,
				@recipients = @SendTo,
				@body = @BodyTxt,
				@subject = 'Automated Rave Message - Timestamp Issue Detected' ;
	 end 
	close cTrouble
	deallocate cTrouble
End
GO
-------------------------------------------------------------------------------------------------------------------------------------------


USE [msdb]
GO

/****** Object:  Job [PDF Monitoring - All DBs]    Script Date: 05/09/2013 10:14:36 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 05/09/2013 10:14:36 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'PDF Monitoring - All DBs', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'useradm', 
		@notify_email_operator_name=N'IT-DBA', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Step1]    Script Date: 05/09/2013 10:14:36 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Step1', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
exec cspDetectPDFIssue ''hdchsnocsupport@mdsol.com'',''IT-DBA@mdsol.com'', 15', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Sched', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=15, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20080527, 
		@active_end_date=99991231, 
		@active_start_time=120000, 
		@active_end_time=115959, 
		@schedule_uid=N'21196789-f1e1-44eb-8187-1239d58659f9'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO
--------------------------------------------------------------------------------------------------------------------------
USE [msdb]
GO

/****** Object:  Job [Purge_Backup_Tables]    Script Date: 05/09/2013 10:15:11 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 05/09/2013 10:15:11 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Purge_Backup_Tables', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'useradm', 
		@notify_email_operator_name=N'IT-DBA', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Step1]    Script Date: 05/09/2013 10:15:11 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Step1', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'use master
go
DECLARE @DB_Name varchar(100) 
DECLARE @Command nvarchar(4000) 
Declare @TableName nvarchar(255)
Declare @SQLCmd nvarchar(255)
set nocount on

if not exists (select name from sys.objects where name =''Temptable'')
  create table Temptable (tname varchar(250))

DECLARE database_cursor CURSOR FOR SELECT name FROM sys.databases  where Name not in (''Master'',''Model'',''Tempdb'',''MSDB'',''ReportServer'',''ReportServerTempDB'')
and state_desc = ''ONLINE''
OPEN database_cursor 
FETCH NEXT FROM database_cursor INTO @DB_Name 

WHILE @@FETCH_STATUS = 0 
BEGIN 
     SELECT @Command = ''insert into Temptable select '' + '''''''' + @DB_Name + '''''''' +  ''+'' + ''''''.dbo.'''''' +  ''+'' +   '' name from '' + @DB_Name + ''.dbo.'' + ''sysobjects 
where ((name like ''''BK_%'''' and name like ''''%WR%'''') or (name like ''''BK_%'''' and name like ''''%WO%'''')) and name NOT like ''''%no_purge%''''
 and datediff(dd, crdate, getUTCDate()) > 7 order by crdate''
     --print @Command     
     EXEC sp_executesql @Command 
     -- purge database of BK_WR files more than 30 days old 
     declare Old_BK_Tables Cursor FAST_FORWARD for select tname from Temptable
     open Old_BK_Tables
     fetch next from Old_BK_Tables into @TableName
 
     while @@fetch_status = 0
          begin
               set @SQLCmd = ''drop table '' + @TableName
               print @SQLCmd
               exec (@SQLCmd)
               fetch next from Old_BK_Tables into @TableName
          end
 
     close Old_BK_Tables
     deallocate Old_BK_Tables  
     delete from Temptable
     FETCH NEXT FROM database_cursor INTO @DB_Name 
END 

CLOSE database_cursor 
DEALLOCATE database_cursor 
Drop table Temptable', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Sched', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20090824, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'17740008-3d88-4345-a648-85da6abf12d8'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO

USE [msdb]
GO

/****** Object:  Job [Timestamp Issue Detected]    Script Date: 05/09/2013 10:15:11 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 06/16/2013 22:25:44 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Timestamp Issue Detected', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'useradm', 
		@notify_email_operator_name=N'IT-DBA', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Step1]    Script Date: 06/16/2013 22:25:44 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Step1', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
exec master..cspDetectTimestampIssue @SendTo =''IT-DBA@mdsol.com;'',@CC = ''IT-DBA@mdsol.com;''', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Sched', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20080527, 
		@active_end_date=99991231, 
		@active_start_time=10000, 
		@active_end_time=235959, 
		@schedule_uid=N'da3f6cbc-ff7d-4409-a60a-cb77c1161c2e'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO



--------------------------------------------------------------------------------------------------------------