
 
 
 
CREATE  procedure [dbo].[spLocal_MPWS__DBUG_ScriptProceduresToFile]
	@LastAltered	DATETIME = NULL
	
AS
 /*-------------------------------------------------------------------------------------

 exec sp_configure 'show advanced options', 1
 go
 reconfigure
 go
 exec sp_configure 'xp_cmdshell',1
 go
 reconfigure
 go
  declare @dt datetime = '2017-08-24'
 execute spLocal_MPWS__DBUG_ScriptProceduresToFile @dt
 exec sp_configure 'xp_cmdshell',0
 go
 reconfigure
 go
 exec sp_configure 'show advanced options', 0
 go
 reconfigure
 go
 */-------------------------------------------------------------------------------------
DECLARE 
	@name sysname,
	@objID int,
	@schemaID int,
	@cmd varchar(1000)
 
DECLARE procs CURSOR FOR 
	SELECT 
		object_name(m.object_id) name, m.object_id, o.schema_id
	FROM sys.sql_modules m
		JOIN sys.objects o ON m.object_id = o.object_id
	WHERE (
			object_name(m.object_id) LIKE 'spLocal_MPWS_%'
			OR 
			object_name(m.object_id) = 'spLocal_INT_GHS_ProcessComplyPlusData'
			OR
			object_name(m.object_id) LIKE 'fnLocal_MPWS_%'
			OR
			object_name(m.object_id) LIKE 'fnMPWS_%'
			OR
			object_name(m.object_id) LIKE 'vMPWS_%'
			)
		AND (o.modify_date > @LastAltered OR @LastAltered IS NULL)
	ORDER BY [name]
 
OPEN procs
 
FETCH NEXT FROM procs INTO @name, @objID, @schemaID
 
WHILE @@FETCH_STATUS = 0
BEGIN
 
	-- append to file
	SET @cmd = 'sqlcmd  -S BRTC-MSLAB2199 -d ' + DB_NAME() 
				+ ' -Q "EXEC dbo.spLocal_MPWS__DBUG_ScriptProcedures ' + CONVERT(VARCHAR(20), @objID) + ', N''' + @name + ''', ' + CONVERT(VARCHAR(20), @schemaID) + '"' 
				--+ ' > C:\SQLScripts\20170825\' + @name + '.sql'
				+ ' > C:\Users\lee.s.3\Documents\SQLScripts\' + @name + '.sql'
 --\\brtc-mslab2199\Users\lee.s.3\Documents\SQLScripts
--print @cmd
	EXEC xp_cmdshell @cmd
 
	FETCH NEXT FROM procs INTO @name, @objID, @schemaID
 
END
 
CLOSE procs
DEALLOCATE procs
 
 

