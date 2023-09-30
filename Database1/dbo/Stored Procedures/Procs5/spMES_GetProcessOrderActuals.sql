
CREATE PROCEDURE dbo.spMES_GetProcessOrderActuals
		@PPId	 			int				= null
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
-- Load the results into a temporary table so we can eliminate any the user is not allowed to see before we return
----------------------------------------------------------------------------------------------------------------------------------
DECLARE @results TABLE(
		PPId  						int			Not Null
		,PathId						int			Null
		,ActualStartTime			datetime	Null
		,ActualEndTime				datetime	Null
		,ActualBadItems				int			Null
		,ActualBadQuantity			float		Null
		,ActualDownTime				float		Null
		,ActualGoodItems			int			Null
		,ActualGoodQuantity			float		Null
		,ActualRunningTime			float		Null
		,PredictedRemainingDuration	float		Null
		,PredictedRemainingQuantity	float		Null
		,PredictedTotalDuration		float		Null
		,AlarmCount					int			Null)

	INSERT INTO @results (	PPId, PathId, ActualStartTime, ActualEndTime, ActualBadItems, ActualBadQuantity, ActualDownTime, ActualGoodItems,
							ActualGoodQuantity, ActualRunningTime, PredictedRemainingDuration, PredictedRemainingQuantity, PredictedTotalDuration,
							AlarmCount)
		SELECT	PP_Id, Path_Id, Actual_Start_Time, Actual_End_Time, Actual_Bad_Items, Actual_Bad_Quantity, Actual_Down_Time, Actual_Good_Items,
				Actual_Good_Quantity, Actual_Running_Time, Predicted_Remaining_Duration, Predicted_Remaining_Quantity, Predicted_Total_Duration,
				Alarm_Count
		  FROM	Production_Plan
		 WHERE (@PPId is null OR @PPId = PP_Id) 

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

SELECT	PPId						= PPId
		,PathId						= PathId
		,ActualStartTime			= dbo.fnServer_CmnConvertFromDbTime(ActualStartTime, 'UTC')
		,ActualEndTime				= dbo.fnServer_CmnConvertFromDbTime(ActualEndTime, 'UTC')
		,ActualBadItems				= ActualBadItems
		,ActualBadQuantity			= ActualBadQuantity
		,ActualDownTime				= ActualDownTime
		,ActualGoodItems			= ActualGoodItems
		,ActualGoodQuantity			= ActualGoodQuantity
		,ActualRunningTime			= ActualRunningTime
		,PredictedRemainingDuration	= PredictedRemainingDuration
		,PredictedRemainingQuantity	= PredictedRemainingQuantity
		,PredictedTotalDuration		= PredictedTotalDuration
		,AlarmCount					= AlarmCount
  FROM  @results order by PPId
