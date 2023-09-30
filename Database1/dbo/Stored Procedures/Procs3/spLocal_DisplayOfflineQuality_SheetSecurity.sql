
--=====================================================================================================================
-- 	Stored Procedure:	spLocal_DisplayOfflineQuality_SheetSecurity
-- 	Athor:				Roberto del Cid
-- 	Date Created:		2007-03-29
-- 	Sp Type:			stored procedure
-- 	Editor Tab Sp:		4
-----------------------------------------------------------------------------------------------------------------------
--	DESCRITION: 
-- 	The purpose of this stored procedure is to return the sheet security to the login page for the display.
-- 	The sp will return two result sets @tblMiscInfo and @tblSecurityPage
-----------------------------------------------------------------------------------------------------------------------
-- CALLED BY:
-- LocalDisplayOfflineQuality.aspx
-----------------------------------------------------------------------------------------------------------------------
-- FUNCTIONS AND SUB-STORED PROCEDURES:
-- NONE
-----------------------------------------------------------------------------------------------------------------------
-- SP SECTIONS:
-- 1.	Declare Variables
-- 2.  	Initilize Values
-- 3.  	Validate sp parameters
-- 4.  	GET Display Security
-- 5.  	ResultSet1	>>> Misc Info
-- 6.	ResultSet2	>>> Page security
-----------------------------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
-- Revision		Date		Who					What
-- ========		====		===					====
-- 1.0			2007-03-29	Roberto Del Cid		Initial Development
-- 1.1			2007-03-29	Renata Piedmont		Code Review
-- 1.2			2007-06-04	Renata Piedmont		Added code to support sheet group security
-----------------------------------------------------------------------------------------------------------------------
-- SAMPLE EXEC STATEMENT
-- EXEC	dbo.spLocal_DisplayOfflineQuality_SheetSecurity
-- @p_intSheetId		= 100,
-- @p_intUserId			= 0
--=====================================================================================================================
CREATE	PROCEDURE dbo.spLocal_DisplayOfflineQuality_SheetSecurity
		@p_intSheetId			INT,
		@p_intUserId			INT 			
AS
SET NOCOUNT ON
--=====================================================================================================================
--	Variable Declaration
-----------------------------------------------------------------------------------------------------------------------
-- INTEGERS
-----------------------------------------------------------------------------------------------------------------------
 DECLARE	@intErrorCode				INT,
			@intGroupId					INT,
			@intAccessId				INT
-----------------------------------------------------------------------------------------------------------------------
-- VARCHAR
-----------------------------------------------------------------------------------------------------------------------		
 DECLARE	@vchErrorMsg				VARCHAR(1000),
			@vchSheetName				VARCHAR(50),
			@vchAccess					VARCHAR(25)   
-----------------------------------------------------------------------------------------------------------------------
-- TEMPORARY TABLES
-----------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------
-- Result Set 1
-- Returns miscellaneous information back to the display
-----------------------------------------------------------------------------------------------------------------------
DECLARE	@tblMiscInfo	TABLE	(
		RcdIdx				INT IDENTITY (1,1),
		GroupId				INT, 		
		AccessId			INT,						
		Access				VARCHAR(25),
		ErrorCode			INT	DEFAULT 0,
		ErrorMsg			VARCHAR(1000))
--=====================================================================================================================
-- INITIALIZE SP VARIABLES
-----------------------------------------------------------------------------------------------------------------------
SELECT	@intErrorCode 	= 0,
		@vchErrorMsg 	= ''
-----------------------------------------------------------------------------------------------------------------------
-- @MiscInfo table
-----------------------------------------------------------------------------------------------------------------------
INSERT INTO	@tblMiscInfo (	
			ErrorCode	,
			ErrorMsg	)
VALUES	(	@intErrorCode,
			@vchErrorMsg)
