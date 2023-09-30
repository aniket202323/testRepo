
--------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_ChtInteractiveTrend
---------------------------------------------------------------------------------------------------
-- Author				: FIT
-- Date created			: 2013-3-21
-- Version 				: 1.2
-- SP Type				: Report Stored Procedure
-- Caller				: Report
-- Description			: This Report will be used to populate the charting tools for FIT4MI
-- 
-- Editor tab spacing	: 4 
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
---------------------------------------------------------------------------------------------------
-- ========	====	  		====							=====
-- 1.0		2013-3-21		Fernando Rio - Facundo Sosa     Initial Release
-- 1.1		2013-4-24		Fernando Rio					Changed @All_Variables table to temp table as SQL 2008 does not support on the fly inserts on Variable Tables.
-- 1.2		2013-6-11		Fernando Rio					Fixed issue with slave units not showing up specs.
-- 1.3		2016-4-26       Facundo Sosa					Update Time Option based on the Frequency of the variable.
---------------------------------------------------------------------------------------------------
-- Specifications Report
---------------------------------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[spLocal_ChtInteractiveTrend]
--DECLARE
		@var_List               		NVARCHAR(4000)	,	-- Var Id
		@cnt_tests						INT				,	-- If 0 it searchs by dates, else last @cnt_tests Tests.
		@in_StartTime          			DATETIME	   	,	-- Start Time of Sample Set
		@in_EndTime            			DATETIME       		-- End Time of Sample Set

AS



---------------------------------------------------------------------------------------------------------------
-- Variable tables
---------------------------------------------------------------------------------------------------------------
DECLARE @PLIDList  TABLE (
			RCDID						INT			,							
			PL_ID						INT			,
			PL_Desc						NVARCHAR(200)	,
			in_StartTime				DATETIME		,
			in_EndTime					DATETIME )

---------------------------------------------------------------------------------------------------
DECLARE @Var_IDs TABLE (	
			RCDID   					INT,
         	Var_ID  					INT,
			PVarId						INT DEFAULT NULL,
            Var_Desc 					NVARCHAR(255),
        	PUId	 					INT,
            PUG_Id  					INT,
        	Data_Type_id 				INT,
        	PLID 						INT,
        	PLDESC 						NVARCHAR(50),	
			SourcePUId					INT,
			VarDataTypeId				INT,
			IsReportable				INT	DEFAULT 1,	-- Options: 1 = YES; 0 = NO
			IsConverting				INT DEFAULT 0,	-- Options: 1 = YES; 0 = NO
			Frequency					NVARCHAR(50)
			)

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
CREATE TABLE #All_Variables    (	
			Var_ID 						INT				,
            Var_Desc 					NVARCHAR(255)	,
			PL_Id						INT				,
			PL_Desc						NVARCHAR(200)	,
            Pu_Id   					INT				,
            MasterPUId					INT				,
			SourcePU_Id					INT				,
            Pug_Desc 					NVARCHAR(150)	,
            Pu_Desc 					NVARCHAR(150)	,
        	Result_on 					DATETIME		NULL,
            Entry_on 					DATETIME		NULL,
            Entry_By 					NVARCHAR(150)	,
        	Result 						NVARCHAR(50)		,
        	L_Reject 					NVARCHAR(25)		, 
        	L_Warning 					NVARCHAR(25)		, -- shifted L_Control
        	L_User 						NVARCHAR(25)		, -- Now will hold the Target Low
			L_Control					NVARCHAR(25)     , -- L_Warning ( again)
        	Target 						NVARCHAR(25)		,
			U_Control					NVARCHAR(25)		, -- U_Warning ( again)
        	U_User 						NVARCHAR(25)		, -- Now will hold the Target High
        	U_Warning 					NVARCHAR(25)		, -- shifted U_Control
        	U_Reject 					NVARCHAR(25)		,
        	Prod_ID 					INT				,
        	Prod_Desc					NVARCHAR(100)		,
            Prod_Group          		NVARCHAR(75)		,
			SourceProd_Id				INT				,
			TestCount					INT				,
			MaxValue					FLOAT			,
			MinValue					FLOAT			,
			Average						FLOAT			,
			StDevs						FLOAT			,
			Defect						INT				,	
			SourceTime					DATETIME		,		
			NonNumericFlag				INT				)
---------------------------------------------------------------------------------------------------
DECLARE @Production_Starts  TABLE(
	 		Pu_id						INT				,
			Start_Time					DATETIME		,
			END_Time					DATETIME		,
			Prod_Id						INT			) 

