CREATE PROCEDURE dbo.spSDK_IncomingProductionSetup
 	 -- Input Parameters
 	 @WriteDirect 	  	  	  	 BIT,
 	 @UpdateClientOnly 	  	  	 BIT,
 	 @PathCode 	  	  	  	  	 nvarchar(50),
 	 @ProcessOrder 	  	  	  	 nvarchar(50),
 	 @PatternCode 	  	  	  	 nvarchar(25),
 	 @ImpliedSequence 	  	  	 INT,
 	 @PPStatusDesc 	  	  	  	 nvarchar(50),
 	 @PatternRepititions 	 INT,
 	 @ForecastQuantity 	  	  	 REAL,
 	 @BaseDimensionX 	  	 REAL,
 	 @BaseDimensionY 	  	 REAL,
 	 @BaseDimensionZ 	  	 REAL,
 	 @BaseDimensionA 	  	 REAL,
 	 @BaseGeneral1 	  	 REAL,
 	 @BaseGeneral2 	  	 REAL,
 	 @BaseGeneral3 	  	 REAL,
 	 @BaseGeneral4 	  	 REAL,
 	 @Shrinkage 	  	 REAL,
 	 @ParentPatternCode  nvarchar(25),
 	 @UserId 	  	  	  	  	  	 INT,
  @TransNum         INT,
 	 @PPSetupId 	  	  	  	 INT,
 	 @TransType 	  	  	   INT
AS
DECLARE 	 @OldStatusId 	 INT,
 	  	  	 @GroupId 	  	  	  	 INT,
 	  	  	 @AccessLevel 	  	 INT,
 	  	  	 @RC 	  	  	  	  	     INT,
 	  	  	 @ErrMsg 	  	  	  	  	 nvarchar(255)
SELECT @RC = 0, @ErrMsg = ''
-- These Are Columns we don't currently support trought EAS but are updateable
-- via the spServer_DBMgrUpdProdSetup SP
DECLARE 	 @EntryOn 	  	     DATETIME,
 	  	  	 @TransactionTime 	 DATETIME,
     	 @PathId 	  	  	  	  	  	 INT,
     	 @PPId 	  	  	  	  	  	   INT,
     	 @PPStatusId 	  	  	  	 INT,
      @CommentId        INT,
      @ParentPPSetupId  INT
Select @EntryOn = dbo.fnServer_CmnGetDate(getUTCdate()), @TransactionTime = dbo.fnServer_CmnGetDate(getUTCdate())
  -- Transaction Numbers
  -- 00 - Coalesce
  -- 01 - Comment Update
  -- 02 - No Coalesce
  -- 91 - Return To Parent Sequence
  -- 92 - Create Child Sequence
  -- 97 - Status Transition
  -- 98 - Move Sequence Back
  -- 99 - Move Sequence Forward
If @TransNum is NULL
  Select @TransNum = 0
--Lookup Path
SELECT 	 @PathId = NULL
SELECT 	 @PathId = Path_Id 
 	 FROM 	 PrdExec_Paths
 	 WHERE 	 Path_Code = @PathCode
IF @PathId IS NULL 
BEGIN
  SELECT 	 @RC = 1, @ErrMsg = 'Path Not Found'
END
--Lookup Process Order
SELECT 	 @PPId = NULL
SELECT 	 @PPId = PP_Id
 	 FROM 	 Production_Plan
 	 WHERE 	 Path_Id = @PathId AND
 	  	  	   Process_Order = @ProcessOrder
IF @PPId IS NULL 
BEGIN
  SELECT 	 @RC = 2, @ErrMsg = 'Process Order Not Found'
END
-- Get the PP_Status_Id from the Status Table
SELECT 	 @PPStatusId = NULL
SELECT 	 @PPStatusId = PP_Status_Id
 	 FROM 	 Production_Plan_Statuses
 	 WHERE 	 PP_Status_Desc = @PPStatusDesc
IF @PPStatusId IS NULL and @TransNum <> 91 and @TransType <> 3
BEGIN
 	 -- The Production Status Passed was not found
  SELECT 	 @RC = 3, @ErrMsg = 'Sequence Status Not Found'
END
if @ParentPatternCode IS NOT NULL and LTrim(RTrim(@ParentPatternCode)) <> ''
  BEGIN
    --Lookup Parent Sequence
    SELECT 	 @ParentPPSetupId = NULL
    SELECT 	 @ParentPPSetupId = PP_Setup_Id
     	 FROM 	 Production_Setup
     	 WHERE 	 PP_Id = @PPId AND
     	  	  	   Pattern_Code = @ParentPatternCode
    IF @ParentPPSetupId IS NULL and @TransNum <= 2 and @TransType <> 3
      BEGIN
        If @PPId is NULL
          SELECT 	 @ParentPPSetupId = PP_Setup_Id
           	 FROM 	 Production_Setup
           	 WHERE 	 Pattern_Code = @ParentPatternCode
        Else
          SELECT 	 @ParentPPSetupId = Parent_PP_Setup_Id
           	 FROM 	 Production_Setup
           	 WHERE 	 PP_Setup_Id = @PPSetupId
        If @ParentPPSetupId IS NULL
          BEGIN
            SELECT 	 @RC = 4, @ErrMsg = 'Parent Sequence Not Found'
          END
      END
  END
