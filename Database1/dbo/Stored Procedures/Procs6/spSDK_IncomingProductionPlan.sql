CREATE PROCEDURE dbo.spSDK_IncomingProductionPlan
 	 -- Input Parameters
 	 @WriteDirect 	  	  	  	  	 BIT,
 	 @UpdateClientOnly 	  	  	  	 BIT,
 	 @PathCode 	  	  	  	  	  	 nvarchar(50),
 	 @ProcessOrder 	  	  	  	  	 nvarchar(50),
 	 @BlockNumber 	  	  	  	  	 nvarchar(50),
 	 @ImpliedSequence 	  	  	  	 INT,
 	 @PPStatusDesc 	  	  	  	  	 nvarchar(50),
 	 @ProductCode 	  	  	  	  	 nvarchar(50),
 	 @ForecastStartTime 	  	  	 DATETIME,
 	 @ForecastEndTime 	  	  	  	 DATETIME,
 	 @ForecastQuantity 	  	  	  	 REAL,
 	 @UserId 	  	  	  	  	  	  	 INT,
 	 @ProductionRate 	  	  	  	 FLOAT,
 	 @PPTypeName 	  	  	  	  	  	 nvarchar(25),
 	 @SourceProcessOrder 	  	  	 nvarchar(50),
 	 @AdjustedQuantity 	  	  	  	 FLOAT,
 	 @ParentProcessOrder 	  	  	 nvarchar(50),
 	 @ControlTypeDesc 	  	  	  	 nvarchar(25),
 	 @SourcePathCode 	  	  	  	 nvarchar(50),
 	 @ParentPathCode 	  	  	  	 nvarchar(50),
 	 @PositionPathCode 	  	  	  	 nvarchar(50),
 	 @PositionProcessOrder 	  	 nvarchar(50),
 	 @PatternCodeProcessOrder 	 nvarchar(50),
 	 @PatternCode 	  	  	  	  	 nvarchar(25),
 	 @TransNum 	  	  	  	  	  	 INT,
 	 @PPId 	  	  	  	  	  	  	  	 INT,
 	 @TransType 	  	  	  	  	  	 INT,
 	 @UserGeneral1 	  	  	  	  	 nvarchar(255),
 	 @UserGeneral2 	  	  	  	  	 nvarchar(255),
 	 @UserGeneral3 	  	  	  	  	 nvarchar(255),
 	 @ExtendedInfo 	  	  	  	  	 nvarchar(255)
AS
DECLARE 	 @OldStatusId 	  	 INT,
 	  	  	 @GroupId 	  	  	  	 INT,
 	  	  	 @AccessLevel 	  	 INT,
 	  	  	 @This_Start 	  	  	 INT,
 	  	  	 @Previous_Start 	 INT,
 	  	  	 @Next_Start 	  	  	 INT,
 	  	  	 @RC 	  	  	  	  	 INT,
 	  	  	 @PUId 	  	  	  	  	 INT,
 	  	  	 @PathId 	  	  	  	 INT,
 	  	  	 @ProdId 	  	  	  	 INT,
 	  	  	 @PPStatusId 	  	  	 INT,
 	  	  	 @PPTypeId 	  	  	 INT,
 	  	  	 @SourcePPId 	  	  	 INT,
 	  	  	 @CommentId 	  	  	 INT,
 	  	  	 @ParentPPId 	  	  	 INT,
 	  	  	 @ControlTypeId 	  	 TINYINT,
 	  	  	 @Misc1 	  	  	  	 INT,
 	  	  	 @Misc2 	  	  	  	 INT,
 	  	  	 @Misc3 	  	  	  	 INT,
 	  	  	 @Misc4 	  	  	  	 INT,
 	  	  	 @PositionPPId 	  	 INT,
 	  	  	 @PPSetupId 	  	  	 INT,
 	  	  	 @ErrMsg 	  	  	  	 nvarchar(255)
