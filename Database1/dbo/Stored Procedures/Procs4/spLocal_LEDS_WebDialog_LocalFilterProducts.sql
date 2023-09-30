--=====================================================================================================================
-- Store Procedure: 	spLocal_LEDS_WebDialog_LocalFilterProducts
-- Author:				Paula LaFuente
-- Date Created:		2007-12-14
-- Sp Type:				Store Procedure
-- Editor Tab Spacing: 	4
-----------------------------------------------------------------------------------------------------------------------
-- DESCRIPTION:
-- This stored procedure is used to get all the product groups for the LEDS Reports
-- Business Rule:
-- This sp returns all the products for the machines that are production points in the 
-- production lines selected by the user
-----------------------------------------------------------------------------------------------------------------------
-- Nested sp: 
-- spCmn_ReportCollectionParsing
-- spCmn_GetRelativeDate
-----------------------------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
-----------------------------------------------------------------------------------------------------------------------
-- Revision		Date		Who					What
-- ========		====		===					====
-- 1.0			2002-05-29	 					Development
-- 1.1			2002-06-17						Modifications
-- 												3 new parameters introdeced: @p_vchProdFamilyIdList, 
--												@p_vchProdGroupIdList, @p_intSelectionType for @p_intMode = 5
-- 1.2			2002-07-18						New functionality introduced: 
--												1 - filtering by time interval and by PUIdList
--												2 - @p_intSelectionType = 3 - Products that belong to @p_vchProdFamilyIdList 
--												Join @p_vchProdGroupIdList
-- 1.3			2003-03-07						Modified to work with new standar
-- 												New Parameters: 
--													@ErrorCode:	INT OutPut
--													@ErrorMessage:	VARCHAR (1000) OutPut
-- 1.4			2003-04-30						Modified to accept @p_vchPUIdList = !Null
-- 1.5			2007-12-10	Paula Lafuente		Initial Development	for Local Version
-- 1.6			2008-03-28	Paula Lafuente		Take out code to filter by teams and shifts		
-- 1.7			2008-04-18	Renata Piedmont		Code Review
-- 1.8			2008-04-28	Renata Piedmont		Fixed bug with product group filter
-- 1.9			2008-11-11	Renata Piedmont		Changed code to look at production starts table to get product list
--												instead of the function to improve the performance of the sp
--												Changed the name of the sp to spLocal_LEDS_WebDialog_LocalFilterProducts
--												from spLocal_WebDialog_LocalFilterProducts because the code is now
--												LEDS specific
-----------------------------------------------------------------------------------------------------------------------
-- SAMPLE EXEC STATEMENT
-----------------------------------------------------------------------------------------------------------------------
/*
	EXEC spLocal_LEDS_WebDialog_LocalFilterProducts
 		0,				-- 	output: @ErrorCode						-- p1
 		'',				-- 	output: @ErrorMessage					-- p2
		'!Null',		--	@p_vchstrRptProdIdList					-- p3
		'11',		--	@p_vchstrRptPLIdList					-- p4
		'!Null',		-- 	@p_vchstrRptPUIdList					-- p5
		31,				--	@p_intTimeOption						-- p6
		'2009-01-08 06:00:00',				--	@p_strStartDate							-- p7
		'2009-01-09 06:00:00',				--	@p_strEndDate							-- p8
		'%%',				-- 	@p_vchSearchString						-- p9
		1,				--	@p_intSearchBy							-- p10
		0				-- 	@p_intReturnCount						-- p11
*/
-----------------------------------------------------------------------------------------------------------------------
--Parameters
-----------------------------------------------------------------------------------------------------------------------
-- 	output: @ErrorCode   							-- 	Return the error code
-- 	output: @ErrorMessage							-- 	Return the error message
--	p3:		@p_vchstrRptProdIdList					--	List of Products lines pipe separated
--	p4:		@p_vchstrRptPLIdList					--	List of Product Lines lines pipe separated
--	p5:		@p_vchstrRptPUIdList					--	List of Product Units lines pipe separated
--	p6:		@p_intTimeOption						--	Parameter to know the time option selected (today, yesterday, custom)
--	p7:		@p_strStartDate							--	Start Date for the Stored Procedure 
--	p8:		@p_strEndDate							--	End Date for the Stored Procedure
--	p9:		@p_vchSearchString						--	String to filter by values
--	p10:	@p_intSearchBy							--	Indicates if the mask has to be activated or not
--																	1. Code
--																	2. Description
--	p11:	@p_intReturnCount						--	Options
--													--	1 - sp returns count
--													--	0 - sp returns result set
--=====================================================================================================================
CREATE	PROCEDURE [dbo].[spLocal_LEDS_WebDialog_LocalFilterProducts]
		@ErrorCode								INT OUTPUT,
		@ErrorMessage							VARCHAR(1000) OUTPUT,
		@p_vchstrRptProdIdList					VARCHAR(1000) 	= NULL,		-- p3
		@p_vchstrRptPLIdList					VARCHAR(1000) 	= NULL,		-- p4
		@p_vchstrRptPUIdList					VARCHAR(1000) 	= NULL,		-- p5
		@p_intTimeOption						INT 			= NULL,		-- p6
		@p_vchstrStartDate						VARCHAR(25)		= NULL,		-- p7
		@p_vchstrEndDate						VARCHAR(25)		= NULL,		-- p8
		@p_vchSearchString						VARCHAR(100)	= NULL,		-- p9
		@p_intSearchBy							INT				= NULL,		-- p10
		@p_intReturnCount						INT				= NULL		-- p11
