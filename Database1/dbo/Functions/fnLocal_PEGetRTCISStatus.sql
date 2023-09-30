-- SELECT  [dbo].[fnLocal_PEGetRTCISStatus]()
--================================================================================================
CREATE FUNCTION [dbo].[fnLocal_PEGetRTCISStatus]
()
RETURNS 
varchar(50)
AS
BEGIN
	DECLARE @RTCISStatus				int,
			@PUID						int,
			@TedId						int

	SET @PUID	= ( SELECT TOP 1 pu_id		FROM dbo.prod_units_Base		WITH(NOLOCK) WHERE equipment_type = 'LotStorage')

	SET @TedId	= (	SELECT TEDet_Id			FROM dbo.timed_event_details	WITH(NOLOCK) WHERE pu_id = @PUID AND End_time IS NULL)

	IF @TedId IS NULL
	BEGIN
		SET @RTCISStatus = 1
	END
	ELSE
	BEGIN
		SET @RTCISStatus = 0
	END

	RETURN @RTCISStatus
END