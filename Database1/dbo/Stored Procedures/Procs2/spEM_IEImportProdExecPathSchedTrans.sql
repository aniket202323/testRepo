CREATE PROCEDURE dbo.spEM_IEImportProdExecPathSchedTrans
@PathCode 	  	 nVarChar(100),
@FromStatus 	  	 nVarChar(100),
@ToStatus 	  	 nVarChar(100),
@UserId 	  	 Int
AS
Declare @PathId 	  	  	 Int,
 	  	 @FromId  	  	 Int,
 	  	 @ToId 	  	  	 Int,
 	  	 @PPSId 	  	  	 Int
/* Clean and verIFy arguments */
SELECT  	 @PathCode 	  	 = ltrim(rtrim(@PathCode)),
 	  	 @FromStatus  	 = ltrim(rtrim(@FromStatus)),
 	  	 @ToStatus  	  	 = ltrim(rtrim(@ToStatus))
IF @PathCode = '' 	  	 SELECT @PathCode = Null
IF @FromStatus = '' 	  	 SELECT @FromStatus = Null
IF @ToStatus = '' 	  	 SELECT @ToStatus = Null
IF @PathCode Is Null 
BEGIN
 	 SELECT 'Failed - Path Code missing'
 	 Return (-100)
END
IF @FromStatus Is Null 
BEGIN
 	 SELECT 'Failed - From status missing'
 	 Return (-100)
END
IF @ToStatus Is Null 
BEGIN
 	 SELECT 'Failed - To status missing'
 	 Return (-100)
END
SELECT @PathId = Path_Id FROM PrdExec_Paths WHERE Path_Code = @PathCode
IF @PathId Is null
BEGIN
 	 SELECT 'Failed - Unable to Find Path'
 	 Return (-100)
END
SELECT @FromId = PP_Status_Id FROM Production_Plan_Statuses WHERE PP_Status_Desc = @FromStatus
IF @FromId Is null
BEGIN
 	 SELECT 'Failed - Unable to Find From status'
 	 Return (-100)
END
SELECT @ToId = PP_Status_Id FROM Production_Plan_Statuses WHERE PP_Status_Desc = @ToStatus
IF @ToId Is null
BEGIN
 	 SELECT 'Failed - Unable to Find To status'
 	 Return (-100)
END
SELECT @PPSId = PPS_Id
 	 FROM Production_Plan_Status
 	 WHERE Path_Id = @PathId And From_PPStatus_Id = @FromId And To_PPStatus_Id = @ToId 
IF @PPSId Is Null
BEGIN
 	 EXECUTE spEMEPC_GetSchedTransitions @PathId,@UserId, @FromId ,@ToId,0
END
SELECT @PPSId = PPS_Id
 	 FROM Production_Plan_Status
 	 WHERE Path_Id = @PathId And From_PPStatus_Id = @FromId And To_PPStatus_Id = @ToId 
IF @PPSId Is null
BEGIN
 	 SELECT 'Failed - Unable to create Status Transition'
 	 Return (-100)
END
