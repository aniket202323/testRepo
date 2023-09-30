
-------------------------------------------------------------------------------------------------------------------------------------------------------
-- Report Name 			: Centerline Specifications
-- Store Procedure Name : spLocal_RptCenterline_Specifications
--
--
--				FRio : Arido Software
--				2015-09-22 
--				Store procedure re-writed to meet Centerline configuration.
-- 
-------------------------------------------------------------------------------------------------------------------------------------------------------
--	Version 1.0			Fernando Rio		Initial Release
--  Version 1.1 		Gonzalo Luc			Fix, Remove database hardcode
--  Version 1.2			Fernando Rio		Changed the way to gather specifications, make it more effective and fast.\-- 1.1		2015-11-09		Fran Osorno				new location
-- 1.1		2015-11-09		Fran Osorno				new location
-- 1.2		2015-12-03		Fran Osorno				Updated for incorrect drop
-- 1.3		2015-12-16		Jim Jowanovitz		
--=================================================================================================

CREATE PROCEDURE dbo.spLocal_RptCenterline_Specifications
--DECLARE
       @Equipment			VARCHAR(1000),             --what equipment
       @CenterlineTypes		VARCHAR(1000),             --all or certian
       @Start				DATETIME                  --if @TimeWindows is UserDefined
AS
-- EXEC dbo.spLocal_RptCenterline_Specifications 	'2753','All','9/19/2015'
--SELECT
--    @Equipment          =	'2753',
--    @CenterlineTypes	=	'All',
--    @Start              =	'9/19/2015'

---------------------------------------------------------------------------------------------------
CREATE TABLE #CType (
			ID				INT IDENTITY,
			CType			VARCHAR(100))
---------------------------------------------------------------------------------------------------
CREATE TABLE #Data (
			ID				INT IDENTITY,
			PUId			INT			,
			UDEID			INT,
			UDEStart		DATETIME,
			UDEEnd			DATETIME,
			FrecuencyStart	DATETIME,
			FrecuencyEnd	DATETIME,
			UDEPUID			INT,
			UDEESTID		INT,
			ESTDesc			VARCHAR(50),
			VarID			INT,
			VarDesc			VARCHAR(50),
			EngUnits		VARCHAR(15),
			UDEDesc			VARCHAR(100),
			MPUID			INT,
			CTestTime		VARCHAR(50),		-- UDP Centerline_TestTime
			CAuditFreq		VARCHAR(50),		-- UDP Centerline_AuditFreq
			CQStartTime		VARCHAR(50),		-- UDP Centerline_QuarterStartTime
			CReported		VARCHAR(50),		-- UDP Centerline_Reported	
			EqGroup			VARCHAR(50),
			DataEntered		INT DEFAULT(0),		-- 1 data has been entered 0 not
			EntryOnTime		INT DEFAULT (0),	-- 1 data was entered within the event time 0 not
			EntryInSpec		INT DEFAULT(0),		-- 1 data within spec if entered 0 not
			EntryWindowEnd	DATETIME,
			ProdID			INT,
			LReject			VARCHAR(25),
			LWarning		NVARCHAR(25), 
			LUser			NVARCHAR(25), 
			Target			VARCHAR(25),
			UUser			NVARCHAR(25), 
			UWarning		NVARCHAR(25), 
			UReject			VARCHAR(25)
			)
---------------------------------------------------------------------------------------------------
CREATE TABLE #MasterOutput (
			Id				INT IDENTITY,
			PlantName		NVARCHAR(200), 
			Line			NVARCHAR(200), 
			PUId			INT			,
			PugDesc			NVARCHAR(200), 
			Frequency		NVARCHAR(200),
			Lreject			NVARCHAR(25), 
			Lwarning		NVARCHAR(25), 
			Luser			NVARCHAR(25), 
			Target			NVARCHAR(25), 
			UUser			NVARCHAR(25), 
			UWarning		NVARCHAR(25), 
			Ureject			NVARCHAR(25),
			SamplesTaken	INT, 
			SamplesDue		INT, 
			FutureSamplesDue INT, 
			Defects			INT, 
			ProdDesc		NVARCHAR(200), 
			VarId			INT, 
			VarDesc			NVARCHAR(200), 
			EngUnits		VARCHAR(15),
			ProdCode		INT, 
			NextStartDate	DATETIME, 
			TestTime		DATETIME,
			AlarmId			INT			 ,
			ActionComment	NVARCHAR(200),
			Action			NVARCHAR(200),
			Cause			NVARCHAR(200))

---------------------------------------------------------------------------------------------------
--Declare local variables
---------------------------------------------------------------------------------------------------
DECLARE
			@End				DATETIME		,
			@PlantName			NVARCHAR(200)	
	
