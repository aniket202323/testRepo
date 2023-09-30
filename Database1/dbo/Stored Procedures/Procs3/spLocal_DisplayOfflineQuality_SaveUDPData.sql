










--=====================================================================================================================
-- 	Stored Procedure:	spLocal_DisplayOfflineQuality_SaveUDPData
-- 	Athor:				Roberto del Cid
-- 	Date Created:		2008/03/31
-- 	Sp Type:			stored procedure
-- 	Editor Tab Sp:		4
-----------------------------------------------------------------------------------------------------------------------
-- DESCRITION: 
-----------------------------------------------------------------------------------------------------------------------
-- CALLED BY:
-- LocalDisplayOfflineQuality.aspx
-----------------------------------------------------------------------------------------------------------------------
-- SP SECTIONS:
-- 1.	Declare Variables
-- 2.  	Initilize Values
-----------------------------------------------------------------------------------------------------------------------
-- EDIT HISTORY:

-- Revision		Date		Who					What
-- ========		====		===					====
-- 1.0			2008-03-15	Roberto Del Cid		Initial Development
-----------------------------------------------------------------------------------------------------------------------
-- SAMPLE EXEC STATEMENT
-- EXEC	dbo.spLocal_DisplayOfflineQuality_SaveUDPData	
-- @p_intUDEId	= 12521,
-- @p_intTestCountRequiredValue	= '5',
-- @p_intTestCountCompleteValue = '10',
-- @p_intConformance			= 'reject',	
-- @p_intTestCountOOL			= '10',
-- @p_intTestCountOOT			= '15',
-- @p_dtmTestCompleteDate		= '2008-05-20 10:00:00'	
--=====================================================================================================================
CREATE       PROCEDURE dbo.spLocal_DisplayOfflineQuality_SaveUDPData
		@p_intUDEId						INT,
		@p_intTestCountRequiredValue	VARCHAR(10) = NULL,
		@p_intTestCountCompleteValue	VARCHAR(10) = NULL,
		@p_intConformance				VARCHAR(50) = NULL,
		@p_intTestCountOOL				VARCHAR(10) = NULL,
		@p_intTestCountOOT				VARCHAR(10) = NULL,
		@p_dtmTestCompleteDate			DATETIME 	= NULL,
		@p_vchTestedById				VARCHAR(10) = NULL
AS
SET NOCOUNT ON
--=====================================================================================================================
--	Variable Declaration
-----------------------------------------------------------------------------------------------------------------------
-- INTEGERS
-----------------------------------------------------------------------------------------------------------------------
DECLARE	@intUDETableId	INT,
		@intUDPId		INT,
		@intErrorCode	INT,
		@i				INT
-----------------------------------------------------------------------------------------------------------------------
-- VARCHARS
-----------------------------------------------------------------------------------------------------------------------
DECLARE	@vchErrorMsg 	VARCHAR(100),
		@vchEventDesc 	VARCHAR(100),
		@vchUDPName		VARCHAR(50),
		@vchValue		VARCHAR(50)
-----------------------------------------------------------------------------------------------------------------------
-- Result Set 1
-- Returns miscellaneous information back to the display
-----------------------------------------------------------------------------------------------------------------------
DECLARE	@tblMiscInfo	TABLE	(
		RcdIdx					INT IDENTITY (1,1),
		ErrorCode				INT	DEFAULT 0,
		ErrorMsg				VARCHAR (100))
--=====================================================================================================================
--	Initialize Variables
-----------------------------------------------------------------------------------------------------------------------
SELECT 	@intErrorCode 	= 0,
		@vchErrorMsg 	= '',
		@vchEventDesc 	= '',
		@vchUDPName	  	= '',
		@i				= 0
-----------------------------------------------------------------------------------------------------------------------
--	@MiscInfo table
-----------------------------------------------------------------------------------------------------------------------
INSERT INTO	@tblMiscInfo (	
			ErrorCode	,
			ErrorMsg	)
VALUES	(	@intErrorCode,
			@vchErrorMsg)
-----------------------------------------------------------------------------------------------------------------------
-- GET Table Ude for user defined events table
-----------------------------------------------------------------------------------------------------------------------
SELECT	@intUDETableId 	= TableId
FROM	dbo.Tables WITH(NOLOCK)
WHERE 	TableName 		= 'User_Defined_Events'	
-----------------------------------------------------------------------------------------------------------------------
-- Validate UdeTable Id 
-----------------------------------------------------------------------------------------------------------------------
IF	COALESCE(@intUDETableId, 0) = 0
BEGIN
	SELECT	@intErrorCode 	= 1,
			@vchErrorMsg 		= 'ERROR: User Defined Events could not be found in table "Table"' 
	GOTO	FINISHError
