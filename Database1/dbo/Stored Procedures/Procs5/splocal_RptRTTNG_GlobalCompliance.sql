
--=======================================================================================================================
-- Report Name			: RTT Global Compliance Report
-- Store Procedure Name : splocal_RptRTTNG_GlobalCompliance
-- Template Name 		:
-- Tab Spacing			: 4
-------------------------------------------------------------------------------------------------------------------------
-- EDIT HISTORY
-- ========		====			===					====
-- 1.0			2008-05-12		FRio				Initial Development
-- 1.1			2009-06-07		Martin Casalis		Store procedure re-writed to meet RTT-To-Core development
-- 1.2			2010-04-07		Martin Casalis		Revised Version
-- 1.2			2018-09-11		Santiago Gimenez	Add If EXISTS
--=======================================================================================================================

--=======================================================================================================================
CREATE    PROCEDURE [dbo].[splocal_RptRTTNG_GlobalCompliance]
--=======================================================================================================================

-- DECLARE
	
			@RptName		NVARCHAR(200)

AS

DECLARE
			
			@PL_id  					INT,
			@TimeStamp					DATETIME,
			@pu_id 						INT,
			@prop_id					INT,
			@pl_desc					VARCHAR(50),
			@Area						VARCHAR(10),
			@strSql						VARCHAR(5000),
			@Site 						VARCHAR(100), 
			@VarTableId					int,
			@AuditFreqUDP				nvarchar(20),
			@AreaUDP					nvarchar(20)


-----------------------------------------------------------------------------------------------------------------
-- CREATE ALL TEMPORARY TABLES
-----------------------------------------------------------------------------------------------------------------
CREATE TABLE #Var_IDs(
					 Var_ID   		INT,
					 Spec_id   		INT,
					 PL_ID   		INT,
					 PU_ID   		INT,
					 Var_Desc		VARCHAR(250),
					PL_Desc		VARCHAR(250),
					Area			varchar(20)
						)

CREATE TABLE #PL_groups	(
									PL_ID   		INT,
									PL_DESC			VARCHAR(200),
									PU_ID 			INT,
									PUG_ID 			INT,
									PUG_DESC 		VARCHAR(30),
									PU_DESC 		VARCHAR(30))


CREATE TABLE #STI_All (
									PL_Desc 		VARCHAR(100),
									Area 			VARCHAR(10),
									Var_Desc		VARCHAR(250),
									P_LSL 			VARCHAR(10),
									P_LCL  			VARCHAR(10), 
									P_LWL  			VARCHAR(10), 
									P_Target  		VARCHAR(10), 
									P_UWL  			VARCHAR(10), 
									P_UCL  			VARCHAR(10), 
									P_USL  			VARCHAR(10),
									P_test_freq 	VARCHAR(10),
									C_LSL  			VARCHAR(10),
									C_LCL  			VARCHAR(10), 
									C_LWL  			VARCHAR(10), 
									C_Target  		VARCHAR(10), 
									C_UWL  			VARCHAR(10), 
									C_UCL  			VARCHAR(10), 
									C_USL  			VARCHAR(10),
									C_Test_Freq 	VARCHAR(10), 
									C_is_defined 	VARCHAR(10),
									Char_desc		VARCHAR(250) 		)

CREATE TABLE #Sti_result (
									PL_Desc			VARCHAR(100),
									Area			VARCHAR(10),
									Over_ride		INT,
									NotOverride		INT	)

CREATE TABLE #PL_IDs
					(RCDID   						INT,
					 PL_Desc 						NVARCHAR(100),
					 PL_id  						INT	)

-----------------------------------------------------------------------------------------------------------------
-- GET Report Parameters		
-----------------------------------------------------------------------------------------------------------------
DECLARE

	@in_LineDesc 		    	NVARCHAR(250)
	
IF	Len(@RptName) > 0	
BEGIN

		EXEC	spCmn_GetReportParameterValue 	@RptName, 'Local_PG_strLinesByName1','', @in_LineDesc OUTPUT
END
ELSE
BEGIN
		SELECT 
			@in_LineDesc 		=	'Line 09 PRJA-009 Pringles'		
END
-----------------------------------------------------------------------------------------------------------------
-- Get the Site Name
-----------------------------------------------------------------------------------------------------------------

SELECT @Site = Value FROM Site_Parameters WHERE Parm_Id = 12

-----------------------------------------------------------------------------------------------------------------
-- Get the Line List
-----------------------------------------------------------------------------------------------------------------

