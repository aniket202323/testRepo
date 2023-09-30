-- SELECT  [dbo].[fnLocal_PEGetQ3RDataTimestamp](15542)
--================================================================================================
CREATE FUNCTION [dbo].[fnLocal_PEGetQ3RDataTimestamp]
(@ppid int)
RETURNS 
datetime
AS
BEGIN
	
	DECLARE @puid		TABLE (
		puid int
		)

	DECLARE @EVentValue TABLE (
		eventId			int,
		EventTime		datetime,
		VariableValue	varchar(25)
		)

	DECLARE @Timestamp		datetime,
			@VarIDOOL		int,
			@VarPUID		int,
			@MinTime		datetime,
			@MaxTime		datetime,
			@TableIdVar		int


	SET @TableIdVar  = (	SELECT TableID 
							FROM  [DBO].[Tables] WITH(NOLOCK) 
							WHERE TableName ='Variables')

	--Get time range
	SELECT @MinTime = MIN(STart_Time), 
			@maxtime = MAX(end_time)
	FROM	[dbo].[Production_Plan_Starts]  WITH(NOLOCK)
	WHERE	PP_ID = @ppid


	--Get possible PUID
	INSERT @PUID (puid)
	SELECT pu_id
	FROM	[dbo].[Production_Plan_Starts]  WITH(NOLOCK)
	WHERE	PP_ID = @ppid


	SELECT @VarIDOOL	=   Var_ID,
			@VarPUID	=	pu_id 
	FROM	[dbo].[Variables_Base] v		WITH(NOLOCK)
	JOIN	[dbo].[Table_Fields_Values] tfv WITH(NOLOCK) ON v.Var_ID = tfv.KeyId
	JOIN	[dbo].[Table_Fields] tf			WITH(NOLOCK) ON tfv.Table_field_id = tf.Table_Field_Id 
	WHERE	tf.Table_Field_Desc = 'Q3ROOLVariable'
	AND		tfv.TableId = @TableIdVar
	AND		tfv.Value = '1'
	AND		v.Pu_ID in (SELECT puID from  @PUID)


	INSERT @EVentValue (eventid, eventTime, variableValue)
	SELECT	e.event_id,
			e.timestamp,
			t.result
	FROM dbo.events e		WITH(NOLOCK)
	LEFT JOIN dbo.tests t	WITH(NOLOCK)	ON e.timestamp = t.result_on AND t.var_id = @VarIDOOL
	WHERE e.pu_id = @VarPUID
		AND e.timestamp >@minTime
		AND e.timestamp <= @maxTime

	SET @Timestamp = (SELECT MAX(eventTime) FROM @EVentValue WHERE VariableValue IS NOT NULL)

	RETURN @Timestamp
END