SELECT @RC = 0, @ErrMsg = ''
-- These Are Columns we don't currently support trought EAS but are updateable
-- via the spServer_DBMgrUpdProdPlan SP
DECLARE 	 @ActualStartTime 	 DATETIME,
 	  	  	 @ActualEndTime 	  	 DATETIME,
 	  	  	 @ActualQuantity 	 REAL,
 	  	  	 @EntryOn 	  	       DATETIME,
 	  	  	 @TransactionTime 	 DATETIME
Select @EntryOn = dbo.fnServer_CmnGetDate(getUTCdate()), @TransactionTime = dbo.fnServer_CmnGetDate(getUTCdate())
  -- Transaction Numbers
  -- 00 - Coalesce
  -- 01 - Comment Update
  -- 02 - No Coalesce
  -- 91 - Return To Parent Process Order
  -- 92 - Create Child Process Order Based On Start Time (@Misc1=Parent_PP_Setup_Id)
  -- 93 - Create Child Process Order Before Process Order (@Misc1=Parent_PP_Setup_Id)
  -- 94 - Create Child Process Order After Process Order (@Misc1=Parent_PP_Setup_Id)
  -- 95 - Re Work Process Order
  -- 96 - Bind/UnBind Process Order
  -- 97 - Process Order Status Transition
  -- 98 - Move Process Order Back
  -- 99 - Move Process Order Forward
IF @TransNum IS NULL
  SET 	 @TransNum = 0
--Lookup Path
SELECT 	 @PathId = NULL
SELECT 	 @PathId = Path_Id 
 	 FROM 	 PrdExec_Paths
 	 WHERE 	 Path_Code = @PathCode
IF @PathId IS NULL AND NOT (@PathCode = '' OR @PathCode IS NULL)
BEGIN
 	 SELECT 	 @RC = 1, @ErrMsg = 'Path Not Found'
 	 GOTO 	  	 CleanUp
END
--Lookup Unit
SELECT  	  @PUId = NULL
/*
Removed by AJ 01-Dec-2004 - It possible a path without PUs associated to it
SELECT  	  @PUId = PU_Id
  	  FROM  	  PrdExec_Paths pp
  	  JOIN  PrdExec_Path_Units pepu ON pepu.Path_Id = pp.Path_Id and pepu.Is_Schedule_Point = 1
  	  WHERE  	  pp.Path_Id = @PathId
IF @PUId IS NULL AND NOT (@PathCode = '' OR @PathCode IS NULL)
BEGIN
  	  SELECT  	  @RC = 2, @ErrMsg = 'Unit Not Found'
  	  GOTO  	    	  CleanUp
END
*/
SELECT 	 @ProdId = NULL
SELECT 	 @ProdId = Prod_Id
 	 FROM 	 Products 
 	 WHERE 	 Prod_Code = @ProductCode
If @ProdId IS NULL AND @TransNum <> 91 AND @TransType <> 3
BEGIN
 	 SELECT 	 @RC = 3, @ErrMsg = 'Product Not Found'
 	 GOTO 	  	 CleanUp
END
SELECT 	 @PPStatusId = NULL
SELECT 	 @PPStatusId = PP_Status_Id
 	 FROM 	 Production_Plan_Statuses
 	 WHERE 	 PP_Status_Desc = @PPStatusDesc
If @PPStatusId IS NULL AND @TransNum <> 91 AND @TransType <> 3
BEGIN
 	 SELECT 	 @RC = 4, @ErrMsg = 'Production Plan Status Not Found'
 	 GOTO 	  	 CleanUp
END
if @PPTypeName IS NOT NULL and LTrim(RTrim(@PPTypeName)) <> ''
  BEGIN
    SELECT 	 @PPTypeId = NULL
    SELECT 	 @PPTypeId = PP_Type_Id
     	 FROM 	 Production_Plan_Types 
     	 WHERE 	 PP_Type_Name = @PPTypeName
    If @PPTypeId IS NULL 
    BEGIN
     	 SELECT 	 @RC = 5, @ErrMsg = 'Production Plan Type Not Found'
 	  	 GOTO 	  	 CleanUp
    END
  END