AS
--=====================================================================================================================
SET NOCOUNT ON
--=====================================================================================================================
--	DECLARE Variables
-----------------------------------------------------------------------------------------------------------------------
--	INTEGER
-----------------------------------------------------------------------------------------------------------------------
DECLARE		@i 						INT,
			@intMaxCount			INT,
			@intIncludeShift		INT,
			@intSplitFactor			INT,
			@intPLId				INT,
			@intPUId				INT,
			@intSplitRecords		INT,
			@intTableId				INT
-----------------------------------------------------------------------------------------------------------------------
--	VARCHAR
-----------------------------------------------------------------------------------------------------------------------
DECLARE 	@nvchSqlStatement 		nVARCHAR (4000),
			@vchLIKEClause 			VARCHAR (100),
			@ProdField 				VARCHAR (100),
			@OUTPUTVALUE 			VARCHAR,
			@TempDate				VarChar(50),
			@TempString				VarChar(1000),
			@vchStartDate			VARCHAR(25),
			@vchEndDate				VARCHAR(25),
			@vchStartDateForRpt		VARCHAR(25),
			@vchEndDateForRpt		VARCHAR(25),
			@vchProdFamilyIdList	VARCHAR(50),
			@vchProdGrpIdList		VARCHAR(50)		
-----------------------------------------------------------------------------------------------------------------------
--	DATETIME
-----------------------------------------------------------------------------------------------------------------------
DECLARE		@StartPeriod 			DATETIME,
			@EndPeriod 				DATETIME,
			@StartDateTime			DATETIME,
			@EndDateTime			DATETIME,
			@DummyDate 				DATETIME,
			@dtmRptStartTime		DATETIME,
			@dtmRptEndTime			DATETIME
-----------------------------------------------------------------------------------------------------------------------
--	INTEGER
-----------------------------------------------------------------------------------------------------------------------
DECLARE		@Prod_Id				INT,
			@Product_Family_Id 		INT,
			@Product_Grp_Id 		INT,
			@PU_ID					INT,
 			@SepLoc 				INT,
			@RESULT 				INT,
			@INTSTARTDATE 			INT,
			@INTENDDATE 			INT,
			@intTotalProdNumber 	INT,
			@intTimeOption			INT
