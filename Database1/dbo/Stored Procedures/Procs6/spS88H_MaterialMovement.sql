CREATE Procedure dbo.spS88H_MaterialMovement
@EventTime datetime,
@Area nvarchar(100),
@Cell nvarchar(100),
@Unit nvarchar(100),
@BatchId nvarchar(50),
@UnitProcedureName nvarchar(50),
@OperationName nvarchar(50),
@PhaseName nvarchar(50),
@PhaseInstance nvarchar(50),
@MaterialAreaName nvarchar(50),
@MaterialCellName nvarchar(50),
@MaterialUnitName nvarchar(50),
@MaterialBatchId nvarchar(50),
@MaterialCode nvarchar(50),
@MaterialDimensionX nvarchar(50),
@MaterialDimensionY nvarchar(50),
@MaterialDimensionZ nvarchar(50),
@MaterialDimensionA nvarchar(50)
AS
--TODO: Need Area, Unit, etc clarification In Transaction Table
If @MaterialAreaName Is Null
  Select @MaterialAreaName = @Area
If @MaterialCellName Is Null
  Select @MaterialCellName = @Cell
Insert Into Event_Transactions (EventType, EventTimestamp, AreaName, CellName, UnitName, BatchName, UnitProcedureName, OperationName, PhaseName, PhaseInstance, RawMaterialAreaName, RawMaterialCellName, RawMaterialUnitName, RawMaterialBatchName, RawMaterialProductCode, RawMaterialDimensionX, RawMaterialDimensionY, RawMaterialDimensionZ, RawMaterialDimensionA)
  Values ('MaterialMovement', @EventTime, @Area, @Cell, @Unit, @BatchId, @UnitProcedureName, @OperationName, @PhaseName, @PhaseInstance, @MaterialAreaName, @MaterialCellName, @MaterialUnitName, @MaterialBatchId, @MaterialCode, @MaterialDimensionX, @MaterialDimensionY, @MaterialDimensionZ, @MaterialDimensionA)   
--Insert Into Event_Transactions (EventType, EventTimestamp, AreaName, CellName, UnitName, BatchName, UnitProcedureName, OperationName, PhaseName, PhaseInstance, RawMaterialBatchName, RawMaterialProductCode, RawMaterialDimensionX, RawMaterialDimensionY, RawMaterialDimensionZ, RawMaterialDimensionA)
--  Values ('MaterialMovement', @EventTime, @Area, @Cell, @Unit, @BatchId, @UnitProcedureName, @OperationName, @PhaseName, @PhaseInstance, @MaterialBatchId, @MaterialCode, @MaterialDimensionX, @MaterialDimensionY, @MaterialDimensionZ, @MaterialDimensionA)   
