--==============================================================================================================================================
-- Store Procedure: 	fnLocal_PG_RTCR_Mandatory_Tests
-- Author:				Wendy Suen
-- Date Created:		2017-05-02
-- Sp Type:				Function
-- Editor Tab Spacing: 	4	
------------------------------------------------------------------------------------------------------------------------------------------------
-- DESCRIPTION: This function returns the result set of many tests. 0 = Pass, 1 = Fail (or missing mandatory), 2 = Missing, not mandatory
------------------------------------------------------------------------------------------------------------------------------------------------
--	CALLED BY:
--	Most stored procedures in the "RTCR" suite. Function that performs the consistent grading of all test results. Requires population of
--	Production Starts (thus - Will NOT Work on any MOQ1 line!).
------------------------------------------------------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
------------------------------------------------------------------------------------------------------------------------------------------------
-- Revision		Date		Who					What
-- ========		====		===					====
--	1.0			2017-05-02	Wendy Suen			Initial Development
--	1.1			2017-08-01	Santosha Spickard	Update for when there are no specs, added grant execute and drop function.
--	1.2			2017-10-31	Santosha Spickard	Update for when there are no specs, re-added grant execute again. 
--	1.3			2017-11-02	Santosha Spickard	Added non mandatory no tests functionality. 
--	1.4			2017-11-20	Santosha Spickard	Added in fix for T
--	1.5			2018-08-27	Alex Klusmeyer		Limited Time range such that report cannot run into the future, pulling false negatives for
--												tests scheduled but not yet taken. Formatting improved throughout.
--	1.6			2018-10-04	Alex Klusmeyer		Corrected Phrase Order Grading To Allow For L_Warning To Count As Pass Criteria (TAMU)
--												NOT just letter placed in Target
--	1.7			2018-10-04	Alex Klusmeyer		Don't Always Return Something. That's just not right.
--	1.8			2019-03-13	Olivier Sirois		Optimize running time of function (Var_Specs retrieval)
--	1.9			2019-04-03	Alex Klusmeyer		Report - but fail - any test result entered in a non-numeric phrase variable that is not a
--												valid phrase per the data type (flagged by phrase order = 999).
--	1.10		2019-05-03	Alex Klusmeyer		Correction to 1.9, make sure NULL results (misses) are not overwritten by logic to catch
--												ungradable phrases.
--	1.11		2019-05-15	Olivier Sirois		Added Comment and Sheet_Desc fields to resultset.
--	1.12		2019-05-28	Olivier Sirois		Added filtering when finding Sheet_Desc to only retrieve sheets that are "Autolog" types.
--	1.13		2019-06-13	Aaron Perreault		Added checks for VarId if there are no prod units, added coalesces to prevent null values
--	1.14		2019-07-10	Alex Klusmeyer		Validated changes for overhaul.
--	1.20		2019-07-22	Alex Klusmeyer		Change executable to be inline w/ reworked suite where Variable Id and (correctly looked up) time
--												range are provided based on lookup logic in calling stored procedures. Grading function now has
--												no "plant model" or "production execution" look-up logic independent of the calling SP.
--												Reduced function to pure grading logic flow.
--	1.25		2019-10-24	Alex Klusmeyer		Non-Mandatory Misses Receive Different Grading Flag then Non-Mandatory Failures.
--	1.30		2019-12-10	Alex Klusmeyer		Ensure rapid Production Starts changes does not result in duplication of test results via
--												multiple, identical, Var_Specs entries.
--	1.40		2020-02-21	Alex Klusmeyer		Site Parameter Spec Grading Setting backwards, such that "1" should allow = to as pass, 
--												and "0" should not.
--	1.50		2020-02-21	Alex Klusmeyer		Allow TAMU Results to Grade Without Any Var Specs Configured.
--	1.60		2020-06-06	Alex Klusmeyer		Do not return UCC-Activities linked results when target duration of Activity has not been exceeded.
--												These results are only reported if taken until this time limit is reached. After it is reached, 
--												untaken results are reported as missing.
--	1.70		2020-06-09	Alex Klusmeyer		Change 1.60 to use activity status instead of target duration (site request).
--	1.80		2020-06-10	Alex Klusmeyer		Expand 1.70 rule to suppress any results (taken or untaken) related to an incomplete activity.
--	1.90		2020-06-15	Alex Klusmeyer		Enhance Activities Status Query to use UDE-Id to Test Tables link. This removes issues when multiple
--												Activities share same Unit + Result On time.
--	2.00		2020-09-24	Alex Klusmeyer		Performance enhancements for querying Activities table.
--	2.10		2020-09-28	Alex Klusmeyer		Must Return Combined Activity + Test Comments for Any Relevant Test Result Found By This Function.
--  2.11		2021-01-22  Arido Software		Use table instead of view.
------------------------------------------------------------------------------------------------------------------------------------------------
-- SAMPLE EXEC STATEMENT
------------------------------------------------------------------------------------------------------------------------------------------------
/*
	SELECT	*	
	FROM	dbo.fnLocal_PG_RTCR_Mandatory_Tests (
													750							,
													'2018-09-26 07:00:00.000'	,
													'2018-09-27 07:00:00.000'
												)
*/
--==============================================================================================================================================
CREATE FUNCTION	[dbo].[fnLocal_PG_RTCR_Mandatory_Tests]
(
	@p_VarId				INT			,
	@p_StartTime			DATETIME	,
	@p_EndTime				DATETIME 
)	
RETURNS 
@RTCRTests TABLE
(
	RcdIdx				INT IDENTITY (1,1)	, 
	SQLErrorCode		INT					,
	SQLErrorMessage		VARCHAR(2000)		,
	VarId				INT					,
	PUId				INT					,
	TestName			NVARCHAR(510)		,
	UoM					VARCHAR(15)			,
	ResultOn			DATETIME			,
	Result				VARCHAR(25)			,
	ProdId				INT					,
	SAId				INT					,
	IsVarNumeric		INT					,
	U_Entry				VARCHAR(25)			,
	U_Reject			VARCHAR(25)			,
	U_User				VARCHAR(25)			,
	U_Warning			VARCHAR(25)			,
	L_Entry				VARCHAR(25)			,
	L_Reject			VARCHAR(25)			,
	L_User				VARCHAR(25)			,
	L_Warning			VARCHAR(25)			,
	[Target]			VARCHAR(25)			,
	IsMandatory			INT					,
	PassCheck			INT	DEFAULT(0)		,
	MajorGroupHasFail	INT	DEFAULT(0)		,
	MinorGroupHasFail	INT	DEFAULT(0)		,
	TestHasFail			INT DEFAULT(0)		,
	OperatorORUnit		VARCHAR(100)		,
	Comment				VARCHAR(MAX)		,
	SheetDesc			VARCHAR(50)	
)
------------------------------------------------------------------------------------------------------------------------------------------------
BEGIN
	--==========================================================================================================================================
	--	Declare Function Tables
	--==========================================================================================================================================
	DECLARE	@ProdUnits	TABLE
	(
		RcdIdx			INT IDENTITY(1,1),
		PUID			INT
	)

	DECLARE	@TestVariables	TABLE
	(
		RcdIdx			INT IDENTITY(1,1)	,
		VarId			INT					,
		PUId			INT					,
		IsPhraseLocked	INT					,
		TestName		NVARCHAR(510)		,
		EventTestId		INT					,
		UoM				VARCHAR(15)			,
		ResultOn		DATETIME			,
		Result			VARCHAR(25)			,
		Result_Order	INT					,
		ProdId			INT					,
		SAId			INT					,
		U_Entry			VARCHAR(25)			,
		U_Reject		VARCHAR(25)			,
		U_User			VARCHAR(25)			,
		U_Warning		VARCHAR(25)			,
		L_Entry			VARCHAR(25)			,
		L_Reject		VARCHAR(25)			,
		L_User			VARCHAR(25)			,
		L_Warning		VARCHAR(25)			,
		L_Warning_Order	INT					,
		[Target]		VARCHAR(25)			,
		Target_Order	INT					,
		MaxPassPhrase	INT DEFAULT(0)		,
		Entry_by		VARCHAR(100)		,
		OperatorORUnit	VARCHAR(100)		,
		TestComment		VARCHAR(MAX)		,
		ActComment		VARCHAR(MAX)		,
		OverdueComment	VARCHAR(MAX)		,
		SkipComment		VARCHAR(MAX)		,
		SheetDesc		VARCHAR(50)			,
		ActId			INT					,
		ActivityStatus	INT
	)

	DECLARE	@IsVarNumeric	TABLE
	(
		RcdIdx			INT IDENTITY(1,1)	,
		VarId			INT					,
		PUId			INT					,
		IsVarNumeric	INT					,
		MaxPhraseValue	VARCHAR(25)			,
		MaxPhraseOrder	INT					,
		IsPhraseLocked	INT					,
		DTId			INT					,
		SAId			INT					, 
		EngUnits		VARCHAR(15)			,
		VarDesc			NVARCHAR(510)		,
		IsMandatory		INT
	)

	DECLARE @VarSpecs TABLE
	(
		Id				INT	IDENTITY(1,1)	,
		VSId			INT					,
		EffectiveDate	DATETIME			,
		ExpirationDate	DATETIME			, 
		L_Control		VARCHAR(100)		, 
		L_Entry			VARCHAR(100)		, 
		L_Reject		VARCHAR(100)		, 
		L_User			VARCHAR(100)		, 
		L_Warning		VARCHAR(100)		, 
		[Target]		VARCHAR(100)		, 
		U_Control		VARCHAR(100)		,
		U_Entry			VARCHAR(100)		, 
		U_Reject		VARCHAR(100)		,
		U_User			VARCHAR(100)		,
		U_Warning		VARCHAR(100)		,
		VarId			INT					,
		ProdId			INT
	)

	DECLARE @ProductionStarts TABLE
	(	
		StartTime	DATETIME		, 
		EndTime		DATETIME		,
		ProdId		INT				,
		PUID		INT				, 
		VarID		INT				,
		SAID		INT				,
		EngUnits	VARCHAR(100)	,
		VarDesc		VARCHAR(100)
	)

	DECLARE	@TableFields	TABLE
	(
		Id					INT	IDENTITY(1,1)	,
		TableFieldDesc		VARCHAR(50)			,
		TableId				INT					,
		TableFieldId		INT
	)

	DECLARE	@SheetTypes	TABLE
	(
		Id					INT	IDENTITY(1,1)	,
		SheetTypeDesc		VARCHAR(50)			,
		SheetTypeId			INT
	)
	--==========================================================================================================================================
	--	Declare Function Variables
	--==========================================================================================================================================
	DECLARE
	@MissingUDP								VARCHAR(50)	,
	@MandatoryTFId							INT			,
	@RelevantTFId							INT			,
	@SpecSetting							INT			,
	@MandatoryNoDataFlag					INT			,
	@AutologTimeBasedSheetTypeId			INT			,
	@AutologProductionEventSheetTypeId		INT			,
	@AutologUserDefinedEventSheetTypeId		INT
	--==========================================================================================================================================
	--	Declare Constants
	--==========================================================================================================================================
	DECLARE
	@VARIABLE_TABLE_ID				INT				,
	@PG_UDP_VARIABLES_MANDATORY		VARCHAR(255)	,
	@PG_UDP_VARIABLES_RELEVANT		VARCHAR(255)	,
	@INTEGER						VARCHAR(25)		,
	@FLOAT							VARCHAR(25)		,
	@LOGICAL						VARCHAR(25)		,
	@ARRAY_INTEGER					VARCHAR(25)		,
	@ARRAY_FLOAT					VARCHAR(25)		,
	@SPECIFICIATION_SETTING			VARCHAR(25)		,
	@AUTOLOG_TIME_BASED				VARCHAR(50)		,
	@AUTOLOG_PRODUCTION_EVENT		VARCHAR(50)		,
	@AUTOLOG_USER_DEFINED_EVENT		VARCHAR(50)		,
	@CURRENT_DATE					DATETIME		,
	@ACTIVITY_STATUS_COMPLETE		INT				,
	@ACTIVITY_STATUS_SKIPPED		INT				,
	@ACTIVITY_TYPE_UDE				INT				,
	@ACT_COMMENT_FIELD				VARCHAR(50)		,
	@OVER_COMMENT_FIELD				VARCHAR(50)		,
	@SKIP_COMMENT_FIELD				VARCHAR(50)		,
	@TEST_COMMENT_FIELD				VARCHAR(50)		,
	@NONE_COMMENT					VARCHAR(10)
	--==========================================================================================================================================
	--	Declare Error Handling
	--==========================================================================================================================================
	DECLARE
	@SQLErrorCode						INT,
	@SQLErrorMessage					VARCHAR(2000)
	--==========================================================================================================================================
	--	Set Constants
	--==========================================================================================================================================
	SET	@VARIABLE_TABLE_ID				=	20
	SET @PG_UDP_VARIABLES_MANDATORY		=	'RTCR_Variables_Mandatory'
	SET @PG_UDP_VARIABLES_RELEVANT		=	'RTCR_Variables_Relevant'
	SET @INTEGER						=	'Integer'
	SET @FLOAT							=	'Float'
	SET @LOGICAL						=	'Logical'
	SET @ARRAY_FLOAT					=	'Array Float'
	SET @ARRAY_INTEGER					=	'Array Integer'
	SET @SPECIFICIATION_SETTING			=	'SpecificationSetting'
	SET @AUTOLOG_TIME_BASED				=	'Autolog Time-Based'
	SET @AUTOLOG_PRODUCTION_EVENT		=	'Autolog Production Event'
	SET @AUTOLOG_USER_DEFINED_EVENT		=	'Autolog User-Defined Event'
	SET	@CURRENT_DATE					=	GETDATE()
	SET	@ACTIVITY_STATUS_COMPLETE		=	3
	SET	@ACTIVITY_STATUS_SKIPPED		=	4
	SET	@ACTIVITY_TYPE_UDE				=	3
	SET	@TEST_COMMENT_FIELD				=	'Test Comment: '
	SET	@ACT_COMMENT_FIELD				=	', Activity Comment: '
	SET	@OVER_COMMENT_FIELD				=	', Override Comment: '
	SET	@SKIP_COMMENT_FIELD				=	', Skip Comment: '
	SET	@NONE_COMMENT					=	'(None)'
	--==========================================================================================================================================
	--	LOOKUP CONFIGURATION
	--==========================================================================================================================================
	--------------------------------------------------------------------------------------------------------------------------------------------
	--	Populate @TableFields w/ All UDPs of Interest
	--------------------------------------------------------------------------------------------------------------------------------------------
	INSERT INTO @TableFields
	(
		TableFieldDesc	,
		TableId
	)
	SELECT	@PG_UDP_VARIABLES_RELEVANT	,	@VARIABLE_TABLE_ID
	UNION
	SELECT	@PG_UDP_VARIABLES_MANDATORY	,	@VARIABLE_TABLE_ID
	--------------------------------------------------------------------------------------------------------------------------------------------
	--	Lookup Table_Field_Ids
	--------------------------------------------------------------------------------------------------------------------------------------------
	UPDATE	tfs
	SET		tfs.TableFieldId	=	tf.Table_Field_Id
	FROM	@TableFields		AS	tfs
	JOIN	dbo.Table_Fields	AS	tf	WITH(NOLOCK)
										ON	tfs.TableFieldDesc	=	tf.Table_Field_Desc
										AND	tfs.TableId			=	tf.TableId
	--------------------------------------------------------------------------------------------------------------------------------------------
	--	Error if Server Is Missing Any UDP for RTCR - Bad Config / RTCR Not Properly Deployed
	--------------------------------------------------------------------------------------------------------------------------------------------
	IF	EXISTS	(
					SELECT	1
					FROM	@TableFields
					WHERE	TableFieldId	IS	NULL
				)
	BEGIN
		----------------------------------------------------------------------------------------------------------------------------------------
		--	Find the UDP Missing On the Server, For the Error Message
		----------------------------------------------------------------------------------------------------------------------------------------
		SET	@MissingUDP	=	(
								SELECT	TOP 1 TableFieldDesc
								FROM	@TableFields
								WHERE	TableFieldId	IS	NULL
							)
		----------------------------------------------------------------------------------------------------------------------------------------
		--	Generate Error Message
		----------------------------------------------------------------------------------------------------------------------------------------
		SET @SQLErrorCode		=	-1
		SET @SQLErrorMessage	=	'The RTCR UDP = ' + COALESCE(@MissingUDP,   'NULL')
										+ ', does not exist on this server, configuration missing.'
		GOTO ERRORFinish
	END	
	--------------------------------------------------------------------------------------------------------------------------------------------
	--	Load @TableFields Lookup Results Into Individual Table Field Id (TFId) Variables
	--------------------------------------------------------------------------------------------------------------------------------------------
	SET	@RelevantTFId	=	(
								SELECT	TableFieldId
								FROM	@TableFields
								WHERE	TableId			=	@VARIABLE_TABLE_ID
								AND		TableFieldDesc	=	@PG_UDP_VARIABLES_RELEVANT
							)

	SET	@MandatoryTFId	=	(
								SELECT	TableFieldId
								FROM	@TableFields
								WHERE	TableId			=	@VARIABLE_TABLE_ID
								AND		TableFieldDesc	=	@PG_UDP_VARIABLES_MANDATORY
							)	
	--------------------------------------------------------------------------------------------------------------------------------------------
	--	Validate Relevant Table Field Id (TFId) Variables Used By This Function Exists
	--------------------------------------------------------------------------------------------------------------------------------------------
	IF	@RelevantTFId	IS	NULL
	BEGIN
		SET @SQLErrorCode		=	-2
		SET @SQLErrorMessage	=	'The User Defined Property (UDP) = ' + @PG_UDP_VARIABLES_RELEVANT
										+ ' is not configured on this server. Mandatory RTCR configuration is missing.'
		GOTO ERRORFinish
	END
	--------------------------------------------------------------------------------------------------------------------------------------------
	--	Validate Mandatory Table Field Id (TFId) Variables Used By This Function Exists
	--------------------------------------------------------------------------------------------------------------------------------------------
	IF	@MandatoryTFId	IS	NULL
	BEGIN
		SET @SQLErrorCode		=	-3
		SET @SQLErrorMessage	=	'The User Defined Property (UDP) = ' + @PG_UDP_VARIABLES_MANDATORY
										+ ' is not configured on this server. Mandatory RTCR configuration is missing.'
		GOTO ERRORFinish
	END
	--------------------------------------------------------------------------------------------------------------------------------------------
	--	Lookup the @SpecSetting Determining >= vs. > Limit Application
	--------------------------------------------------------------------------------------------------------------------------------------------
	SET	@SpecSetting	=	(
								SELECT Value
								FROM	dbo.Site_Parameters	sp	WITH (NOLOCK) 
								JOIN	dbo.Parameters		p	WITH (NOLOCK) 
																ON sp.Parm_Id = p.Parm_Id
								WHERE	Parm_Name	=	@SPECIFICIATION_SETTING
							)
	--------------------------------------------------------------------------------------------------------------------------------------------
	--	Lookup Sheet_Type_Id for @AUTOLOG_TIME_BASED, @AUTOLOG_PRODUCTION_EVENT and @AUTOLOG_USER_DEFINED_EVENT
	--------------------------------------------------------------------------------------------------------------------------------------------
	INSERT INTO	@SheetTypes
	(
		SheetTypeDesc
	)
	SELECT	@AUTOLOG_TIME_BASED
	UNION
	SELECT	@AUTOLOG_PRODUCTION_EVENT
	UNION
	SELECT	@AUTOLOG_USER_DEFINED_EVENT
	--------------------------------------------------------------------------------------------------------------------------------------------
	--	Load All Sheet Type Ids Needed
	--------------------------------------------------------------------------------------------------------------------------------------------
	UPDATE	stt
	SET		stt.SheetTypeId	=	st.Sheet_Type_Id
	FROM	@SheetTypes		AS	stt
	JOIN	dbo.Sheet_Type	AS	st	WITH(NOLOCK)
									ON	stt.SheetTypeDesc	=	st.Sheet_Type_Desc
	--------------------------------------------------------------------------------------------------------------------------------------------
	--	Load Sheet Types Into Variables
	--------------------------------------------------------------------------------------------------------------------------------------------
	SET	@AutologTimeBasedSheetTypeId	=	(
												SELECT	SheetTypeId
												FROM	@SheetTypes
												WHERE	SheetTypeDesc	= @AUTOLOG_TIME_BASED
											)

	SET	@AutologProductionEventSheetTypeId	=	(
													SELECT	SheetTypeId
													FROM	@SheetTypes
													WHERE	SheetTypeDesc	= @AUTOLOG_PRODUCTION_EVENT
												)

	SET	@AutologUserDefinedEventSheetTypeId	=	(
													SELECT	SheetTypeId
													FROM	@SheetTypes
													WHERE	SheetTypeDesc	= @AUTOLOG_USER_DEFINED_EVENT
												)
	--==========================================================================================================================================
	--	VALIDATE INPUTS
	--==========================================================================================================================================
	--------------------------------------------------------------------------------------------------------------------------------------------
	--	Validate a @p_VarId Was Given, Exists On the Server
	--------------------------------------------------------------------------------------------------------------------------------------------
	IF	@p_VarId IS NULL
	OR	NOT EXISTS	(
						SELECT	1
						FROM	dbo.Variables_Base WITH(NOLOCK)
						WHERE	Var_Id	=	@p_VarId
					)
	BEGIN
		SET @SQLErrorCode		=	-4
		SET @SQLErrorMessage	=	'Variable does not exist on the server.'	
		GOTO ERRORFinish
	END
	--------------------------------------------------------------------------------------------------------------------------------------------
	--	Validate a @p_StartTime Was Given
	--------------------------------------------------------------------------------------------------------------------------------------------
	IF	@p_StartTime IS NULL OR @p_StartTime = ''
	BEGIN									
		SET @SQLErrorCode		=	-5
		SET @SQLErrorMessage	=	'StartTime Is Invalid.'	
		GOTO ERRORFinish
	END
	--------------------------------------------------------------------------------------------------------------------------------------------
	--	Validate a @p_EndTime Was Given
	--------------------------------------------------------------------------------------------------------------------------------------------
	IF	@p_EndTime IS NULL OR @p_EndTime = ''
	BEGIN									
		SET @SQLErrorCode		=	-6
		SET @SQLErrorMessage	=	'EndTime Is Invalid.'	
		GOTO ERRORFinish
	END
	--------------------------------------------------------------------------------------------------------------------------------------------
	--	Validate @p_StartTime Is Before @p_EndTime
	--------------------------------------------------------------------------------------------------------------------------------------------
	IF	@p_StartTime >= @p_EndTime
	BEGIN
		SET @SQLErrorCode		=	-7
		SET @SQLErrorMessage	=	'Start Time is Greater Than Or Equal to End Time.'	
		GOTO ERRORFinish		
	END
	--==========================================================================================================================================
	--	Lookup Variable Information
	--==========================================================================================================================================
	--------------------------------------------------------------------------------------------------------------------------------------------
	-- Get Variable Info
	--------------------------------------------------------------------------------------------------------------------------------------------
	INSERT	@IsVarNumeric
	(
		VarId			,
		IsVarNumeric	,
		DTId			,
		PUId			,
		EngUnits		, 
		VarDesc			, 
		SAId
	)
	SELECT
			v.Var_Id							,
			CASE	WHEN dt.Data_Type_Desc IN (@INTEGER, @FLOAT, @LOGICAL, @ARRAY_INTEGER, @ARRAY_FLOAT)	
						THEN	1
					ELSE	0
			END,
			dt.Data_Type_Id						,
			COALESCE(pu.Master_Unit,v.PU_Id)	, 
			v.Eng_Units							, 
			(Case When @@options&(512) !=(0) THEN Coalesce(e.Origin1Name,v.Var_Desc,v.Var_Desc_Global)
 	  	  	  	                                        ELSE  Coalesce(v.Var_Desc_Global, e.Origin1Name,v.Var_Desc)
 	  	  	  	                                        END)							, 
			v.SA_Id 
	FROM	dbo.Variables_Base		AS	v	WITH(NOLOCK)
	Left JOIN dbo.Variables_Aspect_EquipmentProperty e WITH (NOLOCK) on e.Var_Id = v.Var_Id 
	JOIN	dbo.Prod_Units_Base		AS	pu	WITH(NOLOCK)
											ON	v.PU_Id				=	pu.PU_Id
	JOIN	dbo.Data_Type			AS	dt	WITH(NOLOCK)
											ON	dt.Data_Type_Id		=	v.Data_Type_Id
	JOIN	dbo.Table_Fields_Values	AS	tfv	WITH(NOLOCK)
											ON	tfv.KeyId			=	v.Var_Id
											AND	tfv.TableId			=	@VARIABLE_TABLE_ID
											AND	tfv.Table_Field_Id	=	@RelevantTFId
											AND	tfv.Value			=	'1'
	WHERE	v.Var_Id	=	@p_VarID
	--------------------------------------------------------------------------------------------------------------------------------------------
	--	Error If Variable Not Found (Variable Submitted Was Not Flagged Relevant for RTCR)
	--------------------------------------------------------------------------------------------------------------------------------------------
	IF NOT EXISTS	(
						SELECT	1
						FROM	@IsVarNumeric
					)
	BEGIN
		SET @SQLErrorCode		=	-8
		SET @SQLErrorMessage	=	'Variable requested is not configured as RTCR-Relevant.'	
		GOTO ERRORFinish	
	END
	--------------------------------------------------------------------------------------------------------------------------------------------
	-- Determine If a Non-Numeric Variable Is Phrase-Based Per Its Data Type
	--------------------------------------------------------------------------------------------------------------------------------------------
	UPDATE	vn
	SET		vn.IsPhraseLocked	=	1
	FROM	@IsVarNumeric	AS	vn
	JOIN	dbo.Phrase		AS	ph	WITH(NOLOCK)
									ON	vn.DTId	=	ph.Data_Type_Id

	UPDATE	@IsVarNumeric
	SET		IsPhraseLocked	=	0
	WHERE	IsPhraseLocked	IS	NULL
	--------------------------------------------------------------------------------------------------------------------------------------------
	--	For Phrase Based Tests, Find the Max Phrase Assigned
	--------------------------------------------------------------------------------------------------------------------------------------------
	UPDATE	vn
	SET		vn.MaxPhraseValue	=	ph.Phrase_Value	,
			vn.MaxPhraseOrder	=	ph.Phrase_Order
	FROM	@IsVarNumeric	AS	vn
	JOIN	dbo.Phrase		AS	ph	WITH(NOLOCK)
									ON	vn.DTId	=	ph.Data_Type_Id
	WHERE	vn.IsPhraseLocked	=	1
	AND		ph.Phrase_Order		=	(
										SELECT	MAX(ph2.Phrase_Order)
										FROM	dbo.Phrase	AS	ph2
										WHERE	ph2.Data_Type_id	=	vn.DTId
									)
	--------------------------------------------------------------------------------------------------------------------------------------------
	-- Determine if Variable Is Flagged As A Mandatory Test
	--------------------------------------------------------------------------------------------------------------------------------------------
	UPDATE	@IsVarNumeric
	SET		IsMandatory	=	COALESCE(tfv.Value,0) 
	FROM	@IsVarNumeric			AS	v
	JOIN	dbo.Table_Fields_Values	AS	tfv	WITH(NOLOCK)
											ON tfv.KeyId	=	v.VarId
	WHERE	tfv.TableId			=	@VARIABLE_TABLE_ID
	AND		tfv.Table_Field_Id	=	@MandatoryTFId
	--------------------------------------------------------------------------------------------------------------------------------------------
	-- If Mandatory UDP Not Set At All, Default to Non-Mandatory
	--------------------------------------------------------------------------------------------------------------------------------------------
	UPDATE	@IsVarNumeric
	SET		IsMandatory	=	0
	WHERE	IsMandatory IS NULL
	--==========================================================================================================================================
	--  GET TEST RESULTS
	--==========================================================================================================================================
	--------------------------------------------------------------------------------------------------------------------------------------------
	-- Get Production Starts
	--------------------------------------------------------------------------------------------------------------------------------------------
	INSERT	INTO	@ProductionStarts
	(
		StartTime	, 
		EndTime		, 
		ProdId		,
		PUID		, 
		VarID		, 
		SAID		, 
		EngUnits	, 
		VarDesc
	)
	SELECT	ps.Start_Time	,
			ps.End_Time		, 
			ps.Prod_Id		, 
			v.PUId			, 
			v.VarId			,
			v.SAId			, 
			v.EngUnits		, 
			v.VarDesc 
	FROM	@IsVarNumeric			AS	v
	LEFT
	JOIN	dbo.Production_Starts	AS	ps	WITH(NOLOCK)
											ON	v.PUId	=	ps.PU_Id
	AND		ps.Start_Time	<=	@p_EndTime
	AND		(	
				ps.End_Time		>	@p_StartTime
				OR ps.End_Time	IS	NULL
			)
	--------------------------------------------------------------------------------------------------------------------------------------------
	--	Error If Variable Not Found (Variable Submitted Was Not Flagged Relevant for RTCR)
	--------------------------------------------------------------------------------------------------------------------------------------------
	IF NOT EXISTS	(
						SELECT	1
						FROM	@ProductionStarts
					)
	BEGIN
		SET @SQLErrorCode		=	-9
		SET @SQLErrorMessage	=	'Cannot grade results. No products were run during the requested time period.'	
		GOTO ERRORFinish	
	END
	--------------------------------------------------------------------------------------------------------------------------------------------
	-- Get Var Specs
	--------------------------------------------------------------------------------------------------------------------------------------------
	INSERT	INTO	@VarSpecs
	(
		VSId			,
		EffectiveDate	, 
		ExpirationDate	,
		L_Control		,
		L_Entry			,
		L_Reject		,
		L_User			,
		L_Warning		,
		[Target]		,
		U_Control		,
		U_Entry			,
		U_Reject		,
		U_User			,
		U_Warning		,
		VarId			, 
		ProdId
	)
	SELECT
	DISTINCT	
				vs.VS_Id			,
				vs.Effective_Date	,
				vs.Expiration_Date	, 
				vs.L_Control		, 
				vs.L_Entry			, 
				vs.L_Reject			, 
				vs.L_User			, 
				vs.L_Warning		, 
				vs.[Target]			, 
				vs.U_Control		,
				vs.U_Entry			,
				vs.U_Reject			,
				vs.U_User			,
				vs.U_Warning		,
				vs.Var_Id			,
				vs.Prod_Id
	FROM	dbo.Var_Specs		AS	vs	WITH(NOLOCK)
	JOIN	@IsVarNumeric		AS	tv	ON	vs.Var_Id	=	tv.VarId
	JOIN	@ProductionStarts	AS	ps	ON	vs.Prod_Id	=	ps.ProdId
										AND vs.Var_Id	= ps.VarID
	WHERE	vs.Expiration_Date	>=	@p_StartTime
	OR		vs.Expiration_Date	IS NULL
	--------------------------------------------------------------------------------------------------------------------------------------------
	-- Get Tests and Specs Together
	--------------------------------------------------------------------------------------------------------------------------------------------
	INSERT	INTO	@TestVariables  
	(
		VarId			,
		PUId			,
		IsPhraseLocked	,
		TestName		,
		EventTestId		,
		UoM				,
		ResultOn		,
		Result			,
		ProdId			,
		SAId			,
		U_Entry			,
		U_Reject		,
		U_User			,
		U_Warning		,
		L_Entry			,
		L_Reject		,
		L_User			,
		L_Warning		,
		[Target]		,
		Entry_by		,
		TestComment	
	)	
	SELECT	t.Var_Id			,
			ps.PUId				,
			tv.IsPhraseLocked	,
			ps.VarDesc			,
			t.Event_Id			,
			ps.EngUnits			,
			t.Result_On			,
			t.Result			,
			ps.ProdId			,
			ps.SAId				,
			vs.U_Entry			,
			vs.U_Reject			,
			vs.U_User			,
			vs.U_Warning		,
			vs.L_Entry			,
			vs.L_Reject			,
			vs.L_User			,
			vs.L_Warning		,
			vs.[Target]			,
			t.Entry_By			,
			c.Comment_Text
	FROM	@IsVarNumeric		AS	tv
	JOIN	dbo.Tests			AS	t	WITH(NOLOCK) 
										ON	t.Var_Id		=	tv.Varid
	JOIN	@ProductionStarts	AS	ps	ON	ps.VarID		=	tv.VarId
										AND	ps.StartTime	<=	t.Result_On
										AND	(
													ps.EndTime	>	t.Result_On 
												OR	ps.EndTime	IS	NULL
											)
	LEFT	--	Ensure Query Does Not Fail If @VarSpecs Are Not Found!
	JOIN	@VarSpecs			AS	vs	ON	vs.ProdId			=	ps.ProdId
										AND	vs.VarId			=	t.Var_Id
										AND	vs.EffectiveDate	<=	t.Result_On
										AND	(
													vs.ExpirationDate	>	t.Result_On 
												OR	vs.ExpirationDate	IS	NULL
											)
	LEFT												
	JOIN	dbo.Comments		AS	c	WITH(NOLOCK)
										ON c.Comment_Id		=	t.Comment_Id
	WHERE 
	(
			t.Result_On	>=	@p_StartTime 
		AND	t.Result_On	<	@p_EndTime
	)
	--------------------------------------------------------------------------------------------------------------------------------------------
	-- Update @TestVariables SheetDesc Field
	--------------------------------------------------------------------------------------------------------------------------------------------
	UPDATE	tv
	SET		tv.SheetDesc	=	s.Sheet_Desc_Local
	FROM	@TestVariables		AS	tv
	JOIN	dbo.Sheet_Variables	AS	sv	WITH(NOLOCK)
										ON	sv.Var_Id	=	tv.VarId
	JOIN	dbo.Sheets			AS	s	WITH(NOLOCK)
										ON	s.Sheet_Id	=	sv.Sheet_Id
	WHERE	tv.VarId		IS NOT NULL
	AND		s.Sheet_Type	IN (	
									@AutologTimeBasedSheetTypeId		,
									@AutologProductionEventSheetTypeId	,
									@AutologUserDefinedEventSheetTypeId	
								)
	--------------------------------------------------------------------------------------------------------------------------------------------
	-- Update @TestVariables OperatorORUnit Field -- This Will Find Both Operators and Model (Automatic) Users
	--------------------------------------------------------------------------------------------------------------------------------------------
	UPDATE	tv
	SET		tv.OperatorORUnit	=	u.Username
	FROM	@TestVariables	AS	tv
	JOIN	dbo.Users_Base	AS	u	WITH(NOLOCK)
									ON	tv.Entry_By	=	u.[User_Id]

	UPDATE	tv
	SET		tv.OperatorORUnit	=	pu.PU_Desc
	FROM	@TestVariables		AS	tv
	JOIN	dbo.Prod_Units_Base	AS	pu	WITH(NOLOCK)
										ON	tv.PUId	=	pu.PU_Id
	WHERE	tv.OperatorORUnit	IS	NULL
	--==========================================================================================================================================
	-- UCC FILTER - 1.60 - PREVENT PENDING UCC RESULTS FROM BEING REPORTED
	--==========================================================================================================================================
	--------------------------------------------------------------------------------------------------------------------------------------------
	-- Check if Activities Table Is Populated For Related Prod Unit Before Proceeding - If Not Populated, UCC Is Not In Use At Site
	--------------------------------------------------------------------------------------------------------------------------------------------
	IF EXISTS (
				SELECT	1
				FROM	dbo.Activities	AS	act WITH(NOLOCK)
				JOIN	@IsVarNumeric	AS	vn	ON	act.PU_Id	=	vn.PUId	
				)
	BEGIN
		----------------------------------------------------------------------------------------------------------------------------------------
		--	Link Test Results to Activities Via Their Result On = KeyId of Actitivites Table, Get Activity's Current STatus
		----------------------------------------------------------------------------------------------------------------------------------------
		UPDATE	tv
		SET		tv.ActId			=	act.Activity_Id		,
				tv.ActivityStatus	=	act.Activity_Status	,
				tv.ActComment		=	c.Comment_Text		,
				tv.OverdueComment	=	c2.Comment_Text		,
				tv.SkipComment		=	c3.Comment_Text
		FROM	@TestVariables	AS	tv
		JOIN	@IsVarNumeric	AS	vn	ON	tv.VarId	=	vn.VarId
		JOIN	dbo.Activities	AS	act	WITH(NOLOCK)
										ON	vn.PUId			=	act.PU_Id
										AND	tv.ResultOn		=	act.KeyId
										AND	tv.EventTestId	=	act.KeyId1
		LEFT
		JOIN	dbo.Comments		AS	c	WITH(NOLOCK)
											ON c.Comment_Id		=	act.Comment_Id
		LEFT
		JOIN	dbo.Comments		AS	c2	WITH(NOLOCK)
											ON c2.Comment_Id	=	act.Overdue_Comment_Id
		LEFT
		JOIN	dbo.Comments		AS	c3	WITH(NOLOCK)
											ON c3.Comment_Id	=	act.Skip_Comment_Id
		WHERE	act.Activity_Type_Id	=	@ACTIVITY_TYPE_UDE
		----------------------------------------------------------------------------------------------------------------------------------------
		--	Remove ANY Test Results If The Activity is Not Complete Or Skipped (Assuming Activity Status Is Set)
		----------------------------------------------------------------------------------------------------------------------------------------
		DELETE	@TestVariables
		WHERE	ActivityStatus	IS	NOT	NULL
		AND		ActivityStatus	NOT	IN	(@ACTIVITY_STATUS_COMPLETE, @ACTIVITY_STATUS_SKIPPED)
	END
	--==========================================================================================================================================
	--  PREPARE PHRASE GRADING INFORMATION
	--==========================================================================================================================================
	--------------------------------------------------------------------------------------------------------------------------------------------
	-- Lookup Phrase Order of L_Warning For Non-Numeric Tests
	--------------------------------------------------------------------------------------------------------------------------------------------
	UPDATE	tv
	SET		tv.L_Warning_Order	=	ph.Phrase_Order
	FROM	@TestVariables	AS	tv
	JOIN	@IsVarNumeric	AS	iv	ON	tv.VarId	=	iv.VarId
	JOIN	dbo.Phrase		AS	ph	WITH(NOLOCK)
									ON	tv.L_Warning	=	ph.Phrase_Value
									AND	iv.DTId			=	ph.Data_Type_Id
	WHERE	iv.IsVarNumeric	=	0
	--------------------------------------------------------------------------------------------------------------------------------------------
	-- Lookup Phrase Order of Target For Non-Numeric Tests
	--------------------------------------------------------------------------------------------------------------------------------------------
	UPDATE	tv
	SET		tv.Target_Order	=	ph.Phrase_Order
	FROM	@TestVariables	AS	tv
	JOIN	@IsVarNumeric	AS	iv	ON	tv.VarId	=	iv.VarId
	JOIN	dbo.Phrase		AS	ph	WITH(NOLOCK)
									ON	tv.[Target]	=	ph.Phrase_Value
									AND	iv.DTId		=	ph.Data_Type_Id
	WHERE	iv.IsVarNumeric	=	0
	--------------------------------------------------------------------------------------------------------------------------------------------
	-- Lookup Phrase Order of Result For Non-Numeric Tests
	--------------------------------------------------------------------------------------------------------------------------------------------
	UPDATE	tv
	SET		tv.Result_Order	=	ph.Phrase_Order
	FROM	@TestVariables	AS	tv
	JOIN	@IsVarNumeric	AS	iv	ON	tv.VarId	=	iv.VarId
	JOIN	dbo.Phrase		AS	ph	WITH(NOLOCK)
									ON	tv.Result	=	ph.Phrase_Value
									AND	iv.DTId		=	ph.Data_Type_Id
	WHERE	iv.IsVarNumeric	=	0
	--------------------------------------------------------------------------------------------------------------------------------------------
	--	Determine Max Pass Phrase Order Based on L_Warning_Order & Target_Order
	--------------------------------------------------------------------------------------------------------------------------------------------
	UPDATE	tv
	SET		tv.MaxPassPhrase	=	CASE
										WHEN	COALESCE(tv.L_Warning_Order,0)	> COALESCE(tv.Target_Order,0)
											THEN	tv.L_Warning_Order
										WHEN	COALESCE(tv.Target_Order,0)		> COALESCE(tv.L_Warning_Order,0)
											THEN	tv.Target_Order
									END
	FROM	@TestVariables	AS	tv
	JOIN	@IsVarNumeric	AS	iv	ON	tv.VarId	=	iv.VarId
	WHERE	iv.IsVarNumeric	=	0
	--------------------------------------------------------------------------------------------------------------------------------------------
	--	If a Phrase Cannot Be Evaluated (Not Actually Defined Per the dbo.Phrases Table) It Is A Failure, Mask It As Such
	--------------------------------------------------------------------------------------------------------------------------------------------
	UPDATE	tv
	SET		tv.Result		=	CASE
									WHEN	tv.Result	IS	NULL
										THEN	NULL
									ELSE	iv.MaxPhraseValue
								END
			,tv.Result_Order	=	iv.MaxPhraseOrder
	FROM	@TestVariables	AS	tv
	JOIN	@IsVarNumeric	AS	iv	ON	tv.VarId	=	iv.VarId
	WHERE	iv.IsVarNumeric		=	0
	AND		tv.IsPhraseLocked	=	1
	AND		tv.Result_Order		IS	NULL
	--------------------------------------------------------------------------------------------------------------------------------------------
	-- Insert for Phrases
	--------------------------------------------------------------------------------------------------------------------------------------------
	INSERT	INTO	@RTCRTests
	(
		VarId			,
		PUId			,
		TestName		,
		UoM				,
		ResultOn		,
		Result			,
		ProdId			,
		SAId			,
		L_Entry			,
		L_Reject		,
		L_User			,
		L_Warning		,
		U_Entry			,
		U_Reject		,
		U_User			,
		U_Warning		,
		[Target]		,
		IsVarNumeric	,
		IsMandatory		,
		OperatorORUnit	,
		PassCheck		,
		Comment			,
		SheetDesc			
	)
	SELECT	t.VarId				,
			t.PUId				,
			t.TestName			,
			t.UoM				,
			t.ResultOn			,
			t.Result			,
			t.ProdId			,
			t.SAId				,
			t.L_Entry			,
			t.L_Reject			,
			t.L_User			,
			t.L_Warning			,
			t.U_Entry			,
			t.U_Reject			,
			t.U_User			,
			t.U_Warning			,
			t.[Target]			,
			n.IsVarNumeric		, 
			n.IsMandatory		,
			t.OperatorORUnit	,
			CASE	WHEN	t.Result_Order <= t.MaxPassPhrase	--	Case 1: Result Passes Phrase Grading Test
						THEN 1
					WHEN	t.Target	IS	NULL				--	Case 2: Phrase Test, Cannot Grade (No Spec) Result without Target or L_Warning (Failure Case)
					AND		t.Result	IS	NOT NULL
						THEN 0
					WHEN	NULLIF(t.Result,'')	IS	NULL		--	Case 3: Blank Result Fails Pass Check, Whether This Is a Fail or Miss Decided In Mandatory Flagging
						THEN 0
					ELSE 0										--	Case 4: Catch All, All Other Options End in Failure
			END					,
			CONCAT(@TEST_COMMENT_FIELD,COALESCE(t.TestComment,@NONE_COMMENT),@ACT_COMMENT_FIELD,COALESCE(t.ActComment,@NONE_COMMENT),@OVER_COMMENT_FIELD,COALESCE(t.OverdueComment,@NONE_COMMENT),@SKIP_COMMENT_FIELD,COALESCE(t.SkipComment,@NONE_COMMENT))			,
			t.SheetDesc	
	FROM	@TestVariables		AS	t
	JOIN	@IsVarNumeric		AS	n			ON	t.VarId					=	n.VarId
	JOIN	dbo.Variables_Base	AS	vb			WITH(NOLOCK)
												ON	t.VarId					=	vb.Var_Id
	LEFT	--	Account for Non-Var Spec Populated Phrases That Have No Target!
	JOIN	dbo.Phrase			AS	phTest		WITH(NOLOCK)
												ON	phTest.Data_Type_Id		=	vb.Data_Type_Id	
												AND	t.Target				=	phTest.Phrase_Value		
	LEFT	--	Prevents NULL results From Dissapearing!
	JOIN	dbo.Phrase			AS	phResult	WITH(NOLOCK)
												ON	phResult.Data_Type_Id	=	vb.Data_Type_Id	
												AND	t.Result				=	phResult.Phrase_Value				
	WHERE	n.IsVarNumeric		=	0
	AND		n.IsPhraseLocked	=	1
	--------------------------------------------------------------------------------------------------------------------------------------------
	--	For Non-Phrase Text
	--------------------------------------------------------------------------------------------------------------------------------------------
	INSERT INTO @RTCRTests
	(
		VarId			,
		PUId			,
		TestName		,
		UoM				,
		ResultOn		,
		Result			,
		ProdId			,
		SAId			,
		L_Entry			,
		L_Reject		,
		L_User			,
		L_Warning		,
		U_Entry			,
		U_Reject		,
		U_User			,
		U_Warning		,
		[Target]		,
		IsVarNumeric	,
		IsMandatory		,
		OperatorORUnit	,
		PassCheck		,
		Comment			,
		SheetDesc			
	)
	SELECT	t.VarId				,
			t.PUId				,
			t.TestName			,
			t.UoM				,
			t.ResultOn			,
			t.Result			,
			t.ProdId			,
			t.SAId				,
			t.L_Entry			,
			t.L_Reject			,
			t.L_User			,
			t.L_Warning			,
			t.U_Entry			,
			t.U_Reject			,
			t.U_User			,
			t.U_Warning			,
			t.[Target]			,
			n.IsVarNumeric		, 
			n.IsMandatory		,
			t.OperatorORUnit	,
			CASE	WHEN	t.Result	=	t.Target		--	Case 1: Non-Phrase Test, Result Must Match Target To Pass
						THEN 1
					WHEN	t.Target	IS	NULL			--	Case 2: Non-Phrase Test, Cannot Grade (No Spec) Result without Target (Failure Case)
					AND		t.Result	IS	NOT NULL
						THEN 0
					WHEN	NULLIF(t.Result,'')	IS	NULL	--	Case 3: Blank Result Fails Pass Check, Whether This Is a Fail or Miss Decided In Mandatory Flagging
						THEN 0
					ELSE 0									--	Case 3: Catch All, All Other Options End in Failure
			END					,
			CONCAT(@TEST_COMMENT_FIELD,COALESCE(t.TestComment,@NONE_COMMENT),@ACT_COMMENT_FIELD,COALESCE(t.ActComment,@NONE_COMMENT),@OVER_COMMENT_FIELD,COALESCE(t.OverdueComment,@NONE_COMMENT),@SKIP_COMMENT_FIELD,COALESCE(t.SkipComment,@NONE_COMMENT))			,
			t.SheetDesc
	FROM	@TestVariables	AS	t
	JOIN	@IsVarNumeric	AS	n	ON	t.VarId	=	n.VarId
	WHERE	n.IsVarNumeric		=	0
	AND		n.IsPhraseLocked	<>	1
	AND		t.VarId			NOT	IN	(
										SELECT	VarId 
										FROM	@RTCRTests
									)
	--------------------------------------------------------------------------------------------------------------------------------------------
	-- Insert Into Result Set for Numeric Tests
	--------------------------------------------------------------------------------------------------------------------------------------------
	IF	@SpecSetting	=	0	--	Must Be Zero to Respond Properly, Zero Prevents Results on Limits from Passing
	BEGIN
		INSERT INTO @RTCRTests
		(
			VarId			,
			PUId			,
			TestName		,
			UoM				,
			ResultOn		,
			Result			,
			ProdId			,
			SAId			,
			L_Entry			,
			L_Reject		,
			L_User			,
			L_Warning		,
			U_Entry			,
			U_Reject		,
			U_User			,
			U_Warning		,
			[Target]		,
			IsVarNumeric	,
			IsMandatory		,
			OperatorORUnit	,
			PassCheck		,
			Comment			,
			SheetDesc
		)
		SELECT	t.VarId				,
				t.PUId				,
				t.TestName			,
				t.UoM				,
				t.ResultOn			,
				t.Result			,
				t.ProdId			,
				t.SAId				,
				t.L_Entry			,
				t.L_Reject			,
				t.L_User			,
				t.L_Warning			,
				t.U_Entry			,
				t.U_Reject			,
				t.U_User			,
				t.U_Warning			,
				t.[Target]			,
				n.IsVarNumeric		, 
				n.IsMandatory		,
				t.OperatorORUnit	,
				CASE	WHEN	t.U_Reject IS NOT NULL  --	Test Passes If Both Reject Limits Exist, Result Falls Between Them
						AND		CONVERT(FLOAT,t.Result) <  CONVERT(FLOAT,U_Reject)
						AND		t.L_Reject IS NOT NULL
						AND		CONVERT(FLOAT,t.Result) > CONVERT(FLOAT, t.L_Reject)
							THEN 1
						WHEN	t.U_Reject IS NOT NULL	--	Test Passes If Upper Reject Limit Exists, And Result Is Less Than It + No Lower Reject Limit Exists
						AND		CONVERT(FLOAT,t.Result) <  CONVERT(FLOAT,U_Reject)
						AND		t.L_Reject IS NULL
							THEN 1
						WHEN	t.U_Reject IS NULL		--	Test Passes If Lower Reject Limit Exists, And Result is More Than It + No Upper Reject Limit Exists
						AND		t.L_Reject IS NOT NULL
						AND		CONVERT(FLOAT,t.Result) > CONVERT(FLOAT, t.L_Reject)
							THEN 1
						WHEN	t.U_Reject IS NULL	--	Test Passes If Only Target Exists, And Result Exactly Matches
						AND		t.L_Reject IS NULL
						AND		t.[Target] IS NOT NULL	
						AND		CONVERT(FLOAT,t.Result) = CONVERT(FLOAT,t.[Target])
							THEN 1		
						WHEN	t.[Target] IS NOT NULL	--	Catch 1: If No Previous Conditions Were Met, But Target Exists, And Result Is Exact Match, Pass
						AND		CONVERT(FLOAT,t.Result) = CONVERT(FLOAT,t.[Target])
							THEN 1						
						WHEN	t.U_Reject	IS	NULL	--	Catch 2: Intentional Failure Case - No Limits Exist, Cannot Grade Result, Failure!
						AND		t.L_Reject	IS	NULL
						AND		t.[Target]	IS	NULL
						AND		t.Result	IS	NOT NULL
							THEN 0
						WHEN	t.Result	IS	NULL	--	Catch 3: Blank Result Fails Pass Check, Whether This Is a Fail or Miss Decided In Mandatory Flagging
							THEN 0
					ELSE 0								--	Catch 4: Anything Else - Failure!
				END					,
				CONCAT(@TEST_COMMENT_FIELD,COALESCE(t.TestComment,@NONE_COMMENT),@ACT_COMMENT_FIELD,COALESCE(t.ActComment,@NONE_COMMENT),@OVER_COMMENT_FIELD,COALESCE(t.OverdueComment,@NONE_COMMENT),@SKIP_COMMENT_FIELD,COALESCE(t.SkipComment,@NONE_COMMENT))	,
				t.SheetDesc
		FROM	@TestVariables	AS	t
		JOIN	@IsVarNumeric	AS	n	ON	t.VarId	=	n.VarId
		WHERE	n.IsVarNumeric	=	1
	END
	--------------------------------------------------------------------------------------------------------------------------------------------
	-- Spec setting is set to accept = for numeric tests
	--------------------------------------------------------------------------------------------------------------------------------------------
	ELSE	--	If Spec Setting = 1, Results on Limit Pass
	BEGIN
		INSERT INTO @RTCRTests
		(
			VarId			,
			PUId			,
			TestName		,
			UoM				,
			ResultOn		,
			Result			,
			ProdId			,
			SAId			,
			L_Entry			,
			L_Reject		,
			L_User			,
			L_Warning		,
			U_Entry			,
			U_Reject		,
			U_User			,
			U_Warning		,
			[Target]		,
			IsVarNumeric	,
			IsMandatory		,
			OperatorORUnit	,
			PassCheck		,
			Comment			,
			SheetDesc				
		)
		SELECT	t.VarId				,
				t.PUId				,
				t.TestName			,
				t.UoM				,
				t.ResultOn			,
				t.Result			,
				t.ProdId			,
				t.SAId				,
				t.L_Entry			,
				t.L_Reject			,
				t.L_User			,
				t.L_Warning			,
				t.U_Entry			,
				t.U_Reject			,
				t.U_User			,
				t.U_Warning			,
				t.[Target]			,
				n.IsVarNumeric		, 
				n.IsMandatory		,
				t.OperatorORUnit	,
				CASE	WHEN	t.U_Reject IS NOT NULL  --	Test Passes If Both Reject Limits Exist, Result Falls Between Them
						AND		CONVERT(FLOAT,t.Result) <=  CONVERT(FLOAT,U_Reject)
						AND		t.L_Reject IS NOT NULL
						AND		CONVERT(FLOAT,t.Result) >= CONVERT(FLOAT, t.L_Reject)
							THEN 1
						WHEN	t.U_Reject IS NOT NULL	--	Test Passes If Upper Reject Limit Exists, And Result Is Less Than It + No Lower Reject Limit Exists
						AND		CONVERT(FLOAT,t.Result) <=  CONVERT(FLOAT,U_Reject)
						AND		t.L_Reject IS NULL
							THEN 1
						WHEN	t.U_Reject IS NULL		--	Test Passes If Lower Reject Limit Exists, And Result is More Than It + No Upper Reject Limit Exists
						AND		t.L_Reject IS NOT NULL
						AND		CONVERT(FLOAT,t.Result) >= CONVERT(FLOAT, t.L_Reject)
							THEN 1
						WHEN	t.U_Reject IS NULL	--	Test Passes If Only Target Exists, And Result Exactly Matches
						AND		t.L_Reject IS NULL
						AND		t.[Target] IS NOT NULL	
						AND		CONVERT(FLOAT,t.Result) = CONVERT(FLOAT,t.[Target])
							THEN 1		
						WHEN	t.[Target] IS NOT NULL	--	Catch 1: If No Previous Conditions Were Met, But Target Exists, And Result Is Exact Match, Pass
						AND		CONVERT(FLOAT,t.Result) = CONVERT(FLOAT,t.[Target])
							THEN 1						
						WHEN	t.U_Reject	IS	NULL	--	Catch 2: Intentional Failure Case - No Limits Exist, Cannot Grade Result, Failure!
						AND		t.L_Reject	IS	NULL
						AND		t.[Target]	IS	NULL
						AND		t.Result	IS	NOT NULL
							THEN 0
						WHEN	t.Result	IS	NULL	--	Catch 3: Blank Result Fails Pass Check, Whether This Is a Fail or Miss Decided In Mandatory Flagging
							THEN 0
					ELSE 0								--	Catch 4: Anything Else - Failure!
				END					,
				CONCAT(@TEST_COMMENT_FIELD,COALESCE(t.TestComment,@NONE_COMMENT),@ACT_COMMENT_FIELD,COALESCE(t.ActComment,@NONE_COMMENT),@OVER_COMMENT_FIELD,COALESCE(t.OverdueComment,@NONE_COMMENT),@SKIP_COMMENT_FIELD,COALESCE(t.SkipComment,@NONE_COMMENT))			,
				t.SheetDesc
		FROM	@TestVariables	AS	t
		JOIN	@IsVarNumeric	AS	n	ON	t.VarId	=	n.VarId
		WHERE	n.IsVarNumeric	=	1
	END
	--==========================================================================================================================================
	--	POPULATE ERROR MESSAGE FIELDS WHEN FAILURE WAS DUE TO INABLITY TO GRADE
	--==========================================================================================================================================
	--------------------------------------------------------------------------------------------------------------------------------------------
	--	Flag Ungradable Phrase & Non-Phrase Results
	--------------------------------------------------------------------------------------------------------------------------------------------
	UPDATE	@RTCRTests
	SET		SQLErrorCode	=	-10	,
			SQLErrorMessage	=	'Ungradable Result, No Active Specs Found.'
	WHERE	IsVarNumeric	=	0
	AND		Target			IS	NULL
	AND		Result			IS	NOT NULL
	--------------------------------------------------------------------------------------------------------------------------------------------
	--	Flag Ungradable Numeric Results
	--------------------------------------------------------------------------------------------------------------------------------------------
	UPDATE	@RTCRTests
	SET		SQLErrorCode	=	-10	,
			SQLErrorMessage	=	'Ungradable Result, No Active Specs Found.'
	WHERE	IsVarNumeric	=	1
	AND		[Target]	IS	NULL
	AND		U_Reject	IS	NULL
	AND		L_Reject	IS	NULL
	AND		Result		IS	NOT NULL
	--==========================================================================================================================================
	--  FLAG MANDATORY FAILURES (Missing Results Treated Identical to Failed Tests)
	--==========================================================================================================================================
	UPDATE	t
	SET		t.MajorGroupHasFail	=	1	,
			t.MinorGroupHasFail	=	1	,
			t.TestHasFail		=	1
	FROM	@RTCRTests		AS	t 
	JOIN	@TestVariables	AS	tv	ON	t.VarId	=	tv.VarId
	WHERE	t.PassCheck		=	0
	AND		t.IsMandatory	=	1
	AND		t.VarId			IS	NOT NULL
	--==========================================================================================================================================
	--  FLAG NON-MANDATORY FAILURES (Taken But Not Passed)
	--==========================================================================================================================================
	UPDATE	t
	SET		t.MajorGroupHasFail	=	2	,
			t.MinorGroupHasFail	=	2	,
			t.TestHasFail		=	2
	FROM	@RTCRTests		AS	t 
	JOIN	@TestVariables	AS	tv	ON	t.VarId	=	tv.VarId
	WHERE	t.PassCheck		=	0
	AND		t.IsMandatory	=	0
	AND		t.VarId			IS	NOT NULL
	AND		t.Result		IS	NOT NULL
	--==========================================================================================================================================
	--  FLAG NON-MANDATORY MISSES (Not Taken)
	--==========================================================================================================================================
	UPDATE	t
	SET		t.MajorGroupHasFail	=	3	,
			t.MinorGroupHasFail	=	3	,
			t.TestHasFail		=	3
	FROM	@RTCRTests		AS	t
	JOIN	@TestVariables	AS	tv	ON	t.VarId	=	tv.VarId
	WHERE	(
					t.PassCheck	IS	NULL
				OR	t.Result	IS	NULL
				OR	t.Result	=	''
			)
	AND		t.VarId			IS	NOT	NULL
	AND		t.IsMandatory	=	0
	--==========================================================================================================================================
	-- TRAP Errors 
	--==========================================================================================================================================
	ERRORFinish:
	IF @SQLErrorCode <> 0
	BEGIN
		----------------------------------------------------------------------------------------------------------------------------------------
		-- Insert the message in the resultset
		----------------------------------------------------------------------------------------------------------------------------------------
		IF EXISTS   
		(
			SELECT  1
			FROM    @RTCRTests
		)
		BEGIN
			UPDATE  @RTCRTests
			SET     SQLErrorCode    = @SQLErrorCode,
					SQLErrorMessage = COALESCE(OBJECT_NAME(@@ProcId) + ': ', 'Message: ') + @SQLErrorMessage
			WHERE RcdIdx = (
								SELECT  MIN(RcdIdx)
								FROM    @RTCRTests
							)
		END
		ELSE
		BEGIN
			INSERT INTO @RTCRTests(
						SQLErrorCode,
						SQLErrorMessage)
			VALUES  (
						@SQLErrorCode,
						COALESCE(OBJECT_NAME(@@ProcId) + ': ', 'Message: ') + @SQLErrorMessage
					)
		END
	END
	--------------------------------------------------------------------------------------------------------------------------------------------
	-- END
	--------------------------------------------------------------------------------------------------------------------------------------------
	RETURN
END
--==============================================================================================================================================
--  RETURN CODE
--==============================================================================================================================================