-----------------------------------------------------------------------------------------------------------------------
-- DECLARE Variables that will be used by the sp
-----------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------
-- VARCHARS
-----------------------------------------------------------------------------------------------------------------------
DECLARE		@strSQL							NVARCHAR(4000)		
-----------------------------------------------------------------------------------------------------------------------
-- IF variable list IS empty then get variables FROM the PUG List
-----------------------------------------------------------------------------------------------------------------------
--	a.	IF a list of variables is selected return all variables that match the variable description
-----------------------------------------------------------------------------------------------------------------------
IF @Var_List > ''
BEGIN
        INSERT @Var_IDs (RCDID, var_id)
			EXEC SPCMN_ReportCollectionParsing
				@PRMCollectionString = @var_List, 
				@PRMFieldDelimiter = NULL,
				@PRMRecordDelimiter = ',', @PRMDataType01 = 'INT'	

		-- If a Variable Selected belongs to a different Line than the ones in the LIne selection page
		-- then add to the Line List
		INSERT INTO @PLIDList (	PL_Id )
			SELECT DISTINCT pl.PL_Id
				FROM	dbo.Prod_Lines	pl		WITH(NOLOCK) 
				JOIN 	dbo.Prod_Units	pu		WITH(NOLOCK)	ON pl.PL_Id	= pu.PL_Id
				JOIN 	dbo.Variables		v	WITH(NOLOCK)    ON v.PU_Id	= pu.PU_Id
				JOIN	@Var_IDs				vids			ON v.Var_Id	= vids.Var_Id
				WHERE  	pl.PL_Id NOT IN (SELECT PL_ID FROM @PLIDList)

		-------------------------------------------------------------------------------------------------------------------------------------
		-- Get all variables from Lines Selected on the report that matches the variable description.
		-------------------------------------------------------------------------------------------------------------------------------------
		--ALTER TABLE @Var_IDs ADD id integer IDENTITY(1,1) CONSTRAINT id PRIMARY KEY CLUSTERED  

		INSERT INTO @Var_IDs (Var_Id)    
			SELECT V2.VAR_ID 
				FROM @Var_IDs				tv	
				JOIN dbo.Variables	V   WITH(NOLOCK) ON V.var_id = tv.Var_id    
				JOIN dbo.Variables	V2  WITH(NOLOCK) ON V2.Var_Desc = V.Var_Desc  AND v2.var_id!=tv.var_id  
				JOIN dbo.Prod_Units	Pu	WITH(NOLOCK) ON Pu.Pu_id = v2.Pu_id    
				JOIN @PLIDList				PL	ON pl.PL_Id = pu.PL_Id    

END



-------------------------------------------------------------------------------------------------------------------------
-- INSERT Child Variables from Master Variables
-- 1. ONLY IF THEY ARE REPORTABLE !
-- 2. If child variables exists, then delete parent variable.
-------------------------------------------------------------------------------------------------------------------------
INSERT INTO @Var_IDs ( 
			Var_Id		,
			PVarId 		)
SELECT 		v.Var_Id 	,
			v.PVar_Id
	FROM 	@Var_IDs 			vids
	JOIN	dbo.Variables v	WITH(NOLOCK) ON v.PVar_Id = vids.Var_Id	
	WHERE 	vids.Var_Id NOT IN (SELECT Var_Id FROM @Var_IDs)

--=======================================================================================================================
-- After getting all Variables update the all columns information
--=======================================================================================================================
UPDATE @Var_IDs 
	SET	PUId			= CASE WHEN PUId IS NULL THEN v.PU_Id ELSE tv.PUId END,
		PLID 			= pu.PL_ID			,
		Data_Type_id 	= V.Data_Type_id	, 
        Var_Desc 		= V.Var_Desc		, 
		PUG_Id 			= V.Pug_Id			,
		VarDataTypeId   = v.Data_Type_Id	,
		Frequency       = (CASE 
			WHEN v.Extended_Info LIKE '%PAS%'  THEN  'Shiftly'
			WHEN v.Extended_Info LIKE '%PAD%'  THEN  'Daily'
			WHEN v.Extended_Info LIKE '%PAW%'  THEN  'Weekly'
			WHEN v.Extended_Info LIKE '%PAM%'  THEN  'Monthly'
			WHEN v.Extended_Info LIKE '%PAQ%'  THEN  'Quarterly'								END)
	FROM dbo.Variables 	v	WITH(NOLOCK)
	JOIN dbo.Prod_Units 	pu	WITH(NOLOCK) ON pu.PU_Id = v.PU_Id
	JOIN @Var_IDs tv 							ON tv.var_id = v.var_id