INSERT #PL_IDs (RCDID, PL_Desc)
	EXEC SPCMN_ReportCollectionParsing
		@PRMCollectionString = @in_LineDesc, @PRMFieldDelimiter = NULL, @PRMRecordDelimiter = ',',	
		@PRMDataType01 = 'NVARCHAR (100)'

UPDATE #PL_IDs 
	SET PL_ID = pl.PL_ID 
FROM dbo.Prod_Lines 				pl 		WITH(NOLOCK) 
JOIN #PL_Ids 						pl2		ON			pl.PL_Desc =  pl2.PL_Desc 


-- select '#PL_IDs',* from #PL_IDs
-----------------------------------------------------------------------------------------------------------------
-- Get all lines FROM the server or get a specific line

SET @VarTableId 		= (SELECT TableId FROM dbo.Tables WHERE TableName = 'Variables')
SET @AuditFreqUDP	 	= (SELECT Table_Field_id FROM dbo.Table_Fields WHERE Table_Field_Desc = 'RTT_AuditFreq')
SET	@AreaUDP			= (SELECT Table_Field_id FROM dbo.Table_Fields WHERE Table_Field_Desc = 'RTT_EquipmentGroup')

IF @in_LineDesc IS NULL
	BEGIN
		INSERT INTO #Var_IDs(
					 Var_ID,
					Spec_id,
					 PL_ID,
					 PU_ID,
					 Var_Desc,
					 PL_Desc,
					Area
							)
		SELECT 		v.Var_id,
					v.Spec_id,
					pl.PL_ID,
					puids.PU_ID,
					v.Var_Desc,
					pl.PL_Desc,
					pug.PUG_Desc
		FROM dbo.Variables 					v	  	WITH(NOLOCK)		
		JOIN dbo.Prod_Units 				puids 	WITH(NOLOCK)
													ON puids.PU_Id = v.PU_Id
		JOIN dbo.PU_Groups	pug			WITH(NOLOCK) ON pug.pug_id = v.pug_id
		JOIN dbo.Prod_Lines pl 	   		WITH(NOLOCK) ON puids.pl_id = pl.pl_id						
		JOIN dbo.Table_Fields_Values 		tfv 	WITH(NOLOCK)
													ON tfv.KeyId = v.Var_Id
		WHERE 	tfv.TableId = @VarTableId
				AND	tfv.Table_Field_id = @AuditFreqUDP
	END
ELSE
	BEGIN
		INSERT INTO #Var_IDs(
					 Var_ID,
					 Spec_id,
					 PL_ID,
					 PU_ID,
					 Var_Desc,
					PL_Desc,
					Area
							)
		SELECT 		v.Var_id,
					v.Spec_id,
					pl.PL_ID,
					puids.PU_ID,
					v.Var_Desc,	
					pl.PL_Desc,
					pug.PUG_Desc
		FROM dbo.Variables 					v	  	WITH(NOLOCK)		
		JOIN dbo.Table_Fields_Values 		tfv 	WITH(NOLOCK)
													ON tfv.KeyId = v.Var_Id
		JOIN dbo.Prod_Units 				puids 	WITH(NOLOCK)
													ON puids.PU_Id = v.PU_Id
		JOIN dbo.PU_Groups	pug			WITH(NOLOCK) ON pug.pug_id = v.pug_id
		JOIN #PL_Ids       					pl	  	ON pl.PL_id = puids.PL_Id
		WHERE 	tfv.TableId = @VarTableId
				AND	tfv.Table_Field_id = @AuditFreqUDP
	END


UPDATE #Var_IDs
SET Area = tfv.value
from #Var_IDs v
	JOIN dbo.Table_Fields_Values tfv WITH(NOLOCK) ON tfv.KeyId = v.var_id
	WHERE 	tfv.TableId = @VarTableId
			AND	tfv.Table_Field_id = @AreaUDP



