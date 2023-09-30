






--=====================================================================================================================
-- 	Stored Procedure:	spLocal_DisplayOfflineQuality_GetSPCChild
-- 	Athor:				Roberto del Cid
-- 	Date Created:		2007/02/09
-- 	Sp Type:			stored procedure
-- 	Editor Tab Sp:		4
-----------------------------------------------------------------------------------------------------------------------
-- DESCRIPTION: 
-- This Store Procedure has two options:
-- GET SPC Children: 
-- 	Returns the SPC Children data asked by the user but If the number is greater than
--	the number of variables that exists in the database then it returns the extra variables
--	needed with a VarId in consecutive minus numbers.
-- CREATE SPC Child:
--	Creates one spc Child and returns a Miscellaneous table with the new VarId and VarDescription
-----------------------------------------------------------------------------------------------------------------------
-- CALLED BY:
-- LocalDisplayOfflineQuality.aspx
-----------------------------------------------------------------------------------------------------------------------
-- SP SECTIONS:
-- 1.	Declare Variables
-- 2.  	Initilize Values
-- 3.  	Validate sp parameters
-- 4.	Get Spc Children
-- 5.	Create SPC Child 
-----------------------------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
-- Revision		Date		Who					What
-- ========		====		===					====
-- 1.0			2007-04-13	Roberto Del Cid		Initial Development
-----------------------------------------------------------------------------------------------------------------------
-- SAMPLE EXEC STATEMENT
-- NOTE:
-- SimpleSample will return 4 result sets: Miscellaneous, Sample Header and Details, variabls and SPC Child
-- EXEC	dbo.spLocal_DisplayOfflineQuality_GetSPCChild	
-- 		@p_vchOutputType					= 'GetChildren',		
-- 		@p_intParentSPCVarId				= 1296,
-- 		@p_intChildCount					= 10,
-- 		@p_intUserId						= 1,
-- 		@p_dtmParentUDEEndTime 				= '2007-02-16 14:54:18.920', 	
-- 		@p_intParentProdId 					= 1,			
-- 		@p_dtmParentLookUpTimeStamp			= '2007-02-14 12:00:00.000',	
-- 		@p_dtmParentProdChangeTimesTamp 	= '2007-02-14 11:05:00.000'
--=====================================================================================================================
CREATE  PROCEDURE dbo.spLocal_DisplayOfflineQuality_GetSPCChild
		@p_vchOutputType					VARCHAR(25),		
		@p_intParentSPCVarId				INT,
		@p_intChildCount					INT,
		@p_intUserId						INT,
		@p_dtmParentUDEEndTime 				DATETIME , 	
 		@p_intParentProdId 					INT		 ,			
 		@p_dtmParentLookUpTimeStamp			DATETIME ,	
 		@p_dtmParentProdChangeTimesTamp 	DATETIME 		
AS
SET NOCOUNT ON
--=====================================================================================================================
--	Variable Declaration
-----------------------------------------------------------------------------------------------------------------------
-- INTEGERS
-----------------------------------------------------------------------------------------------------------------------
DECLARE	@intErrorCode					INT,
		@intSPCChildrenCount			INT,
		@intNewChildrenCount			INT,
		@i								INT,
		@CVarOrder						INT, 
		@CDSId 							INT, 
		@CDataTypeId 					INT, 
		@CEventTypeId	  				INT, 
		@CPrecision  					INT,
		@CSPCVariableTypeId  			INT, 
		@CSpecId 						INT, 
		@CTestFreq 						INT,
		@VarId							INT,
		@intSPCResultCount				INT
-----------------------------------------------------------------------------------------------------------------------
-- VARCHAR
-----------------------------------------------------------------------------------------------------------------------		
DECLARE	@vchErrorMsg					VARCHAR (1000),
		@vchParentName					VARCHAR (50),
		@vchSPCChildName				VARCHAR (50)		
