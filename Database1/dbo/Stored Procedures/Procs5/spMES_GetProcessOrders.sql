
CREATE PROCEDURE dbo.spMES_GetProcessOrders
		@PPId	 			int				= null
		,@LineId			int				= null	-- Line to return PO details for
		,@StatusSet			nvarchar(30)	= null	-- Set of status ID as a string
		,@UserId			int				= null
AS
----------------------------------------------------------------------------------------------------------------------------------
-- Make sure we have a good user
----------------------------------------------------------------------------------------------------------------------------------
IF NOT EXISTS(SELECT 1 FROM Users_Base WHERE User_id = @UserId )
BEGIN
	SELECT Error = 'ERROR: Valid User Required', Code = 'InsufficientPermission', ErrorType = 'ValidUserNotFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
	RETURN
END

----------------------------------------------------------------------------------------------------------------------------------
-- Parse the status set by into a temp table for later selection
----------------------------------------------------------------------------------------------------------------------------------
DECLARE @StatusValues Table (StatusValue Int)

IF @StatusSet IS NOT NULL
BEGIN
	INSERT INTO @StatusValues(StatusValue)
		SELECT Id
		  FROM dbo.fnCMN_IdListToTable('Production_Plan_Statuses ',@StatusSet,',')
END

----------------------------------------------------------------------------------------------------------------------------------
-- Load the results into a temporary table so we can eliminate any the user is not allowed to see before we return
----------------------------------------------------------------------------------------------------------------------------------
DECLARE @results TABLE(
		PPId  				int				Not Null
		,Name				nvarchar(50)	Null
		,ProductId			int				Not Null
		,PlannedQuantity	float			Null
		,PPStatusId			int				Null
		,PlannedStartTime	datetime		Null
		,PlannedEndTime		datetime		Null
		,PathId				int				Not Null
		,BomFormulationId	bigint			Null
		,ControlTypeId		int				Null
		,PPTypeId			int				Not Null
		,ImpliedSequence	int				Null
		,AdjustedQuantity	float			Null
		,ProductionRate		float			Null
		,CommentId			int				Null
		,UserId				int				Not Null)

	INSERT INTO @results (PPId, Name, ProductId, PlannedQuantity, PPStatusId, PlannedStartTime, PlannedEndTime, PathId,
							BomFormulationId, ControlTypeId, PPTypeId, ImpliedSequence, AdjustedQuantity, ProductionRate,
							CommentId, UserId)
		SELECT	po.PP_Id, po.Process_Order, po.Prod_Id, po.Forecast_Quantity, po.PP_Status_Id, po.Forecast_Start_Date,
				po.Forecast_End_Date, po.Path_Id, po.BOM_Formulation_Id, po.Control_Type, po.PP_Type_Id, po.Implied_Sequence,
				po.Adjusted_Quantity, po.Production_Rate, po.Comment_Id, po.User_Id
		  FROM	Production_Plan po
		  JOIN	Prdexec_Paths pth ON po.Path_Id = pth.Path_Id

		 WHERE (@PPId is null OR @PPId = po.PP_Id) 
		   AND (@LineId is null or @LineId = pth.PL_Id)
		   AND (@StatusSet is null or po.PP_Status_Id in (SELECT StatusValue FROM @StatusValues))
		 ORDER BY po.PP_Id

IF (@PPId is not null) and (NOT EXISTS(SELECT 1 FROM @results WHERE PPid = @PPId))
BEGIN
	SELECT Error = 'ERROR: Process Order not found', Code = 'ResourceNotFound', ErrorType = 'ProcessOrderNotFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
	RETURN
END

----------------------------------------------------------------------------------------------------------------------------------
-- Eliminate orders if the user doesn't have read access to the path
----------------------------------------------------------------------------------------------------------------------------------
DECLARE @paths TABLE(PathId	int Not Null)
INSERT INTO @paths (PathId)
	SELECT DISTINCT PathId FROM @results

declare @PathIds nvarchar(max)
select @PathIds = coalesce(@PathIds + ',', '') +  convert(nvarchar(12), PathId) from @paths

declare @Security Table (PathId Int, ReadSecurity Int)
insert into @Security (PathId, ReadSecurity)
	select Path_Id, ReadSecurity from dbo.fnMES_GetScheduleSecurity (null, null, @PathIds, @UserId)

Delete from @results where PathId not in (Select PathId from @Security where ReadSecurity = 1)

if (@PPId is not null) and (NOT EXISTS(SELECT 1 FROM @results WHERE @PPId = PPId))
BEGIN
	SELECT Error = 'ERROR: Process Order not visible to user', Code = 'InsufficientPermission', ErrorType = '', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
	RETURN
END

----------------------------------------------------------------------------------------------------------------------------------
-- The DBMgr sproc can return System result sets.  They will be Process order result sets (type 15), so we need to make
-- sure this result set doesn't get confused with a system result set.  So, best to make sure the value in the first column is
-- not a number.  For system results sets, the number in the first column tells us the type.
-- We want this resultset extractor to be able to be sharred with the same one used by spMES_ModifyProcessOrder.  It uses the DBMgr
-- sproc, so we need worry about it here also.
----------------------------------------------------------------------------------------------------------------------------------
SELECT	RSType				= 'ProcessOrder'
		,PPId				= PPId
		,Name				= Name
		,ProductId			= ProductId
		,PlannedQuantity	= PlannedQuantity
		,PPStatusId			= PPStatusId
		,PlannedStartTime	= dbo.fnServer_CmnConvertFromDbTime(PlannedStartTime, 'UTC')
		,PlannedEndTime		= dbo.fnServer_CmnConvertFromDbTime(PlannedEndTime, 'UTC')
		,PathId				= PathId
		,BomFormulationId	= BomFormulationId
		,ControlTypeId		= ControlTypeId
		,PPTypeId			= PPTypeId
		,ImpliedSequence	= ImpliedSequence
		,AdjustedQuantity	= AdjustedQuantity
		,ProductionRate		= ProductionRate
		,CommentId			= CommentId
		,UserId				= UserId
  FROM  @results order by PPId
