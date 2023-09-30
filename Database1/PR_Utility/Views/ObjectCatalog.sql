-- ©2014 GE Intelligent Platforms, Inc. All rights reserved.

-- VIEW: [PR_PersonnelMigration].ObjectCatalog

-- This view lists all objects in all schemas owned by the caller

CREATE VIEW [PR_Utility].[ObjectCatalog] AS
(
	SELECT substring(o.name,1,60) AS ObjectName,
		CASE UPPER(o.type) 
			WHEN 'FN' THEN 'FUNCTION'
			WHEN 'TF' THEN 'FUNCION TABLE-VALUED' 
			WHEN 'P'  THEN 'PROCEDURE' 
			WHEN 'U'  THEN 'TABLE'
			WHEN 'V'  THEN 'VIEW'
		END                    AS ObjectType,
		''                   AS TableName,
		substring(s.name,1,30) AS SchemaName,
		o.object_id
	FROM sys.objects o INNER JOIN sys.schemas s ON (o.schema_id = s.schema_id)
	WHERE UPPER(o.type) IN ('FN','TF','P','U','V')
	AND o.schema_id IN  (SELECT s.schema_id
								FROM INFORMATION_SCHEMA.SCHEMATA i, sys.schemas s
								WHERE i.SCHEMA_OWNER = user
								AND i.SCHEMA_NAME = s.name)
UNION
   SELECT SUBSTRING(c.name,1,60) AS ObjectName,
	   CASE UPPER(c.type) 
	      WHEN 'F'   THEN 'FOREIGN KEY'
	      WHEN 'C'   THEN 'CHECK CONSTRAINT'
	      WHEN 'PK'  THEN 'PRIMARY KEY'
	      WHEN 'UQ'  THEN 'UNIQUE CONSTRAINT'
      END                    AS ObjectType,
      SUBSTRING(o.name,1,60) AS TableName,
      substring(s.name,1,30) AS SchemaName,
      c.object_id
   FROM sys.objects c 
	INNER JOIN sys.objects o ON (c.parent_object_id = o.object_id)
   INNER JOIN sys.schemas s ON (o.schema_id = s.schema_id)
   WHERE UPPER(c.type) IN ('F','C','PK','UQ')
   AND o.type = 'U'
   AND o.schema_id IN  (SELECT s.schema_id
								FROM INFORMATION_SCHEMA.SCHEMATA i, sys.schemas s
								WHERE i.SCHEMA_OWNER = user
								AND i.SCHEMA_NAME = s.name)
UNION
   SELECT 
		SUBSTRING(i.name,1,60)    AS ObjectName,
			'INDEX'                AS ObjectType,
			SUBSTRING(o.name,1,60) AS TableName,
			substring(s.name,1,30) AS SchemaName,
			i.index_id             AS object_id
   FROM sys.indexes i 
		INNER JOIN sys.objects o ON (i.object_id = o.object_id)
      INNER JOIN sys.schemas s ON (o.schema_id = s.schema_id)
   WHERE i.name IS NOT NULL 
 	AND o.type = 'U'
   AND o.schema_id IN  (SELECT s.schema_id
								FROM INFORMATION_SCHEMA.SCHEMATA i, sys.schemas s
								WHERE i.SCHEMA_OWNER = user
								AND i.SCHEMA_NAME = s.name)
UNION
   SELECT 
		substring(t.name,1,60) AS ObjectName,
      'TRIGGER'              AS ObjectType,
      substring(o.name,1,60) AS TableName,
      substring(s.name,1,30) AS SchemaName,
      t.object_id
   FROM sys.triggers t 
	INNER JOIN sys.objects o ON (t.object_id = o.object_id)
   INNER JOIN sys.schemas s ON (o.schema_id = s.schema_id)
   WHERE t.type = 'TR'
   AND t.parent_id = o.object_id
	AND o.type = 'U'
   AND o.schema_id IN  (SELECT s.schema_id
								FROM INFORMATION_SCHEMA.SCHEMATA i, sys.schemas s
								WHERE i.SCHEMA_OWNER = user
								AND i.SCHEMA_NAME = s.name)
UNION
   SELECT
		substring(substring(s.name,1,60),1,60) AS ObjectName,
		'SCHEMA'               AS ObjectType,
		''                     AS TableName,
		substring(s.name,1,30) AS SchemaName,
		s.schema_id            AS object_id
   FROM sys.schemas s
   WHERE s.schema_id IN (SELECT s.schema_id
									FROM INFORMATION_SCHEMA.SCHEMATA i, sys.schemas s
									WHERE i.SCHEMA_OWNER = user
									AND i.SCHEMA_NAME = s.name)
UNION
   SELECT 
		substring(y.name,1,60)             AS ObjectName,
	   'SYNONYM'                          AS ObjectType,
	   SUBSTRING(y.base_object_name,1,60) AS TableName,
      substring(s.name,1,30)             AS SchemaName,
      y.object_id                        AS object_id
   FROM sys.synonyms y INNER JOIN sys.schemas s ON (y.schema_id = s.schema_id)
   WHERE s.schema_id IN (SELECT s.schema_id
								FROM INFORMATION_SCHEMA.SCHEMATA i, sys.schemas s
								WHERE i.SCHEMA_OWNER = user
								AND i.SCHEMA_NAME = s.name)
)
GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'List all objects in all schemas owned by the caller', @level0type = N'SCHEMA', @level0name = N'PR_Utility', @level1type = N'VIEW', @level1name = N'ObjectCatalog';

