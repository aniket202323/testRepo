CREATE PROCEDURE dbo.spPDB_B2mmlGetTableColumnMap
(
 	 @schema nvarchar(50)
)
 AS
SELECT     dbo.MappedxsdSchemaElements_R_PdbTableColumnDS.TableName, dbo.MappedxsdSchemaElements_R_PdbTableColumnDS.ColumnName, 
                      dbo.MappedxsdSchemaElements_R_PdbTableColumnDS.ElementId
FROM         dbo.Mapped_xsdSchemaElements INNER JOIN
                      dbo.MappedxsdSchemaElements_R_PdbTableColumnDS ON 
                      dbo.Mapped_xsdSchemaElements.ElementId = dbo.MappedxsdSchemaElements_R_PdbTableColumnDS.ElementId INNER JOIN
                      dbo.xsdSchemaElements ON dbo.Mapped_xsdSchemaElements.ElementId = dbo.xsdSchemaElements.ElementId
Where dbo.xsdSchemaElements.SchemaName = @schema
