-- ©2014 GE Intelligent Platforms, Inc. All rights reserved.

-- FUNCTION: ufn_ObjectExists

-- Check that the specified object exists.
-- Object types supported are
-- BASE (TABLE), VIEW, GBL_TMP (GLOBAL TEMPORARY TABLE),
-- INDEX, PROCEDURE, FUNCTION, TRIGGER, SYNONYM

--DROP FUNCTION [PR_Utility].ufn_ObjectExists 
--GO
CREATE FUNCTION [PR_Utility].ufn_ObjectExists ( 
	@objectName  SYSNAME,
	@objectType  VARCHAR(30),
	@ownerTable  SYSNAME = NULL, -- table name for the object if it is an INDEX, FOREIGN KEY, TRIGGER or COLUMN
	@schemaName  SYSNAME = NULL  -- search for objects in this schema, use current schema by default
) RETURNS INT 
AS 
BEGIN 
	DECLARE @objectExists  INT 
	DECLARE @mssqlObjectType VARCHAR(5) 
	DECLARE @schemaId      INT
	-- set schemaId 
	IF @schemaName IS NULL
		SET @schemaId = (SELECT schema_id
								FROM sys.schemas
								WHERE name = schema_name())
	ELSE
		SET @schemaId =(SELECT schema_id
								FROM sys.schemas
								WHERE name = @schemaName)

	SET @objectExists = 0 
	SET @mssqlObjectType = (SELECT  
	CASE UPPER(@objectType) 
		WHEN 'CHECK'       THEN 'C' -- check constraint
		WHEN 'CONSTRAINT'  THEN 'D' -- default constraint
		WHEN 'DEFAULT'     THEN 'D'
		WHEN 'FOREIGN KEY' THEN 'F'
		WHEN 'FUNCTION'    THEN 'FN' -- scalar function
		WHEN 'INDEX'       THEN 'K' 
		WHEN 'PRIMARY KEY' THEN 'PK' 
		WHEN 'PROCEDURE'   THEN 'P' 
		WHEN 'TABLE'       THEN 'U' 
		WHEN 'TRIGGER'     THEN 'TR' 
		WHEN 'VIEW'        THEN 'V' 
		WHEN 'SCHEMA'      THEN 'S'
		WHEN 'SYNONYM'     THEN 'SN'
	END) 
	SET @objectExists = (SELECT
	CASE UPPER(@objectType)
		WHEN 'INDEX' THEN (
			SELECT 1 
			FROM sys.indexes i, sys.objects o
			WHERE i.name    = LOWER(@objectName)
			AND i.object_id = o.object_id
			AND o.name      = LOWER(@ownerTable)
			AND o.schema_id = @schemaId
		)
		WHEN 'COLUMN' THEN (
			SELECT 1
			FROM sys.columns scol
			WHERE scol.name = LOWER(@objectName)
			AND scol.object_id  = (SELECT object_id
											FROM sys.objects
											WHERE name  = LOWER(@ownerTable)
	 										AND type  IN ('U','V')
											AND schema_id = @schemaId)
		)
		WHEN 'TRIGGER' THEN (
			SELECT 1 
			FROM sys.objects 
			WHERE type    = @mssqlObjectType 
			AND name      = LOWER(@objectName )
			AND parent_object_id = OBJECT_ID(@ownerTable)
			AND schema_id = @schemaId
		)
		ELSE (
			SELECT 1 
			FROM sys.objects 
			WHERE type    = @mssqlObjectType 
			AND name      = LOWER(@objectName )
			AND schema_id = @schemaId)
	END)

	RETURN ISNULL(@objectExists,0) 
END
GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Return 1 if object exists, 0 otherwise', @level0type = N'SCHEMA', @level0name = N'PR_Utility', @level1type = N'FUNCTION', @level1name = N'ufn_ObjectExists';

