
CREATE PROCEDURE dbo.spMES_ModifyProcessOrderStart
		@TransactionType	int
		,@PPStartId  		int				= Null
		,@UnitId			int
		,@PPId				int				= Null
		,@PPSetupId			int				= Null
		,@StartTime			datetime		= Null
		,@EndTime			datetime		= Null
		,@CommentId			int				= Null
		,@UserId			int
AS
/* 
Times In and Out are in UTC
@TransactionType
	1 - Add
	2 - Update
	3 - Delete
*/

If (@StartTime is not null)
	SELECT @StartTime = dbo.fnServer_CmnConvertToDBTime(@StartTime,'UTC')
	
If (@EndTime is not null)
	SELECT @EndTime = dbo.fnServer_CmnConvertToDBTime(@EndTime,'UTC') 
	
DECLARE @CurUnitId			int
DECLARE @ScheduleControlled	bit
DECLARE @PathId				int
DECLARE @PPStatusId			int
DECLARE @TransNum			int

Set @TransNum = 0
If (@TransactionType = 2)
	Set @TransNum = 2 -- Do not coalesce on update

----------------------------------------------------------------------------------------------------------------------------------
-- Make sure we have a good user
----------------------------------------------------------------------------------------------------------------------------------
IF NOT EXISTS(SELECT 1 FROM Users_Base WHERE User_id = @UserId )
BEGIN
	SELECT Error = 'Valid User Required', Code = 'InsufficientPermission', ErrorType = 'ValidUserNotFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
	RETURN
END

----------------------------------------------------------------------------------------------------------------------------------
-- Make sure we have a good PP_Id and its active
----------------------------------------------------------------------------------------------------------------------------------
Set @PPStatusId = null
Select @PPStatusId = PP_Status_Id FROM Production_Plan WHERE PP_id = @PPId

IF @PPStatusId is Null
BEGIN
	SELECT Error = 'Process Order not found', Code = 'ResourceNotFound', ErrorType = 'ProcessOrderNotFound', PropertyName1 = 'ProcessOrderId', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
	RETURN
END

IF @PPStatusId NOT in (3,4)
BEGIN
	SELECT Error = 'Process Order status must be active or complete', Code = 'InvalidData', ErrorType = 'InvalidStatus', PropertyName1 = 'PPStatusId', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
	RETURN
END

----------------------------------------------------------------------------------------------------------------------------------
-- Rule checks
----------------------------------------------------------------------------------------------------------------------------------
IF @TransactionType in (1)
BEGIN
	IF @UnitId IS NULL
	BEGIN
		SELECT Error = 'Unit not found', Code = 'InvalidData', ErrorType = 'MissingRequiredData', PropertyName1 = 'UnitId', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
		RETURN
	END
END
	
IF @TransactionType in (1,2)
BEGIN
	IF @PPId IS NULL
	BEGIN
		SELECT Error = 'Process Order not found', Code = 'ResourceNotFound', ErrorType = 'ProcessOrderNotFound', PropertyName1 = 'ProcessOrderId', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
		RETURN
	END

	IF @StartTime IS NULL
	BEGIN
		SELECT Error = 'Start Time not found', Code = 'InvalidData', ErrorType = 'MissingRequiredData', PropertyName1 = 'StartTime', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
		RETURN
	END

	if (@StartTime is not null) and (@EndTime is not null) and (@StartTime >= @EndTime)
	BEGIN
		SELECT Error = 'Start Time must be before End Time', Code = 'InvalidData', ErrorType = 'StartTimeNotBeforeEndTime', PropertyName1 = 'StartTime', PropertyName2 = 'EndTime', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
		RETURN
	END

	IF (@PPSetupId is not null) AND (NOT EXISTS(SELECT 1 FROM Production_Setup WHERE PP_Setup_Id = @PPSetupId and PP_Id = @PPId))
	BEGIN
		SELECT Error = 'PP Setup not found', Code = 'InvalidData', ErrorType = 'InvalidParameterValue', PropertyName1 = 'PPSetupId', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
		RETURN
	END

	IF (@CommentId is not null) AND (NOT EXISTS(SELECT 1 FROM Comments WHERE Comment_id = @CommentId and ((TopOfChain_Id = Comment_Id) or (TopOfChain_Id is null))))
	BEGIN
		SELECT Error = 'Comment not found', Code = 'InvalidData', ErrorType = 'InvalidParameterValue', PropertyName1 = 'CommentId', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
		RETURN
	END

END

----------------------------------------------------------------------------------------------------------------------------------
-- If it's a delete, load the information from the Production Plan Start and return error if it doesn't exist
----------------------------------------------------------------------------------------------------------------------------------
IF @TransactionType in (3)
BEGIN
	SELECT @UnitId = Null
	SELECT	@UnitId					= pps.PU_Id
			,@PPSetupId				= pps.pp_setup_id
			,@StartTime				= pps.Start_Time
			,@EndTime				= pps.End_Time
			,@CommentId				= pps.Comment_Id
			,@UserId				= pps.User_Id
			,@PathId				= po.Path_Id
			,@ScheduleControlled	= pth.Is_Schedule_Controlled
	 FROM	Production_Plan_Starts pps
	 JOIN	Production_Plan po ON po.PP_Id = pps.PP_Id
	 JOIN	Prdexec_Paths pth ON pth.Path_Id = po.Path_Id
	 WHERE	pps.PP_Start_Id = @PPStartId and pps.PP_Id = @PPId
	IF (@UnitId is null)
	BEGIN
		SELECT Error = 'Process Order Start not found', Code = 'ResourceNotFound', ErrorType = 'ProcessOrderStartNotFound', PropertyName1 = 'ProcessOrderStartId', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
		RETURN
	END
