CREATE PROCEDURE [PR_Utility].[usp_SystemPreDeploy]
@Debug	BIT = 0,  -- when 1 print debug statements
@Test	BIT = 0   -- when 1 do not make any changes
AS
	-- if table does not exist, there's nothing to do
	IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'dbo.QFDataTypePhrases'))
	BEGIN
		RETURN 0
	END

	IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'dbo.tmpQFDataTypesForeignKeys'))
	BEGIN
		DROP TABLE dbo.tmpQFDataTypesForeignKeys
	END
	-- temporary table to hold the existing foreign key details
	CREATE TABLE dbo.tmpQFDataTypesForeignKeys (
		row_number  INT NOT NULL IDENTITY(1,1),
		foreign_key_name SYSNAME,
		parent_table   SYSNAME NOT NULL,
		parent_column  SYSNAME NOT NULL,
		foreign_table  SYSNAME NOT NULL,
		foreign_column SYSNAME NOT NULL
	) 
	-- capture all existing foreign keys involving the QFDataType or QFDataTypePhrases table
	INSERT INTO dbo.tmpQFDataTypesForeignKeys (
		foreign_key_name,
		parent_table,
		parent_column,
		foreign_table,
		foreign_column)
	SELECT 
		f.name
		, parentTable = o.name
		, parentColumn = c.name
		, foreignTable = ofr.name
		, foreignColumn = cfr.name
	FROM sys.foreign_keys f
	  INNER JOIN sys.foreign_key_columns fc ON f.object_id = fc.constraint_object_id
	  INNER JOIN sys.objects o ON fc.parent_object_id = o.object_id
	  INNER JOIN sys.columns c ON fc.parent_column_id = c.column_id
		AND o.object_id = c.object_id
	  INNER JOIN sys.objects ofr ON fc.referenced_object_id = ofr.object_id
	  INNER JOIN sys.columns cfr ON fc.referenced_column_id = cfr.column_id
		AND ofr.object_id = cfr.object_id
	  INNER JOIN sys.indexes i ON ofr.object_id = i.object_id
	WHERE i.name = 'NC_QFDataTypePhrases_DataTypeId' OR i.name = 'UQ_QFDataTypes_DataTypeName'
	AND o.object_id != OBJECT_ID(N'dbo.QFDataTypePhrases')

	DECLARE @IsNullable BIT

	SELECT @IsNullable = is_nullable 
	FROM sys.columns 
	WHERE object_id = object_id(N'dbo.QFDataTypePhrases') AND name = 'DataTypeId'
	
	-- if the column is already NOT NULL, there's nothing to do
	IF (@IsNullable = 1)
	BEGIN

		-- drop existing FK on the column if it exists
		IF EXISTS (SELECT 1 FROM sys.foreign_keys 
					WHERE object_id = OBJECT_ID(N'dbo.QFDataTypePhrases_QFDataTypes_Relation1')
					AND parent_object_id = OBJECT_ID(N'dbo.QFDataTypePhrases'))
		BEGIN
			ALTER TABLE [dbo].[QFDataTypePhrases] DROP CONSTRAINT [QFDataTypePhrases_QFDataTypes_Relation1]
		END

		-- drop index on this column if it exists
		IF EXISTS (SELECT * FROM sys.indexes 
					WHERE object_id = object_id(N'dbo.QFDataTypePhrases') 
					AND NAME = 'NC_QFDataTypePhrases_DataTypeId')
		BEGIN
			DROP INDEX [NC_QFDataTYpePhrases_DataTypeId] ON [dbo].[QFDataTypePhrases]
		END

		-- alter the column to NOT NULL
		ALTER TABLE [dbo].[QFDataTypePhrases] ALTER COLUMN DataTypeId UNIQUEIDENTIFIER NOT NULL

		-- Note: the System dacpac will re-create the index and the foreign key 
	END
RETURN 0