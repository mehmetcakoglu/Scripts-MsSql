/*
	Move TempDB datafiles
	v20140909 Wilfred van Dijk (wvand@wilfredvandijk.nl)
	http://www.sqlservercentral.com/scripts/tempdb/115853/
*/
use master
set nocount on
go

declare @new_datafile_location varchar(256)
declare @new_logfile_location varchar(256)
declare @new_datafile_size int
declare @new_datafile_maxsize int
declare @new_logfile_size int
declare @new_logfile_maxsize int
declare @new_datagrowth_size int
declare @new_loggrowth_size int
declare @new_datagrowth_is_percent bit
declare @new_loggrowth_is_percent bit

declare @debug char(1)
declare @SQLCmd table(id int identity(1,1), TSQL nvarchar(512), type int NULL)
declare @Statement nvarchar(512)
declare @max_datafile_size bigint
declare @max_logfile_size bigint
/*
	MANDATORY PARAMETERS:
	(at least one new location must be specified)
*/
set @debug = 'Y'
set @new_datafile_location = 'D:\SQLDATA\TEMPDB\DATAFILE'-- (no backslash added)
set @new_logfile_location = 'D:\SQLDATA\TEMPDB\LOGFILE'-- (no backslash added)
/*
	OPTIONAL PARAMETERS HERE:
*/
--set @new_datafile_size = 
--set @new_logfile_size =
--set @new_datafile_maxsize = 
--set @new_logfile_maxsize =
--set @new_datagrowth_size =
--set @new_loggrowth_size =
--set @new_datagrowth_is_percent = 0
--set @new_loggrowth_is_percent = 0
/*
	CREATE COMMANDS
	1) create subdirectories
*/
insert into @SQLCmd(TSQL)
select 'EXECUTE master.dbo.xp_create_subdir "'+ @new_datafile_location + '"'
where @new_datafile_location is not null
union
select 'EXECUTE master.dbo.xp_create_subdir "'+ @new_logfile_location + '"'
where @new_logfile_location is not null
/*
	2) Change location(s)
*/
insert into @SQLCmd
SELECT 'ALTER DATABASE Tempdb MODIFY FILE ( NAME = ' + name + ', FILENAME = "'+ @new_datafile_location + right(physical_name, charindex('\', reverse(physical_name))) + '"', type
FROM sys.master_files
WHERE database_id = 2 and type = 0
and @new_datafile_location is not null
;
insert into @SQLCmd
SELECT 'ALTER DATABASE Tempdb MODIFY FILE ( NAME = ' + name + ', FILENAME = "'+ @new_logfile_location + right(physical_name, charindex('\', reverse(physical_name))) + '"', type
FROM sys.master_files
WHERE database_id = 2 and type = 1
and @new_logfile_location is not null;
/*
	3) Change size (if specified)
*/
if @new_datafile_size is not null
	update @SQLCmd
	set TSQL = TSQL + ', SIZE = ' + cast(@new_datafile_size as varchar) + 'MB'
	where type = 0
;
if @new_logfile_size is not null
	update @SQLCmd
	set TSQL = TSQL + ', SIZE = ' + cast(@new_logfile_size as varchar) + 'MB'
	where type = 1;
/*
	4) Change maxsize (if specified)
*/
if @new_datafile_maxsize is not null
	update @SQLCmd
	set TSQL = TSQL + ', MAXSIZE = ' + cast(@new_datafile_maxsize as varchar) + 'MB'
	where type = 0
;
if @new_logfile_maxsize is not null
	update @SQLCmd
	set TSQL = TSQL + ', MAXSIZE = ' + cast(@new_logfile_maxsize as varchar) + 'MB'
	where type = 1;
/*
	5) filegrowth settings (if specified)
*/
if @new_datagrowth_size is not null
	update @SQLCmd
	set TSQL = TSQL + ', FILEGROWTH = ' + cast(@new_datagrowth_size as varchar) + case when @new_datagrowth_is_percent = 1 then '%' else 'MB' end
	where type = 0	
;
if @new_loggrowth_size is not null
	update @SQLCmd
	set TSQL = TSQL + ', FILEGROWTH = ' + cast(@new_loggrowth_size as varchar) + case when @new_loggrowth_is_percent = 1 then '%' else 'MB' end
	where type = 1;
/*
	FINALIZE: Add closing parenthesis
*/
update @SQLCmd
set TSQL = TSQL + ')'
where type is not null
/*
	Show max size allocated for TempDb
*/
if @new_datafile_maxsize is not null
	set @max_datafile_size = @new_datafile_maxsize * (select count(*) from @SQLCmd where type = 0)

if @new_logfile_maxsize is not null
	set @max_logfile_size = @new_logfile_maxsize * (select count(*) from @SQLCmd where type = 1)

print '-- TempDb uses a maximum of '+ cast(@max_datafile_size as varchar) + 'MB for datafiles on '+ @new_datafile_location
print '-- TempDb uses a maximum of '+ cast(@max_logfile_size as varchar) + 'MB for logfiles on '+ @new_logfile_location
/*
	Execute or display?
*/
if @debug = 'Y'

	select TSQL from @SQLCmd order by id

else

	begin
		
		declare c_lus cursor for
			select TSQL from @SQLCmd

		open c_lus
		fetch next from c_lus into @Statement

		while @@FETCH_STATUS = 0

			begin

				print '-- Executing: "' + @Statement + '"'
				exec (@Statement)
				fetch next from c_lus into @statement

			end

		close c_lus
		deallocate c_lus

		print '-- Finished'
		print '-- Restart MSSQL Server to apply changes'
		print '-- After the restart, delete the Tempdb datafiles at the old location'

	end
