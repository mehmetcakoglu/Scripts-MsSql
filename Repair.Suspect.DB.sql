EXEC sp_resetstatus ‘DBName’
GO
ALTER DATABASE DBName SET EMERGENCY
DBCC checkdb(‘DBname’)
ALTER DATABASE DBName SET SINGLE_USER WITH ROLLBACK IMMEDIATE
DBCC CheckDB (‘DBName’, REPAIR_ALLOW_DATA_LOSS)
ALTER DATABASE DBName SET MULTI_USER
GO
– Rebuild the index
ALTER INDEX ALL ON [ TableName] REBUILD