CREATE VIEW dbo.EC_Mapping
AS
SELECT     xsdSchemaElements.[SchemaName], xsdSchemaElements.[ElementName], xsdSchemaElements.ElementId, UserTablesAndColumns.TableName, 
                      UserTablesAndColumns.ColumnName
FROM         xsdSchemaElements INNER JOIN
                      MappedxsdSchemaElements_R_PdbTableColumnDS ON xsdSchemaElements.ElementId = MappedxsdSchemaElements_R_PdbTableColumnDS.ElementId INNER JOIN
                      UserTablesAndColumns ON MappedxsdSchemaElements_R_PdbTableColumnDS.TableName = UserTablesAndColumns.TableName AND 
                      MappedxsdSchemaElements_R_PdbTableColumnDS.ColumnName = UserTablesAndColumns.ColumnName
