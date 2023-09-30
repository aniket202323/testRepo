CREATE VIEW dbo.PdbTableColumnDSToxsdSchemaElements
AS
SELECT UserTablesAndColumns.TableName, UserTablesAndColumns.ColumnName, xsdSchemaElements.[SchemaName], 
               xsdSchemaElements.[ElementName], xsdSchemaElements.ElementType
FROM  UserTablesAndColumns LEFT OUTER JOIN
               MappedxsdSchemaElements_R_PdbTableColumnDS ON UserTablesAndColumns.TableName = MappedxsdSchemaElements_R_PdbTableColumnDS.TableName AND 
               UserTablesAndColumns.ColumnName = MappedxsdSchemaElements_R_PdbTableColumnDS.ColumnName LEFT OUTER JOIN
               xsdSchemaElements ON xsdSchemaElements.ElementId = MappedxsdSchemaElements_R_PdbTableColumnDS.ElementId
