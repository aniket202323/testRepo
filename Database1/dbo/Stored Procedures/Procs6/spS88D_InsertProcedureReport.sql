CREATE Procedure dbo.spS88D_InsertProcedureReport
@EventTime datetime,
@UnitId int,
@BatchProductId int,
@BatchId nvarchar(50),
@UnitProcedureName nvarchar(50),
@OperationName nvarchar(50),
@State nvarchar(50),
@UserName nvarchar(100),
@ProcessOrderId int,
@InitialDimensionX float,
@InitialDimensionY float,
@InitialDimensionZ float,
@InitialDimensionA float,
@EventTransactionId int output,
@FinalDimensionX float = null,
@FinalDimensionY float = null,
@FinalDimensionZ float = null,
@FinalDimensionA float = null,
@EventSubtype nvarchar(50) = null,
@LotIdentifier nVarChar(100) = null,
@FriendlyOperationName nVarChar(100) = null,
@ProcedureStartTime datetime = null,
@ProcedureEndTime datetime = null
AS
  DECLARE @BatchProductCode nvarchar(50);
  -- Get name of unit, line and department
  DECLARE @AreaName nvarchar(100);
  DECLARE @CellName nvarchar(100);
  DECLARE @UnitName nvarchar(100);
  SELECT @UnitName = PU_Desc, @CellName = PL_Desc, @AreaName = Dept_Desc
  FROM dbo.Prod_Units_Base u
    JOIN dbo.Prod_Lines_Base l
      on l.PL_Id = u.PL_Id
    JOIN dbo.Departments_Base d
      on d.Dept_Id = l.Dept_Id
  WHERE PU_Id = @UnitId;
  -- Throw error if a unit name wasn't found for the provided ID
  IF @UnitName IS NULL
  BEGIN;
      THROW 50001, 'The provided UnitId does not exist', 1;
  END;
  -- Get the batch product code if a batch product ID is provided
  IF @BatchProductId IS NOT NULL
  BEGIN;
    SELECT @BatchProductCode = Prod_Code
    FROM dbo.Products_Base
    WHERE Prod_Id = @BatchProductId;
    -- Throw error if a product code wasn't found for the provided ID
    IF @BatchProductCode IS NULL
    BEGIN;
        THROW 50002, 'The provided BatchProductId does not exist', 1;
    END;
  END;
  -- Throw error if State parameter is null
  IF @State IS NULL
  BEGIN;
    THROW 50003, 'The State parameter must not be NULL', 1;
  END;
  SELECT @EventTime = dbo.fnServer_CmnConvertToDbTime(@EventTime,'UTC');
  SELECT @ProcedureStartTime = dbo.fnServer_CmnConvertToDbTime(@ProcedureStartTime,'UTC');
  SELECT @ProcedureEndTime = dbo.fnServer_CmnConvertToDbTime(@ProcedureEndTime,'UTC');
  DECLARE @OutputTbl TABLE (ID INT);
  INSERT INTO Event_Transactions (EventType, EventTimestamp, AreaName, CellName, UnitName, BatchProductCode, BatchName, UnitProcedureName, OperationName, OrphanedFlag, ProcessedFlag,
 	  	  	  	  	  	  	  	   StateValue, UserName, ProcessOrderId, InitialDimensionX, InitialDimensionY, InitialDimensionZ, InitialDimensionA,
 	  	  	  	  	  	  	  	   FinalDimensionX, FinalDimensionY, FinalDimensionZ, FinalDimensionA, EventSubtype, LotIdentifier, FriendlyOperationName, ProcedureStartTime, ProcedureEndTime)
    OUTPUT INSERTED.EventTransactionId INTO @OutputTbl(ID)
    VALUES ('ProcedureReport', @EventTime, @AreaName, @CellName, @UnitName, @BatchProductCode, @BatchId, @UnitProcedureName, @OperationName, 0, 0,
 	  	  	 @State, @UserName, @ProcessOrderId, @InitialDimensionX, @InitialDimensionY, @InitialDimensionZ, @InitialDimensionA,
 	  	  	 @FinalDimensionX, @FinalDimensionY, @FinalDimensionZ, @FinalDimensionA, @EventSubtype, @LotIdentifier, @FriendlyOperationName, @ProcedureStartTime, @ProcedureEndTime);
  SELECT @EventTransactionId = ID FROM @OutputTbl;
