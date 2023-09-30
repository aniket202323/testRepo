

--=====================================================================================================================
-- 	Stored Procedure:	spLocal_DisplayOfflineQuality_NewSampleResultSet
-- 	Athor:				Roberto del Cid
-- 	Date Created:		2007/08/21
-- 	Sp Type:			stored procedure
-- 	Editor Tab Sp:		4
-----------------------------------------------------------------------------------------------------------------------
--	DESCRITION: 
--	This stored procedure is called by the New Sample pop-up in the LocalDisplayOfflineQuality application
--	This purpose of this sp is to generate a result set with the list of departments, lines, units, and variables that
--	support the offline quality application
-----------------------------------------------------------------------------------------------------------------------
-- CALLED BY:
-- LocalDisplayOfflineQuality.aspx
-----------------------------------------------------------------------------------------------------------------------
-- SP SECTIONS:
-- 1.	Declare Variables
-- 2.  	Initilize Values
-- 3.  	Validate sp parameters
-----------------------------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
-- Revision		Date		Who					What
-- ========		====		===					====
-- 1.0			2007-08-21	Roberto Del Cid		Initial Development
-- 1.1			2007-08-27	Renata Piedmont		Code Review
-- 1.2			2007-09-24	Roberto del Cid		Added columns to work with Print Labels
-----------------------------------------------------------------------------------------------------------------------
--	SAMPLE EXEC STATEMENT
--	EXEC	dbo.spLocal_DisplayOfflineQuality_NewSampleResultSet
--	@p_intEventSubtypeId = 25		--	Event SubType id used by the sheet configuration called by the offline quality 
--										display
--=====================================================================================================================
CREATE	PROCEDURE dbo.spLocal_DisplayOfflineQuality_NewSampleResultSet
	@p_intEventSubtypeId 	INT		
AS
SET NOCOUNT ON
--=====================================================================================================================
--	Variable Declaration
--=====================================================================================================================
-- INTEGERS
-----------------------------------------------------------------------------------------------------------------------
 DECLARE	@intErrorCode					INT
-----------------------------------------------------------------------------------------------------------------------
-- VARCHAR
-----------------------------------------------------------------------------------------------------------------------		
 DECLARE	@vchErrorMsg					VARCHAR(1000),
			@vchEventSubtypeDesc			VARCHAR(1000)
-----------------------------------------------------------------------------------------------------------------------
-- TEMPORARY TABLES
-----------------------------------------------------------------------------------------------------------------------
-- Result Set 1
-- Returns miscellaneous information back to the display
-----------------------------------------------------------------------------------------------------------------------
DECLARE	@tblMiscInfo	TABLE	(
		RcdIdx					INT IDENTITY (1,1),
		ErrorCode				INT	DEFAULT 0,
		ErrorMsg				VARCHAR(1000))
-----------------------------------------------------------------------------------------------------------------------
-- Result Set 2
-- Returns miscellaneous information back to the display
-----------------------------------------------------------------------------------------------------------------------
DECLARE	@tblSamplesInformation	TABLE (
		DeptId					INT,
		DeptDesc				VARCHAR(50),
		PLId					INT,
		PLDesc					VARCHAR(50),
		PUId					INT,
		PUDesc					VARCHAR(50),
		CalcVarId				INT,
		CalcDesc				VARCHAR(100),
		CalcId					INT,
		CalcEventSubTypeInputId	INT,
		CalcEventSubType		VARCHAR(50),
		CalcTriggerVarIdInputId	INT,
		CalcTriggerVarId		INT,
		CalcTriggerVarDesc		VARCHAR(50),
		CalcAutoPrintValue		INT,
		CalcPrintKeyWord		VARCHAR(50),
		CalcRePrintKeyWord		VARCHAR(50),
		CalcSampleNumberVarId	INT,
		CalcSampleNumberVarDesc	VARCHAR(100))
--=====================================================================================================================
-- INITIALIZE SP VARIABLES
--=====================================================================================================================
SELECT	@intErrorCode 	= 0,
		@vchErrorMsg 	= ''