--=====================================================================================================================
--	CONSTANTS
--=====================================================================================================================
DECLARE	@constUDPDescBatchUnit 			VARCHAR(50),
		@constUDPDescConstraintUnit		VARCHAR(50),
		@constUDPDescREProductionUnit	VARCHAR(25)
--=====================================================================================================================
--	TABLES
--=====================================================================================================================
-- TEMP TABLE used for parsing labels
-----------------------------------------------------------------------------------------------------------------------
CREATE TABLE	#TempParsingTable	(
				RcdId			INT,
				ValueINT		INT,
				ValueVARCHAR100	VARCHAR(100))
-----------------------------------------------------------------------------------------------------------------------
-- 	#TempProducts TABLE to get all the products
-----------------------------------------------------------------------------------------------------------------------
CREATE TABLE	#tblProductList (
				RcdIdx			INT IDENTITY(1,1),
				ProductId		INT,
				ProdCode		VARCHAR(100),
				ProdDesc		VARCHAR(100))
-------------------------------------------------------------------------------------------------------------------
-- List of all production lines to be included in the result set
-------------------------------------------------------------------------------------------------------------------	
DECLARE @tblPLList TABLE 			(
		RcdIdx				INT	Identity (1,1),
		PLId				INT	,
		ProductionPUId		INT	,
		CrewSchedulePUId	INT)
-------------------------------------------------------------------------------------------------------------------
--	List of LEDS production units to be included in the result set
-------------------------------------------------------------------------------------------------------------------
DECLARE @tblPUList TABLE(
	 	RcdIdx			INT IDENTITY(1,1),
		PLId			INT,
	 	PUId			INT,
		ProductionPUId	INT)
-------------------------------------------------------------------------------------------------------------------
--	List of PRODUCT production units to be included in the result set
-------------------------------------------------------------------------------------------------------------------
DECLARE @tblPRODUCTPUList TABLE(
	 	RcdIdx	INT IDENTITY(1,1),
	 	PUId	INT)
--=====================================================================================================================
--	INITIALIZE Variables
--=====================================================================================================================
SELECT 	@nvchSqlStatement = '',
		@vchLIKEClause = '',
		@ProdField = '',
		@ErrorCode	= 0,
		@ErrorMessage	= ''
--=====================================================================================================================
--	INITIALIZE Constants
--=====================================================================================================================
SELECT	@constUDPDescBatchUnit 			= 'IsBatchUnit',
		@constUDPDescConstraintUnit 	= 'IsConstraintUnit',
		@constUDPDescREProductionUnit	= 'RE-ProductionUnit'
--=====================================================================================================================
--	GET Shift Parameter and Split Records variable
--=====================================================================================================================
SELECT 	@intIncludeShift = 0,
		@intSplitRecords = 1
--=====================================================================================================================
--	SET START DATE AND END DATE
--	Business Rule
--	a.	CHECK Value for TimeOption
--	b.	IF	TimeOption = 0
--			take the VALUES of StartDate and EndDate which are user defined
--	c.	ELSE 
--			CALL spCMN_GETRelativeDate and pass the TimeOption Value
--			The TimeOption Value is the RRD_Id in dbo.Report_Relative_Dates
--			The spCMN_GETRelativeDate sp takes the RRD_Id and interprets the SQL code in
--			the dbo.Report_Relative_Dates table and returns the calculated dates
-----------------------------------------------------------------------------------------------------------------------
--	a.	CHECK Value for TimeOption
-----------------------------------------------------------------------------------------------------------------------
SELECT	@intTimeOption = CONVERT(INT, COALESCE(@p_intTimeOption, 0))
-----------------------------------------------------------------------------------------------------------------------
--	b.	IF	TimeOption = 0
--			take the VALUES of StartDate and EndDate which are user defined
--	c.	ELSE 
--			CALL spCMN_GETRelativeDate and pass the TimeOption Value
--			The TimeOption Value is the RRD_Id in dbo.Report_Relative_Dates 
--			The spCMN_GETRelativeDate sp takes the RRD_Id and interprets the SQL code in
--			the dbo.Report_Relative_Dates table and returns the calculated dates
-----------------------------------------------------------------------------------------------------------------------
IF @intTimeOption = 0 
BEGIN
	-------------------------------------------------------------------------------------------------------------------
	--	GET user defined start date
	-------------------------------------------------------------------------------------------------------------------
	SELECT	@dtmRptStartTime = CONVERT(DATETIME, @p_vchstrStartDate)
	-------------------------------------------------------------------------------------------------------------------
	--	GET user defined end date
	-------------------------------------------------------------------------------------------------------------------
	SELECT	@dtmRptEndTime = CONVERT(DATETIME, @p_vchstrEndDate)
