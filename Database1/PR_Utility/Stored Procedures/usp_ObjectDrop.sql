-- ©2014 GE Intelligent Platforms, Inc. All rights reserved.

-- PROCEDURE: usp_ObjectDrop

-- Drop the named object from the user's schema

--DROP PROCEDURE [PR_Utility].usp_ObjectDrop
--GO
CREATE PROCEDURE [PR_Utility].usp_ObjectDrop (
	@objectName     SYSNAME,
	@objectType     VARCHAR(30),
	@ownerTable     SYSNAME = '', -- table to which object belongs if objectType = INDEX, FOREIGN KEY or TRIGGER
	@objectSchemaName SYSNAME = NULL,   -- if the schema for the object is not the same as the current schema 
	@debug          BIT = 0,           -- set to 1 to see SQL statements
	@test           BIT = 0				-- if 1, don't actually drop anything
) AS
BEGIN
	DECLARE @upperObjectType SYSNAME  = UPPER(@objectType)
	DECLARE @fullObjectName  SYSNAME
	DECLARE @fullOwnerTable  SYSNAME
	DECLARE @object_exists   BIT = 0
	DECLARE @schemaName      SYSNAME
	DECLARE @routineName     VARCHAR(100) = 'ufn_ObjectDrop: '
	DECLARE @sqlStatement    VARCHAR(MAX)

	IF (@objectSchemaName IS NULL)
	BEGIN
		SET @schemaName = schema_name()
	END
	ELSE
	BEGIN
		SET @schemaName = @objectSchemaName
	END
	
	SET @fullObjectName = (SELECT  
									CASE @upperObjectType 
										WHEN 'INDEX' THEN @ownerTable + '.' + @objectName
										ELSE @objectName
									END) 

	SET @fullOwnerTable = '[' + @schemaName + '].' + @ownerTable

	-- check to see if object exists first 
	EXEC @object_exists = [PR_Utility].ufn_ObjectExists @objectName,@upperObjectType,@ownerTable,@schemaName
	IF (@debug = 1)
	BEGIN
		PRINT @routineName + @objectType + ' ' + @schemaName + '.' + @objectName + ' exists = ' + convert(char(1), ISNULL(@object_exists,0))
	END

	--  drop the object if it exists 
	IF (@object_exists = 1)
	BEGIN
		-- most likely DROP statment
		SET @sqlStatement =  'DROP ' + @upperObjectType + ' [' + @schemaName + '].' + @fullObjectName

		-- object-specific DROP statements
		IF (@upperObjectType = 'FOREIGN KEY' OR @upperObjectType = 'PRIMARY KEY' OR 
			@upperObjectType = 'CONSTRAINT' OR @upperObjectType = 'DEFAULT' OR @upperObjectType = 'CHECK')
		BEGIN
			SET @sqlStatement = 'ALTER TABLE ' +  @fullOwnerTable + ' DROP CONSTRAINT ' + @objectName 
		END
		IF (@upperObjectType = 'COLUMN')
		BEGIN
			SET @sqlStatement = 'ALTER TABLE ' +  @fullOwnerTable + ' DROP COLUMN ' + @objectName
		END
		IF (@upperObjectType = 'INDEX')
		BEGIN
			SET @sqlStatement = 'DROP INDEX ' + @objectName + ' ON ' + @fullOwnerTable
		END
	
		-- drop the object
		IF (@debug = 1)
		BEGIN 
			PRINT @routineName + @sqlStatement
		END
		IF (@test = 0)
		BEGIN
			EXEC (@sqlStatement)
		END
	END
END
GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Drop the named object from the user''s schema if it exists.', @level0type = N'SCHEMA', @level0name = N'PR_Utility', @level1type = N'PROCEDURE', @level1name = N'usp_ObjectDrop';