---------------------------------------------------------------------------------------------------
--Set the local variables
---------------------------------------------------------------------------------------------------
SET @PlantName		= (SELECT Value FROM dbo.Site_Parameters WITH(NOLOCK) WHERE Parm_ID = 12)
SELECT @End			= DATEADD(d, 1, @Start)

---------------------------------------------------------------------------------------------------
-- Get Centerline Event Types 
---------------------------------------------------------------------------------------------------

	INSERT INTO #CType (CType)
		VALUES('Centerline Auto')

	INSERT INTO #CType (CType)
		VALUES('Centerline CPE Monthly')

	INSERT INTO #CType (CType)
		VALUES('Centerline CPE Quarterly')

	INSERT INTO #CType (CType)
		VALUES('Centerline CPE Weekly')

	INSERT INTO #CType (CType)
		VALUES('Centerline Manual')


---------------------------------------------------------------------------------------------------
-- Get Data
---------------------------------------------------------------------------------------------------
INSERT INTO #Data (		
			PUId		,
			ESTDesc		,
			VarID		,
			VarDesc		,
			EngUnits	,
			MPUID		)
	SELECT	pu.PU_Id	,
			est.Event_Subtype_Desc,
			v.Var_Id,
			v.Var_Desc,
			v.Eng_Units,
			pu.Master_Unit
		FROM dbo.Event_Configuration	ec	(NOLOCK)
		JOIN dbo.Event_Subtypes			est (NOLOCK) ON est.Event_Subtype_Id = ec.Event_Subtype_Id
		JOIN dbo.Prod_Units				pu	(NOLOCK) ON pu.Master_Unit = ec.PU_Id
		JOIN dbo.Variables				v	(NOLOCK) ON v.PU_Id = pu.PU_Id 
														AND v.Event_Subtype_Id = ec.Event_Subtype_Id
		JOIN #CType						ct	(NOLOCK)ON ct.CType = est.Event_Subtype_Desc
		WHERE ec.PU_Id IN (SELECT value FROM Split(@Equipment))

--Update 'Centerline_TestTime'		
UPDATE d
	SET CTestTime = tfv.value
	FROM dbo.Table_Fields_Values	tfv (NOLOCK) 
	JOIN dbo.Table_Fields			tf (NOLOCK) ON tf.Table_Field_Id = tfv.Table_Field_Id AND tf.TableId = tfv.TableId
	JOIN dbo.Tables					t (NOLOCK) ON t.TableId = tf.TableId AND t.TableName = 'Variables'
	JOIN #Data						d ON d.VarID = tfv.KeyId
	WHERE tf.Table_Field_Desc = 'Centerline_TestTime'

--update 'Centerline_TAuditFreq	
UPDATE d
	SET CAuditFreq = tfv.value
	FROM dbo.Table_Fields_Values tfv (NOLOCK) 
	JOIN dbo.Table_Fields tf (NOLOCK) ON tf.Table_Field_Id = tfv.Table_Field_Id AND tf.TableId = tfv.TableId
	JOIN dbo.Tables t (NOLOCK) ON t.TableId = tf.TableId AND t.TableName = 'Variables'
	JOIN #Data d ON d.VarID = tfv.KeyId
	WHERE tf.Table_Field_Desc = 'Centerline_AuditFreq'

---------------------------------------------------------------------------------------------------
-- @CenterlineTypes is going to be used to Filter Frequency
---------------------------------------------------------------------------------------------------
IF @CenterlineTypes <> 'All'
	DELETE FROM #Data WHERE CAuditFreq NOT IN (SELECT value FROM Split(@CenterlineTypes))

---------------------------------------------------------------------------------------------------
--update 'Centerline_QuarterStartTime'
UPDATE d
	SET CQStartTime = tfv.value
	FROM dbo.Table_Fields_Values tfv (NOLOCK) 
	JOIN dbo.Table_Fields tf (NOLOCK) ON tf.Table_Field_Id = tfv.Table_Field_Id AND tf.TableId = tfv.TableId
	JOIN dbo.Tables t (NOLOCK) ON t.TableId = tf.TableId AND t.TableName = 'Variables'
	JOIN #Data d ON d.VarID = tfv.KeyId
	WHERE tf.Table_Field_Desc = 'Centerline_QuarterStartTime'

