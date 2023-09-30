

-------------------------------------------------------------------------------------------------------------------------------------------------------
-- Store Procedure Name : spLocal_OpsDataStore_GetQualityRawData
-- Pablo Galanzini: Arido Software
-- 2016-11-03 
-- Store procedure for QA Datawarehouse Application for Baby Care.
--  Transfer data of Variables, Specifications, Products, Tests, each 30 minutes, 
--	to flat table in [OpsDataStore].[dbo].[OpsDB_Quality_RawData] 
-------------------------------------------------------------------------------------------------------------------------------------------------------
--  Version 1.0		2016-11-11	Pablo Galanzini		Initial Release
--  Version 1.1     2016-11-14	Fernando Rio		Modified to meet Proficy Quality: the script needs to use the Line Id vs the Unit Id.
--=====================================================================================================================================================
CREATE PROCEDURE [dbo].[spLocal_OpsDataStore_ETL_GetQuality]
--DECLARE 
	@OpsDB_UnitLastResultOn [dbo].[TT_OpsDB_QASLastTransf_by_Line] 
	READONLY
			
--WITH ENCRYPTION 
AS

-- test
--INSERT INTO @OpsDB_UnitLastResultOn VALUES ('2016-09-28 03:00:00.000',40)
--INSERT INTO @OpsDB_UnitLastResultOn VALUES ('2016-09-27 15:00:00.000',34)
--INSERT INTO @OpsDB_UnitLastResultOn VALUES ('2016-09-28 17:04:30.000',26)
--INSERT INTO @OpsDB_UnitLastResultOn VALUES ('2016-09-28 17:00:00.000',27)

---------------------------------------------------------------------------------------------------------
--	Tables
---------------------------------------------------------------------------------------------------------
DECLARE @OpsDB_Quality_RawData TABLE(
		RcId				INT IDENTITY(1,1) NOT NULL,
		Site				NVARCHAR(50) NULL,
		RptDate				NVARCHAR(30) NULL,
		ProdDay				NVARCHAR(10),
		Var_Id				INT NULL,
		Var_Desc			NVARCHAR(255) NULL,
		Var_Desc_Global		NVARCHAR(255) NULL,
		VarType				NVARCHAR(30) NULL,
		PL_id				INT NULL,
		PU_id				INT NULL,
		PL_Desc				NVARCHAR(255) NULL,
		PU_Desc				NVARCHAR(255) NULL,
		PUG_Desc			NVARCHAR(255)  NULL,
		Product_Grp_Desc	NVARCHAR(255) NULL,
		Prod_Id				INT NULL,
		Prod_Code			NVARCHAR(30) NULL,
		Prod_Desc			NVARCHAR(255) NULL,
		ResultOn			DATETIME NULL,
		Result				NVARCHAR(255) NULL,
		Target				NVARCHAR(255) NULL,
		L_Reject			NVARCHAR(255) NULL,
		U_Reject			NVARCHAR(255) NULL,
		L_Warning			NVARCHAR(255) NULL,
		U_Warning			NVARCHAR(255) NULL,
		L_User				NVARCHAR(255) NULL,
		U_User				NVARCHAR(255) NULL
)

DECLARE @VarTestComplete TABLE(
		Var_Id				INT NULL,
		PL_Id				INT NULL,		
		PU_Id				INT NULL,		
		PU_Desc				NVARCHAR(255) NULL,
		PUG_Desc			NVARCHAR(266)  NULL,
		Var_Desc			NVARCHAR(255) NULL,
		ProdDay				VARCHAR(10),
		LastTestComplete	DATETIME,
		SheetId				INT,
		SheetDesc			NVARCHAR(255) NULL)

DECLARE @Vars TABLE(
		Var_Id				INT NULL,
		PL_Id				INT NULL,		
		PL_Desc				NVARCHAR(255) NULL,
		PU_Id				INT NULL,		
		PU_Desc				NVARCHAR(255) NULL,
		PUG_Desc			NVARCHAR(255)  NULL,
		Var_Desc			NVARCHAR(255) NULL,
		Var_Desc_Global		NVARCHAR(255) NULL,
		VarType				NVARCHAR(30) NULL,
		VarDataTypeId		INT,
		SheetId				INT,
		SheetDesc			NVARCHAR(255) NULL)

---------------------------------------------------------------------------------------------------------
--	Variables
---------------------------------------------------------------------------------------------------------
DECLARE @strQProdGrps		NVARCHAR(255),
		@strProdDayStart	VARCHAR(10),
		@Site				VARCHAR(50)
		