DELETE FROM @PLIDList
	WHERE PL_ID NOT IN (SELECT DISTINCT PLID FROM @Var_IDs)


-------------------------------------------------------------------------------------------------------------------------
-- Update Time Option based Frequency of the variable.
-------------------------------------------------------------------------------------------------------------------------

SELECT  @in_EndTime   = GETDATE()	   	,	-- Start Time of Sample Set
		@in_StartTime =(CASE 
			WHEN Frequency LIKE 'Shiftly'	THEN  DATEADD(dd,- @cnt_tests, @in_EndTime)
			WHEN Frequency LIKE 'Daily'		THEN  DATEADD(dd,- (@cnt_tests + 1), @in_EndTime)
			WHEN Frequency LIKE 'Weekly'	THEN  DATEADD(week,- @cnt_tests, @in_EndTime)
			WHEN Frequency LIKE 'Monthly'	THEN  DATEADD(month,- @cnt_tests, @in_EndTime)
			WHEN Frequency LIKE 'Quarterly' THEN  DATEADD(quarter,- @cnt_tests, @in_EndTime)
			ELSE DATEADD(dd,-200,@in_EndTime)
						END)
FROM @Var_IDs

-------------------------------------------------------------------------------------------------------------------------
-- Update the Production Line Description
-------------------------------------------------------------------------------------------------------------------------
UPDATE @PLIDList
	SET PL_Desc = PL.PL_Desc,
		in_StartTime = @in_StartTime,
		in_EndTime = @in_ENDTime
FROM @PLIDList PLid
JOIN dbo.Prod_Lines PL  WITH(NOLOCK) ON PL.PL_Id = PLid.PL_id

