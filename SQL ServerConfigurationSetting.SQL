Sp_configure 'show advanced options', '1'
Go
sp_configure 'backup compression default', 1
go
exec sp_configure 'Database Mail XPs', 1
go
sp_configure 'min server memory (MB)', 0
go
sp_configure 'cost threshold for parallelism', 5
go
sp_configure 'xp_cmdshell',0
go
sp_configure 'xp_cmdshell',1
go
sp_configure 'remote admin connections', 1
go
sp_configure 'optimize for ad hoc workloads',1
go
DECLARE @CPUCount int 
DECLARE @MemMB int;
SELECT @CPUCount = cpu_count, @MemMB = Cast(ROUND(((physical_memory_in_bytes/1048576) - 4096),-1) as int) FROM sys.dm_os_sys_info;
print @CPUCount
print @MemMB 
IF @CPUCount >= 8
BEGIN
sp_configure 'max degree of parallelism', 8   ;
END ;
IF @CPUCount < 8 
BEGIN
sp_configure 'max degree of parallelism', 0;
END;
go
sp_configure N'max server memory (MB)', @MemMB;
go
reconfigure with override
go


