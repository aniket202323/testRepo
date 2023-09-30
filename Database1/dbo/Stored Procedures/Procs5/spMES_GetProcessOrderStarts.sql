
CREATE PROCEDURE dbo.spMES_GetProcessOrderStarts
		@PPId	 			int				= null
		,@PPStartId	 		int				= null
		,@UnitIds			nvarchar(1000)	= null	-- Only return PPStarts from these units
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
-- Make sure we have a good PP_Id
----------------------------------------------------------------------------------------------------------------------------------
IF (@PPId is not null) and (NOT EXISTS(SELECT 1 FROM Production_Plan WHERE PP_id = @PPId))
BEGIN
	SELECT Error = 'Process Order not found', Code = 'ResourceNotFound', ErrorType = 'ProcessOrderNotFound', PropertyName1 = 'ProcessOrderId', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
	RETURN
END

----------------------------------------------------------------------------------------------------------------------------------
-- Parse the unit ids into a temp table for later selection
----------------------------------------------------------------------------------------------------------------------------------
DECLARE @AllUnits Table (UnitId Int)

IF @UnitIds IS NOT NULL
BEGIN
	INSERT INTO @AllUnits(UnitId)
		SELECT Id
		  FROM dbo.fnCMN_IdListToTable('Prod_Units', @UnitIds, ',')
END

----------------------------------------------------------------------------------------------------------------------------------
-- Load the results into a temporary table so we can eliminate any the user is not allowed to see before we return
----------------------------------------------------------------------------------------------------------------------------------
DECLARE @results TABLE(
		PPStartId			int				Not Null
		,DepartmentId		int				Null
		,LineId				int				Null
		,UnitId				int				Null
		,PPId				int				Not Null
		,PPSetupId			int				Null
		,StartTime			datetime		Not Null
		,EndTime			datetime		Null
		,CommentId			int				Null
		,UserId				int				Not Null
		,PathId				int				Null)

	INSERT INTO @results (PPStartId, DepartmentId, LineId, UnitId, PPId, PPSetupId, StartTime, EndTime,
						  CommentId, UserId, PathId)
		SELECT		pps.PP_Start_Id, d.Dept_Id, l.PL_Id, u.PU_Id, po.PP_Id, ps.PP_Setup_Id, pps.Start_Time, pps.End_Time,
					pps.Comment_Id, pps.User_Id, po.Path_Id
		 FROM		Production_Plan po
		 JOIN		Production_Plan_Starts pps ON pps.PP_Id = po.PP_Id
		 LEFT JOIN	Production_Setup ps ON ps.PP_Id = po.PP_Id and ps.PP_Setup_Id = pps.pp_setup_id
		 LEFT JOIN	Prod_Units_Base u ON u.PU_Id = pps.PU_Id
		 LEFT JOIN	Prod_Lines_Base l ON l.PL_Id = u.PL_Id
		 LEFT JOIN	Departments_Base d ON d.Dept_Id = l.Dept_Id
		 WHERE		(@PPId is null OR @PPId = po.PP_Id) 
		   AND		(@PPStartId is null or @PPStartId = pps.PP_Start_Id)
		   AND		(@UnitIds is null or pps.PU_Id in (SELECT UnitId FROM @AllUnits))
		   AND		pps.User_Id is not null
		 ORDER BY	po.PP_Id, pps.PP_Start_Id

IF (@PPStartId is not null) and (NOT EXISTS(SELECT 1 FROM @results WHERE PPStartId = @PPStartId))
BEGIN
	SELECT Error = 'ERROR: Process Order Start not found', Code = 'ResourceNotFound', ErrorType = 'ProcessOrderStartNotFound', PropertyName1 = 'ProcessOrderStartId', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
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

IF (@PPStartId is not null) and (NOT EXISTS(SELECT 1 FROM @results WHERE PPStartId = @PPStartId))
BEGIN
	SELECT Error = 'ERROR: Process Order Start not visible to user', Code = 'InsufficientPermission', ErrorType = '', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
	RETURN
END


----------------------------------------------------------------------------------------------------------------------------------
-- The DBMgr sproc can return System result sets.  They will be Process order result sets (type 15), so we need to make
-- sure this result set doesn't get confused with a system result set.  So, best to make sure the value in the first column is
-- not a number.  For system results sets, the number in the first column tells us the type.
-- We want this resultset extractor to be able to be sharred with the same one used by spMES_ModifyProcessOrder.  It uses the DBMgr
-- sproc, so we need worry about it here also.
----------------------------------------------------------------------------------------------------------------------------------
SELECT	RSType				= 'ProcessOrderStart'
		,PPStartId			= PPStartId
		,DepartmentId		= DepartmentId
		,LineId				= LineId
		,UnitId				= UnitId
		,PPId				= PPId
		,PPSetupId			= PPSetupId
		,StartTime			= dbo.fnServer_CmnConvertFromDbTime(StartTime, 'UTC')
		,EndTime			= dbo.fnServer_CmnConvertFromDbTime(EndTime, 'UTC')
		,CommentId			= CommentId
		,UserId				= UserId
  From  @Results
  Order by PPId, PPStartId
