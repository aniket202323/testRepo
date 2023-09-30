CREATE VIEW dbo.ElementMapping
AS
SELECT     TOP 100 PERCENT dbo.xsdSchemaElements.ElementId, dbo.xsdSchemaElements.ParentElementId, dbo.xsdSchemaElements.ElementName, 
                      '' AS TableColumn, dbo.MappedxsdSchemaElements_R_ConstantsDS.Constant, dbo.MappedxsdSchemaElements_R_PdbProcParmDS.ProcName, 
                      dbo.MappedxsdSchemaElements_R_PdbProcParmDS.ParamName, dbo.MappedxsdSchemaElements_R_PdbProcsDS.ProcName AS xPathProc, 
                      dbo.MappedxsdSchemaElements_R_PdbProcsDS.sequence_num, dbo.Mapped_xsdSchemaElements.MappingTypeId, 
                      dbo.xsdSchemaElements.ElementType, dbo.xsdSchemaElements.SchemaName
FROM         dbo.Mapped_xsdSchemaElements LEFT OUTER JOIN
                      dbo.MappedxsdSchemaElements_R_PdbProcsDS ON 
                      dbo.Mapped_xsdSchemaElements.ElementId = dbo.MappedxsdSchemaElements_R_PdbProcsDS.ElementId LEFT OUTER JOIN
                      dbo.MappedxsdSchemaElements_R_PdbProcParmDS ON 
                      dbo.Mapped_xsdSchemaElements.ElementId = dbo.MappedxsdSchemaElements_R_PdbProcParmDS.ElementId LEFT OUTER JOIN
                      dbo.MappedxsdSchemaElements_R_ConstantsDS ON 
                      dbo.Mapped_xsdSchemaElements.ElementId = dbo.MappedxsdSchemaElements_R_ConstantsDS.ElementId RIGHT OUTER JOIN
                      dbo.xsdSchemaElements ON dbo.Mapped_xsdSchemaElements.ElementId = dbo.xsdSchemaElements.ElementId