---------------------------------------------------------------------------------------------------------
--	Set Constants
---------------------------------------------------------------------------------------------------------
SELECT	@strQProdGrps	= 'DefaultQProdGrps'

-----------------------------------------------------------------------------------------------------------------
--	Get Site
-----------------------------------------------------------------------------------------------------------------
SELECT  @Site = sp.value 
	FROM site_parameters	sp 
	JOIN parameters			pp ON pp.parm_id = sp.parm_id 
	WHERE pp.parm_name = 'sitename'

---------------------------------------------------------------------------------------------------------
--	Variables Test Complete
---------------------------------------------------------------------------------------------------------
INSERT INTO @VarTestComplete (
			Var_Id		,
			PL_Id		,		
			PU_Id		,		
			PU_Desc		,
			PUG_Desc	,
			Var_Desc	,
			LastTestComplete)
	SELECT	t.Var_Id	, 
			pu.pl_id	, 
			pu.PU_Id	, 
			pu.Pu_desc	,
			pg.PUG_Desc	,
			v.Var_Desc	,
			MIN(t.Result_on) 
	FROM dbo.Variables				v	WITH(NOLOCK)
	JOIN dbo.Prod_Units				pu	WITH(NOLOCK)ON v.PU_id = pu.PU_Id
	JOIN dbo.prod_lines				pl	WITH(NOLOCK)ON pl.pl_id = pu.pl_id 
	JOIN dbo.pu_groups				pg	WITH(NOLOCK)ON v.pug_id = pg.pug_id AND v.pu_id = pg.pu_id  
	JOIN @OpsDB_UnitLastResultOn	dd	ON dd.PL_Desc = pl.PL_Desc
	JOIN dbo.Table_Fields_Values	tfv	WITH(NOLOCK)ON v.Var_Id = tfv.KeyId 
	JOIN dbo.Table_Fields			tf	WITH(NOLOCK)ON tf.Table_Field_Id = tfv.Table_Field_Id 
	JOIN dbo.Tests					t	WITH(NOLOCK)ON t.var_id = v.var_id AND t.Result_on > dd.StartTime
	WHERE tf.Table_Field_Desc LIKE '%Is TestComplete%'
		AND t.result IS NOT NULL 
		AND LTRIM(RTRIM(t.result)) = '1' 
		AND t.canceled = 0
	GROUP BY
		t.Var_Id	, 
		pu.pl_id	, 
		pu.PU_Id	, 
		Pu_desc		,
		pg.PUG_Desc	,
		Var_Desc 

--select *
--	FROM @VarTestComplete			v
--	JOIN @OpsDB_UnitLastResultOn	dd				ON dd.LineId = v.PL_Id
--	JOIN dbo.Tests					t	WITH(NOLOCK)ON t.var_id = v.var_id 
--													AND t.Result_on > dd.StartTime
--	WHERE NOT t.result IS NULL 
--		AND LTRIM(RTRIM(t.result)) <> '' 
--		AND t.canceled = 0
--		AND t.result LIKE '1'

--select t.var_id, v.var_desc, MIN(t.Result_on) MINResultOn
--	FROM @VarTestComplete			v
--	JOIN @OpsDB_UnitLastResultOn	dd				ON dd.LineId = v.PL_Id
--	JOIN dbo.Tests					t	WITH(NOLOCK)ON t.var_id = v.var_id 
--													AND t.Result_on > dd.StartTime
--	WHERE NOT t.result IS NULL 
--		AND LTRIM(RTRIM(t.result)) <> '' 
--		AND t.canceled = 0
--		AND t.result LIKE '1'
--	GROUP BY t.var_id, v.var_desc

---------------------------------------------------------------------------------------------------------
--	Set Sheet
---------------------------------------------------------------------------------------------------------
UPDATE vt
	SET vt.SheetId	= sv.Sheet_Id,
		vt.SheetDesc= s.Sheet_Desc
	FROM @VarTestComplete	vt	
	JOIN Sheet_Variables	sv	ON sv.Var_id = vt.Var_id
	JOIN Sheets				s	ON sv.Sheet_Id = s.Sheet_Id

---------------------------------------------------------------------------------------------------------
--	Update ProdDay
---------------------------------------------------------------------------------------------------------
SELECT @strProdDayStart = Value
	FROM dbo.Site_Parameters WITH(NOLOCK) 
	WHERE Parm_Id = 17

