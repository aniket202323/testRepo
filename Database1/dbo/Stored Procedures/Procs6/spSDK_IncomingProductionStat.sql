CREATE PROCEDURE dbo.spSDK_IncomingProductionStat
 	 @WriteDirect 	  	  	  	  	 BIT,
 	 @UpdateClientOnly 	  	  	  	 BIT,
    @StatsType 	  	  	  	  	  	 INT,
    @PSId 	  	  	  	  	  	  	 INT,
    @ActualStartTime 	  	  	  	 DATETIME,
 	 @ActualEndTime 	  	  	  	  	 DATETIME,
    @ActualGoodQuantity 	  	  	  	 FLOAT,
 	 @PredictedRemainingQuantity 	  	 FLOAT,
 	 @ActualBadQuantity 	  	  	  	 FLOAT,
 	 @PredictedTotalDuration 	  	  	 FLOAT,
 	 @PredictedRemainingDuration 	  	 FLOAT,
 	 @ActualRunningTime 	  	  	  	 FLOAT,
 	 @ActualDownTime 	  	  	  	  	 FLOAT,
 	 @ActualGoodItems 	  	  	  	 INT,
 	 @ActualBadItems 	  	  	  	  	 INT,
 	 @AlarmCount 	  	  	  	  	  	 INT,
 	 @LateItems 	  	  	  	  	  	 INT,
 	 @ActualRepetitions 	  	  	  	 INT,
 	 @TransType 	  	  	  	  	  	 INT,
 	 @TransNum 	  	  	  	  	  	 INT,
 	 @PPId 	  	  	  	  	  	  	 INT OUTPUT,
 	 @ParentPPId 	  	  	  	  	  	 INT OUTPUT
AS
-- Declare local variables
DECLARE @CheckId INT,
 	  	 @RC INT
-- Production Stats can only be updated
IF (@TransType <> 2) RETURN(1)
-- StatsType can either be 1 (Production Plan) or 2 (ProductionPlanSetup)
IF (@StatsType<>1 And @StatsType<>2) RETURN(2)
-- TransNum can be either 0 (Coalesce) or 2 (No Coalesce)
IF (@TransNum <> 2 AND @TransNum <> 0) RETURN(5)
-- Check if @PId exists
IF (@StatsType = 1) BEGIN
   -- Make sure production plan exists
   IF @PSID IS NULL RETURN(3)
   SET @CheckId = NULL
   SELECT @CheckId = pp.PP_Id FROM Production_Plan pp WHERE PP_Id = @PSId
--   IF @CheckId IS NULL RETURN(3)
END
ELSE BEGIN
   -- Make sure production plan setup exists
   IF @PSID IS NULL RETURN(4)
   SET @CheckId = NULL
   SELECT @CheckId = ps.PP_Setup_Id FROM Production_Setup ps WHERE PP_Setup_Id = @PSId
  IF @CheckId IS NULL RETURN(4)
END
SET @PPID = 0
SET @ParentPPId = 0
-- Execute Write Direct
IF @WriteDirect = 1 AND @UpdateClientOnly 	 = 0
BEGIN
 	 EXECUTE 	 @RC = spServer_DBMgrUpdProdStats 
 	  	  	  	  	 @TransType,
 	  	  	  	  	 @TransNum,
 	  	  	  	  	 @StatsType,
 	  	  	  	  	 @PSId,
 	  	  	  	  	 @ActualStartTime,
 	  	  	  	  	 @ActualEndTime,
 	  	  	  	  	 @ActualGoodItems, 
 	  	  	  	  	 @ActualBadItems, 
 	  	  	  	  	 @ActualRunningTime, 
 	  	  	  	  	 @ActualDownTime, 
 	  	  	  	  	 @ActualGoodQuantity, 
 	  	  	  	  	 @ActualBadQuantity, 
 	  	  	  	  	 @PredictedTotalDuration, 
 	  	  	  	  	 @PredictedRemainingDuration, 
 	  	  	  	  	 @PredictedRemainingQuantity,
 	  	  	  	  	 @AlarmCount,
 	  	  	  	  	 @LateItems,
 	  	  	  	  	 @ActualRepetitions,
 	  	  	  	  	 @PPId OUTPUT,
 	  	  	  	  	 @ParentPPId OUTPUT
 	 IF @RC < 0 RETURN(6)
END
RETURN(0)