-----------------------------------------------------------------------------------------------------------------------
-- NVARCHAR
-----------------------------------------------------------------------------------------------------------------------		
DECLARE @nvchSQLCommand					NVARCHAR(4000)
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
-----------------------------------------------------------------------------------------------------------------------
-- Result Set 2
-- Table stores SPC child variables result set
-----------------------------------------------------------------------------------------------------------------------	
CREATE TABLE	#SPCChildVariables (
				RcdIdx					INT UNIQUE IDENTITY,
				PVarId					INT,
				VarId					INT,
				VarDesc					VARCHAR(50),
				VarDataTypeId			INT,	
				VarPrecision			INT,
				VarUDEEndTime    		DATETIME,
				VarProdId				INT,
				VarSpecActivation		INT,
				VarLookUpTimeStamp		DATETIME,
				VarProdChangeTimeStamp 	DATETIME,
				TestId					INT,
				TestResult				VARCHAR(25),
				UEL						VARCHAR(25),
				URL						VARCHAR(25),
				UWL						VARCHAR(25),
				UUL						VARCHAR(25),
				Target					VARCHAR(25),
				LUL						VARCHAR(25),
				LWL						VARCHAR(25),
				LRL						VARCHAR(25),
				LEL						VARCHAR(25),
				MiscColumn				VARCHAR(25),
				VarRelationNumber		INT)

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
-- GET Spc Children
--=====================================================================================================================
	IF (@p_vchOutputType = 'GetChildren')
	BEGIN
		-----------------------------------------------------------------------------------------------------------------------
		IF @intSPCChildrenCount > @p_intChildCount	
		BEGIN
			SELECT @intSPCChildrenCount = @p_intChildCount
		END
		-----------------------------------------------------------------------------------------------------------------------
		IF @intSPCChildrenCount < 1
		BEGIN
			SELECT	@intErrorCode 	= 1,
					@vchErrorMsg 	= 'ERROR: ParentSPCVarId = ' + CONVERT(VARCHAR(25), @p_intParentSPCVarId) + ' is not a SPC variable.'
			GOTO	FINISHError	
		END	 
	---------------------------------------------------------------------------------------------------------------
	-- GET the corresponding SPC children
	---------------------------------------------------------------------------------------------------------------
	SET	@nvchSQLCommand	 =	'	SELECT	TOP	' + CONVERT(VARCHAR(25), @intSPCChildrenCount)
						+		'			v.PVar_Id,		'
						+		'			v.Var_Id,			'
						+		'			v.Var_Desc,		'
						+		'			v.Data_Type_Id,	'
						+		'			v.Var_Precision,	'
						+		'			v.SA_Id			'
						+		'	FROM	dbo.Variables v	WITH(NOLOCK)	'	
						+		'	JOIN	dbo.Tests	t	WITH (NOLOCK)	'
						+		'			ON	v.Var_Id = t.Var_Id			'
						+		'			AND	t.Canceled <> 1				'
						+		'			AND	t.Result IS NOT NULL		'
						+		'			AND	t.Result_On = @PrmUdeEndTime'
						+		'	WHERE 	PVar_Id = @PrmSPCVarId			'
						+		'	AND v.DS_Id = 2	'
						+		'	ORDER BY v.Var_Id'		
	---------------------------------------------------------------------------------------------------------------
	INSERT INTO #SPCChildVariables (	
				PVarId,
				VarId,
				VarDesc,														
				VarDataTypeId,
				VarPrecision,
				VarSpecActivation)
	EXECUTE sp_ExecuteSQL 	@SQLString = @nvchSQLCommand,
						  	@ParmDefinition = N'@PrmSPCVarId INT, @PrmUdeEndTime DATETIME',
							@PrmSPCVarId = @p_intParentSPCVarId, 
						@PrmUdeEndTime = @p_dtmParentUDEEndTime 
	---------------------------------------------------------------------------------------------------------------
	-- GET The number of Children returned in the last insert
	---------------------------------------------------------------------------------------------------------------
	SELECT @intSPCResultCount = COUNT(VarId)
	FROM #SPCChildVariables
	WHERE PVarId = @p_intParentSPCVarId
	-------------------------------------------------------------------------------------------------------------------
	-- IF the last query don't return all the variables asked. The sp check if exist any variable
	-- without test value to fill it.
	-------------------------------------------------------------------------------------------------------------------
	IF (@intSPCChildrenCount > @intSPCResultCount)	
	BEGIN		
		---------------------------------------------------------------------------------------------------------------
		-- GET the corresponding SPC children
		---------------------------------------------------------------------------------------------------------------
		SET	@nvchSQLCommand	 =	'SELECT	TOP	' + CONVERT(VARCHAR(25), @intSPCChildrenCount - @intSPCResultCount)
						+		'	v.PVar_Id,	'	
						+		'	v.Var_Id,	'		
						+		'	v.Var_Desc,	'	
						+		'	v.Data_Type_Id,	'
						+		'	v.Var_Precision,'
						+		'	v.SA_Id		'	
						+		'FROM	dbo.Variables v	WITH(NOLOCK) '
						+		'WHERE 	PVar_Id = @PrmSPCVarId		 '	
						+		'AND NOT EXISTS (SELECT t.Var_Id	 '
						+		'				FROM dbo.Tests	t	WITH(NOLOCK)	'
						+		'				WHERE t.Var_Id = v.Var_Id			'
						+		'					AND	t.Canceled <> 1				'
						+		'					AND	t.Result IS NOT NULL		'	
						+		'					AND	t.Result_On = @PrmUdeEndTime)	'
						+		'AND v.DS_Id = 2 	'
						+		'ORDER BY v.Var_Id 	'
		---------------------------------------------------------------------------------------------------------------
		INSERT INTO #SPCChildVariables (	
					PVarId,
					VarId,
					VarDesc,														
					VarDataTypeId,
					VarPrecision,
					VarSpecActivation)
 		EXECUTE sp_ExecuteSQL 	@SQLString = @nvchSQLCommand,
 							  	@ParmDefinition = N'@PrmSPCVarId INT, @PrmUdeEndTime DATETIME',
 								@PrmSPCVarId = @p_intParentSPCVarId, 
								@PrmUdeEndTime = @p_dtmParentUDEEndTime 
	END		
	-------------------------------------------------------------------------------------------------------------------
	-- UPDATE SPC child product and spec lookup information
	-------------------------------------------------------------------------------------------------------------------
	UPDATE	cv	
	SET	cv.VarUDEEndTime 			= @p_dtmParentUDEEndTime,
		cv.VarProdId 				= @p_intParentProdId,
		cv.VarLookUpTimeStamp		= @p_dtmParentLookUpTimeStamp,
		cv.VarProdChangeTimesTamp 	= @p_dtmParentProdChangeTimesTamp
	FROM	#SPCChildVariables	cv
	-------------------------------------------------------------------------------------------------------------------
	-- GET the SPC child test values
	-------------------------------------------------------------------------------------------------------------------
	UPDATE #SPCChildVariables 												
	SET	TestId = Test_Id,
		TestResult = Result	
	FROM	#SPCChildVariables	cv
		JOIN	dbo.Tests t		WITH(NOLOCK)	
								ON	cv.VarId = t.Var_Id
									AND t.Result_On = cv.VarUDEEndTime
									AND t.Canceled <> 1		
	-------------------------------------------------------------------------------------------------------------------					
	--	Update Specifications where specification activation is equal to
	--	Inmediate
	--	Note: VarLookUpTimeStamp is the COALESCE(Production Event TimeStamp, UDE End Time)
	-------------------------------------------------------------------------------------------------------------------					
	UPDATE #SPCChildVariables
	SET	UEL		= vsp.U_Entry,
		URL		= vsp.U_Reject,
		UWL		= vsp.U_Warning,
		UUL		= vsp.U_User,
		Target	= vsp.Target,					
		LUL		= vsp.L_User,
		LWL		= vsp.L_Warning,
		LRL		= vsp.L_Reject,
		LEL		= vsp.L_Entry 
	FROM	#SPCChildVariables sv
		JOIN	dbo.Var_Specs vsp	WITH(NOLOCK)	
									ON	sv.VarId = vsp.Var_Id 
										AND	sv.VarProdId = vsp.Prod_Id 
										AND  sv.VarLookUpTimeStamp >= vsp.Effective_Date
										AND  (sv.VarLookUpTimeStamp < vsp.Expiration_Date 
							 				OR vsp.Expiration_Date is NULL)	
										AND  sv.VarSpecActivation = 1
	--------------------------------------------------------------------------------------------------------------					
	--Update Specifications where specification activation is equal to
	--Product Change
	--------------------------------------------------------------------------------------------------------------					
	UPDATE #SPCChildVariables
	SET	UEL		= vsp.U_Entry,
		URL		= vsp.U_Reject,
		UWL		= vsp.U_Warning,
		UUL		= vsp.U_User,
		Target	= vsp.Target,					
		LUL		= vsp.L_User,
		LWL		= vsp.L_Warning,
		LRL		= vsp.L_Reject,
		LEL		= vsp.L_Entry 
	FROM	#SPCChildVariables sv
		JOIN	dbo.Var_Specs vsp	WITH(NOLOCK)	
									ON	sv.VarId = vsp.Var_Id 
										AND	sv.VarProdId = vsp.Prod_Id 
										AND sv.VarProdChangeTimeStamp >= vsp.Effective_Date
										AND (sv.VarProdChangeTimeStamp < vsp.Expiration_Date 
											OR vsp.Expiration_Date is NULL)	
										AND sv.VarSpecActivation = 2
	-----------------------------------------------------------------------------------------------------------------------
	--Check if the sp needs to return new spc children
	-----------------------------------------------------------------------------------------------------------------------
	IF (@p_intChildCount > @intSPCChildrenCount)
	BEGIN
		SELECT 	@intNewChildrenCount = @p_intChildCount - @intSPCChildrenCount,
				@i = 0
		-------------------------------------------------------------------------------------------------------------------
		-- Creates new children
		-------------------------------------------------------------------------------------------------------------------
		-- It copy the information from any Child found before
		-------------------------------------------------------------------------------------------------------------------		
		WHILE @i < 	@intNewChildrenCount
		BEGIN
			INSERT INTO #SPCChildVariables(						
						PVarId					,
						VarId					,
						VarDesc					,
						VarDataTypeId			,	
						VarPrecision			,
						VarUDEEndTime    		,
						VarProdId				,
						VarSpecActivation		,
						VarLookUpTimeStamp		,
						VarProdChangeTimeStamp 	,
						TestId					,
						TestResult				,
						UEL						,
						URL						,
						UWL						,
						UUL						,
						Target					,
						LUL						,
						LWL						,
						LRL						,
						LEL						)
			SELECT TOP 1 
						PVarId					,
						-@i - 1					,
						''						,
						VarDataTypeId			,	
						VarPrecision			,
						VarUDEEndTime    		,
						VarProdId				,
						VarSpecActivation		,
						VarLookUpTimeStamp		,
						VarProdChangeTimeStamp 	,
						NULL					,
						NULL				,
						UEL						,
						URL						,
						UWL						,
						UUL						,
						Target					,
						LUL						,
						LWL						,
						LRL						,
						LEL											
			FROM #SPCChildVariables tblSPC			
			SET @i = @i + 1
		END
	END