END 
ELSE
BEGIN
	EXEC	spCmn_GetRelativeDate
			@StartTimeStamp = @dtmRptStartTime OUTPUT,
			@EndTimeStamp = @dtmRptEndTime OUTPUT,
			@PrmRRDId =  @intTimeOption
END
--=================================================================================================================
-- GET the production lines
-- Busines Rule:
-- PL qualifying criteria
--		1. Line must have a virtual production unit
-- Virtual Batch Unit will be identified by a UDP on the dbo.Prod_Units table with a 
-- UDP field name = @constUDPDescREProductionUnit
-- and a UDP value = 1 (TRUE)
--=================================================================================================================
--	GET table Id for dbo.Prod_Units
-------------------------------------------------------------------------------------------------------------------
SELECT	@intTableId = TableId
FROM	dbo.Tables	WITH (NOLOCK)
WHERE	TableName = 'Prod_Units'
-------------------------------------------------------------------------------------------------------------------
--	GET the production lines
-------------------------------------------------------------------------------------------------------------------
IF @p_vchstrRptPLIdList IS NOT NULL 
AND UPPER(@p_vchstrRptPLIdList) <> '!NULL' 
AND UPPER(@p_vchstrRptPLIdList) <> 'ALL'
BEGIN
	---------------------------------------------------------------------------------------------------------------
	--	1. @p_vchstrRptPLIdList <> NULL THEN Get the Prod Units that belong to that product lines list
	---------------------------------------------------------------------------------------------------------------
	---------------------------------------------------------------------------------------------------------------
	-- SPLIT the values of the product lines list
	---------------------------------------------------------------------------------------------------------------
	TRUNCATE TABLE	#TempParsingTable
	INSERT INTO	#TempParsingTable(RcdId, VALUEINT)
	EXEC	spCMN_ReportCollectionParsing 
			@PRMCollectionString = 	@p_vchstrRptPLIdList,
			@PRMFieldDelimiter = NULL,		
			@PRMRecordDelimiter = '|',
			@PRMDataType01 = 'INT'
	---------------------------------------------------------------------------------------------------------------	
	-- GET the lines
	---------------------------------------------------------------------------------------------------------------		
	INSERT INTO @tblPLList (
				PLId,
				ProductionPUId)
	SELECT 	pu.PL_Id, 
			pu.PU_Id
	FROM 	dbo.#TempParsingTable pl		WITH (NOLOCK)
		JOIN 	dbo.Prod_Units 			pu	WITH (NOLOCK)
											ON	pl.VALUEINT = pu.PL_Id
		JOIN	dbo.Table_Fields_Values	tfv	WITH (NOLOCK)
											ON	pu.PU_Id = tfv.KeyId
		JOIN	dbo.Table_Fields		tf	WITH (NOLOCK)
											ON	tf.Table_Field_Id 	= tfv.Table_Field_Id
	WHERE	tf.Table_Field_Desc = @constUDPDescREProductionUnit
		AND	tfv.TableId = @intTableId
		AND	tfv.Value = '1' -- True