else
  BEGIN
    SELECT 	 @PPTypeId = 1
  END
if @SourceProcessOrder IS NOT NULL and LTrim(RTrim(@SourceProcessOrder)) <> ''
  BEGIN
    SELECT 	 @SourcePPId = NULL
    SELECT 	 @SourcePPId = pp.PP_Id
     	 FROM 	 Production_Plan pp
      JOIN  PrdExec_Paths pep on pep.Path_Id = pp.Path_Id
     	 WHERE 	 pep.Path_Code = @SourcePathCode AND
     	  	  	   pp.Process_Order = @SourceProcessOrder
    If @SourcePPId IS NULL
      BEGIN
       	 SELECT 	 @RC = 6, @ErrMsg = 'Source Process Order Not Found'
 	  	  	 GOTO 	  	 CleanUp
      END
  END
else
  BEGIN
    SELECT 	 @SourcePPId = NULL
  END  
if @ParentProcessOrder IS NOT NULL and LTrim(RTrim(@ParentProcessOrder)) <> ''
  BEGIN
    SELECT 	 @ParentPPId = NULL
    SELECT 	 @ParentPPId = pp.PP_Id
     	 FROM 	 Production_Plan pp
      JOIN  PrdExec_Paths pep on pep.Path_Id = pp.Path_Id      
     	 WHERE 	 pep.Path_Code = @ParentPathCode AND
     	  	  	   pp.Process_Order = @ParentProcessOrder
    If @ParentPPId IS NULL
      BEGIN
       	 SELECT 	 @RC = 7, @ErrMsg = 'Parent Process Order Not Found'
 	  	  	 GOTO 	  	 CleanUp
      END
  END
else
  BEGIN
    SELECT 	 @ParentPPId = NULL
  END  
if @ControlTypeDesc IS NOT NULL and LTrim(RTrim(@ControlTypeDesc)) <> ''
  BEGIN
    SELECT 	 @ControlTypeId = NULL
    SELECT 	 @ControlTypeId = Control_Type_Id
     	 FROM 	 Control_Type 
     	 WHERE 	 Control_Type_Desc = @ControlTypeDesc
    If @ControlTypeId IS NULL
    BEGIN
     	 SELECT 	 @RC = 8, @ErrMsg = 'Control Type Not Found'
 	  	 GOTO 	  	 CleanUp
    END
  END
else
  BEGIN
    SELECT 	 @ControlTypeId = NULL
  END  
IF @GroupId IS NOT NULL
BEGIN
 	 --Check Security Group
 	 SELECT 	 @AccessLevel = NULL
 	 SELECT 	 @AccessLevel = MAX(Access_Level) 
 	  	 FROM 	 User_Security 
 	  	 WHERE 	 User_id = @UserId AND 
 	  	  	  	 Group_id = @GroupId
 	 IF (@AccessLevel IS NULL) OR (@AccessLevel < 3)
 	 BEGIN
   	  	 SELECT 	 @RC = 9, @ErrMsg = 'Access Denied To Production Plan'
 	  	 GOTO 	  	 CleanUp
 	 END
END
IF @PPId IS NULL
BEGIN
 	 IF @PathId IS NOT NULL
 	 BEGIN
 	 -- Check For Existence Of Process Order
 	  	 SELECT 	 @PPId = NULL
 	  	 SELECT 	 @PPId = PP_Id
 	  	  	 FROM 	 Production_Plan
 	  	  	 WHERE 	 Path_Id = @PathId
 	  	  	 AND 	 Process_Order = @ProcessOrder
 	 END ELSE
 	 BEGIN
 	 -- Check For Existence Of Process Order
 	  	 SELECT 	 @PPId = NULL
 	  	 SELECT 	 @PPId = PP_Id
 	  	  	 FROM 	 Production_Plan
 	  	  	 WHERE 	 Path_Id IS NULL
 	  	  	 AND 	 Process_Order = @ProcessOrder
 	 END
