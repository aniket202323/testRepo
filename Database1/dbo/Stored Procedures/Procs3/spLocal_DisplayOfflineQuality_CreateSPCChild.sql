
--=====================================================================================================================
-- 	Stored Procedure:	spLocal_DisplayOfflineQuality_CreateSPCChild
-- 	Athor:				Roberto del Cid
-- 	Date Created:		2007/02/09
-- 	Sp Type:			stored procedure
-- 	Editor Tab Sp:		4
-----------------------------------------------------------------------------------------------------------------------
-- DESCRIPTION: 
--	Creates one spc Child and returns a Miscellaneous table with the new VarId and VarDescription
-----------------------------------------------------------------------------------------------------------------------
-- CALLED BY:
-- LocalDisplayOfflineQuality.aspx
-----------------------------------------------------------------------------------------------------------------------
-- SP SECTIONS:
-- 1.	Declare Variables
-- 2.  	Initilize Values
-- 3.  	Validate sp parameters
-- 5.	Create SPC Child 
-----------------------------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
-- Revision		Date		Who					What
-- ========		====		===					====
-- 1.0			2007-04-13	Roberto Del Cid		Initial Development
-- 1.1			2007-05-11	Renata Piedmont		Code Review
-- 1.2			2007-12-05	Roberto Del Cid		Added logic to update children configuration table	
-----------------------------------------------------------------------------------------------------------------------
-- SAMPLE EXEC STATEMENT
-- NOTE:
-- EXEC	dbo.spLocal_DisplayOfflineQuality_CreateSPCChild	
-- 		@p_intParentSPCVarId				= 1296,
-- 		@p_intUserId						= 1
--		@p_intParentSPCVarId				= 2006,
--		@p_intUserId						= 1,
--		@p_intVarSpecId						= 1010,		
--		@p_dtmVarLookUpTimeStamp			= '2007-12-05',									
--		@p_intOldVariableCount				= 10
--=====================================================================================================================
CREATE  PROCEDURE dbo.spLocal_DisplayOfflineQuality_CreateSPCChild
		@p_intParentSPCVarId				INT,
		@p_intUserId						INT,
		@p_intVarSpecId						INT,		
		@p_dtmVarLookUpTimeStamp			DATETIME,									
		@p_intOldVariableCount				INT
AS
SET NOCOUNT ON
--=====================================================================================================================
--	Variable Declaration
-----------------------------------------------------------------------------------------------------------------------
-- INTEGERS
-----------------------------------------------------------------------------------------------------------------------
DECLARE	@intErrorCode					INT,
 		@intSPCChildrenCount			INT,
 		@intCVarOrder					INT, 
 		@intCDSId 						INT, 
 		@intCDataTypeId 				INT, 
 		@intCEventTypeId	  			INT, 
 		@intCPrecision  				INT,
 		@intCSPCVariableTypeId  		INT, 
 		@intCSpecId 					INT, 
 		@intCTestFreq 					INT,
 		@intVarId						INT
-----------------------------------------------------------------------------------------------------------------------
-- VARCHAR
-----------------------------------------------------------------------------------------------------------------------		
DECLARE	@vchErrorMsg					VARCHAR (1000),
		@vchParentName					VARCHAR (50),
		@vchSPCChildName				VARCHAR (50)		
-----------------------------------------------------------------------------------------------------------------------
-- TEMPORARY TABLES
-----------------------------------------------------------------------------------------------------------------------
-- Result Set 1
-- Returns miscellaneous information back to the display
-----------------------------------------------------------------------------------------------------------------------
DECLARE	@tblMiscInfo	TABLE	(
		RcdIdx					INT IDENTITY (1,1),
		ErrorCode				INT	DEFAULT 0,
		ErrorMsg				VARCHAR(1000),
		VarId					INT,
		VarDesc					VARCHAR(50))	
--=====================================================================================================================
-- INITIALIZE SP VARIABLES
--=====================================================================================================================
SELECT	@intErrorCode 	= 0,
		@vchErrorMsg 	= ''
--=====================================================================================================================
-- VALIDATE SP PARAMETERS
--=====================================================================================================================
-- VALIDATE Parent SPC VarId
-----------------------------------------------------------------------------------------------------------------------
SELECT	@p_intParentSPCVarId = COALESCE(@p_intParentSPCVarId, 0)	
IF	NOT EXISTS	(	SELECT	Var_Id
					FROM	dbo.Variables	WITH (NOLOCK)
					WHERE	Var_Id = @p_intParentSPCVarId)
BEGIN
	SELECT	@intErrorCode 	= 1,
			@vchErrorMsg 	= 'ERROR: ParentSPCVarId = ' + CONVERT(VARCHAR(25), @p_intParentSPCVarId) + ' doest not exist in the database. CALL IT!'
	GOTO	FINISHError
END
-----------------------------------------------------------------------------------------------------------------------
--	Validate User Id
-----------------------------------------------------------------------------------------------------------------------
IF	NOT EXISTS	(	SELECT	User_Id
					FROM	dbo.Users	WITH (NOLOCK)
					WHERE	User_Id = @p_intUserId)
