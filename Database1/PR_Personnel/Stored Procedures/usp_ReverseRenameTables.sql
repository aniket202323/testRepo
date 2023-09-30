-- ©2014 GE Intelligent Platforms, Inc. All rights reserved.

-- PROCEDURE: usp_ReverseRanameTables

-- Drop Personnel synonyms and rename Legacy tables back to their original names.
-- Called during the PersonnelData migration to reverse any effects of previously
-- failed deployment attempts


CREATE PROCEDURE [PR_Personnel].usp_ReverseRenameTables  (
@debug BIT = 1,                    -- if 1, print out all statements before executing
@test  BIT = 0                     -- if 1, do not make any changes
) AS
BEGIN

	SET NOCOUNT ON

	DECLARE @routineName VARCHAR(100) = '[PR_Personnel].usp_ReverseRenameTables: '
	DECLARE @tableCount INT = 0
	DECLARE @tableIndex INT = 0

	-- table variable to hold a list of table names to process
	DECLARE @tableNames AS TABLE (
		rowNumber INT IDENTITY(1,1),
		tableName SYSNAME
	)

	INSERT INTO @tableNames (tableName)VALUES ('Person')
	INSERT INTO @tableNames (tableName) VALUES ('UserAccount')
	INSERT INTO @tableNames (tableName) VALUES ('PersonnelPrivileges')
	INSERT INTO @tableNames (tableName) VALUES ('PersonnelGroup')
	INSERT INTO @tableNames (tableName) VALUES ('PersonAndGroup')
	INSERT INTO @tableNames (tableName) VALUES ('GroupAndPerson')
	
	SET @tableCount = (SELECT COUNT(*) FROM @tableNames)
	SET @tableIndex = @tableCount +1

	-- drop synonyms if they exist 
	WHILE (@tableIndex > 0)
	BEGIN
		SET @tableIndex = @tableIndex - 1
		DECLARE @synonymName SYSNAME
		SELECT @synonymName = tableName
		FROM @tableNames 
		WHERE rowNumber = @tableIndex

		IF (@debug = 1)
		BEGIN
			PRINT @routineName + 'EXEC [PR_Utility].usp_ObjectDrop ''' + @synonymName + ''',''SYNONYM'',NULL,''dbo'',1'
		END
		IF (@test = 0)
		BEGIN
			EXEC [PR_Utility].usp_ObjectDrop @synonymName,'SYNONYM',NULL,'dbo',1
		END
	END

	-- reverse rename of Personnel tables if they were already renamed
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
		WHERE rowNUmber = @tableIndex

		IF ([PR_Utility].ufn_ObjectExists (@legacyTableName,'TABLE',NULL,'dbo') =  1)
		BEGIN
			SET @legacyTableName = '[dbo].' + @legacyTableName
			IF (@debug = 1)
			BEGIN
				PRINT @routineName + 'EXEC [dbo].sp_rename '''+ @legacyTableName + ''', ''' + @originalTableName + '''' 
			END
			IF (@test = 0)
			BEGIN
				EXEC [dbo].sp_rename @legacyTableName, @originalTableName
			END
		END
	END

END