END
IF @TransType IN (2,3) AND @PPId IS NULL
BEGIN
 	 -- We didn't find the Process Order
 	 SELECT 	 @RC = 10, @ErrMsg = 'Process Order Not Found'
 	 GOTO 	  	 CleanUp
END
IF @PPId IS NOT NULL
BEGIN
  -- Get the Old Status of the Production Plan
  SELECT 	 @OldStatusId = NULL
  SELECT 	 @OldStatusId = PP_Status_Id
   	 FROM 	 Production_Plan
   	 WHERE PP_Id = @PPId
END
-- SELECT 	 @OldStatusId, @PPStatusId
-- SELECT * FROM Production_Plan WHERE Path_Id = @PathId AND PP_Status_Id = @PPStatusId
-- If this is a status change to Active, make sure there are no other active Process Orders
IF (@OldStatusId <> 3 OR @OldStatusId IS NULL) AND @PPStatusId = 3
BEGIN
 	 IF (SELECT COUNT(*) FROM Production_Plan WHERE Path_Id = @PathId AND PP_Status_Id = @PPStatusId) > 0
 	 BEGIN
 	  	 -- There was another Active Process Order
 	    	 SELECT 	 @RC = 11, @ErrMsg = 'Already an Active Order'
 	  	 GOTO 	  	 CleanUp
 	 END
END
if @PositionProcessOrder IS NOT NULL and LTrim(RTrim(@PositionProcessOrder)) <> '' and (@TransNum = 93 or @TransNum = 94) and @TransType = 1
  BEGIN
    SELECT 	 @PositionPPId = NULL
    SELECT 	 @PositionPPId = pp.PP_Id
     	 FROM 	 Production_Plan pp
      JOIN  PrdExec_Paths pep on pep.Path_Id = pp.Path_Id
     	 WHERE 	 pep.Path_Code = @PositionPathCode AND
     	  	  	   pp.Process_Order = @PositionProcessOrder
    If @PositionPPId IS NULL
      BEGIN
       	 SELECT 	 @RC = 12, @ErrMsg = 'Create Child Position Process Order Not Found'
      END
    Select @PPId = @PositionPPId
  END
else
  BEGIN
    SELECT 	 @PositionPPId = NULL
  END
if @PatternCode IS NOT NULL and LTrim(RTrim(@PatternCode)) <> '' and (@TransNum >= 92 and @TransNum <= 94) and @TransType = 1
  BEGIN
    SELECT 	 @PPSetupId = NULL
    SELECT 	 @PPSetupId = ps.PP_Setup_Id
     	 FROM 	 Production_Setup ps
     	 JOIN 	 Production_Plan pp on pp.PP_Id = ps.PP_Id
     	 WHERE 	 pp.Process_Order = @PatternCodeProcessOrder AND
     	  	  	   ps.Pattern_Code = @PatternCode
    If @PPSetupId IS NULL
      BEGIN
       	 SELECT 	 @RC = 13, @ErrMsg = 'Create Child Pattern Code Not Found'
 	  	  	 GOTO 	  	 CleanUp
      END
    Select @Misc1 = @PPSetupId
  END
else
  BEGIN
    SELECT @PPSetupId = NULL
  END