--update 'Centerline_Reported
UPDATE d
	SET CReported = tfv.value
	FROM dbo.Table_Fields_Values tfv (NOLOCK) 
	JOIN dbo.Table_Fields tf (NOLOCK) ON tf.Table_Field_Id = tfv.Table_Field_Id AND tf.TableId = tfv.TableId
	JOIN dbo.Tables t (NOLOCK) ON t.TableId = tf.TableId AND t.TableName = 'Variables'
	JOIN #Data d ON d.VarID = tfv.KeyId
	WHERE tf.Table_Field_Desc = 'Centerline_Reported'

--update 'Centerline_Reported
UPDATE d
	SET EqGroup = tfv.value
	FROM dbo.Table_Fields_Values tfv (NOLOCK) 
	JOIN dbo.Table_Fields tf (NOLOCK) ON tf.Table_Field_Id = tfv.Table_Field_Id AND tf.TableId = tfv.TableId
	JOIN dbo.Tables t (NOLOCK) ON t.TableId = tf.TableId AND t.TableName = 'Variables'
	JOIN #Data d ON d.VarID = tfv.KeyId
	WHERE tf.Table_Field_Desc = 'Centerline_EquipmentGroup'

--update ProdID
UPDATE d
	SET ProdID = p.prod_id
	FROM dbo.production_starts ps (NOLOCK)
	JOIN dbo.Products p (NOLOCK) ON p.prod_id = ps.prod_id
	JOIN #Data d ON d.MPUID = ps.pu_id
	WHERE ps.start_time <= @Start AND (ps.end_time >= @Start OR ps.End_Time IS NULL)	
		
--Update the Specs
UPDATE d
	SET	LReject		= vs.l_reject,
		LWarning	= vs.L_Warning,
		LUser		= vs.L_User,
		Target		= vs.Target,
		UUser		= vs.U_User,
		UWarning	= vs.U_Warning,
		UReject		= vs.U_reject
	FROM dbo.Var_Specs	vs	(NOLOCK) 
	JOIN #Data			d	ON d.VarID = vs.var_id AND d.ProdID = vs.Prod_Id
	WHERE vs.Effective_Date <= @Start 
		AND (vs.Expiration_Date >= @start OR vs.Expiration_Date IS NULL)

--Update EntryWindowEnd for CAuditFreq = S
UPDATE d
	SET EntryWindowEnd = cs.Start_Time
	FROM dbo.Crew_Schedule	cs (NOLOCK)
	JOIN #Data				d	ON d.MPUID = cs.pu_id
	WHERE cs.Start_Time = d.UDEEnd

----------------------------------------------------------------------------------------------------------------
ReturnData:

INSERT INTO	#MasterOutput (
			PlantName		, 
			Line			, 
			PUId			,
			PugDesc			, 
			Frequency		,
			Lreject			, 
			Lwarning		, 
			Luser			, 
			Target			, 
			UUser			, 
			UWarning		, 
			Ureject			,
			SamplesTaken	, 
			SamplesDue		, 
			FutureSamplesDue, 
			Defects			, 
			ProdDesc		, 
			VarDesc			, 
			VarId			, 
			EngUnits		,
			ProdCode		, 
			NextStartDate	 )
	SELECT	@PlantName		,
			PL_Desc			,
			PUId			,
			EqGroup			,
			CAuditFreq		,
			Lreject			, 
			LWarning		, 
			LUser			, 
			Target			, 
			UUser			, 
			UWarning		, 
			Ureject			,
			DataEntered										 'Samples Taken'			,
			(CASE WHEN DATAEntered = 0 THEN 1 ELSE 0 END)    'SamplesDue'				,	
			0												 'Future Samples Due'		,
			EntryInSpec										 'Defects'					,	
			p.Prod_Desc		,
			VarDesc			,
			VarId			,
			EngUnits		,
			p.Prod_Code		,
			''												 'Next Start Time'			
		FROM #Data			d
		JOIN dbo.Prod_Units	pu	WITH(NOLOCK) ON pu.PU_Id = d.PUId
		JOIN dbo.Prod_Lines	pl	WITH(NOLOCK) ON pl.PL_Id = pu.PL_Id
		LEFT JOIN dbo.Products	p	WITH(NOLOCK) ON p.Prod_Id = d.ProdId


----------------------------------------------------------------------------------------------------------------
-- Report Output
----------------------------------------------------------------------------------------------------------------
SELECT	PlantName		, 
		Line			, 
		VarId			, 
		VarDesc			, 
		EngUnits		,
		Frequency		,
		PugDesc			, 
		Lreject			, 
		Lwarning		, 
		Luser			, 
		Target			, 
		UUser			, 
		UWarning		, 
		Ureject			,
		ProdCode		, 
		ProdDesc		
	FROM #MasterOutput 


CleanUp:
DROP TABLE #CType
DROP TABLE #Data
DROP TABLE #MasterOutput

SET NOCOUNT OFF