--select '#var_ids',* from #var_ids
-----------------------------------------------------------------------------------------------------------------
--IF @in_LineDesc IS NULL		
--	BEGIN

	INSERT INTO  #Sti_ALL	(		PL_Desc 		,
									Area 			,
									Var_Desc		,
									P_LSL 			,
									P_LCL  			, 
									P_LWL  			, 
									P_Target  		, 
									P_UWL  			, 
									P_UCL  			, 
									P_USL  			,
									P_test_freq 	,
									C_LSL  			,
									C_LCL  			, 
									C_LWL  			, 
									C_Target  		, 
									C_UWL  			, 
									C_UCL  			, 
									C_USL  			,
									C_Test_Freq 	, 
									C_is_defined 	,
									Char_desc		)
	SELECT	TOP 10000				v.pl_Desc Line, 
									v.Area,
									v.var_desc Variable ,
									asp1.L_reject LSL,
									asp1.L_Warning LCL, 	
									asp1.L_user LWL, 
									asp1.target Target, 
									asp1.U_user UWL,
									asp1.U_Warning UCL, 
									asp1.U_Reject USL,
									asp1.test_freq [Test Freq],
									asp.L_reject LSL,
									asp.L_Warning LCL, 
									asp.L_user LWL, 
									asp.target Target, 
									asp.U_user UWL,
									asp.U_Warning UCL, 
									asp.U_Reject USL,
									asp.test_freq [Test Freq], 
									asp.is_defined,
									c.char_desc 
	FROM dbo.Active_Specs asp
	JOIN #Var_IDs v 			WITH(NOLOCK) ON 	v.Spec_Id	=	asp.Spec_Id 
            						AND asp.Expiration_Date IS NULL 
            						--AND IsNumeric(SubString(Var_Desc,1,1)) <> 0
	JOIN dbo.Specifications s 		WITH(NOLOCK) ON 	s.Spec_Id	=	asp.spec_id
    JOIN dbo.Product_Properties pp 	WITH(NOLOCK) ON 	pp.prop_id	=	s.prop_id
	JOIN dbo.Characteristics c 		WITH(NOLOCK) ON  	c.Char_id	=	asp.char_id 	
--									AND	c.char_desc LIKE '%' + v.pl_desc
    left JOIN dbo.Active_Specs asp1 		WITH(NOLOCK) ON 	asp1.char_id	=	c.derived_FROM_parent 
									AND asp1.Expiration_Date IS NULL 
									AND asp1.Spec_Id	=	v.spec_id


						
-- select '#Sti_ALL',* from #Sti_ALL
-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------
--
-- CHECK HOW THIS UPDATES STATEMENTS REPLACE THE CURSOR ABOVE >>>>>>>>>>>

INSERT INTO  #Sti_result (PL_Desc, Area, Over_Ride,NotOverride)
SELECT DISTINCT PL_Desc, Area, 0, 0 FROM #STI_All

UPDATE #Sti_result 
				SET Over_Ride = (SELECT count(*) 
								FROM #STI_all
								WHERE 	PL_Desc 	= 	r.PL_Desc 
										AND Area	=	r.Area
										AND C_is_defined IS NOT NULL 
										AND C_is_defined > 0)
FROM #STI_Result r
JOIN (SELECT DISTINCT PL_Desc, Area FROM #STI_All) a ON r.PL_Desc	= a.PL_Desc	
														AND	r.Area	= a.Area								


UPDATE #STI_Result 
				SET NotOverride = (SELECT count(*) 
								   FROM #STI_All
								   WHERE PL_Desc 	= 	r.PL_Desc 
										AND Area	=	r.Area
										AND (C_is_defined IS NULL OR c_is_defined	=	0))
FROM #STI_Result r
JOIN (SELECT DISTINCT PL_Desc, Area FROM #STI_All) a ON r.PL_Desc	=	a.PL_Desc	AND	r.Area	=	a.Area								
-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------

SELECT DISTINCT @Site AS Site,@in_LineDesc AS Line_List,getdate() AS StartTime,'All' AS Area 

--	SELECT for sheet1
SELECT Pl_Desc Line, Area, Over_Ride as 'Override', NotOverride 
FROM #Sti_Result

--	SELECT for sheet2
SELECT 	distinct		pl_Desc 			Line		, 
						Area 				Area		,
						Var_Desc 			Variable 	,
						P_LSL 							,
						P_LCL 							, 
						P_LWL 							, 
						P_Target			P_Tgt		, 
						P_UWL 							,
						P_UCL 							, 
						P_USL 							,
						P_Test_Freq 		P_Fx		,
						C_LSL 							,
						C_LCL 							, 
						C_LWL 							, 
						C_Target 			C_Tgt		, 
						C_UWL 							,	
						C_UCL 							, 
						C_USL 							,
						C_Test_Freq 		C_Fx		, 
						char_desc 			[Description], 
						0 as C_is_defined  
FROM #Sti_All 
WHERE C_is_defined IS NOT NULL 
	  AND C_is_defined > 0 
ORDER BY pl_desc,Area

-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------
DROP TABLE #Var_IDs
DROP TABLE #STI_All
DROP TABLE #STI_Result
DROP TABLE #PL_Groups
DROP TABLE #PL_IDs

