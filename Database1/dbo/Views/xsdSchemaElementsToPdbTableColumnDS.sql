CREATE VIEW dbo.xsdSchemaElementsToPdbTableColumnDS
AS
SELECT UserTablesAndColumns.TableName, UserTablesAndColumns.ColumnName, xsdSchemaElements.[SchemaName], 
               xsdSchemaElements.[ElementName], xsdSchemaElements.ElementType
FROM  UserTablesAndColumns RIGHT OUTER JOIN
               MappedxsdSchemaElements_R_PdbTableColumnDS ON UserTablesAndColumns.TableName = MappedxsdSchemaElements_R_PdbTableColumnDS.TableName AND 
               UserTablesAndColumns.ColumnName = MappedxsdSchemaElements_R_PdbTableColumnDS.ColumnName RIGHT OUTER JOIN
               xsdSchemaElements ON xsdSchemaElements.ElementId = MappedxsdSchemaElements_R_PdbTableColumnDS.ElementId
