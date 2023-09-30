-- �2014 GE Intelligent Platforms, Inc. All rights reserved.

-- PROCEDURE: usp_LoadPersonnelForeignKeys

-- Create rows in the Personnel.PersonnelForeignKeys table.
-- This table contains the list of the existing foreign keys against Personnel-related tables
-- that is used during data migration.

-- DROP PROCEDURE [PR_Personnel].usp_LoadPersonnelForeignKeys
-- GO
CREATE PROCEDURE [PR_Personnel].usp_LoadPersonnelForeignKeys (
@debug BIT = 1,                    -- if 1, print out all statements before executing
@test  BIT = 0                     -- if 1, do not make any changes
) WITH EXECUTE AS OWNER
 AS
BEGIN
	SET NOCOUNT ON

	DECLARE @routineName VARCHAR(100) = '[PR_Personnel].usp_LoadPersonnelForeignKeys: '
	DECLARE @foreignKeys INT

	IF (@debug = 1)
	BEGIN
		PRINT @routineName + 'entry'
	END

	-- Check to see if there are already rows in the table. 
	-- DOC: We only want to get the list of existing foreign keys the first time we attempt the migration. 
	-- If the migration fails, we can reverse the changes by going through this table and reverting the foreign keys to they way the were before
	IF NOT EXISTS (SELECT 1 
		FROM [PR_Personnel].PersonnelForeignKeys 
		WHERE ReferenceTableName = 'Person')
	BEGIN
		IF (@test = 0)
		BEGIN
			-- Find all foreign keys who are referencing one of our Personnel tables of interest but 
			-- are NOT originating from those same tables. (for example, we don't want the FK between PersonnelGroup and Person)
			INSERT INTO [PR_Personnel].PersonnelForeignKeys 
			SELECT 
				ForeignKeyName
				,SchemaName
				,TableName
				,ColumnName
				,ReferenceTableName
				,ReferenceColumnName
			FROM [PR_Utility].ForeignKeys 
			WHERE SchemaName = 'dbo' 
			AND ReferenceTableName IN
			(
				'Person',
				'PersonnelGroup',
				'PersonnelPrivileges',
				'UserAccount',
				'PersonAndGroup',
				'GroupAndPerson'
			)
			AND TableName NOT IN
			(
				'Person',
				'PersonnelGroup',
				'PersonnelPrivileges',
				'UserAccount',
				'PersonAndGroup',
				'GroupAndPerson')	  
			ORDER BY ReferenceTableName, TableName
			SET @foreignKeys = @@ROWCOUNT
		END
		ELSE
		BEGIN
			SELECT @foreignKeys = COUNT(*)
			FROM [PR_Utility].ForeignKeys 
			WHERE SchemaName = 'dbo' 
				AND ReferenceTableName IN
				(
					'Person',
					'PersonnelGroup',
					'PersonnelPrivileges',
					'UserAccount',
					'PersonAndGroup',
					'GroupAndPerson'
				)
				AND TableName NOT IN
				(
					'Person',
					'PersonnelGroup',
					'PersonnelPrivileges',
					'UserAccount',
					'PersonAndGroup',
					'GroupAndPerson')	  
		END
		IF (@debug = 1)
		BEGIN
			PRINT @routineName + CONVERT(VARCHAR(5),@foreignKeys) + ' Personnel foreign keys found.'
		END
	END
	ELSE
	BEGIN
		IF (@debug = 1)
		BEGIN
			SELECT @foreignKeys = COUNT(*)
			FROM [PR_Personnel].PersonnelForeignKeys 
			PRINT @routineName + 'PersonnelForiegnKeys already loaded with ' + CONVERT(VARCHAR(5),@foreignKeys) + ' records'
		END
	END

	IF (@debug = 1)
	BEGIN
		PRINT @routineName + 'exit'
	END

END