END
ELSE
BEGIN
	---------------------------------------------------------------------------------------------------------------	
	-- GET the lines
	---------------------------------------------------------------------------------------------------------------		
	INSERT INTO @tblPLList (
				PLId,
				ProductionPUId)
	SELECT 	pl.PL_Id, 
			pu.PU_Id
	FROM 	dbo.Prod_Lines pl				WITH (NOLOCK)
		JOIN 	dbo.prod_units 			pu	WITH (NOLOCK)
											ON	pl.PL_Id = pu.PL_Id
		JOIN	dbo.Table_Fields_Values	tfv	WITH (NOLOCK)
											ON	pu.PU_Id = tfv.KeyId
		JOIN	dbo.Table_Fields		tf	WITH (NOLOCK)
											ON	tf.Table_Field_Id 	= tfv.Table_Field_Id
	WHERE	tf.Table_Field_Desc = @constUDPDescREProductionUnit
		AND	tfv.TableId = @intTableId
		AND	tfv.Value = '1' -- True
END
--=====================================================================================================================
-- 	ADD the PRODUCTION PU's to the LEDS PU's
--  Business Rule:
-- 	Sometimes the production PU's are the same as the LEDS PU's
--  Sometimes the production PU's are virtual PU's
--=====================================================================================================================
INSERT INTO @tblPUList (
			PUId)
SELECT	ProductionPUId
FROM	@tblPLList
--=====================================================================================================================
--	GET the list of LEDS and PRODUCTION Product Units
--=====================================================================================================================
INSERT INTO @tblPRODUCTPUList (
			PUId)
SELECT	DISTINCT
		ProductionPUID
FROM	@tblPLList
--=====================================================================================================================
--	GET the list of PRODUCT produced on the production units
--=====================================================================================================================
INSERT 	INTO	#tblProductList (
				ProductId,
				ProdCode,
				ProdDesc)
SELECT 	DISTINCT
		ps.Prod_Id	,
		p.Prod_Code	,
		p.Prod_Desc
FROM	dbo.Production_Starts	ps	WITH(NOLOCK)
JOIN	@tblPRODUCTPUList		tpu	ON	tpu.PUId = ps.PU_Id
									AND	ps.Start_Time <= @dtmRptEndTime
									AND	(ps.End_Time > @dtmRptStartTime
										OR	ps.End_Time IS NULL)
JOIN	dbo.Products			p	WITH(NOLOCK)
									ON	ps.Prod_Id = p.Prod_Id
WHERE	ps.Confirmed = 1
-----------------------------------------------------------------------------------------------------------------------
--	GET a Product that may overlap the end
-----------------------------------------------------------------------------------------------------------------------
INSERT 	INTO	#tblProductList (
				ProductId,
				ProdCode,
				ProdDesc)
SELECT 	DISTINCT
		ps.Prod_Id	,
		p.Prod_Code	,
		p.Prod_Desc
FROM	dbo.Production_Starts	ps	WITH(NOLOCK)
JOIN	@tblPRODUCTPUList		tpu	ON	tpu.PUId = ps.PU_Id
									AND	ps.End_Time <= @dtmRptEndTime
									AND	ps.End_Time > @dtmRptEndTime
JOIN	dbo.Products			p	WITH(NOLOCK)
									ON	ps.Prod_Id = p.Prod_Id
-----------------------------------------------------------------------------------------------------------------------
--	GET a Product that may overlap the date range
-----------------------------------------------------------------------------------------------------------------------
INSERT 	INTO	#tblProductList (
				ProductId,
				ProdCode,
				ProdDesc)
SELECT 	DISTINCT
		ps.Prod_Id	,
		p.Prod_Code	,
		p.Prod_Desc
FROM	dbo.Production_Starts	ps	WITH(NOLOCK)
JOIN	@tblPRODUCTPUList		tpu	ON	tpu.PUId = ps.PU_Id
									AND	ps.Start_Time < @dtmRptStartTime
									AND	ps.End_Time > @dtmRptEndTime
