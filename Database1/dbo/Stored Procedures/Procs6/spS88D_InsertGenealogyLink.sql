CREATE Procedure dbo.spS88D_InsertGenealogyLink
@EventTime datetime,
@ParentUnitId int,
@ParentBatchId nvarchar(50),
@ChildUnitId int,
@ChildBatchId nvarchar(50),
@UserName nvarchar(100),
@DimensionX float,
@DimensionY float,
@DimensionZ float,
@DimensionA float,
@EventTransactionId int output
AS
  -- Get parent name of unit, line and department
  DECLARE @ParentAreaName nvarchar(100);
  DECLARE @ParentCellName nvarchar(100);
  DECLARE @ParentUnitName nvarchar(100);
  SELECT @ParentUnitName = PU_Desc, @ParentCellName = PL_Desc, @ParentAreaName = Dept_Desc
    FROM dbo.Prod_Units_Base u
    JOIN dbo.Prod_Lines_Base l on l.PL_Id = u.PL_Id
    JOIN dbo.Departments_Base d on d.Dept_Id = l.Dept_Id
  WHERE PU_Id = @ParentUnitId;
  -- Throw error if a unit name wasn't found for the provided ID
  IF @ParentUnitName IS NULL
  BEGIN;
      THROW 50001, 'The provided ParentUnitId does not exist', 1;
  END;
  -- Get parent name of unit, line and department
  DECLARE @ChildAreaName nvarchar(100);
  DECLARE @ChildCellName nvarchar(100);
  DECLARE @ChildUnitName nvarchar(100);
  SELECT @ChildUnitName = PU_Desc, @ChildCellName = PL_Desc, @ChildAreaName = Dept_Desc
    FROM dbo.Prod_Units_Base u
    JOIN dbo.Prod_Lines_Base l on l.PL_Id = u.PL_Id
    JOIN dbo.Departments_Base d on d.Dept_Id = l.Dept_Id
  WHERE PU_Id = @ChildUnitId;
  -- Throw error if a unit name wasn't found for the provided ID
  IF @ChildUnitName IS NULL
  BEGIN;
      THROW 50002, 'The provided ChildUnitId does not exist', 1;
  END;
  SELECT @EventTime = dbo.fnServer_CmnConvertToDbTime(@EventTime,'UTC');
  DECLARE @OutputTbl TABLE (ID INT);
  INSERT INTO Event_Transactions (OrphanedFlag, ProcessedFlag, EventType, EventTimestamp, AreaName, CellName, UnitName, BatchName,
 	  	  	  	  	  	  	  	   RawMaterialAreaName, RawMaterialCellName, RawMaterialUnitName, RawMaterialBatchName, UserName,
 	  	  	  	  	  	  	  	   RawMaterialDimensionX, RawMaterialDimensionY, RawMaterialDimensionZ, RawMaterialDimensionA)
    OUTPUT INSERTED.EventTransactionId INTO @OutputTbl(ID)
    VALUES (0, 0, 'GenealogyLink', @EventTime, @ChildAreaName, @ChildCellName, @ChildUnitName, @ChildBatchId,
 	  	  	 @ParentAreaName, @ParentCellName, @ParentUnitName, @ParentBatchId, @UserName, @DimensionX, @DimensionY, @DimensionZ, @DimensionA);
  SELECT @EventTransactionId = ID FROM @OutputTbl;
