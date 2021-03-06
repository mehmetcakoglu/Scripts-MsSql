
-- aylara g�re database b�y�mesini g�steren script
SELECT
[database_name] AS "Database",
DATEPART(month,[backup_start_date]) AS "Month",
AVG([backup_size]/1024/1024) AS "Backup Size MB",
AVG([compressed_backup_size]/1024/1024) AS "Compressed Backup Size MB",
AVG([backup_size]/[compressed_backup_size]) AS "Compression Ratio"
FROM msdb.dbo.backupset
WHERE 1=1
--and [database_name] = N'AdventureWorks'
AND [type] = 'D'
GROUP BY [database_name],DATEPART(mm,[backup_start_date])
ORDER BY DATABASE_NAME,DATEPART(mm,[backup_start_date])
;


SELECT
[database_name] AS "Database",
DATEPART(month,[backup_start_date]) AS "Month",
AVG([backup_size]/1024/1024) AS "Backup Size MB"
FROM msdb.dbo.backupset
WHERE 1=1
-- and [database_name] = N'AdventureWorks'
AND [type] = 'D'
GROUP BY [database_name],DATEPART(mm,[backup_start_date])
ORDER BY DATABASE_NAME,DATEPART(mm,[backup_start_date])
;