-----------------------------------------------------------------------------------------------------------------------
-- GET UDE Description
-----------------------------------------------------------------------------------------------------------------------
SELECT 	@vchEventSubtypeDesc = es.Event_Subtype_Desc
FROM 	dbo.Event_SubTypes	es WITH (NOLOCK)
WHERE 	Event_Subtype_Id = @p_intEventSubtypeId
-----------------------------------------------------------------------------------------------------------------------
-- @MiscInfo table
-----------------------------------------------------------------------------------------------------------------------
INSERT INTO	@tblMiscInfo (	
			ErrorCode	,
			ErrorMsg	)
VALUES	(	@intErrorCode,
			@vchErrorMsg)		
-----------------------------------------------------------------------------------------------------------------------
-- INSERT SAMPLEs INFORMATION
-- Business Rule:
-- Sample variables are time based variables so cannot be looked up using the event sub type
-- for this reason we need to locate them using the calculation configuration in the plant model.
-- 1.	Use the calculation stored procedure name to locate the calculation
-- 2. 	Filter the result set by Event SubType
-- 3. 	Locate the trigger var id
-- 4.	Return all dept,lines,units and varibles to display. New sample pop-up will so the additional filtering 
--		required
-----------------------------------------------------------------------------------------------------------------------
INSERT INTO	@tblSamplesInformation (
			DeptId		,
			DeptDesc	,
			PLId		,
			PLDesc		,
			PUId		,
			PUDesc		,
			CalcVarId	,
			CalcId		,
			CalcDesc,
			CalcEventSubTypeInputId	,
			CalcEventSubType		,
			CalcTriggerVarIdInputId	,
			CalcTriggerVarId		,
			CalcTriggerVarDesc		,
			CalcAutoPrintValue		,
			CalcPrintKeyWord		,
			CalcRePrintKeyWord		,
			CalcSampleNumberVarId	,
			CalcSampleNumberVarDesc)
SELECT	d.Dept_Id,
		d.Dept_Desc,
		pl.PL_Id,
		pl.PL_Desc,
		pu.PU_Id,
		pu.PU_Desc,
		v.Var_Id,	
		v.Calculation_Id,
		v.Var_Desc,
		ci.Calc_Input_Id,
		COALESCE(cid.Default_Value, ci.Default_Value),
		ci2.Calc_Input_Id,
		cid2.Member_Var_Id,
		v2.Var_Desc,
		COALESCE(cid3.Default_Value, ci3.Default_Value),
		cid4.Default_Value,
		cid5.Default_Value,
		cid6.Member_Var_Id,
		v3.Var_Desc
