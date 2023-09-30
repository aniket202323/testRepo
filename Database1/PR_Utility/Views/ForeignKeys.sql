-- ©2014 GE Intelligent Platforms, Inc. All rights reserved.

-- VIEW: [PR_PersonnelMigration].ObjectCatalog

-- This view lists all of the foreign key details

CREATE VIEW [PR_Utility].[ForeignKeys] AS
(
   SELECT 
    obj.name  AS ForeignKeyName,
    sch.name  AS SchemaName,
    tab1.name AS TableName,
    col1.name AS ColumnName,
    tab2.name AS ReferenceTableName,
    col2.name AS ReferenceColumnName
   FROM sys.foreign_key_columns fkc
   INNER JOIN sys.objects obj   ON (obj.object_id  = fkc.constraint_object_id)
   INNER JOIN sys.tables tab1   ON (tab1.object_id = fkc.parent_object_id)
   INNER JOIN sys.schemas sch   ON (tab1.schema_id = sch.schema_id)
   INNER JOIN sys.columns col1  ON (col1.column_id = parent_column_id AND col1.object_id = tab1.object_id)
   INNER JOIN sys.tables tab2   ON (tab2.object_id = fkc.referenced_object_id)
   INNER JOIN sys.columns col2  ON (col2.column_id = referenced_column_id AND col2.object_id = tab2.object_id)
)
GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'List all foreign key details', @level0type = N'SCHEMA', @level0name = N'PR_Utility', @level1type = N'VIEW', @level1name = N'ForeignKeys';