END
--=====================================================================================================================
-- CREATE Spc Child
--=====================================================================================================================
IF (@p_vchOutputType = 'CreateChild')
BEGIN
	SELECT @vchParentName = Var_Desc
	FROM dbo.Variables WITH(NOLOCK)
	WHERE Var_Id = @p_intParentSPCVarId
	
	PRINT '@vchParentName =' + @vchParentName
	-------------------------------------------------------------------------------------------------------------------
	-- Get Child Information
	-------------------------------------------------------------------------------------------------------------------
	SELECT TOP 1
		@CVarOrder 				= pug_order, 
		@CDSId 					= ds_Id, 
		@CDataTypeId 			= data_type_Id, 
		@CEventTypeId 			= event_type, 
		@CPrecision 			= var_precision,
		@CSPCVariableTypeId 	= spc_group_variable_type_id, 
		@CSpecId 				= spec_id, 
		@CTestFreq 				= Extended_Test_Freq
	FROM dbo.Variables WITH(NOLOCK) 
	WHERE PVar_Id = @p_intParentSPCVarId
		AND	DS_Id = 2				
		AND	Is_Active = 1			
	-------------------------------------------------------------------------------------------------------------------
	-- Get last SPC Child name
	-------------------------------------------------------------------------------------------------------------------
	--	To create the spc variable is necessary to follow proficy behavior So the sp takes the 
	--	last Child found (SPC vars has a least one) and copy the information to create the new 
	--	spc child.
	-------------------------------------------------------------------------------------------------------------------
	PRINT '@intSPCChildrenCount = ' + CONVERT(VARCHAR,@intSPCChildrenCount)
	SELECT @vchSPCChildName = @vchParentName + '-' + RIGHT('000' + CONVERT(VARCHAR(10), @intSPCChildrenCount + 1),2)
	PRINT '@vchSPCChildName = ' + @vchSPCChildName
	-------------------------------------------------------------------------------------------------------------------
	-- CREATE a new SPC Child
	-------------------------------------------------------------------------------------------------------------------
	EXEC 	dbo.spEM_CreateChildVariable				
			@Var_Desc 				= @vchSPCChildName,
			@PVar_Id				= @p_intParentSPCVarId,
			@VarOrder				= @CVarOrder,
			@DS_Id					= @CDSId,
			@DataType_Id			= @CDataTypeId,
			@Event_Type_Id			= @CEventTypeId,
			@Precision				= @CPrecision,
			@SPCVariableType_Id		= @CSPCVariableTypeId,
			@SpecId					= @CSpecId,
			@TestFreq				= @CTestFreq,
			@User_Id				= @p_intUserId,
			@Var_Id 				= @VarId OUTPUT	
END
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
	INSERT INTO @tblMiscInfo(ErrorCode,ErrorMsg, VarId, VarDesc) VALUES (0, '', @VarId, @vchSPCChildName) 
	-------------------------------------------------------------------------------------------------------------------
	-- RS1: Miscellaneous result set
	-------------------------------------------------------------------------------------------------------------------
	SELECT	*	FROM @tblMiscInfo
	-------------------------------------------------------------------------------------------------------------------
	-- RS2: Sample Header and Sample Detail result set
	-------------------------------------------------------------------------------------------------------------------
	SELECT	*	FROM	#SPCChildVariables
	ORDER BY PVarId ASC, TestResult DESC, VarId ASC
END
-----------------------------------------------------------------------------------------------------------------------
-- Drop temporary table
-----------------------------------------------------------------------------------------------------------------------
DROP TABLE	#SPCChildVariables
--=====================================================================================================================		
-- END SP
--=====================================================================================================================		
SET NOCOUNT OFF
RETURN