FROM	dbo.Variables	v
	JOIN	dbo.Calculations	c	WITH (NOLOCK)
									ON	c.Calculation_Id = v.Calculation_Id
	JOIN	dbo.Calculation_Inputs	ci	WITH (NOLOCK)
										ON	ci.Calculation_Id = v.Calculation_Id
	LEFT JOIN	dbo.Calculation_Input_Data	cid	WITH (NOLOCK)
											ON	cid.Calc_Input_Id = ci.Calc_Input_Id
											AND	v.Var_Id = cid.Result_Var_Id											
	JOIN	dbo.Calculation_Inputs	ci2		WITH (NOLOCK)
											ON	ci.Calculation_Id = v.Calculation_Id
	JOIN	dbo.Calculation_Input_Data	cid2	WITH (NOLOCK)
											ON	cid2.Calc_Input_Id = ci2.Calc_Input_Id
											AND	v.Var_Id = cid2.Result_Var_Id
	--------------------------------
	LEFT JOIN	dbo.Calculation_Inputs	ci3		WITH (NOLOCK)
											ON	ci.Calculation_Id = v.Calculation_Id
	LEFT JOIN	dbo.Calculation_Input_Data	cid3	WITH (NOLOCK)
											ON	cid3.Calc_Input_Id = ci3.Calc_Input_Id
											AND	v.Var_Id = cid3.Result_Var_Id
	---------------------------------
	LEFT JOIN	dbo.Calculation_Inputs	ci4		WITH (NOLOCK)
											ON	ci.Calculation_Id = v.Calculation_Id
	LEFT JOIN	dbo.Calculation_Input_Data	cid4	WITH (NOLOCK)
											ON	cid4.Calc_Input_Id = ci4.Calc_Input_Id
											AND	v.Var_Id = cid4.Result_Var_Id	
	----------------------------------
	LEFT JOIN	dbo.Calculation_Inputs	ci5		WITH (NOLOCK)
											ON	ci.Calculation_Id = v.Calculation_Id	
	LEFT JOIN	dbo.Calculation_Input_Data	cid5	WITH (NOLOCK)
											ON	cid5.Calc_Input_Id = ci5.Calc_Input_Id
											AND	v.Var_Id = cid5.Result_Var_Id	
	-----------------------------------
	LEFT JOIN	dbo.Calculation_Inputs	ci6		WITH (NOLOCK)
											ON	ci.Calculation_Id = v.Calculation_Id	
	LEFT JOIN	dbo.Calculation_Input_Data	cid6	WITH (NOLOCK)
											ON	cid6.Calc_Input_Id = ci6.Calc_Input_Id
											AND	v.Var_Id = cid6.Result_Var_Id	
	LEFT JOIN	dbo.Variables	v3				ON v3.Var_Id = cid6.Member_Var_Id
	------------------------------------
	JOIN	dbo.Variables	v2	WITH (NOLOCK)
								ON	cid2.Member_Var_Id = v2.Var_Id
	JOIN	dbo.Prod_Units	pu	WITH (NOLOCK)
								ON	pu.PU_Id = v.PU_Id
	JOIN	dbo.Prod_Lines	pl	WITH (NOLOCK)
								ON	pl.PL_Id = pu.PL_Id
	JOIN	dbo.Departments	d	WITH (NOLOCK)
								ON	d.Dept_Id = pl.Dept_Id
WHERE	c.Calculation_Type_Id = 2
	AND	c.Stored_Procedure_Name = 'Calc_OQ_CreateSampleUDEs'
	AND	ci.Input_Name = 'UDESubTypeDesc'
	AND	ci2.Input_Name = 'TriggerVarId'
	AND ci3.Input_Name = 'SampleLabelAutoPrint'
	AND ci4.Input_Name = 'PrintKeyWord'
	AND ci5.Input_Name = 'RePrintKeyWord'
	AND ci6.Input_Name = 'SampleNumberVarId'
	AND cid.Default_Value = @vchEventSubtypeDesc 	
