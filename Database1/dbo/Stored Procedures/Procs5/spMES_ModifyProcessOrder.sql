
CREATE PROCEDURE dbo.spMES_ModifyProcessOrder
		@TransactionType	int
		,@PPId  			int				= Null
		,@Name				nvarchar(50)	= Null
		,@ProductId			int
		,@PlannedQuantity	float			= Null
		,@PPStatusId		int				= Null
		,@PlannedStartTime	datetime		= Null
		,@PlannedEndTime	datetime		= Null
		,@PathId			int
		,@BomFormulationId	bigint			= Null
		,@ControlTypeId		int				= Null
		,@PPTypeId			int
		,@ImpliedSequence	int				= Null
		,@AdjustedQuantity	float			= Null
		,@ProductionRate	float			= Null
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

If (@PlannedStartTime is not null)
	SELECT @PlannedStartTime = dbo.fnServer_CmnConvertToDBTime(@PlannedStartTime,'UTC')
	
If (@PlannedEndTime is not null)
	SELECT @PlannedEndTime = dbo.fnServer_CmnConvertToDBTime(@PlannedEndTime,'UTC') 
	
DECLARE @CurProductId		int
DECLARE @CurPPStatusId		int
DECLARE @SourcePPId			int
DECLARE @ParentPPId			int
DECLARE @BlockNumber		nvarchar(50)
DECLARE @UserGeneral1		nvarchar(255)
DECLARE @UserGeneral2		nvarchar(255)
DECLARE @UserGeneral3		nvarchar(255)
DECLARE @ExtendedInfo		nvarchar(255)
DECLARE @TransNum			int

----------------------------------------------------------------------------------------------------------------------------------
-- Rule checks for Adds and Updates - Do these checks early because they don't require DB hits
----------------------------------------------------------------------------------------------------------------------------------
IF @TransactionType in (1,2)
BEGIN
	IF @ProductId IS NULL
	BEGIN
		SELECT Code = 'InvalidData', Error = 'Product not found', ErrorType = 'ParameterResourceNotFound', PropertyName1 = 'ProductId', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
		RETURN
	END
	
	IF @PPTypeId IS NULL
	BEGIN
		SELECT Code = 'InvalidData', Error = 'Order Type not found', ErrorType = 'ParameterResourceNotFound', PropertyName1 = 'OrderTypeId', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
		RETURN
	END

	IF @PPStatusId IS NULL
	BEGIN
		SELECT Code = 'InvalidData', Error = 'Status not found', ErrorType = 'ParameterResourceNotFound', PropertyName1 = 'OrderStatusId', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
		RETURN
	END

	if (@PlannedStartTime is not null) and (@PlannedEndTime is not null) and (@PlannedStartTime >= @PlannedEndTime)
	BEGIN
		SELECT Code = 'InvalidData', Error = 'Planned Start Time must be before Planned End Time', ErrorType = 'StartTimeNotBeforeEndTime', PropertyName1 = 'PlannedStartTime', PropertyName2 = 'PlannedEndTime', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
		RETURN
	END

END

----------------------------------------------------------------------------------------------------------------------------------
-- Make sure we have a good user
----------------------------------------------------------------------------------------------------------------------------------
IF NOT EXISTS(SELECT 1 FROM Users_Base WHERE User_id = @UserId )
BEGIN
	SELECT Error = 'ERROR: Valid User Required', Code = 'InsufficientPermission', ErrorType = 'ValidUserNotFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
	RETURN
END

