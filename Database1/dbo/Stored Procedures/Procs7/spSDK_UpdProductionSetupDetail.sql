CREATE PROCEDURE dbo.spSDK_UpdProductionSetupDetail
 	 -- Input Parameters
 	 @TransType        INT,
 	 @PathCode 	  	  	  	  	 nVarChar(50),
 	 @ProcessOrder 	  	  	 nVarChar(50),
 	 @PatternCode 	  	  	 nVarChar(25),
  @ElementStatus    nVarChar(50),
  @ElementNumber    INT,
  @TargetDimensionX REAL,
  @TargetDimensionY REAL,
  @TargetDimensionZ REAL,
  @TargetDimensionA REAL,
  @UserGeneral1     nVarChar(255),
  @UserGeneral2     nVarChar(255),
  @UserGeneral3     nVarChar(255),
  @ExtendedInfo     nVarChar(255),
  @UserId           INT,
  @PlantOrderNumber nVarChar(50),
 	 -- Input/Output Parameters
 	 @PPSetupDetailId 	 INT = NULL OUTPUT
AS
-- Return Codes
-- 	  	  1: @PPSetupDetailId Not Specified on Update/Delete
-- 	  	  2: Path Not Found
-- 	  	  3: Process Order Not Found
-- 	  	  4: Sequence Not Found
-- 	  	  5: Element Status Not Found
DECLARE 	 @RC 	  	  	  	  	  	         INT,
     	   @PathId 	  	  	  	  	  	     INT,
     	   @PPId 	  	  	  	  	  	       INT,
     	   @PPSetupId 	  	  	  	  	  	 INT,
        @ProdStatusId         INT,
        @MaxElementNumber     INT,
        @CommentId            INT,
        @OldStatusId 	         INT,
        @OldElementNumber     INT,
        @OrderLineId          INT,
        @OldOrderLineId       INT
-- Check to Make Sure @OrderId was passed on Update Or Delete
IF 	 (@PPSetupDetailId IS NULL OR @PPSetupDetailId = 0) AND @TransType IN (2,3)
BEGIN
 	 RETURN(1)
END
--Lookup Path
SELECT 	 @PathId = NULL
SELECT 	 @PathId = Path_Id 
 	 FROM 	 PrdExec_Paths
 	 WHERE 	 Path_Code = @PathCode
IF @PathId IS NULL 
BEGIN
 	 RETURN(2)
END
--Lookup Process Order
SELECT 	 @PPId = NULL
SELECT 	 @PPId = PP_Id
 	 FROM 	 Production_Plan
 	 WHERE 	 Path_Id = @PathId AND
 	  	  	   Process_Order = @ProcessOrder
IF @PPId IS NULL 
BEGIN
 	 RETURN(3)
END
-- Check For Existence Of Process Order
SELECT 	 @PPSetupId = NULL
SELECT 	 @PPSetupId = PP_Setup_Id
 	 FROM 	 Production_Setup
 	 WHERE 	 Pattern_Code = @PatternCode AND
 	  	  	   PP_Id = @PPId
IF @PPSetupId IS NULL 
BEGIN
 	 RETURN(4)
END
-- Get the Element_Status from the Status Table
SELECT 	 @ProdStatusId = NULL
SELECT 	 @ProdStatusId = ProdStatus_Id
 	 FROM 	 Production_Status
 	 WHERE 	 ProdStatus_Desc = @ElementStatus
IF @ProdStatusId IS NULL
BEGIN
 	 -- The Production Status Passed was not found
 	 RETURN(5)
END
if @PlantOrderNumber IS NOT NULL and LTrim(RTrim(@PlantOrderNumber)) <> ''
  BEGIN
    --Lookup Order Line Id
    SELECT 	 @OrderLineId = NULL
    SELECT 	 @OrderLineId = col.Order_Line_Id
     	 FROM 	 Customer_Order_Line_Items col 
      JOIN  Customer_Orders co on co.Order_Id = col.Order_Id
     	 WHERE 	 co.Plant_Order_Number = @PlantOrderNumber
    IF @OrderLineId IS NULL 
    BEGIN
     	 RETURN(6)
    END
  END
IF @TransType = 1
BEGIN
 	 EXECUTE 	 @RC = spSV_PutPattern
              @TransType, 
              @PPSetupId, 
              @PPSetupDetailId, 
              @TargetDimensionX, 
              @TargetDimensionY, 
              @TargetDimensionZ, 
              @TargetDimensionA, 
              @CommentId, 
              @UserGeneral1, 
              @UserGeneral2, 
              @UserGeneral3, 
              @ExtendedInfo, 
              @UserId
 	 IF @RC <> 1
 	 BEGIN
 	  	 RETURN(10)
 	 END
  SELECT @MaxElementNumber = max(Element_Number) From Production_Setup_Detail Where PP_Setup_Id = @PPSetupId
  SELECT @PPSetupDetailId = PP_Setup_Detail_Id From Production_Setup_Detail Where PP_Setup_Id = @PPSetupId and Element_Number = @MaxElementNumber
END ELSE
IF @TransType = 2
BEGIN
  -- Get the Old Status, Order Line Id, and Comment Id of the Pattern
  SELECT 	 @OldStatusId = NULL, @OldOrderLineId = NULL, @CommentId = NULL
  SELECT 	 @OldStatusId = Element_Status, @OldOrderLineId = Coalesce(Order_Line_Id, 0), @CommentId = Comment_Id
   	 FROM 	 Production_Setup_Detail
   	 WHERE PP_Setup_Detail_Id = @PPSetupDetailId
 	 EXECUTE 	 @RC = spSV_PutPattern
              @TransType, 
              @PPSetupId, 
              @PPSetupDetailId, 
              @TargetDimensionX, 
              @TargetDimensionY, 
              @TargetDimensionZ, 
              @TargetDimensionA, 
              @CommentId, 
              @UserGeneral1, 
              @UserGeneral2, 
              @UserGeneral3, 
              @ExtendedInfo, 
              @UserId
 	 IF @RC <> 1
 	 BEGIN
 	  	 RETURN(20)
 	 END
END ELSE
IF @TransType = 3
BEGIN
 	 EXECUTE 	 @RC = spSV_PutPattern
              @TransType, 
              @PPSetupId, 
              @PPSetupDetailId, 
              @TargetDimensionX, 
              @TargetDimensionY, 
              @TargetDimensionZ, 
              @TargetDimensionA, 
              @CommentId, 
              @UserGeneral1, 
              @UserGeneral2, 
              @UserGeneral3, 
              @ExtendedInfo, 
              @UserId
 	 IF @RC <> 1
 	 BEGIN
 	  	 RETURN(30)
 	 END
END
IF @TransType IN (1,2) -- Add, Update
  BEGIN
    IF @ProdStatusId <> @OldStatusId
      EXECUTE spSV_UpdPatternStatus @PPSetupDetailId, @ProdStatusId
    IF @TransType = 2
      BEGIN
        IF @ElementNumber > 0
          BEGIN
            Select @OldElementNumber = Element_Number From Production_Setup_Detail Where PP_Setup_Detail_Id = @PPSetupDetailId
            IF @OldElementNumber < @ElementNumber
              EXECUTE spSV_MovePattern @PPSetupDetailId, 1 --Move Up
            ELSE IF  @OldElementNumber > @ElementNumber
              EXECUTE spSV_MovePattern @PPSetupDetailId, 2 --Move Down
          END    
      END
    IF @OrderLineId <> @OldOrderLineId
      EXECUTE spSV_PutCustOrdLineItems @PPSetupDetailId, @OrderLineId
  END
RETURN(0)