END
	-----------------------------------------------------------------------------------------------------------------------
WHILE @i < 6
BEGIN
	-----------------------------------------------------------------------------------------------------------------------
	-- Assign UDP Name
	-----------------------------------------------------------------------------------------------------------------------
	SELECT 	@vchUDPName = CASE @i
							WHEN 0	THEN 'SampleTestCountRequired'
							WHEN 1	THEN 'SampleTestCountComplete'
							WHEN 2	THEN 'SampleConformance'
							WHEN 3	THEN 'SampleTestCountOOL'
							WHEN 4	THEN 'SampleTestCountOOT'
							WHEN 5	THEN 'SampleTestCompleteDate'
							WHEN 6	THEN 'SampleTestTestedBy'							
							END,
			@vchValue	= CASE @i
							WHEN 0	THEN @p_intTestCountRequiredValue
							WHEN 1	THEN @p_intTestCountCompleteValue
							WHEN 2	THEN @p_intConformance
							WHEN 3	THEN @p_intTestCountOOL
							WHEN 4	THEN @p_intTestCountOOT
							WHEN 5	THEN CONVERT(VARCHAR, @p_dtmTestCompleteDate, 20)
							WHEN 6	THEN @p_vchTestedById
							END
	-----------------------------------------------------------------------------------------------------------------------
	-- GET UDP Id
	-----------------------------------------------------------------------------------------------------------------------
	SELECT 	@intUDPId = Table_Field_Id
	FROM 	dbo.Table_Fields WITH(NOLOCK)
	WHERE 	Table_Field_Desc = @vchUDPName
	-----------------------------------------------------------------------------------------------------------------------
	-- Validate UdeTable Id 
	-----------------------------------------------------------------------------------------------------------------------
	IF	COALESCE(@intUDPId, 0) = 0
	BEGIN
		SELECT	@intErrorCode 		= 1,
				@vchErrorMsg 		= 'ERROR: UDP ' + COALESCE(@vchUDPName, '')  + ' could not be found' 
		GOTO	FINISHError
	END
	-----------------------------------------------------------------------------------------------------------------------
	-- Validate if the value exists
	-----------------------------------------------------------------------------------------------------------------------
	-- 
	-----------------------------------------------------------------------------------------------------------------------
	IF (@vchValue IS NOT NULL)
	BEGIN
		IF EXISTS(	SELECT 	KeyId
					FROM 	dbo.Table_Fields_Values WITH(NOLOCK)
					WHERE	keyId = @p_intUDEId
						AND	Table_Field_Id = @intUDPId
						AND	TableId = @intUDETableId  )
		BEGIN
			-----------------------------------------------------------------------------------------------------------------------
			-- Update UDP Value
			-----------------------------------------------------------------------------------------------------------------------
			UPDATE 	dbo.Table_Fields_Values
			SET 	Value = @vchValue
			WHERE 	keyId = @p_intUDEId
				AND	Table_Field_Id = @intUDPId
				AND	TableId = @intUDETableId
		END
		ELSE
		BEGIN
			-----------------------------------------------------------------------------------------------------------------------
			-- INSERTS the new UDP value
			-----------------------------------------------------------------------------------------------------------------------
			INSERT INTO dbo.Table_Fields_Values(
							KeyId,
							Table_Field_Id,
							TableId,
							Value)
			VALUES (@p_intUDEId,
					@intUDPId,
					@intUDETableId,
					@vchValue)				
		END
	END
	SET @i = @i + 1
END
FINISHError:
IF	@intErrorCode > 0
BEGIN
	-------------------------------------------------------------------------------------------------------------------
	-- This error message is returned to the display and trapped by the C# code.
	-- The error message is currently displayed as an alert to inform the user something has failed with the sp
	-------------------------------------------------------------------------------------------------------------------
	UPDATE	@tblMiscInfo 
	SET	ErrorCode = @intErrorCode,
		ErrorMsg = @vchErrorMsg	
	-------------------------------------------------------------------------------------------------------------------
	-- RETURN Result set
	-------------------------------------------------------------------------------------------------------------------
	SELECT	*	FROM @tblMiscInfo
END
ELSE
BEGIN
	-------------------------------------------------------------------------------------------------------------------
	-- RS1: Miscellaneous result set
	-------------------------------------------------------------------------------------------------------------------
	SELECT	*	FROM @tblMiscInfo		
END
--=====================================================================================================================		
-- END SP
--=====================================================================================================================		
SET NOCOUNT OFF
RETURN