----------------------------------------------------------------------------------------------------------------------------------
-- If it a delete, load the information from the Production Plan and return error if it doesn't exist
----------------------------------------------------------------------------------------------------------------------------------
IF @TransactionType in (3)
BEGIN
	SELECT @ProductId = Null
	SELECT @Name				= Process_Order
		  ,@ProductId			= Prod_Id
		  ,@PlannedQuantity		= Forecast_Quantity
		  ,@PPStatusId			= PP_Status_Id
		  ,@PlannedStartTime	= Forecast_Start_Date
		  ,@PlannedEndTime		= Forecast_End_Date
		  ,@PathId				= Path_Id
		  ,@BomFormulationId	= BOM_Formulation_Id
		  ,@ControlTypeId		= Control_Type
		  ,@PPTypeId			= PP_Type_Id
		  ,@ImpliedSequence		= Implied_Sequence
		  ,@AdjustedQuantity	= Adjusted_Quantity
		  ,@ProductionRate		= Production_Rate
		  ,@CommentId			= Comment_Id
		  ,@UserId				= User_Id
		  ,@SourcePPId			= Source_PP_Id
		  ,@ParentPPId			= Parent_PP_Id
		  ,@BlockNumber			= Block_Number
		  ,@UserGeneral1		= User_General_1
		  ,@UserGeneral2		= User_General_2
		  ,@UserGeneral3		= User_General_3
		  ,@ExtendedInfo		= Extended_Info
	  FROM Production_Plan
	 WHERE PP_Id = @PPId
	IF (@ProductId is null)
	BEGIN
		SELECT Error = 'ERROR: Process Order not found', Code = 'ResourceNotFound', ErrorType = 'ProcessOrderNotFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
		RETURN
	END
END

----------------------------------------------------------------------------------------------------------------------------------
-- If it's an update return error if it doesn't exist.  Also, get some fields of the order that we don't want to change
----------------------------------------------------------------------------------------------------------------------------------
IF @TransactionType = 2 -- Update
BEGIN
	SELECT @CurProductId = Null
	SELECT @CurProductId		= Prod_Id
		  ,@CurPPStatusId		= PP_Status_Id
		  ,@SourcePPId			= Source_PP_Id
		  ,@ParentPPId			= Parent_PP_Id
		  ,@BlockNumber			= Block_Number
		  ,@UserGeneral1		= User_General_1
		  ,@UserGeneral2		= User_General_2
		  ,@UserGeneral3		= User_General_3
		  ,@ExtendedInfo		= Extended_Info
	  FROM Production_Plan
	 WHERE PP_Id = @PPId
	IF (@CurProductId is null)
	BEGIN
		SELECT Error = 'ERROR: Process Order not found', Code = 'ResourceNotFound', ErrorType = 'ProcessOrderNotFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
		RETURN
	END
END

----------------------------------------------------------------------------------------------------------------------------------
-- Make sure we have a good path
----------------------------------------------------------------------------------------------------------------------------------
IF NOT EXISTS(SELECT 1 FROM Prdexec_Paths WHERE Path_id = @PathId)
BEGIN
	SELECT Error = 'ERROR: Valid Path Required', Code = 'InvalidData', ErrorType = 'PathNotFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
	RETURN
END

----------------------------------------------------------------------------------------------------------------------------------
-- If it's an add return error if it allready exists
----------------------------------------------------------------------------------------------------------------------------------
IF @TransactionType = 1 -- Add
BEGIN
	IF EXISTS(SELECT 1 FROM Production_Plan WHERE Path_id = @PathId and Process_Order = @Name)
	BEGIN
		SELECT Error = 'ERROR: Process Order allready exists', Code = 'InvalidData', ErrorType = 'ProcessOrderNameConflict', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
		RETURN
	END
END

----------------------------------------------------------------------------------------------------------------------------------
-- If it's an update return error if name allready exists
----------------------------------------------------------------------------------------------------------------------------------
IF @TransactionType = 2 -- Update
BEGIN
	IF EXISTS(SELECT 1 FROM Production_Plan WHERE Path_id = @PathId and Process_Order = @Name and PP_Id <> @PPId)
	BEGIN
		SELECT Error = 'ERROR: Process Order allready exists', Code = 'InvalidData', ErrorType = 'ProcessOrderNameConflict', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
		RETURN
	END
END

----------------------------------------------------------------------------------------------------------------------------------
-- If it's an add, make sure the status is ok for an initial status
----------------------------------------------------------------------------------------------------------------------------------
IF (@TransactionType = 1)
BEGIN
	IF NOT EXISTS(SELECT 1 FROM Production_Plan_Status WHERE Path_Id = @PathId and From_PPStatus_Id = @PPStatusId)
	BEGIN
		SELECT Code = 'InvalidData', Error = 'Invalid Status Provide', ErrorType = 'InvalidStatus', PropertyName1 = 'OrderStatusId', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
		RETURN
	END
