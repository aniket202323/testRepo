CREATE Procedure dbo.spS88H_RecipeSetup
@EventTime datetime,
@Area nvarchar(100),
@Cell nvarchar(100),
@Unit nvarchar(100),
@BatchId nvarchar(50),
@UnitProcedureName nvarchar(50),
@OperationName nvarchar(50),
@PhaseName nvarchar(50),
@PhaseInstance nvarchar(50),
@ParameterName nvarchar(50),
@ParameterAttributeName nvarchar(50),
@ParameterAttributeValue nvarchar(50),
@ParameterAttributeUOM nvarchar(50)
AS
Insert Into Event_Transactions (EventType, EventTimestamp, AreaName, CellName, UnitName, BatchName, UnitProcedureName, OperationName, PhaseName, PhaseInstance, ParameterName, ParameterAttributeName, ParameterAttributeValue, ParameterAttributeUOM)
  Values ('RecipeSetup', @EventTime, @Area, @Cell, @Unit, @BatchId, @UnitProcedureName, @OperationName, @PhaseName, @PhaseInstance, @ParameterName, @ParameterAttributeName, @ParameterAttributeValue, @ParameterAttributeUOM)   