if (@TransNum >= 92 and @TransNum <= 94) and @TransType = 1
  BEGIN
    If @ParentPPId IS NULL
      BEGIN
       	 SELECT 	 @RC = 13, @ErrMsg = 'Parent Process Order Not Found'
 	  	  	 GOTO 	  	 CleanUp
      END
    If @ForecastQuantity IS NULL
      BEGIN
 	  	 SELECT  	 @ForecastQuantity = NULL
 	  	 SELECT 	 @ForecastQuantity = Forecast_Quantity
 	  	  	 FROM 	 Production_Plan
 	  	  	 WHERE 	 PP_Id = @ParentPPId
 	 
 	  	 If @ForecastQuantity IS NULL
 	  	   BEGIN
 	        	     SELECT 	 @RC = 13, @ErrMsg = 'Parent Forecast Quantity Not Found'
 	  	  	  	     GOTO 	  	 CleanUp
 	  	   END
      END
    If @TransNum = 92
      BEGIN
     	 SELECT  	 @ForecastStartTime = NULL
     	 SELECT  	 @ForecastEndTime = NULL
     	 SELECT 	 @ForecastStartTime = Forecast_Start_Date,
     	  	     @ForecastEndTime = Forecast_End_Date
     	  	 FROM 	 Production_Plan
     	  	 WHERE 	 PP_Id = @ParentPPId
        If @ForecastStartTime IS NULL
          BEGIN
           	 SELECT 	 @RC = 13, @ErrMsg = 'Parent Forecast Start Time Not Found'
     	  	  	 GOTO 	  	 CleanUp
          END
        If @ForecastEndTime IS NULL
          BEGIN
           	 SELECT 	 @RC = 13, @ErrMsg = 'Parent Forecast End Time Not Found'
     	  	  	 GOTO 	  	 CleanUp
          END    
      END
  END