--SELECT CAST(@strProdDayStart AS INT) * 60 AS INI_SEC,
--	((DATEPART(hh,LastTestComplete) * 60) * 60) + (DATEPART(mi,LastTestComplete) * 60) + DATEPART(ss,LastTestComplete) as seconds,
--	CASE WHEN (CAST(@strProdDayStart AS INT) * 60) > ((DATEPART(hh,LastTestComplete) * 60) * 60) + (DATEPART(mi,LastTestComplete) * 60) + DATEPART(ss,LastTestComplete)
--		THEN CONVERT(VARCHAR(10), DATEADD(DAY, -1, LastTestComplete), 120)
--		ELSE CONVERT(VARCHAR(10), LastTestComplete, 120)
--	END PRODDAY
--	FROM @VarTestComplete

UPDATE @VarTestComplete
	SET	ProdDay = 	
		CASE WHEN (CAST(@strProdDayStart AS INT) * 60) > 
					((DATEPART(hh,LastTestComplete) * 60) * 60) + (DATEPART(mi,LastTestComplete) * 60) + DATEPART(ss,LastTestComplete)
			THEN CONVERT(VARCHAR(10), DATEADD(DAY, -1, LastTestComplete), 120)
			ELSE CONVERT(VARCHAR(10), LastTestComplete, 120)
		END


--SELECT 'sheet_variables', * 
--	FROM sheet_variables	sv
--	JOIN @VarTestComplete	vt	ON sv.Var_id = vt.Var_id
--return
---------------------------------------------------------------------------------------------------------
--	Variables
---------------------------------------------------------------------------------------------------------
INSERT INTO @Vars	(
			Var_Id		,
			PL_Id		,
			PL_Desc		,
			PU_Id		,
			PU_Desc		,
			PUG_Desc	,
			Var_Desc	,
			Var_Desc_Global,
			SheetId		,
			SheetDesc	,
			VarDataTypeId,
			VarType)
	SELECT	DISTINCT
			vb.Var_Id	,
			pl.PL_Id	,
			pl.PL_Desc	,
			pu.PU_Id	,
			pu.PU_Desc	,
			pg.PUG_Desc	,
			vb.Var_Desc	,
			vb.Var_Desc_Global,
			sv.Sheet_Id	,
			s.Sheet_Desc,
			vb.Data_Type_Id,
			--	Flag for Non-Numeric variables
			CASE	WHEN	vb.Data_Type_Id =	1	THEN	'VARIABLE'
					WHEN	vb.Data_Type_Id	=	2	THEN	'VARIABLE'
					WHEN	vb.Data_Type_Id	=	6	THEN	'VARIABLE'
					WHEN	vb.Data_Type_Id	=	7	THEN	'VARIABLE'
				ELSE	'ATTRIBUTE'
			END
			FROM dbo.variables				vb	WITH(NOLOCK) 
			JOIN dbo.Prod_Units				pu	WITH(NOLOCK)ON pu.pu_id = vb.pu_id 
			JOIN dbo.prod_lines				pl	WITH(NOLOCK)ON pl.pl_id = pu.pl_id 
			JOIN dbo.pu_groups				pg	WITH(NOLOCK)ON vb.pug_id = pg.pug_id
															AND vb.pu_id = pg.pu_id  
			JOIN dbo.Table_Fields_Values	tfv WITH(NOLOCK)ON tfv.KeyId = pg.PUG_Id 
															AND tfv.Value = 'Yes' 
			JOIN dbo.table_fields			tf	WITH(NOLOCK)ON tf.Table_Field_Id = tfv.Table_Field_Id 
			-- Data from Input
			--JOIN @OpsDB_UnitLastResultOn	dd	ON dd.LineId = pu.PL_Id
			JOIN @OpsDB_UnitLastResultOn	dd	ON dd.PL_Desc = pl.PL_Desc
			JOIN Sheet_Variables			sv	WITH(NOLOCK)ON vb.Var_Id = sv.Var_Id
			JOIN @VarTestComplete			vt	ON vt.SheetId = sv.Sheet_Id
												--AND vb.var_id <> vt.var_id
			JOIN Sheets						s	WITH(NOLOCK)ON sv.Sheet_Id = s.Sheet_Id
			WHERE vb.Is_Active = 1 
				AND tf.Table_Field_Desc = @strQProdGrps
				--nnd vb.Var_Desc like 'PAT%'
			ORDER BY 
				vb.Var_Id, 
				pl.PL_Desc, 
				pu.PU_Desc

