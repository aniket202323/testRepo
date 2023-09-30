-- ©2014 GE Intelligent Platforms, Inc. All rights reserved.

-- PROCEDURE: usp_RenameTables

-- Rename tables and create synonyms

CREATE PROCEDURE [PR_Personnel].usp_RenameTables  (
@debug BIT = 1,                    -- if 1, print out all statements before executing
@test  BIT = 0                     -- if 1, do not make any changes
) AS
BEGIN

	SET NOCOUNT ON

	DECLARE @routineName VARCHAR(100) = '[PR_Personnel].usp_RenameTables: '
	DECLARE @tableCount INT = 0
	DECLARE @tableIndex INT = 0

	-- table variable to hold a list of table names to process
	DECLARE @tableNames AS TABLE (
		rowNumber INT IDENTITY(1,1),
		tableName SYSNAME
	)

	INSERT INTO @tableNames (tableName) VALUES ('Person')
	INSERT INTO @tableNames (tableName) VALUES ('UserAccount')
	INSERT INTO @tableNames (tableName) VALUES ('PersonnelPrivileges')
	INSERT INTO @tableNames (tableName) VALUES ('PersonnelGroup')
	INSERT INTO @tableNames (tableName) VALUES ('PersonAndGroup')
	INSERT INTO @tableNames (tableName) VALUES ('GroupAndPerson')
	
	SET @tableCount = (SELECT COUNT(*) FROM @tableNames)
	SET @tableIndex = @tableCount

	DECLARE @transactionCount INT = @@TRANCOUNT

	BEGIN try
		-- rename dbo tables
		SET @tableIndex = 0
		WHILE (@tableIndex < @tableCount)
		BEGIN
			SET @tableIndex = @tableIndex + 1
			DECLARE @legacyTableName SYSNAME
			DECLARE @originalTableName SYSNAME
			SELECT
				@legacyTableName = tableName + 'Legacy',
				@originalTableName = tableName
			FROM @tableNames 
			WHERE rowNumber = @tableIndex

			IF ([PR_Utility].ufn_ObjectExists (@originaltableName,'TABLE',NULL,'dbo') =  1)
			BEGIN
				SET @originalTableName = '[dbo].' + @originalTableName
				IF (@debug = 1)
				BEGIN
					PRINT @routineName + 'EXEC [dbo].sp_rename '''+ @originalTableName + ''', ''' + @legacyTableName + '''' 
				END
				IF (@test = 0)
				BEGIN
					EXEC [dbo].sp_rename @originalTableName, @legacyTableName
				END
			END
		END

		-- create synonyms 
		SET @tableIndex = 0
		WHILE (@tableIndex < @tableCount)
		BEGIN
			SET @tableIndex = @tableIndex + 1

			DECLARE @synonymName SYSNAME
			DECLARE @viewName SYSNAME
			SELECT 
				@synonymName = '[dbo].' + tableName,
				@viewName    = CASE (tableName )
										-- Both GroupAndPerson and PersonAndGroup can use the same view
										WHEN 'GroupAndPerson' THEN '[dbo].PersonAndGroupView'
										ELSE '[dbo].' + tableName + 'View'
									END 
			FROM @tableNames 
			WHERE rowNumber = @tableIndex

			DECLARE @sqlStmt VARCHAR(500)
			SET @sqlStmt = 'CREATE SYNONYM ' + @synonymName + ' FOR ' + @viewName
			IF (@debug = 1)
			BEGIN
				PRINT @routineName + @sqlStmt
			END
			IF (@test = 0)
			BEGIN
				EXEC (@sqlStmt)
			END
		END

	END try
	BEGIN catch

		-- Collect info on the error and rollback
		DECLARE @error INT = ERROR_NUMBER()
		DECLARE @message VARCHAR(4000) = ERROR_MESSAGE()
		DECLARE @transactionState  INT = XACT_STATE()

		IF (@transactionState = -1)
		BEGIN
			IF (@debug = 1) PRINT @routineName + 'ROLLBACK'
			ROLLBACK
		END
		IF (@transactionState = 1 AND @transactionCount = 0)
		BEGIN
			IF (@debug = 1) PRINT @routineName + 'ROLLBACK'
			ROLLBACK
		END

		RAISERROR('%s: %d: %s',16,1, @routineName, @error, @message)

	END catch
END