CREATE Procedure dbo.spS88H_ProcedureReport
@EventTime datetime,
@Area nvarchar(100),
@Cell nvarchar(100),
@Unit nvarchar(100),
@BatchProductCode nvarchar(50),
@BatchId nvarchar(50),
@UnitProcedureName nvarchar(50),
@OperationName nvarchar(50),
@PhaseName nvarchar(50),
@PhaseInstance nvarchar(50),
@State nvarchar(50),
@MaterialCode nvarchar(50)
AS
If @PhaseName Is Null 
  Select @MaterialCode = NULL
If @State Is Null
  Select @State = 'Unknown'
Insert Into Event_Transactions (EventType, EventTimestamp, AreaName, CellName, UnitName, BatchProductCode, BatchName, UnitProcedureName, OperationName, PhaseName, PhaseInstance, StateValue, RawMaterialProductCode)
  Values ('ProcedureReport', @EventTime, @Area, @Cell, @Unit, @BatchProductCode, @BatchId, @UnitProcedureName, @OperationName, @PhaseName, @PhaseInstance, @State, @MaterialCode)
