CREATE Procedure dbo.spS88H_GetParameters
@HistorianName nvarchar(100),
@ModelNumber nvarchar(50)
AS
Create Table #Parameters (
  Collection nvarchar(100),
  Name nvarchar(100),
  Value nvarchar(100) NULL
)
Insert Into #Parameters (Collection, Name) Values ('ProcedureReport', 'BatchProductCode')
Insert Into #Parameters (Collection, Name) Values ('ProcedureReport', 'BatchId')
Insert Into #Parameters (Collection, Name) Values ('ProcedureReport', 'UnitProcedureName')
Insert Into #Parameters (Collection, Name) Values ('ProcedureReport', 'OperationName')
Insert Into #Parameters (Collection, Name) Values ('ProcedureReport', 'PhaseName')
Insert Into #Parameters (Collection, Name) Values ('ProcedureReport', 'PhaseInstance')
Insert Into #Parameters (Collection, Name) Values ('ProcedureReport', 'State')
Insert Into #Parameters (Collection, Name) Values ('ProcedureReport', 'MaterialCode')
Insert Into #Parameters (Collection, Name) Values ('MaterialMovement', 'BatchId')
Insert Into #Parameters (Collection, Name) Values ('MaterialMovement', 'UnitProcedureName')
Insert Into #Parameters (Collection, Name) Values ('MaterialMovement', 'OperationName')
Insert Into #Parameters (Collection, Name) Values ('MaterialMovement', 'PhaseName')
Insert Into #Parameters (Collection, Name) Values ('MaterialMovement', 'PhaseInstance')
Insert Into #Parameters (Collection, Name) Values ('MaterialMovement', 'MaterialAreaName')
Insert Into #Parameters (Collection, Name) Values ('MaterialMovement', 'MaterialCellName')
Insert Into #Parameters (Collection, Name) Values ('MaterialMovement', 'MaterialUnitName')
Insert Into #Parameters (Collection, Name) Values ('MaterialMovement', 'MaterialBatchId')
Insert Into #Parameters (Collection, Name) Values ('MaterialMovement', 'MaterialCode')
Insert Into #Parameters (Collection, Name) Values ('MaterialMovement', 'MaterialDimensionX')
Insert Into #Parameters (Collection, Name) Values ('MaterialMovement', 'MaterialDimensionY')
Insert Into #Parameters (Collection, Name) Values ('MaterialMovement', 'MaterialDimensionZ')
Insert Into #Parameters (Collection, Name) Values ('MaterialMovement', 'MaterialDimensionA')
Insert Into #Parameters (Collection, Name) Values ('RecipeSetup', 'BatchId')
Insert Into #Parameters (Collection, Name) Values ('RecipeSetup', 'UnitProcedureName')
Insert Into #Parameters (Collection, Name) Values ('RecipeSetup', 'OperationName')
Insert Into #Parameters (Collection, Name) Values ('RecipeSetup', 'PhaseName')
Insert Into #Parameters (Collection, Name) Values ('RecipeSetup', 'PhaseInstance')
Insert Into #Parameters (Collection, Name) Values ('ParameterReport', 'BatchId')
Insert Into #Parameters (Collection, Name) Values ('ParameterReport', 'UnitProcedureName')
Insert Into #Parameters (Collection, Name) Values ('ParameterReport', 'OperationName')
Insert Into #Parameters (Collection, Name) Values ('ParameterReport', 'PhaseName')
Insert Into #Parameters (Collection, Name) Values ('ParameterReport', 'PhaseInstance')
Insert Into #Parameters (Collection, Name, Value) Values ('State', '0','Complete')
Insert Into #Parameters (Collection, Name, Value) Values ('State', '1','Running')
Insert Into #Parameters (Collection, Name, Value) Values ('State', '2','Aborted')
Select * From #Parameters
Drop Table #Parameters
