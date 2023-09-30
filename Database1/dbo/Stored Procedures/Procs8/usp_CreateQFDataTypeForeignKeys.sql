CREATE PROCEDURE [dbo].[usp_CreateQFDataTypeForeignKeys] (
@debug INT = 0,                        -- if 1, print out all statements before executing
@test  INT = 0                         -- if 1, do not make any changes
) AS
BEGIN

	DECLARE @foreignKeyCount INT
	DECLARE @recordNumber INT = 0

	DECLARE @foreignKeyName SYSNAME
	DECLARE @parentTable  SYSNAME
	DECLARE @parentColumn SYSNAME
	DECLARE @foreignTable SYSNAME
	DECLARE @foreignColumn SYSNAME
	DECLARE @sqlStmt VARCHAR(2000)

	-- if table does not exist, there's nothing to do
	IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'dbo.QFDataTypePhrases'))
	BEGIN
		RETURN 0
	END

	IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'dbo.tmpQFDataTypesForeignKeys'))
	BEGIN
		RETURN 0
	END

	SELECT @foreignKeyCount = COUNT(*) FROM [dbo].[tmpQFDataTypesForeignKeys]

	WHILE (@recordNumber < @foreignKeyCount) 
	BEGIN
		SET @recordNumber = @recordNumber + 1
		SELECT
			@foreignKeyName  = foreign_key_name,
			@parentTable     = parent_table,
			@parentColumn    = parent_column,
			@foreignTable    = foreign_table,
			@foreignColumn   = foreign_column
		FROM [dbo].[tmpQFDataTypesForeignKeys]
		WHERE row_number = @recordNumber
		-- show which table we are processing
		IF (@debug = 1) 
		BEGIN
			PRINT ' '
			PRINT '*** ' + @parentTable + ' ***'
		END

		-- create new foreign key
		SET @sqlStmt = 
			'ALTER TABLE ' + @parentTable + 
			' ADD CONSTRAINT ' + @foreignKeyName + ' FOREIGN KEY ([' + @parentColumn + '])' +
			' REFERENCES [dbo].' + @foreignTable + '([' + @foreignColumn + '])'

		IF (@debug = 1)
		BEGIN
			PRINT @sqlStmt
		END

		-- create the new foreign key if it does not already exist
		SET @sqlStmt = 
			'IF ([PR_Utility].ufn_ObjectExists(''' + @foreignKeyName + ''',''FOREIGN KEY'',''' + @parentTable + ''',''dbo'') = 0) ' +
			@sqlStmt

		-- execute if not in test mode
		IF (@test = 0)
		BEGIN
			IF (@debug = 1) PRINT ('Creating FK ' + @foreignKeyName)
			EXEC (@sqlStmt)
		END
	END -- WHILE (@recordNumber < @rowCount)

	IF (@debug = 1) PRINT CONVERT(VARCHAR(5),@recordNumber) + ' foreign keys created.'

	-- drop this table, we are done with it
	IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'dbo.tmpQFDataTypesForeignKeys'))
	BEGIN
		DROP TABLE dbo.tmpQFDataTypesForeignKeys
	END

END