-------------------------------------------------------------------------------------------------------------------------
--                                 Main Processing                                     								   --
-------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
-- Get all tests for Converting Unit
------------------------------------------------------------------------------------------------------------------
-- Builds SQL			
SELECT @strSQL = 'SELECT  TOP ' + CONVERT(NVARCHAR,@cnt_tests) + ' t.Var_id, v.Var_Desc, pu.PL_Id, pl.PL_Desc, v.PU_Id, pu.pu_desc, pug.Pug_Desc, '
SELECT @strSQL = @strSQL + ' t.Result_On, t.Entry_On, t.Result_On, u.UserName, CONVERT(NVARCHAR,T.Result) , '
SELECT @strSQL = @strSQL + ''''', '''', 0	, ' -- , Var_Desc, '
SELECT @strSQL = @strSQL + 'CASE WHEN v.Data_Type_Id = 1 THEN 0 WHEN v.Data_Type_Id = 2 THEN 0 '
SELECT @strSQL = @strSQL + 'WHEN v.Data_Type_Id = 6 THEN 0 WHEN v.Data_Type_Id = 7 THEN 0 ELSE	1 END '
SELECT @strSQL = @strSQL + 'FROM dbo.Tests 			t 		WITH(NOLOCK) '
SELECT @strSQL = @strSQL + 'JOIN dbo.variables		v		WITH(NOLOCK) ON v.var_id = t.var_id '
SELECT @strSQL = @strSQL + 'JOIN dbo.PU_Groups 		pug		WITH(NOLOCK) ON v.pug_id = pug.pug_id '
SELECT @strSQL = @strSQL + 'JOIN dbo.Prod_units		pu		WITH(NOLOCK) ON v.PU_Id = pu.pu_id '
SELECT @strSQL = @strSQL + 'JOIN dbo.Prod_Lines		pl		WITH(NOLOCK) ON pu.Pl_Id = pl.pl_id '
SELECT @strSQL = @strSQL + 'JOIN dbo.Users 			u 		WITH(NOLOCK) ON t.Entry_by = u.user_id '
SELECT @strSQL = @strSQL + 'WHERE T.Result IS NOT NULL '
SELECT @strSQL = @strSQL + 'AND T.Result <> '''' '
SELECT @strSQL = @strSQL + 'AND T.Result <> ''NULL'' '
SELECT @strSQL = @strSQL + 'AND t.Canceled = 0 '
SELECT @strSQL = @strSQL + 'AND t.var_id = ' + CONVERT(NVARCHAR,@var_List) 
SELECT @strSQL = @strSQL + 'AND t.Result_On BETWEEN ''' + CONVERT(NVARCHAR,@in_StartTime) + ''' AND ''' + CONVERT(NVARCHAR,@in_EndTime) + ''''
SELECT @strSQL = @strSQL + 'ORDER BY t.Result_On DESC '


-- Retrieve Tests
INSERT INTO #All_Variables 
		(			Var_ID, 
					Var_Desc, 
					PL_ID,
					PL_Desc,
					Pu_Id,
					Pu_Desc,
					Pug_Desc,  
					Result_On,  
					Entry_on, 
					SourceTime,
					Entry_by,
					Result, 
					Prod_Id,
					Prod_Desc,
					Defect		,
					NonNumericFlag )
EXECUTE (@strSQL)

UPDATE #All_Variables
		SET MasterPUId = ISNULL(pu.Master_Unit, av.PU_Id)
FROM #All_Variables		av
LEFT JOIN dbo.Prod_Units pu ON av.PU_Id = pu.PU_Id

--SELECT '@All_Variables-1', result, * FROM #All_Variables

-------------------------------------------------------------------------------------------------------------------------
-- 								   Create AND Populate the Base Table
-------------------------------------------------------------------------------------------------------------------------
INSERT INTO @Production_Starts (PU_Id,
				Start_Time,
				END_Time,
				Prod_Id )
SELECT 			av.PU_Id	,    
				Start_Time		,
				END_Time		,
				ps.Prod_Id 
FROM			dbo.Production_Starts		ps 	WITH(NOLOCK)	
JOIN            #All_Variables					av 
												ON av.MasterPUId = ps.PU_Id 
WHERE           ps.Start_Time <= @in_EndTime
				AND (ps.End_Time > @in_StartTime OR ps.End_Time IS NULL)	


--SELECT '@Production_Starts',* FROM @Production_Starts
-----------------------------------------------------------------------------------------------------------------------
--	Update Product information
-----------------------------------------------------------------------------------------------------------------------
-- Product Information from Converter
UPDATE #All_Variables
	SET Prod_Id			=	Tpi.Prod_Id,
		Prod_Desc		=	Tpi.Prod_Desc
		FROM #All_Variables		av
	JOIN @Production_Starts ps	ON PS.Start_Time <= av.Result_On
   								AND (PS.END_Time > av.Result_On OR PS.END_Time IS NULL) 
								AND PS.PU_ID = av.PU_Id
	JOIN dbo.Products tpi WITH(NOLOCK)  ON ps.Prod_ID = tpi.Prod_id   
	WHERE av.SourcePU_Id IS NULL


-- Product Information from Converter for Paper Machine variables
UPDATE #All_Variables
	SET Prod_Id			=	Tpi.Prod_Id,
		Prod_Desc		=	Tpi.Prod_Desc
	FROM #All_Variables		av
	JOIN @Production_Starts ps	ON PS.Start_Time <= av.SourceTime
   								AND (PS.END_Time > av.SourceTime OR PS.END_Time IS NULL) 
								AND ps.PU_ID = av.PU_Id
	JOIN dbo.Products tpi WITH(NOLOCK) ON ps.Prod_ID = tpi.Prod_id   

-----------------------------------------------------------------------------------------------------------------------
-- Get Variable Specification
-----------------------------------------------------------------------------------------------------------------------
UPDATE #All_Variables
    SET L_Reject  = vs.L_Reject ,
		L_Warning = vs.L_Warning,
		L_User    = vs.L_User ,
		Target    = vs.Target ,
		U_User    = vs.U_User,
		U_Warning = vs.U_Warning,
		U_Reject  = vs.U_Reject ,
		L_Control = vs.L_Control,
		U_Control = vs.U_Control
	FROM #All_Variables			Av
	JOIN dbo.Var_Specs	VS	WITH(NOLOCK) ON VS.Var_ID = Av.Var_ID AND VS.Prod_Id = Av.Prod_id
									AND VS.Effective_Date < Av.Result_ON
									AND (VS.Expiration_Date > Av.Result_ON OR VS.Expiration_Date IS NULL) 
	WHERE Av.SourcePU_Id IS NULL

UPDATE #All_Variables
    SET L_Reject  = vs.L_Reject ,
		L_Warning = vs.L_Warning,
		L_User    = vs.L_User ,
		Target    = vs.Target ,
		U_User    = vs.U_User,
		U_Warning = vs.U_Warning,
		U_Reject  = vs.U_Reject ,
		L_Control = vs.L_Control,
		U_Control = vs.U_Control
	FROM #All_Variables			Av
	JOIN dbo.Var_Specs	VS  WITH(NOLOCK) ON VS.Var_ID = Av.Var_ID AND VS.Prod_Id = Av.SourceProd_id
									AND VS.Effective_Date < Av.Result_ON
									AND (VS.Expiration_Date > Av.Result_ON OR VS.Expiration_Date IS NULL) 
	WHERE Av.SourcePU_Id IS NOT NULL

-----------------------------------------------------------------------------------------------------------------------
-- Convert data back to float (numeric) format for NUMERIC Variables
-----------------------------------------------------------------------------------------------------------------------
UPDATE #All_Variables
	SET 	Result 		= 	Convert(float, result),
			L_reject 	= 	Convert(float, l_reject),
			l_warning 	= 	Convert(float, l_warning),
			l_user 		= 	Convert(float, l_user),
			L_Control 	= 	CONVERT(FLOAT,L_Control),
			target 		= 	Convert(float, target),
			U_Control 	= 	CONVERT(FLOAT,U_Control),
			u_user 		= 	Convert(float, u_user),
			u_warning 	= 	Convert(float, u_warning),
			u_reject 	= 	Convert(float, u_reject)
	WHERE   NonNumericFlag = 0
			AND ISNumeric(l_reject) = 1
			AND ISNumeric(l_warning) = 1
			AND ISNumeric(l_user) = 1
			AND ISNumeric(target) = 1
			AND ISNumeric(u_user) = 1
			AND ISNumeric(u_warning) = 1
			AND ISNumeric(u_reject) = 1
			AND ISNumeric(U_Control) = 1
			AND ISNumeric(L_Control) = 1

-----------------------------------------------------------------------------------------------------------------------
-- CALCULATE Count, Max, Min, Avg, StDev
-----------------------------------------------------------------------------------------------------------------------

UPDATE #All_Variables 
	SET TestCount = (SELECT Count(*) FROM #All_Variables a WHERE a.Var_id = av.Var_Id)
FROM #All_Variables av

UPDATE #All_Variables 
	SET MaxValue = (SELECT MAX(CONVERT(FLOAT,Result)) FROM #All_Variables a WHERE a.Var_id = av.Var_Id),
		MinValue = (SELECT MIN(CONVERT(FLOAT,Result)) FROM #All_Variables a WHERE a.Var_id = av.Var_Id),
		Average = (SELECT AVG(CONVERT(FLOAT,Result)) FROM #All_Variables a WHERE a.Var_id = av.Var_Id),
		StDevs = (SELECT STDEV(CONVERT(FLOAT,Result)) FROM #All_Variables a WHERE a.Var_id = av.Var_Id)
FROM #All_Variables av
WHERE Result IS NOT NULL AND ISNUMERIC(Result) = 1

------------------------------------------------------------------------------------------
-- Output
------------------------------------------------------------------------------------------
SELECT		'Output'										,
			Var_Id											,
			Var_Desc										,									
			PL_Desc											,
			Pu_Desc											,
            Pug_Desc 										,
			Prod_Group										,
			CONVERT(DATETIME,Result_On) Result_On			,
			ISNULL(CONVERT(FLOAT,Result),0)		Result				,
			ISNULL(CONVERT(FLOAT,L_Reject),0)		L_Reject			,
			ISNULL(CONVERT(FLOAT,L_Control),0)	L_Warning			,
			ISNULL(CONVERT(FLOAT,L_Warning),0)	L_User				,
			ISNULL(CONVERT(FLOAT,Target),0)		Target				,
			ISNULL(CONVERT(FLOAT,U_Warning),0)	U_User				,
			ISNULL(CONVERT(FLOAT,U_Control),0)	U_Warning			,
			ISNULL(CONVERT(FLOAT,U_Reject)-CONVERT(FLOAT,L_Reject),0)		U_Reject			,
			ISNULL(CONVERT(FLOAT,L_User),0)		Tgt_Low				,
			ISNULL(CONVERT(FLOAT,U_User),0)		Tgt_High			,
			TestCount,
			MaxValue						,
			MinValue						,
			Average						,
			StDevs						,
			CONVERT(FLOAT,Defect)		Defect		
FROM 		#All_Variables a
WHERE 		Var_Desc NOT LIKE '%zpv_%'
			AND Var_Id IS NOT NULL
			AND Var_Desc NOT LIKE '%Test Complet%'
			AND NonNumericFlag = 0
ORDER BY Var_Id,Prod_Group,Result_On


------------------------------------------------------------------------------------------
-- Debug Section
------------------------------------------------------------------------------------------
--SELECT  '#All_Variables', * FROM #All_Variables 
-- SELECT  '@Var_IDs -->',* FROM @Var_IDs 
-- SELECT  '@Var_IDs -->',var_id, var_desc,* FROM @Var_IDs WHERE IsReportable = 1
DROP TABLE #All_Variables

SET NOCOUNT OFF