IF @RC = 0
BEGIN
 	 IF @WriteDirect = 0 AND @UpdateClientOnly = 0
 	 BEGIN
 	  	 IF @UserGeneral1 IS NOT NULL OR @UserGeneral2 IS NOT NULL OR @UserGeneral3 IS NOT NULL OR @ExtendedInfo IS NOT NULL
 	  	 BEGIN
 	  	  	 SET 	 @WriteDirect = 1
 	  	 END ELSE
 	  	 BEGIN
 	  	  	 SELECT 	 15, 1, @TransType, @TransNum, @PathId, @PPId, @CommentId, @ProdId, @ImpliedSequence, @PPStatusId, @PPTypeId, 
 	  	  	  	  	  	 @SourcePPId, @UserId, @ParentPPId, @ControlTypeId, @ForecastStartTime, @ForecastEndTime, @EntryOn, @ForecastQuantity, 
 	  	  	  	  	  	 @ProductionRate, @AdjustedQuantity, @BlockNumber, @ProcessOrder, @TransactionTime
 	  	 END
 	 END
 	 ELSE IF @WriteDirect = 0 AND @UpdateClientOnly = 1
 	 BEGIN
 	  	 SELECT 	 15, 0, @TransType, @TransNum, @PathId, @PPId, @CommentId, @ProdId, @ImpliedSequence, @PPStatusId, @PPTypeId, 
 	  	  	  	  	 @SourcePPId, @UserId, @ParentPPId, @ControlTypeId, @ForecastStartTime, @ForecastEndTime, @EntryOn, @ForecastQuantity, 
 	  	  	  	  	 @ProductionRate, @AdjustedQuantity, @BlockNumber, @ProcessOrder, @TransactionTime
 	 END
 	 IF @WriteDirect = 1 AND @UpdateClientOnly 	 = 0
 	 BEGIN
 	  	 IF @TransType = 1 AND @PPId IS NOT NULL and @TransNum <= 2
 	  	 BEGIN
 	  	  	 SELECT @TransType = 2
 	  	 END
 	  	 IF @TransType = 3
 	  	 BEGIN
 	  	  	 DELETE 	 Production_Plan_Starts
 	  	  	  	 WHERE 	 PP_Id = @PPId
 	  	 END
 	 
 	  	 SELECT 	 @PPTypeId = 1
 	  	 EXEC @RC = spServer_DBMgrUpdProdPlan
 	  	  	  	  	  	  	 @PPId OUTPUT, 
 	  	  	  	  	  	  	 @TransType, 
 	  	  	  	  	  	  	 @TransNum, 
 	  	  	  	  	  	  	 @PathId, 
 	  	  	  	  	  	  	 @CommentId, 
 	  	  	  	  	  	  	 @ProdId, 
 	  	  	  	  	  	  	 @ImpliedSequence OUTPUT,
 	  	  	  	  	  	  	 @PPStatusId, 
 	  	  	  	  	  	  	 @PPTypeId, 
 	  	  	  	  	  	  	 @SourcePPId, 
 	  	  	  	  	  	  	 @UserId, 
 	  	  	  	  	  	  	 @ParentPPId, 
 	  	  	  	  	  	  	 @ControlTypeId, 
 	  	  	  	  	  	  	 @ForecastStartTime, 
 	  	  	  	  	  	  	 @ForecastEndTime, 
 	  	  	  	  	  	  	 @EntryOn OUTPUT, 
 	  	  	  	  	  	  	 @ForecastQuantity, 
 	  	  	  	  	  	  	 @ProductionRate, 
 	  	  	  	  	  	  	 @AdjustedQuantity, 
 	  	  	  	  	  	  	 @BlockNumber, 
 	  	  	  	  	  	  	 @ProcessOrder, 
 	  	  	  	  	  	  	 @TransactionTime, 
 	  	  	  	  	  	  	 @Misc1, 
 	  	  	  	  	  	  	 @Misc2, 
 	  	  	  	  	  	  	 @Misc3, 
 	  	  	  	  	  	  	 @Misc4
 	  	 IF @RC < 0
 	  	 BEGIN
 	  	  	 SELECT 	 @ErrMsg = 'WriteDirect Error: ' + CONVERT(VARCHAR, @RC) + '.'
 	  	  	 GOTO 	  	 CleanUp
 	  	 END ELSE
 	  	 BEGIN
 	  	  	 SELECT 	 @RC = 0
 	  	 END
 	  	 -- Added the @TransType filter.  If you are deleting
 	  	 IF @TransType <> 3 AND (@UserGeneral1 IS NOT NULL OR @UserGeneral2 IS NOT NULL OR @UserGeneral3 IS NOT NULL OR @ExtendedInfo IS NOT NULL)
 	  	 BEGIN
 	  	  	 EXEC 	 @RC = spSDK_IncomingProductionPlanExt
 	  	  	  	  	  	  	  	 @PPId,
 	  	  	  	  	  	  	  	 @UserGeneral1,
 	  	  	  	  	  	  	  	 @UserGeneral2,
 	  	  	  	  	  	  	  	 @UserGeneral3,
 	  	  	  	  	  	  	  	 @ExtendedInfo
 	  	  	 IF @RC <> 0
 	  	  	 BEGIN
 	  	  	  	 SET 	 @RC = @RC + 10
 	  	  	  	 SELECT 	 @ErrMsg = 'WriteDirect Error: ' + CONVERT(VARCHAR, @RC) + '.'
 	  	  	  	 GOTO 	  	 CleanUp
 	  	  	 END ELSE
 	  	  	 BEGIN
 	  	  	  	 SELECT 	 @RC = 0
 	  	  	 END
 	  	 END 