/*INSERT INTO	@tblSamplesInformation (
			DeptId		,
			DeptDesc	,
			PLId		,
			PLDesc		,
			PUId		,
			PUDesc		,
			CalcVarId	,
			CalcId		,
			CalcDesc,
			CalcEventSubTypeInputId	,
			CalcEventSubType		,
			CalcTriggerVarIdInputId	,
			CalcTriggerVarId		,
			CalcTriggerVarDesc		,
			CalcAutoPrintValue		,
			CalcPrintKeyWord		,
			CalcRePrintKeyWord		,
			CalcSampleNumberVarId	,
			CalcSampleNumberVarDesc)
SELECT	DISTINCT 
		d.Dept_Id,
		d.Dept_Desc,
		pl.PL_Id,
		pl.PL_Desc,
		pu.PU_Id,
		pu.PU_Desc,
		v.Var_Id,	
		v.Calculation_Id,
		v.Var_Desc,
		ci.Calc_Input_Id,
		COALESCE(cid.Default_Value, ci.Default_Value),
		ci2.Calc_Input_Id,
		cid2.Member_Var_Id,
		v2.Var_Desc,
		COALESCE(cid3.Default_Value, ci3.Default_Value),
		cid4.Default_Value,
		cid5.Default_Value,
		cid6.Member_Var_Id,
		v3.Var_Desc
FROM	dbo.Variables	v
	JOIN	dbo.Calculations	c	WITH (NOLOCK)
									ON	c.Calculation_Id = v.Calculation_Id
	JOIN	dbo.Calculation_Inputs	ci	WITH (NOLOCK)
										ON	ci.Calculation_Id = v.Calculation_Id
	LEFT JOIN	dbo.Calculation_Input_Data	cid	WITH (NOLOCK)
											ON	cid.Calc_Input_Id = ci.Calc_Input_Id
											AND	v.Var_Id = cid.Result_Var_Id											
	JOIN	dbo.Calculation_Inputs	ci2		WITH (NOLOCK)
											ON	ci.Calculation_Id = v.Calculation_Id
	JOIN	dbo.Calculation_Input_Data	cid2	WITH (NOLOCK)
											ON	cid2.Calc_Input_Id = ci2.Calc_Input_Id
											AND	v.Var_Id = cid2.Result_Var_Id
	--------------------------------
	JOIN	dbo.Calculation_Inputs	ci3		WITH (NOLOCK)
											ON	ci.Calculation_Id = v.Calculation_Id
	JOIN	dbo.Calculation_Input_Data	cid3	WITH (NOLOCK)
											ON	cid3.Calc_Input_Id = ci3.Calc_Input_Id
											AND	v.Var_Id = cid3.Result_Var_Id
	---------------------------------
	JOIN	dbo.Calculation_Inputs	ci4		WITH (NOLOCK)
											ON	ci.Calculation_Id = v.Calculation_Id
	JOIN	dbo.Calculation_Input_Data	cid4	WITH (NOLOCK)
											ON	cid4.Calc_Input_Id = ci4.Calc_Input_Id
											AND	v.Var_Id = cid4.Result_Var_Id	
	----------------------------------
	JOIN	dbo.Calculation_Inputs	ci5		WITH (NOLOCK)
											ON	ci.Calculation_Id = v.Calculation_Id	
	JOIN	dbo.Calculation_Input_Data	cid5	WITH (NOLOCK)
											ON	cid5.Calc_Input_Id = ci5.Calc_Input_Id
											AND	v.Var_Id = cid5.Result_Var_Id	
	-----------------------------------
	JOIN	dbo.Calculation_Inputs	ci6		WITH (NOLOCK)
											ON	ci.Calculation_Id = v.Calculation_Id	
	LEFT JOIN	dbo.Calculation_Input_Data	cid6	WITH (NOLOCK)
											ON	cid6.Calc_Input_Id = ci6.Calc_Input_Id
											AND	v.Var_Id = cid6.Result_Var_Id	
	LEFT JOIN	dbo.Variables	v3				ON v3.Var_Id = cid6.Member_Var_Id
	------------------------------------
	JOIN	dbo.Variables	v2	WITH (NOLOCK)
								ON	cid2.Member_Var_Id = v2.Var_Id
	JOIN	dbo.Prod_Units	pu	WITH (NOLOCK)
								ON	pu.PU_Id = v.PU_Id
	JOIN	dbo.Prod_Lines	pl	WITH (NOLOCK)
								ON	pl.PL_Id = pu.PL_Id
	JOIN	dbo.Departments	d	WITH (NOLOCK)
								ON	d.Dept_Id = pl.Dept_Id
WHERE	c.Calculation_Type_Id = 2
	AND	c.Stored_Procedure_Name = 'Calc_OQ_CreateSampleUDEs'
	AND	ci.Input_Name = 'UDESubTypeDesc'
	AND	ci2.Input_Name = 'TriggerVarId'
	AND ci3.Input_Name = 'SampleLabelAutoPrint'
	AND ci4.Input_Name = 'PrintKeyWord'
	AND ci5.Input_Name = 'RePrintKeyWord'
	AND ci6.Input_Name = 'SampleNumberVarId'*/
-----------------------------------------------------------------------------------------------------------------------
-- Remove values that doesn't belong to the event subtype specified
-----------------------------------------------------------------------------------------------------------------------
DELETE FROM @tblSamplesInformation
WHERE CalcEventSubType <> @vchEventSubtypeDesc
--=====================================================================================================================		
-- RETURN Result Sets
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
	-------------------------------------------------------------------------------------------------------------------
	-- RS2: Samples Information result set
	-------------------------------------------------------------------------------------------------------------------
	SELECT	*	FROM	@tblSamplesInformation
END

SET NOCOUNT OFF
RETURN

