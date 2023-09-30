CREATE PROCEDURE dbo.spSDK_IncomingProductionPlanStart
-- Input Parameters
@WriteDirect 	  	  	  	  	 BIT,
@UpdateClientOnly 	  	  	  	 BIT,
@DeptName 	  	  	  	  	  	 nvarchar(50),
@LineName 	  	  	  	  	  	 nvarchar(50),
@UnitName 	  	  	  	  	  	 nvarchar(50),
@StartTime 	  	  	  	  	 DATETIME,
@EndTime 	  	  	  	  	  	 DATETIME,
@PathCode 	  	  	  	  	  	 nvarchar(50),
@ProcessOrder 	  	  	  	  	 nvarchar(50),
@UserId 	  	  	  	  	  	 int,
@PatternCode 	  	  	  	  	 nvarchar(25),
@TransNum 	  	  	  	  	  	 int,
@PPStartId 	  	  	  	  	 int,
@TransType 	  	  	  	  	 INT
AS
DECLARE 	 @GroupId 	  	  	  	 int,
 	  	 @AccessLevel 	  	  	 int,
 	  	 @RC 	  	  	  	  	 int,
 	  	 @PPId 	  	  	  	 int,
 	  	 @PLId 	  	  	  	 int,
 	  	 @PUId 	  	  	  	 int,
 	  	 @PathId 	  	  	  	 int,
 	  	 @CommentId 	  	  	 int,
 	  	 @ParentPPId 	  	  	 int,
 	  	 @ScheduleControlled 	  	 int,
 	  	 @PPSetupId 	  	  	 int,
 	  	 @ErrMsg 	  	  	  	 nvarchar(255)
SELECT 	 @RC 	  	 = 0,
 	  	 @ErrMsg 	 = ''
-- These Are Columns we don't currently support trought EAS but are updateable
-- via the spServer_DBMgrUpdProdPlan SP
DECLARE 	 @EntryOn 	  	  	 datetime,
 	  	 @TransactionTime 	 datetime
Select @EntryOn = dbo.fnServer_CmnGetDate(getUTCdate()), @TransactionTime = dbo.fnServer_CmnGetDate(getUTCdate())
IF @TransNum IS NULL
  SET 	 @TransNum = 0
--Lookup path code
SELECT 	 @PathId 	 = NULL
SELECT 	 @PathId 	 = Path_Id
FROM PrdExec_Paths
WHERE Path_Code = @PathCode
--Lookup process order
SELECT 	 @PPId 	 = NULL
SELECT 	 @PPId 	 = PP_Id
FROM 	 Production_Plan
WHERE 	 Path_Id = @PathId
 	  	 AND Process_Order = @ProcessOrder
If @PPId IS NULL RETURN(4)
--Lookup Unit
SELECT 	 @PLId = NULL
SELECT 	 @PLId = PL_Id 
FROM 	 Prod_Lines 
WHERE 	 PL_Desc = @LineName
IF @PLId IS NULL RETURN(2)
SELECT 	 @PUId = NULL
SELECT 	 @PUId = PU_Id 
FROM 	 Prod_Units 
WHERE 	 PU_Desc = @UnitName
 	  	 AND PL_Id = @PLId
IF @PUId IS NULL RETURN(3)
SELECT 	 @PPSetupId = NULL
IF 	 @PatternCode IS NOT NULL
 	 AND ltrim(rtrim(@PatternCode)) <> ''
 	 BEGIN
 	 SELECT 	 @PPSetupId = ps.PP_Setup_Id
 	 FROM 	 Production_Setup ps
 	  	 JOIN 	 Production_Plan pp on pp.PP_Id = ps.PP_Id
 	 WHERE 	 pp.Process_Order = @ProcessOrder
 	  	  	 AND ps.Pattern_Code = @PatternCode
 	 IF @PPSetupId IS NULL
 	  	 BEGIN
       	 SELECT 	 @RC = 13, @ErrMsg = 'Pattern Code Not Found'
 	  	 GOTO 	  	 CleanUp
       	 END
 	  	 END
IF @RC = 0
 	 BEGIN
 	 IF 	 @WriteDirect = 0
 	  	 AND @UpdateClientOnly = 0
 	  	 BEGIN
 	  	 SELECT 	 17,
 	  	  	  	 1,
 	  	  	  	 @TransType,
 	  	  	  	 @TransNum,
 	  	  	  	 @PUId,
 	  	  	  	 @PPStartId,
 	  	  	  	 @StartTime,
 	  	  	  	 @EndTime,
 	  	  	  	 @PPId,
 	  	  	  	 @CommentId,
 	  	  	  	 @PPSetupId,
 	  	  	  	 @UserId
 	  	 END
 	 ELSE IF 	 @WriteDirect = 0
 	  	  	 AND @UpdateClientOnly = 1
 	  	 BEGIN
 	  	 SELECT 	 17,
 	  	  	  	 0,
 	  	  	  	 @TransType,
 	  	  	  	 @TransNum,
 	  	  	  	 @PUId,
 	  	  	  	 @PPStartId,
 	  	  	  	 @StartTime,
 	  	  	  	 @EndTime,
 	  	  	  	 @PPId,
 	  	  	  	 @CommentId,
 	  	  	  	 @PPSetupId,
 	  	  	  	 @UserId
 	  	 END
 	 IF 	 @WriteDirect = 1
 	  	 AND @UpdateClientOnly 	 = 0
 	  	 BEGIN
 	  	 IF 	 @TransType = 1
 	  	  	 AND @PPStartId IS NOT NULL
 	  	  	 BEGIN
 	  	  	 SELECT @TransType = 2
 	  	  	 END
 	  	 EXEC @RC = spServer_DBMgrUpdProdPlanStarts
 	  	  	  	  	  	  	 @PPStartId OUTPUT, 
 	  	  	  	  	  	  	 @TransType, 
 	  	  	  	  	  	  	 @TransNum, 
 	  	  	  	  	  	  	 @PUId,
 	  	  	  	  	  	  	 @StartTime,
 	  	  	  	  	  	  	 @EndTime,
 	  	  	  	  	  	  	 @PPId,
 	  	  	  	  	  	  	 @CommentId, 
 	  	  	  	  	  	  	 @PPSetupId,
 	  	  	  	  	  	  	 @UserId,
 	  	  	  	  	  	  	 @ScheduleControlled,
 	  	  	  	  	  	  	 NULL
 	  	 IF @RC < 0
 	  	  	 BEGIN
 	  	  	 SELECT 	 @ErrMsg = 'WriteDirect Error: ' + CONVERT(varchar, @RC) + '.'
 	  	  	 GOTO 	  	 CleanUp
 	  	  	 END
 	  	 ELSE
 	  	  	 BEGIN
 	  	  	 SELECT 	 @RC = 0
 	  	  	 END
 	  	 END
 	 END
CleanUp:
-- RETURN BACK SUCCESS CODE AND ERROR MESSAGES
SELECT 	 ResultSet 	  	  	  	 = -999, 
 	  	 ReturnCode 	  	  	 = @RC, 
 	  	 ErrorMsg 	  	  	  	 = @ErrMsg,
 	  	 ProductionPlanStartId 	 = @PPStartId
RETURN (0)