END

----------------------------------------------------------------------------------------------------------------------------------
-- If it's an update return error if it doesn't exist.  Also, get some fields of the order that we don't want to change
----------------------------------------------------------------------------------------------------------------------------------
IF @TransactionType = 2 -- Update
BEGIN
	SELECT @CurUnitId = Null
	SELECT	@CurUnitId				= pps.PU_Id
			,@PathId				= po.Path_Id
			,@ScheduleControlled	= pth.Is_Schedule_Controlled
			,@UnitId				= coalesce(@UnitId, pps.PU_Id)
	 FROM	Production_Plan_Starts pps
	 JOIN	Production_Plan po ON po.PP_Id = pps.PP_Id
	 JOIN	Prdexec_Paths pth ON pth.Path_Id = po.Path_Id
	 WHERE	pps.PP_Start_Id = @PPStartId and pps.PP_Id = @PPId

	IF (@CurUnitId is null)
	BEGIN
		SELECT Error = 'Process Order Start not found', Code = 'ResourceNotFound', ErrorType = 'ProcessOrderStartNotFound', PropertyName1 = 'ProcessOrderStartId', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
		RETURN
	END
	IF (@CurUnitId <> @UnitId)
	BEGIN
		SELECT Error = 'Unit Id cannot be changed', Code = 'InvalidData', ErrorType = 'InvalidParameterValue', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
		RETURN
	END
END

----------------------------------------------------------------------------------------------------------------------------------
-- If it's an add validate inputs and get some data we need
----------------------------------------------------------------------------------------------------------------------------------
IF @TransactionType = 1 -- Add
BEGIN
	SELECT @PathId = NULL
	SELECT		 @PathId				= po.Path_Id
				,@ScheduleControlled	= pth.Is_Schedule_Controlled
	 FROM		Production_Plan po
	 JOIN		Prdexec_Paths pth ON pth.Path_Id = po.Path_Id
	 WHERE		po.PP_Id = @PPId
	IF (@PathId is null)
	BEGIN
		SELECT Error = 'Path not found', Code = 'ResourceNotFound', ErrorType = 'ParameterResourceNotFound', PropertyName1 = 'Path', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
		RETURN
	END

	IF ((@ScheduleControlled is not null) and (@ScheduleControlled = 1))
	BEGIN
		SELECT Error = 'Path cannot be schedule controlled', Code = 'InvalidData', ErrorType = 'PathIsScheduleControlled', PropertyName1 = 'Path', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
		RETURN
	END

	IF Not Exists(Select 1 from Prod_Units_Base where PU_Id = @UnitId)
	BEGIN
		SELECT Error = 'Unit not found', Code = 'ResourceNotFound', ErrorType = 'ParameterResourceNotFound', PropertyName1 = 'UnitId', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
		RETURN
	END

	IF Not Exists(Select 1 From PrdExec_Path_Units Where Path_Id = @PathId and PU_Id = @UnitId)
	BEGIN
		SELECT Error = 'Unit not on path', Code = 'InvalidData', ErrorType = 'UnitNotOnPath', PropertyName1 = 'UnitId', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
		RETURN
	END
END

----------------------------------------------------------------------------------------------------------------------------------
-- Get security level of the user and return error if transaction not allowed
----------------------------------------------------------------------------------------------------------------------------------
Declare @ReadSecurity Int
Declare @AddSecurity Int
Declare @UpdateSecurity Int
Declare @DeleteSecurity Int

SELECT	@ReadSecurity		= ReadSecurity
		,@AddSecurity		= AddSecurity
		,@UpdateSecurity	= EditSecurity
		,@DeleteSecurity	= DeleteSecurity
  from	dbo.fnMES_GetScheduleSecurity (null, null, convert(nvarchar(12), @PathId), @UserId)

IF	(@ReadSecurity <> 1) or
	(@TransactionType = 1 and @AddSecurity <> 1) or
	(@TransactionType = 2 and @UpdateSecurity <> 1) or
	(@TransactionType = 3 and @DeleteSecurity <> 1)
BEGIN
	SELECT Error = 'Process Order Start transaction not authorized to user', Code = 'InsufficientPermission', ErrorType = '', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
	RETURN
END

----------------------------------------------------------------------------------------------------------------------------------
-- Execute the transaction using the DBMgr sproc
----------------------------------------------------------------------------------------------------------------------------------
DECLARE @RC int
EXECUTE @RC = spServer_DBMgrUpdProdPlanStarts
			@PPStartId OUTPUT, @TransactionType, @TransNum, @UnitId, @StartTime, @EndTime, @PPId, @CommentId, @PPSetupId, @UserId, @ScheduleControlled

IF (@RC < 0) -- spServer sproc had an error
BEGIN
   SELECT Code = 'UnknownError', Error = 'Unknown error occurred in spServer_DBMgrUpdProdPlanStarts', ErrorType = 'UnknownError', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
   RETURN
END

IF @TransactionType in (1,2)
BEGIN
  exec [dbo].[spMES_GetProcessOrderStarts] null, @PPStartId, null, @UserId
END