/* 	  	 REMOVED BY ARW... Old Code... replaced by spServer_DBMgrUpdProdPlan
 	  	 IF @TransType IN (1,2) -- Add, Update
 	  	 BEGIN
 	    	  	 -- If Current Status Is Active
 	    	  	 IF @OldStatusId = 3 AND @PPStatusId <> 3 --Active
 	    	  	 BEGIN
 	    	  	  	 IF @ActualEndTime IS NULL
 	    	  	  	 BEGIN
 	    	  	  	  	 SELECT 	 @ActualEndTime = dbo.fnServer_CmnGetDate(getUTCdate())
 	    	  	  	 END
 	    	  	 
 	    	  	  	 -- From Active to Complete
 	    	  	  	 IF @PPStatusId = 4 --Complete
 	    	  	  	 BEGIN
 	    	  	  	  	 -- Close Production Plan Starts
 	    	  	  	  	 UPDATE 	 Production_Plan_Starts
 	    	  	  	  	  	 SET 	 End_Time = @ActualEndTime,
 	  	  	  	  	  	  	  	 User_Id = @UserId
 	    	  	  	  	  	 WHERE 	 PP_Id = @PPId 
 	  	  	  	  	  	 AND  	 End_Time IS NULL
 	    	  	  	  	 
 	    	  	  	  	 -- Update All Patterns To Complete
 	    	  	  	  	 UPDATE 	 Production_Setup
 	    	  	  	  	  	 SET 	 PP_Status_Id = @PPStatusId,
 	  	  	  	  	  	  	  	 User_Id = @UserId
 	    	  	  	  	  	 WHERE 	 PP_Id = @PPId
 	    	  	  	 END ELSE
 	    	  	  	 -- From Active to Pending
 	    	  	  	 IF @PPStatusId IN (1,2) --Next, Pending
 	    	  	  	 BEGIN
 	    	  	  	  	 -- Close Production Plan Starts
 	    	  	  	  	 UPDATE 	 Production_Plan_Starts
 	    	  	  	  	  	 SET 	 End_Time = @ActualEndTime,
 	  	  	  	  	  	  	  	 User_Id = @UserId
 	    	  	  	  	  	 WHERE 	 PP_Id = @PPId AND 
 	    	  	  	  	  	  	  	 End_Time IS NULL
 	    	  	  	 END
 	    	  	 END
   	  	 
 	  	  	 -- From Next to Active
 	  	  	 -- From Complete to Active
 	  	  	 -- If Going To Active, Compare New Product To Old Product
 	    	  	 IF (@OldStatusId <> 3 OR @OldStatusId IS NULL) AND @PPStatusId = 3 --Active
 	    	  	 BEGIN
 	    	  	  	 IF @ActualStartTime IS NULL
 	    	  	  	 BEGIN
 	    	  	  	  	 SELECT 	 @ActualStartTime = dbo.fnServer_CmnGetDate(getUTCdate()),
 	    	  	  	  	  	  	  	 @ActualEndTime = NULL
 	    	   	  	 END
 	  	  	    	 --  	 
 	  	  	    	 --  	 --Close Currently Open Production Plan Start
 	  	  	    	 --  	 UPDATE 	 Production_Plan_Starts
 	  	  	    	 --  	  	 SET 	 End_Time = @ActualStartTime
 	  	  	    	 -- 	  	  	 WHERE 	 PU_Id = @PUId AND 
 	  	  	    	 --  	  	  	  	 End_Time IS NULL
 	  	  	    	 -- 
 	  	  	    	 --  	 --Open Production Plan Starts
 	  	  	    	 --  	 INSERT INTO 	 Production_Plan_Starts (PU_Id, PP_Id, Start_Time)
 	  	  	    	 --  	  	 VALUES 	 (@PUId, @PPId, @ActualStartTime)
   	  	 
 	    	  	  	 -- TODO - Go Ahead And Blow In Production Plan Starts Based On Actual Times
 	    	  	  	 -- See Of There Is Already Record With Exact Times, For This Unit
 	    	  	  	 SELECT 	 @This_Start = NULL
 	    	  	  	 SELECT 	 @This_Start = PP_Start_Id
 	    	  	  	  	 FROM 	 Production_Plan_Starts 
 	    	  	  	  	 WHERE 	 PU_Id = @PUId 	 AND
 	    	  	  	  	  	  	 Start_Time = @ActualStartTime AND 
 	    	  	  	  	  	  	 ((End_Time = @ActualEndTime) OR ((End_Time IS NULL) AND (@ActualEndTime IS NULL))) 
   	  	  	  	 
 	    	  	  	 -- Find Previous Record Based On Start Time
 	    	  	  	 SELECT 	 @Previous_Start = NULL
 	    	  	  	 SELECT 	 @Previous_Start = PP_Start_Id
 	    	  	  	  	 FROM 	 Production_Plan_Starts 
 	    	  	  	  	 WHERE 	 PU_Id = @PUId and
 	    	  	  	  	  	  	 Start_Time < @ActualStartTime and 
 	    	  	  	  	  	  	 ((End_Time > @ActualStartTime) or (End_Time Is NULL))
   	  	 
 	    	  	  	 --Update Previous End With Start Time
 	    	  	  	 IF @Previous_Start IS NOT NULL
 	    	  	  	 BEGIN
 	    	  	  	  	 UPDATE 	 Production_Plan_Starts
 	    	  	  	  	  	 SET 	 End_Time = @ActualStartTime,
 	  	  	  	  	  	  	  	 User_Id = @UserId
 	    	  	  	  	  	 WHERE 	 PP_Start_Id = @Previous_Start 
 	    	  	  	 END
   	  	 
 	    	  	  	 -- Find Next Record Based On End Time
 	    	  	  	 IF @ActualEndTime IS NOT NULL
 	    	  	  	 BEGIN
 	    	  	  	  	 SELECT 	 @Next_Start = NULL
 	    	  	  	  	 SELECT 	 TOP 1 @Next_Start = PP_Start_Id
 	    	  	  	       FROM 	 Production_Plan_Starts 
 	    	  	  	       WHERE 	 PU_Id = @PUId AND
 	    	  	  	             Start_Time < @ActualEndTime and 
 	    	  	  	             ((End_Time > @ActualEndTime) or (End_Time Is Null))
 	    	  	  	  	  	 ORDER BY Start_Time
 	    	  	  	 
 	    	  	  	  	 IF @Next_Start IS NOT NULL
 	    	  	  	  	 BEGIN
 	    	  	  	  	  	 UPDATE 	 Production_Plan_Starts
 	    	  	  	  	  	  	 SET 	 Start_Time = @ActualEndTime,
 	  	  	  	  	  	  	  	  	 User_Id = @UserId
 	    	  	  	  	  	  	 WHERE 	 PP_Start_Id = @Next_Start 
 	    	  	  	  	 END
 	    	  	  	 END
   	  	  	  	 
 	    	  	  	 -- Smoke All Records Entirely Between Start And End Time
 	    	  	  	 DELETE 	 Production_Plan_Starts
 	    	  	  	  	 WHERE 	 PU_Id = @PUId and
 	    	  	  	  	  	  	 Start_Time > @ActualStartTime AND
 	    	  	  	  	  	  	 ((End_Time <= @ActualEndTime) OR (@ActualEndTime IS NULL))
   	  	 
 	    	  	  	 IF @This_Start IS NOT NULL
 	    	  	  	 BEGIN
 	    	  	  	  	 UPDATE 	 Production_Plan_Starts 
 	    	  	  	  	  	 SET 	 PP_Id = @PPId,
 	  	  	  	  	  	  	  	 User_Id = @UserId
 	    	  	  	  	  	 WHERE 	 PP_Start_Id = @This_Start
 	    	  	  	 END ELSE
 	    	  	  	 BEGIN
 	    	  	  	  	 INSERT INTO 	 Production_Plan_Starts (PP_Id, PU_Id, Start_Time, End_Time, User_Id)
 	    	  	  	  	  	 VALUES 	 (@PPId, @PUId, @ActualStartTime, @ActualEndTime, @UserId)
 	    	  	  	 END
 	  	  	 END
 	  	 END
 	  	 */
 	 END
END
CleanUp:
-- RETURN BACK SUCCESS CODE AND ERROR MESSAGES
SELECT 	 ResultSet 	  	  	 = -999, 
   	  	  	 ReturnCode 	  	  	 = @RC, 
   	  	  	 ErrorMsg 	  	  	  	 = @ErrMsg,
 	  	  	 ProductionPlanId 	 = @PPId
RETURN (0)