else
  BEGIN
    --Lookup Parent Sequence
    SELECT 	 @ParentPPSetupId = NULL
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
    SELECT 	 @RC = 5, @ErrMsg = 'Access Denied To Unit'
 	 END
END
IF @PPSetupId IS NULL
BEGIN
 	 -- Check For Existence Of Process Order
  SELECT 	 @PPSetupId = NULL
  SELECT 	 @PPSetupId = PP_Setup_Id
   	 FROM 	 Production_Setup
   	 WHERE 	 Pattern_Code = @PatternCode AND
   	  	  	   PP_Id = @PPId
END
IF @TransType IN (2,3) AND @PPSetupId IS NULL
BEGIN
 	 -- We didn't find the Sequence
  SELECT 	 @RC = 6, @ErrMsg = 'Sequence Not Found'
END
-- Get the Old Status of the Sequence
SELECT 	 @OldStatusId = NULL
SELECT 	 @OldStatusId = PP_Status_Id
 	 FROM 	 Production_Setup
 	 WHERE PP_Setup_Id = @PPSetupId
-- If this is a status change to Active, make sure there are no other active Process Orders
IF (@OldStatusId <> 3 OR @OldStatusId IS NULL) AND @PPStatusId = 3
BEGIN
 	 IF (SELECT COUNT(*) FROM Production_Setup WHERE PP_Id = @PPId AND PP_Status_Id = @PPStatusId) > 0
 	 BEGIN
 	  	 -- There was another Active Sequence
    SELECT 	 @RC = 7, @ErrMsg = 'Already an Active Sequence'
 	 END
END
IF @RC = 0
BEGIN
 	 IF @WriteDirect = 0 AND @UpdateClientOnly = 0
 	 BEGIN
    SELECT 16, 1, @TransType, @TransNum, @PathId, @PPSetupId, @PPId, @ImpliedSequence, @PPStatusId, @PatternRepititions, 
          @CommentId, @ForecastQuantity, @BaseDimensionX, @BaseDimensionY, @BaseDimensionZ, @BaseDimensionA, @BaseGeneral1, 
          @BaseGeneral2, @BaseGeneral3, @BaseGeneral4, @Shrinkage, @PatternCode, @UserId, @EntryOn, @TransactionTime, @ParentPPSetupId
 	 END
 	 ELSE IF @WriteDirect = 0 AND @UpdateClientOnly = 1
 	 BEGIN
    SELECT 16, 0, @TransType, @TransNum, @PathId, @PPSetupId, @PPId, @ImpliedSequence, @PPStatusId, @PatternRepititions, 
          @CommentId, @ForecastQuantity, @BaseDimensionX, @BaseDimensionY, @BaseDimensionZ, @BaseDimensionA, @BaseGeneral1, 
          @BaseGeneral2, @BaseGeneral3, @BaseGeneral4, @Shrinkage, @PatternCode, @UserId, @EntryOn, @TransactionTime, @ParentPPSetupId
 	 END
  ELSE IF @WriteDirect = 1 AND @UpdateClientOnly 	 = 0
  BEGIN
 	  	 IF @TransType = 1 AND @PPSetupId IS NOT NULL and @TransNum <= 2
 	  	 BEGIN
 	  	  	 SELECT @TransType = 2
 	  	 END
   	 IF @TransType = 3
   	 BEGIN
   	  	 DELETE 	 Production_Plan_Starts
   	  	  	 WHERE 	 PP_Id = @PPId
    END
 	 
 	  	 EXEC @RC = spServer_DBMgrUpdProdSetup
              @PPSetupId OUTPUT,
              @TransType,
              @TransNum,
              @UserId,
              @PPId,
              @ImpliedSequence OUTPUT,
              @PPStatusId,
              @PatternRepititions,
              @CommentId,
              @ForecastQuantity, 
              @BaseDimensionX, 
              @BaseDimensionY, 
              @BaseDimensionZ, 
              @BaseDimensionA, 
              @BaseGeneral1, 
              @BaseGeneral2, 
              @BaseGeneral3, 
              @BaseGeneral4, 
              @Shrinkage,
              @PatternCode,
              @PathId, 
              @EntryOn OUTPUT,
              @TransactionTime,
              @ParentPPSetupId
 	  	 IF @RC < 0
 	  	 BEGIN
 	  	  	 SELECT 	 @ErrMsg = 'WriteDirect Error: ' + CONVERT(VARCHAR, @RC) + '.'
 	  	 END ELSE
 	  	 BEGIN
 	  	  	 SELECT 	 @RC = 0
 	  	 END  
 	 END
END
-- RETURN BACK SUCCESS CODE AND ERROR MESSAGES
SELECT 	 ResultSet 	 = -999, 
   	  	  	 ReturnCode 	 = @RC, 
   	  	  	 ErrorMsg 	  	 = @ErrMsg
RETURN (0)
