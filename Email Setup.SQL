if not exists (select null from msdb.dbo.sysmail_account where name = 'TimeStampMonitor')
	Begin
		declare @display_name nvarchar(1000)
		     	set @display_name = @@servername + ' Notification Alert' 

		-- Create a Mail
		EXEC msdb.dbo.sysmail_add_account_sp
			@account_name = 'TimeStampMonitor',
			@description = 'Mail account for use by all database users.',
			@email_address = 'Rave@mdsol.com',
			@replyto_address = 'IT-DBA@mdsol.com',
			@display_name = @display_name,
			@mailserver_name = 'smtp.mdsol.com'

		-- Create a Database Mail profile

		EXEC msdb.dbo.sysmail_add_profile_sp
			@profile_name = 'TimeStampMonitor',
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
			
	     exec msdb.dbo.sysmail_configure_sp 'MaxFileSize' ,1000000000		
	End
Go
EXEC msdb.dbo.sp_add_operator
    @name = N'IT-DBA',
    @enabled = 1,
    @email_address = N'IT-DBA@mdsol.com';
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_set_sqlagent_properties @email_save_in_sent_folder=1
GO
EXEC master.dbo.xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent', N'UseDatabaseMail', N'REG_DWORD', 1
GO
EXEC master.dbo.xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent', N'DatabaseMailProfile', N'REG_SZ', N'TimeStampMonitor'
GO


USE [msdb]
GO
EXEC msdb.dbo.sp_set_sqlagent_properties @email_save_in_sent_folder=1
GO
EXEC master.dbo.xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent', N'UseDatabaseMail', N'REG_DWORD', 1
GO
EXEC master.dbo.xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent', N'DatabaseMailProfile', N'REG_SZ', N'TimeStampMonitor'
GO