END

----------------------------------------------------------------------------------------------------------------------------------
-- If it's an update and the status has changed, make sure this is a valid transition
----------------------------------------------------------------------------------------------------------------------------------
IF (@TransactionType = 2) and (@CurPPStatusId <> @PPStatusId)
BEGIN
	IF NOT EXISTS(SELECT 1 FROM Production_Plan_Status WHERE Path_Id = @PathId and From_PPStatus_Id = @CurPPStatusId and To_PPStatus_Id = @PPStatusId)
	BEGIN
		SELECT Code = 'InvalidData', Error = 'Invalid Status Provide', ErrorType = 'InvalidStatus', PropertyName1 = 'OrderStatusId', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
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
	SELECT Error = 'ERROR: Process Order transaction not authorized to user', Code = 'InsufficientPermission', ErrorType = '', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
	RETURN
END

----------------------------------------------------------------------------------------------------------------------------------
-- For an Add, we must ensure that the PP Id passed to the DBMgr sproc is null.
-- If not, it will return the wrong id in the result set
----------------------------------------------------------------------------------------------------------------------------------
IF (@TransactionType = 1)
BEGIN
	Set @PPId = null
END

----------------------------------------------------------------------------------------------------------------------------------
-- TransNum = 0 (Coalesce) for Adds and Deletes
-- TransNum = 2 (Don't Coalesce) for Updates
----------------------------------------------------------------------------------------------------------------------------------
Set @TransNum = 0
IF (@TransactionType = 2)
BEGIN
	Set @TransNum = 2
END

----------------------------------------------------------------------------------------------------------------------------------
-- Execute the transaction using the DBMgr sproc
----------------------------------------------------------------------------------------------------------------------------------
DECLARE @RC int
EXECUTE @RC = spServer_DBMgrUpdProdPlan
			@PPId OUTPUT, @TransactionType, @TransNum, @PathId, @CommentId, @ProductId, @ImpliedSequence OUTPUT, @PPStatusId, @PPTypeId
			,@SourcePPId, @UserId, @ParentPPId, @ControlTypeId, @PlannedStartTime, @PlannedEndTime
			,null -- EntryOn not needed
			,@PlannedQuantity, @ProductionRate, @AdjustedQuantity, @BlockNumber, @Name
			,null  -- TransactionTime
			,null  -- Misc1
			,null  -- Misc2
			,null  -- Misc3
			,null  -- Misc4
			,@BOMFormulationId, @UserGeneral1, @UserGeneral2, @UserGeneral3, @ExtendedInfo

IF (@RC < 0) -- spServer sproc had an error
BEGIN
   SELECT Code = 'UnknownError', Error = 'Unknown error occurred in spServer_DBMgrUpdProdPlan', ErrorType = 'UnknownError', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
   RETURN
END
----------------------------------------------------------------------------------------------------------------------------------
-- The DBMgr sproc above can return System result sets.  They will be Process order result sets (type 15), so we need to make
-- sure this result set doesn't get confused with a system result set.  So, best to make sure the value in the first column is
-- not a number.  For system results sets, the number in the first column tells us the type.
----------------------------------------------------------------------------------------------------------------------------------
SELECT	RSType				= 'ProcessOrder'
		,PPId				= @PPId
		,Name				= @Name
		,ProductId			= @ProductId
		,PlannedQuantity	= @PlannedQuantity
		,PPStatusId			= @PPStatusId
		,PlannedStartTime	= dbo.fnServer_CmnConvertFromDbTime(@PlannedStartTime, 'UTC')
		,PlannedEndTime		= dbo.fnServer_CmnConvertFromDbTime(@PlannedEndTime, 'UTC')
		,PathId				= @PathId
		,BomFormulationId	= @BomFormulationId
		,ControlTypeId		= @ControlTypeId
		,PPTypeId			= @PPTypeId
		,ImpliedSequence	= @ImpliedSequence
		,AdjustedQuantity	= @AdjustedQuantity
		,ProductionRate		= @ProductionRate
		,CommentId			= @CommentId
		,UserId				= @UserId

