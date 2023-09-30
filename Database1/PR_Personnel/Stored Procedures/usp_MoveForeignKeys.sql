-- �2014 GE Intelligent Platforms, Inc. All rights reserved.

-- PROCEDURE: MoveForeignKeys 

-- Move all foreign keys from a Personnel table to its corresponding PR_Authorization table
-- by finding all the existing foreign keys on the Personnel table and executing DROP statements
-- for them followed by CREATEs on PR_Authorization.

--DROP PROCEDURE [PR_Personnel].usp_MoveForeignKeys
--GO
CREATE PROCEDURE [PR_Personnel].usp_MoveForeignKeys (
@originalReferenceTableName  SYSNAME,  -- move all foreign keys from this table (ie: dbo.Person
@newReferenceTableName       SYSNAME,  -- to this reference table (ie: PR_Authorization.Person)
@newReferenceColumnName      SYSNAME,  -- on this column (ie: Key)
@debug INT = 1,                        -- if 1, print out all statements before executing
@test  INT = 0                         -- if 1, do not make any changes
) AS
BEGIN
	DECLARE @foreignKeyCount INT
	DECLARE @recordNumber INT
	DECLARE @foreignKeyName SYSNAME
	DECLARE @tableName SYSNAME
	DECLARE @columnName SYSNAME
	DECLARE @originalReferenceColumnName SYSNAME
	DECLARE @sqlStmt VARCHAR(2000)
	DECLARE @routineName VARCHAR(100) = '[PR_Personnel].usp_MoveForeignKeys: '

	-- temporary table to hold the original foreign keys for the originalReferenceTable (ie dbo.Person)
	CREATE TABLE #fk_stmts (
	   row_number  INT NOT NULL IDENTITY(1,1),
	   [action]    VARCHAR(10) NOT NULL,
		foreign_key_name SYSNAME,
	   table_name  SYSNAME NOT NULL,
	   column_name SYSNAME NOT NULL,
	   orig_ref_column_name SYSNAME NOT NULL,
	   fk_sql      VARCHAR(2000) NOT NULL
   ) 

	IF (@debug = 1)
	BEGIN
		PRINT @routineName + 'entry, origionalReferenceTableName ' + @originalReferenceTableName
	END

	-- drop all existing foreign keys for this table
	INSERT INTO #fk_stmts (
		action,
		foreign_key_name,
		table_name,
		column_name,
		orig_ref_column_name,
		fk_sql) 
	SELECT 
		'DROP',
		ForeignKeyName,
		TableName,
		ColumnName,
		ReferenceColumnName,
		'IF ([PR_Utility].ufn_ObjectExists(''' + ForeignKeyName +''',''FOREIGN KEY'',''' + TableName + ''',''dbo'') = 1) ALTER TABLE ' + TableName + ' DROP CONSTRAINT ' + ForeignKeyName 
	 FROM [PR_Personnel].PersonnelForeignKeys
	WHERE ReferenceTableName = @originalReferenceTableName
	ORDER BY TableName,ForeignKeyName

	SELECT @foreignKeyCount = @@ROWCOUNT, @recordNumber = 0
	-- recreate the foreign keys pointing to the new table
	WHILE (@recordNumber < @foreignKeyCount) 
	BEGIN
		SET @recordNumber = @recordNumber + 1
      SELECT
			@tableName       = table_name,
			@foreignKeyName  = foreign_key_name,
			@columnName      = column_name,
			@originalReferenceColumnName = orig_ref_column_name,
			@sqlStmt = fk_sql
      FROM #fk_stmts
	   WHERE row_number = @recordNumber
     	-- show which table we are processing
		IF (@debug = 1) 
		BEGIN
		   PRINT ' '
		   PRINT '***' + @tableName + '***'
      END

		-- drop existing foreign key
		IF (@debug = 1) PRINT @sqlStmt
		IF (@test = 0) EXEC (@sqlStmt)

		-- create new foreign key
		SET @sqlStmt = 
			'ALTER TABLE ' + @tableName + 
			'  ADD CONSTRAINT ' + @foreignKeyName + ' FOREIGN KEY ([' + @columnName + '])' +
			'  REFERENCES [PR_Authorization].' + @newReferenceTableName + '([' + @newReferenceTableName + 'Id])'
		IF (@debug = 1)
		BEGIN
			PRINT @sqlStmt
		END

		-- create the new foreign key if it does not already exist
		SET @sqlStmt = 
			'IF ([PR_Utility].ufn_ObjectExists(''' + @foreignKeyName + ''',''FOREIGN KEY'',''' + @tableName + ''',''dbo'') = 0) ' +
			@sqlStmt

		-- execute if not in test mode
		IF (@test = 0)
		BEGIN
			EXEC (@sqlStmt)
		END
  END -- WHILE (@recordNumber < @rowCount)

	IF (@debug = 1)
	BEGIN
		PRINT @routineName + 'exit'
	END

END