BEGIN
	SELECT	@intErrorCode 	= 1,
			@vchErrorMsg 	= 'ERROR: User Id = ' + COALESCE(CONVERT(VARCHAR(25), @p_intUserId), '') + ' doest not exist in the database.'
	GOTO	FINISHError
END
--=====================================================================================================================
-- GET Spc Children Count
--=====================================================================================================================
SELECT 	@intSPCChildrenCount = COUNT(Var_Id)
FROM 	dbo.Variables	WITH (NOLOCK)
WHERE 	PVAR_id = @p_intParentSPCVarId
	AND	DS_Id = 2				
	AND	Is_Active = 1
--=====================================================================================================================
-- CREATE Spc Child
--=====================================================================================================================
--	GET the parent name
-----------------------------------------------------------------------------------------------------------------------
SELECT @vchParentName = Var_Desc
FROM dbo.Variables WITH(NOLOCK)
WHERE Var_Id = @p_intParentSPCVarId
-----------------------------------------------------------------------------------------------------------------------
-- Get Child Information
--	Business Rule:
--	All the SPC children share the same infomation, this code selects the first SPC child as a temmplate for the 
--	creation of the new child
-----------------------------------------------------------------------------------------------------------------------
SELECT	TOP 1
		@intCVarOrder 			= PUG_Order, 
		@intCDSId 				= DS_Id, 
		@intCDataTypeId 		= Data_Type_Id, 
		@intCEventTypeId 		= Event_Type, 
		@intCPrecision 			= Var_Precision,
		@intCSPCVariableTypeId 	= SPC_Group_Variable_Type_Id, 
		@intCSpecId 			= Spec_Id, 
		@intCTestFreq 			= Extended_Test_Freq
FROM dbo.Variables WITH(NOLOCK) 
WHERE PVar_Id = @p_intParentSPCVarId
	AND	DS_Id = 2				
	AND	Is_Active = 1			
-------------------------------------------------------------------------------------------------------------------
-- Get last SPC Child name
-------------------------------------------------------------------------------------------------------------------
--	Business Rule:
--	To create the spc variable is necessary to follow proficy behavior so the sp counts the children and makes the
--	new child desc the name of the parent plus the existing child count + 1
-------------------------------------------------------------------------------------------------------------------
SELECT @vchSPCChildName = @vchParentName + '-' + RIGHT('000' + CONVERT(VARCHAR(10), @intSPCChildrenCount + 1), 2)
-------------------------------------------------------------------------------------------------------------------
-- CREATE a new SPC Child
-------------------------------------------------------------------------------------------------------------------
EXEC 	dbo.spEM_CreateChildVariable				
		@Var_Desc 				= @vchSPCChildName,
		@PVar_Id				= @p_intParentSPCVarId,
		@VarOrder				= @intCVarOrder,
		@DS_Id					= @intCDSId,
		@DataType_Id			= @intCDataTypeId,
		@Event_Type_Id			= @intCEventTypeId,
		@Precision				= @intCPrecision,
		@SPCVariableType_Id		= @intCSPCVariableTypeId,
		@SpecId					= @intCSpecId,
		@TestFreq				= @intCTestFreq,
		@User_Id				= @p_intUserId,
		@Var_Id 				= @intVarId OUTPUT	
--=====================================================================================================================
-- Check SPC configuration
--=====================================================================================================================
-- First the sp checks if exists some configuration alredy set in Local_PG_Spec_UDP table 
--		a.If the configuration is not found for the spec the sp will insert the configuration for
--	 	each Characteristic that belongs to the same prop_id	
-----------------------------------------------------------------------------------------------------------------------
IF NOT EXISTS (SELECT Spec_Udp_id 
				FROM dbo.Local_PG_Spec_UDP	lsu	WITH (NOLOCK)
				WHERE	lsu.Spec_Id = @p_intVarSpecId
					--AND lsu.Char_Id = p_intVarCharId
					AND	@p_dtmVarLookUpTimeStamp >= lsu.Effective_Date
					AND	(@p_dtmVarLookUpTimeStamp < lsu.Expiration_Date
						OR	lsu.Expiration_Date IS NULL))
BEGIN
	-------------------------------------------------------------------------------------------------------------------
	-- a.If the configuration is not found for the spec the sp will insert the configuration for
	--	 each Characteristic that belongs to the same prop_id
	-------------------------------------------------------------------------------------------------------------------
	INSERT INTO dbo.Local_PG_Spec_UDP (							
					Spec_Id,
					Char_Id,
					Effective_Date,
					Expiration_Date,
					Sample_Number,
					Priority
				)
	SELECT 	sp.Spec_Id ,
			ch.Char_Id,
			'2007-01-01 00:00:00',
			NULL,
			@p_intOldVariableCount,
			0
	FROM	dbo.Specifications sp
			JOIN dbo.Characteristics ch ON sp.Prop_Id = ch.Prop_Id
	WHERE	sp.Spec_Id = @p_intVarSpecId		   
END
--=====================================================================================================================
--	RETURN RESULT SETS
--=====================================================================================================================
FINISHError:
-----------------------------------------------------------------------------------------------------------------------
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
	INSERT INTO @tblMiscInfo(ErrorCode,ErrorMsg, VarId, VarDesc) VALUES (0, '', @intVarId, @vchSPCChildName) 
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
