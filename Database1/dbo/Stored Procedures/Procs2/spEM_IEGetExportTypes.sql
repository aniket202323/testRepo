CREATE PROCEDURE dbo.spEM_IEGetExportTypes
  AS
Create Table #ExportTypes (
   ExportType nvarchar(50),
   ExportDesc nVarChar(200),
   QueryType int
)
Insert into #ExportTypes (ExportType, ExportDesc, QueryType)
  values ('EngineeringUnit', 'Engineering units', 1)
Insert into #ExportTypes (ExportType, ExportDesc, QueryType)
  values ('EngineeringUnitConversion', 'Engineering unit conversions', 1)
Insert into #ExportTypes (ExportType, ExportDesc, QueryType)
  values ('BillOfMaterial', 'Bill Of Materials', 2)
Insert into #ExportTypes (ExportType, ExportDesc, QueryType)
  values ('BillOfMaterialFormulation', 'Bill Of Material Formulations', 2)
Insert into #ExportTypes (ExportType, ExportDesc, QueryType)
  values ('BOMFormulationItem', 'Bill Of Material Formulations Items', 2)
Insert into #ExportTypes (ExportType, ExportDesc, QueryType)
  values ('BillOfMaterialSubstitution', 'Bill Of Material Substitutions', 2)
Insert into #ExportTypes (ExportType, ExportDesc, QueryType)
  values ('BillOfMaterialProduct', 'Bill Of Material Products', 2)
Insert into #ExportTypes (ExportType, ExportDesc, QueryType)
  values ('CrossReference', 'Foreign System X-Ref', 2)
Insert into #ExportTypes (ExportType, ExportDesc, QueryType)
  values ('Subscription', 'Subscriptions', 2)
Select ExportType, ExportDesc, QueryType from #ExportTypes
Drop Table #ExportTypes