JOIN	dbo.Products			p	WITH(NOLOCK)
									ON	ps.Prod_Id = p.Prod_Id
--=====================================================================================================================
-- FILTER by Product Ids
-- SPLIT the values of the product id list
-----------------------------------------------------------------------------------------------------------------------
IF LEN(ISNULL(@p_vchstrRptProdIdList,'')) > 0 
AND UPPER(@p_vchstrRptProdIdList) <> '!NULL' 
AND UPPER(@p_vchstrRptProdIdList) <> 'ALL'
BEGIN
	TRUNCATE TABLE	#TempParsingTable
	INSERT INTO	#TempParsingTable(RcdId, VALUEINT)
	EXEC	spCMN_ReportCollectionParsing 
			@PRMCollectionString = 	@p_vchstrRptProdIdList,
			@PRMFieldDelimiter = NULL,		
			@PRMRecordDelimiter = '|',
			@PRMDataType01 = 'INT'
	-------------------------------------------------------------------------------------------------------------------
	-- DELETE all the products that have already been selected
	-------------------------------------------------------------------------------------------------------------------
	DELETE	#tblProductList
	WHERE	ProductId IN (	SELECT	ValueINT
							FROM	#TempParsingTable)
END
-------------------------------------------------------------------------------------------------------------------
--	Apply Search String if needed
-------------------------------------------------------------------------------------------------------------------
IF @p_vchSearchString IS NOT NULL AND LEN(@p_vchSearchString) > 0
BEGIN
	SELECT @nvchSqlStatement = 	'DELETE FROM #tblProductList ' +
								'WHERE'
	---------------------------------------------------------------------------------------------------------------
	-- Search by code
	---------------------------------------------------------------------------------------------------------------
	IF @p_intSearchBy = 1
	BEGIN			
		SELECT @vchLIKEClause = ' ProdCode NOT LIKE ''' + @p_vchSearchString + ''''
	END
	---------------------------------------------------------------------------------------------------------------
	-- Search by description
	---------------------------------------------------------------------------------------------------------------
	IF @p_intSearchBy = 2
	BEGIN
		SELECT @vchLIKEClause = ' ProdDesc NOT LIKE ''' + @p_vchSearchString + ''''
	END
	---------------------------------------------------------------------------------------------------------------
	-- CONCAT the statement
	---------------------------------------------------------------------------------------------------------------
	SELECT @nvchSqlStatement = @nvchSqlStatement + @vchLIKEClause
	---------------------------------------------------------------------------------------------------------------
	-- Delete the values from the table
	---------------------------------------------------------------------------------------------------------------
	EXEC sp_ExecuteSQL @nvchSqlStatement
END
--=====================================================================================================================	
-- RETURN PRODUCTS
--=====================================================================================================================	
IF	@p_intReturnCount = 1
BEGIN
	SELECT	DISTINCT 
			''					DummyColumn,
			COUNT(ProductId)	CountProductId
	FROM	#tblProductList
END
ELSE
BEGIN
	IF	@p_intSearchBy = 1
	BEGIN
		SELECT	DISTINCT	
				ProductId,
				ProdCode
		FROM	#tblProductList
	END
	ELSE
	BEGIN
		SELECT	DISTINCT	
				ProductId,
				ProdDesc
		FROM	#tblProductList
	END
END
--=====================================================================================================================	
-- TABLE LIST FOR DEBUG -- COMMENT BEFORE INSTALLATION
--=====================================================================================================================	
-- SELECT '@tblPLList', * FROM @tblPLList
-- SELECT '@tblPUList', * FROM @tblPUList
-- SELECT '@tblPRODUCTPUList', * FROM @tblPRODUCTPUList
--=====================================================================================================================	
-- DELETE Temporary tables
--=====================================================================================================================	
DROP TABLE #TempParsingTable
DROP TABLE #tblProductList
--=====================================================================================================================	
SET NOCOUNT ON
--=====================================================================================================================	
RETURN