--=====================================================================================================================
-- VALIDATE SP PARAMETERS
-----------------------------------------------------------------------------------------------------------------------
SELECT	@p_intSheetId = COALESCE(@p_intSheetId, 0)
IF	NOT EXISTS	(	SELECT	Sheet_Id
					FROM	dbo.Sheets	WITH (NOLOCK)
					WHERE	Sheet_Id = @p_intSheetId)
BEGIN
	SELECT	@intErrorCode 	= 1,
			@vchErrorMsg 		= 'ERROR: Sheet_Id = ' + CONVERT(VARCHAR(25), @p_intSheetId) + ' doest not exist in the database. CALL IT!'
	GOTO	FINISHError
END
ELSE
BEGIN
	SELECT	@vchSheetName = Sheet_Desc
	FROM	dbo.Sheets
	WHERE	Sheet_Id = @p_intSheetId
END
-----------------------------------------------------------------------------------------------------------------------
--	Validate User Id
-----------------------------------------------------------------------------------------------------------------------
IF	NOT EXISTS	(	SELECT	User_Id
					FROM	dbo.Users	WITH (NOLOCK)
					WHERE	User_Id = @p_intUserId)
BEGIN
	SELECT	@intErrorCode 	= 1,
			@vchErrorMsg 		= 'ERROR: User Id = ' + COALESCE(CONVERT(VARCHAR(25), @p_intUserId), '') + ' doest not exist in the database.'
	GOTO	FINISHError
END
--=====================================================================================================================
-- GET PAGE SECURITY
-----------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------
--	Gets the groupId, this field shows the security associated to the sheet
--	Business Rule:
--	Sheet security can be assigned to an individual sheet or to a sheet group
-----------------------------------------------------------------------------------------------------------------------
SELECT 	@intGroupId = COALESCE(s.Group_Id, sg.Group_Id)
FROM	dbo.Sheets s WITH(NOLOCK)
	JOIN	dbo.Sheet_Groups sg	WITH (NOLOCK)
								ON	s.Sheet_Group_Id = sg.Sheet_Group_Id
WHERE	s.Sheet_Id = @p_intSheetId	
-----------------------------------------------------------------------------------------------------------------------
-- CHECK for NULLS
-----------------------------------------------------------------------------------------------------------------------
SET @intGroupId = COALESCE(@intGroupId, 0)
-----------------------------------------------------------------------------------------------------------------------
-- If the sheet belongs to a specific security group the sp will return the security
-- access asociated to the user.
-----------------------------------------------------------------------------------------------------------------------
IF (@intGroupId > 0)
BEGIN
	SELECT	@intGroupId 	= us.Group_Id,
			@intAccessId 	= acl.Al_Id,		
			@vchAccess		= acl.AL_Desc
	FROM	dbo.User_Security us		WITH(NOLOCK)													
		JOIN	dbo.Users usr         	WITH(NOLOCK)	
										ON usr.User_Id = us.User_ID 
											AND usr.User_Id = @p_intUserId
		JOIN dbo.Access_Level acl 		WITH(NOLOCK)	
										ON acl.Al_Id = us.Access_Level
	WHERE us.Group_Id = @intGroupId
	-------------------------------------------------------------------------------------------------------------------
	-- UPDATE @tblMiscInfo
	-------------------------------------------------------------------------------------------------------------------	
	UPDATE	@tblMiscInfo
	SET	GroupId 	= @intGroupId,
		AccessId 	= @intAccessId,
		Access		= @vchAccess
	WHERE	RcdIdx = 1
END
-----------------------------------------------------------------------------------------------------------------------
-- If the sheet Doesn't belong to a specific security group the sp will return manager
-- access as default
-----------------------------------------------------------------------------------------------------------------------
ELSE 
BEGIN
	UPDATE	@tblMiscInfo
	SET	Access = 'Manager'
	WHERE	RcdIdx = 1
END
--=====================================================================================================================
-- RETURN Result sets
--=====================================================================================================================
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
	WHERE	RcdIdx = 1
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