---------------------------------------------------------------------------------------------------------
--	Search data
-----------------------------------------------------------------------------------------------------------
INSERT INTO @OpsDB_Quality_RawData (
			Site				,
			RptDate				,
			ProdDay				,
			Var_Id				,
			Pl_Id				,
			PU_Id				,
			PL_Desc				,
			PU_Desc				,
			PUG_Desc			,
			Var_Desc			,
			Var_Desc_Global		,
			VarType				,
			ResultOn			,
			Result				)
	SELECT	DISTINCT
			--'test',
			@Site				,
			CONVERT(DATE,GETDATE()) AS Rptdate,
			ProdDay,
			v.Var_Id			,
			V.Pl_Id				,
			v.PU_Id				,
			v.PL_Desc			,
			v.PU_Desc			,
			v.PUG_Desc			,
			v.Var_Desc			,
			v.Var_Desc_Global	,
			v.VarType			,
			t.Result_on			,
			t.Result			 
			FROM @Vars						v
			JOIN dbo.Tests					t	WITH(NOLOCK)ON t.var_id = v.var_id 
			--JOIN @OpsDB_UnitLastResultOn	dd				ON dd.LineId = v.PL_Id
															--AND t.Result_on > dd.StartTime
			JOIN @VarTestComplete			vt	ON t.Result_on = vt.LastTestComplete
												AND v.PL_id = vt.PL_id
												--AND v.PL_Desc = vt.PL_Desc
			WHERE t.result IS NOT NULL 
				AND LTRIM(RTRIM(t.result)) <> '' 
				AND t.canceled = 0

--return
---------------------------------------------------------------------------------------------------------
--	Update the product information
---------------------------------------------------------------------------------------------------------
UPDATE @OpsDB_Quality_RawData
	SET Product_Grp_Desc	=  pgr.Product_Grp_Desc		,
		prod_id				=  pd.Prod_Id			,
		Prod_Code			=  pd.Prod_Code			,
		Prod_Desc			=  pd.Prod_Desc			
	FROM @OpsDB_Quality_RawData		q
	JOIN dbo.production_starts		p	WITH(NOLOCK)ON p.start_Time	<=	q.ResultOn 
													AND (p.End_Time	>	q.ResultOn OR p.End_Time IS NULL)
													AND p.pu_id		=	q.PU_Id 
	JOIN dbo.Product_Group_Data		pgd WITH(NOLOCK)ON pgd.prod_id	=	p.prod_id 
	JOIN dbo.Product_Groups			pgr WITH(NOLOCK)ON pgd.Product_Grp_Id =	pgr.Product_Grp_Id 
	JOIN dbo.Products				pd	WITH(NOLOCK)ON pd.prod_id =	p.prod_id 

---------------------------------------------------------------------------------------------------------
--	Update Var Specs information
---------------------------------------------------------------------------------------------------------
UPDATE @OpsDB_Quality_RawData
	SET L_Reject			=  vs.L_Reject			,
		U_Reject			=  vs.U_Reject			,
		L_Warning			=  vs.L_Warning			,
		U_Warning			=  vs.U_Warning			,
		L_User				=  vs.L_User			,
		U_User				=  vs.U_User			,
		Target				=  vs.Target	
	FROM @OpsDB_Quality_RawData	q
	LEFT JOIN dbo.Var_Specs		vs	WITH(NOLOCK)ON q.var_id	=	vs.var_id 
												AND		vs.prod_id	=	q.prod_id 
												AND		vs.expiration_date IS NULL 

---------------------------------------------------------------------------------------------------------
--	Update VarType
---------------------------------------------------------------------------------------------------------
UPDATE @OpsDB_Quality_RawData	
	SET VarType = 'NUMATTRIBUTE'
	WHERE VarType = 'ATTRIBUTE'
		AND ISNUMERIC(Result) = 1

---------------------------------------------------------------------------------------------------------
--	Debug
---------------------------------------------------------------------------------------------------------
--select '@OpsDB_UnitLastResultOn', * from @OpsDB_UnitLastResultOn
--select '@VarTestComplete', * from @VarTestComplete
--SELECT '@Vars', * FROM @Vars ORDER BY Var_Desc
--SELECT COUNT(*) FROM @Vars 
--SELECT COUNT(*) FROM @OpsDB_Quality_RawData
--RETURN

---------------------------------------------------------------------------------------------------------
--	OUTPUT
---------------------------------------------------------------------------------------------------------
SELECT	
		Site ,
		RptDate ,
		ProdDay ,
		Var_Id ,
		PL_Id ,
		PL_Desc ,
		PU_ID ,
		PU_Desc ,
		PUG_Desc,
		Var_Desc ,
		Var_Desc_Global ,
		Product_Grp_Desc ,
		Prod_Id ,
		Prod_Code ,
		Prod_Desc ,
		ResultOn ,
		Result ,
		L_Reject ,
		U_Reject ,
		L_Warning ,
		U_Warning ,
		L_User ,
		U_User ,
		Target ,
		VarType 
	FROM @OpsDB_Quality_RawData
	ORDER BY ResultOn DESC

RETURN
