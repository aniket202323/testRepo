--=====================================================================================================================    
-- Store Procedure:  spLocal_BETS_WebDialog_LocalFilterProducts    
-- Author:    Paula LaFuente    
-- Date Created:  2007-12-14    
-- Sp Type:    Store Procedure    
-- Editor Tab Spacing:  4    
-----------------------------------------------------------------------------------------------------------------------    
-- DESCRIPTION:    
-- This stored procedure is used to get all the product groups for the BETSSummary Report    
-----------------------------------------------------------------------------------------------------------------------    
-- Nested sp:     
-- spCmn_ReportCollectionParsing    
-- spCmn_GetRelativeDate    
-----------------------------------------------------------------------------------------------------------------------    
-- EDIT HISTORY:    
-----------------------------------------------------------------------------------------------------------------------    
-- Revision  Date  Who     What    
-- ========  ====  ===     ====    
-- 1.0   2002-05-29       Development    
-- 1.1   2002-06-17      Modifications    
--             3 new parameters introdeced: @p_vchProdFamilyIdList,     
--            @p_vchProdGroupIdList, @p_intSelectionType for @p_intMode = 5    
-- 1.2   2002-07-18      New functionality introduced:     
--            1 - filtering by time interval and by PUIdList    
--            2 - @p_intSelectionType = 3 - Products that belong to @p_vchProdFamilyIdList     
--            Join @p_vchProdGroupIdList    
-- 1.3   2003-03-07      Modified to work with new standar    
--             New Parameters:     
--             @ErrorCode: INT OutPut    
--             @ErrorMessage: VARCHAR (1000) OutPut    
-- 1.4   2003-04-30      Modified to accept @p_vchPUIdList = !Null    
-- 1.5   2007-12-10 Paula Lafuente  Initial Development for Local Version    
-- 1.6   2008-03-28 Paula Lafuente  Take out code to filter by teams and shifts      
-- 1.7   2008-04-18 Renata Piedmont  Code Review    
-- 1.8   2008-04-28 Renata Piedmont  Fixed but with product group filter    
-- 1.9   2008-05-05 Paula Lafuente  Change name of the store procedure and take out code to have this sp    
--            working just for BETS    
-----------------------------------------------------------------------------------------------------------------------    
-- SAMPLE EXEC STATEMENT    
-----------------------------------------------------------------------------------------------------------------------    
-- EXEC spLocal_BETS_WebDialog_LocalFilterProducts    
--   0,    --  output: @ErrorCode    
--   '',    --  output: @ErrorMessage    
--  0,    --  @p_intWebLocalFilterProdLinesOutputType    
--  0,    -- @p_intWebLocalProductFilterSelectedType    
--  '!Null',  -- @p_vchstrRptProdIdList    
--  '!Null',  -- @p_vchstrRptPLIdList    
--  '!Null',  --  @p_vchstrRptPUIdList    
--  '!Null',  -- @p_strRptProductFamilyIdList    
--  '!Null',  -- @p_strRptProductGrpIdList    
--  0,    -- @p_intTimeOption    
--  '',    -- @p_strStartDate    
--  '',    -- @p_strEndDate    
--  1,    -- @p_intFilterByDate    
--  '',    --  @p_vchSearchString    
--  1,    -- @p_intSearchBy    
--  0,    --  @p_intOption    
--  'ALL',   -- @p_vchShiftsSelected    
--  'ALL'   --  @p_vchTeamsSelected    
-----------------------------------------------------------------------------------------------------------------------    
--Parameters    
-----------------------------------------------------------------------------------------------------------------------    
--  output: @ErrorCode          --  Return the error code    
--  output: @ErrorMessage       --  Return the error message    
-- p1:  @p_intWebLocalFilterProdLinesOutputType -- Parameter to indicate if we are working with 0.All 2.BETS    
-- p2:  @p_intWebLocalProductFilterSelectedType -- Parameter use to indicate the mode     
--              Options: 0. All Products    
--                 1. Products that belong to a ProdFamilyIdList    
--                 2. Products that belong to a ProdGroupIdList    
--                 3. Products that belong to a ProdFamilyIdList JOIN to ProdGroupIdList    
-- p3:  @p_vchstrRptProdIdList     -- List of Products lines pipe separated    
-- p4:  @p_vchstrRptPLIdList     -- List of Product Lines lines pipe separated    
-- p5:  @p_vchstrRptPUIdList     -- List of Product Units lines pipe separated    
-- p6:  @p_strRptProductFamilyIdList   -- List of Product Family lines pipe separated    
-- p7:  @p_strRptProductGrpIdList    -- List of Product Group lines pipe separated    
-- p8:  @p_intTimeOption      -- Parameter to know the time option selected (today, yesterday, custom)    
-- p9:  @p_strStartDate       -- Start Date for the Stored Procedure     
-- p10: @p_strEndDate       -- End Date for the Stored Procedure    
-- p11: @p_intFilterByDate      -- Filter the products by date defaulted to 1    
--                 0. No Filtering    
--                 1. Filter by date within reporting period    
-- p12: @p_vchSearchString      -- String to filter by values    
-- p13: @p_intSearchBy       -- Indicates if the mask has to be activated or not    
--                 1. Code    
--                 2. Description    
-- p14: @p_intOption       -- Indicates if we are using the sp to get the families or to get the products    
--                 0. Get Products    
--                 1. Get Families    
--                 2. Get Product Grps    
-- p15: @p_vchShiftsSelected     -- Indicates the shifts the user has picked    
-- p16: @p_vchTeamsSelected      --  Indicates the teams the user has picked    
--=====================================================================================================================    
CREATE PROCEDURE [dbo].[spLocal_BETS_WebDialog_LocalFilterProducts]    
  @ErrorCode        INT OUTPUT,    
  @ErrorMessage       VARCHAR(1000) OUTPUT,    
  @p_intWebLocalFilterProdLinesOutputType INT,    
  @p_intWebLocalProductFilterSelectedType INT,    
  @p_vchstrRptProdIdList     VARCHAR(1000)  = NULL,    
  @p_vchstrRptPLIdList     VARCHAR(1000)  = NULL,    
  @p_vchstrRptPUIdList     VARCHAR(1000)  = NULL,    
  @p_strRptProductFamilyIdList   VARCHAR(1000)  = NULL,    
  @p_strRptProductGrpIdList    VARCHAR(1000)  = NULL,    
  @p_intTimeOption      INT    = NULL,    
  @p_vchstrStartDate      VARCHAR(25)  = NULL,    
  @p_vchstrEndDate      VARCHAR(25)  = NULL,    
  @p_intFilterByDate      INT    = NULL,    
  @p_vchSearchString      VARCHAR(100) = NULL,    
  @p_intSearchBy       INT    = NULL,    
  @p_intOption       INT,    
  @p_vchShiftsSelected     VARCHAR(50)  = NULL,    
  @p_vchTeamsSelected      VARCHAR(50)  = NULL    
AS    
--=====================================================================================================================    
SET NOCOUNT ON    
--=====================================================================================================================    
-- DECLARE Variables    
-----------------------------------------------------------------------------------------------------------------------    
-- INTEGER    
-----------------------------------------------------------------------------------------------------------------------    
DECLARE  @i       INT,    
   @intMaxCount   INT,    
   @intIncludeShift  INT,    
   @intSplitFactor   INT,    
   @intPLId    INT,    
   @intPUId    INT,    
   @intSplitRecords  INT    
-----------------------------------------------------------------------------------------------------------------------    
-- VARCHAR    
-----------------------------------------------------------------------------------------------------------------------    
DECLARE  @nvchSqlStatement   nVARCHAR (4000),    
   @vchlikeclause    VARCHAR (100),    
   @ProdField     VARCHAR (100),    
   @OUTPUTVALUE    VARCHAR,    
   @TempDate    VarChar(50),    
   @TempString    VarChar(1000),    
   @vchStartDate   VARCHAR(25),    
   @vchEndDate    VARCHAR(25),    
@vchStartDateForRpt  VARCHAR(25),    
   @vchEndDateForRpt  VARCHAR(25),    
   @vchProdFamilyIdList VARCHAR(50),    
   @vchProdGrpIdList  VARCHAR(50)      
-----------------------------------------------------------------------------------------------------------------------    
-- DATETIME    
-----------------------------------------------------------------------------------------------------------------------    
DECLARE  @StartPeriod    DATETIME,    
   @EndPeriod     DATETIME,    
   @StartDateTime   DATETIME,    
   @EndDateTime   DATETIME,    
   @DummyDate     DATETIME,    
   @dtmRptStartTime  DATETIME,    
   @dtmRptEndTime   DATETIME    
-----------------------------------------------------------------------------------------------------------------------    
-- INTEGER    
-----------------------------------------------------------------------------------------------------------------------    
DECLARE  @Prod_Id    INT,    
   @Product_Family_Id   INT,    
   @Product_Grp_Id   INT,    
   @PU_ID     INT,    
    @SepLoc     INT,    
   @RESULT     INT,    
   @INTSTARTDATE    INT,    
   @INTENDDATE    INT,    
   @intTotalProdNumber  INT,    
   @intTimeOption   INT    
--=====================================================================================================================    
-- CONSTANTS    
--=====================================================================================================================    
DECLARE @constUDPDescBatchUnit   VARCHAR(50),    
  @constUDPDescConstraintUnit VARCHAR(50)    
--=====================================================================================================================    
-- TABLES    
--=====================================================================================================================    
-- Temporary Tables    
-----------------------------------------------------------------------------------------------------------------------    
--  #tblTempProductsFilteredByProdFamilyIdList TABLE    
-----------------------------------------------------------------------------------------------------------------------    
CREATE  TABLE #tblTempProductsFilteredByProdFamilyIdList(    
 Prod_Id INTEGER)    
-----------------------------------------------------------------------------------------------------------------------    
--  #tblTempProductsFilteredByProdGroupIdList TABLE    
-----------------------------------------------------------------------------------------------------------------------    
CREATE TABLE #tblTempProductsFilteredByProdGroupIdList(    
 Prod_Id INTEGER)    
-----------------------------------------------------------------------------------------------------------------------    
--  #TempProductsFilteredByDateAndPUIdList TABLE    
-----------------------------------------------------------------------------------------------------------------------    
CREATE TABLE #tblTempProductsFilteredByDateAndPUIdList(    
 Prod_Id INTEGER)    
-----------------------------------------------------------------------------------------------------------------------    
--  #TempProductFamily TABLE    
-----------------------------------------------------------------------------------------------------------------------    
CREATE TABLE #tblTempProductFamily(    
 RcdIdx    INT IDENTITY(1,1),    
 ProductFamilyId  INT,    
 ProductFamilyDesc  VARCHAR(1000))    
-----------------------------------------------------------------------------------------------------------------------    
--  #TempProdUnits TABLE    
-----------------------------------------------------------------------------------------------------------------------    
CREATE TABLE #tblTempProdUnits(    
 PU_Id INTEGER)    
-----------------------------------------------------------------------------------------------------------------------    
--  #tblTempProductGroup Table use to get all the product groups    
-----------------------------------------------------------------------------------------------------------------------    
CREATE TABLE #tblTempProductGroup(    
 RcdIdx   INT IDENTITY(1,1),    
 ProductGrpId  INT,    
 ProductGrpDesc VARCHAR(1000))    
-----------------------------------------------------------------------------------------------------------------------    
-- TEMP TABLE used for parsing labels    
-----------------------------------------------------------------------------------------------------------------------    
CREATE TABLE #TempParsingTable (    
    RcdId   INT,    
    ValueINT  INT,    
    ValueVARCHAR100 VARCHAR(100))    
-----------------------------------------------------------------------------------------------------------------------    
-- Temporary table to get the list of lines    
-----------------------------------------------------------------------------------------------------------------------    
DECLARE @tblTempPLIdList TABLE(    
 RcdIdx   INT IDENTITY(1,1),    
 PLId   INT,    
 PUConstraintId  INT)    
-----------------------------------------------------------------------------------------------------------------------    
-- Temporary table to get the list of shifts    
-----------------------------------------------------------------------------------------------------------------------    
DECLARE @tblTempShiftList TABLE(    
 RcdIdx   INT IDENTITY(1,1),    
 ShiftId   INT)    
-----------------------------------------------------------------------------------------------------------------------    
--  #TempProducts TABLE to get all the products    
-----------------------------------------------------------------------------------------------------------------------    
CREATE TABLE #tblTempProducts(    
 RcdIdx   INT IDENTITY(1,1),    
 ProductId  INT,    
 ProdCode  VARCHAR(100),    
 ProdDesc  VARCHAR(100),    
 ProductGrpId INT,    
 ProductFamilyId INT,    
 Shift   VARCHAR(10),    
 Team   VARCHAR(10))    
    
DECLARE @tblProdUnitsTable TABLE(    
 RcdIdx  INT IDENTITY(1,1),    
 ProdUnitId INT)    
    
DECLARE @tblConstraintLinesforBETS TABLE(    
 RdcIdx  INT IDENTITY(1,1),    
 PUId  INT)    
DECLARE @tblProducts TABLE(    
 RdcIdx  INT IDENTITY(1,1),    
 ProdId  INT)    
    
--=====================================================================================================================    
-- INITIALIZE Variables    
--=====================================================================================================================    
SELECT  @nvchSqlStatement = '',    
  @vchlikeclause = '',    
  @ProdField = '',    
  @ErrorCode = 0,    
  @ErrorMessage = ''    
--=====================================================================================================================    
-- INITIALIZE Constants    
--=====================================================================================================================    
SELECT @constUDPDescBatchUnit   = 'IsBatchUnit',    
  @constUDPDescConstraintUnit = 'IsConstraintUnit'    
--=====================================================================================================================    
-- GET Shift Parameter and Split Records variable    
--=====================================================================================================================    
SELECT  @intIncludeShift = 0,    
  @intSplitRecords = 1    
--=====================================================================================================================    
-- SET START DATE AND END DATE    
-- Business Rule    
-- a. CHECK Value for TimeOption    
-- b. IF TimeOption = 0    
--   take the VALUES of StartDate and EndDate which are user defined    
-- c. ELSE     
--   CALL spCMN_GETRelativeDate and pass the TimeOption Value    
--   The TimeOption Value is the RRD_Id in dbo.Report_Relative_Dates    
--   The spCMN_GETRelativeDate sp takes the RRD_Id and interprets the SQL code in    
--   the dbo.Report_Relative_Dates table and returns the calculated dates    
-----------------------------------------------------------------------------------------------------------------------    
-- a. CHECK Value for TimeOption    
-----------------------------------------------------------------------------------------------------------------------    
SELECT @intTimeOption = CONVERT(INT, COALESCE(@p_intTimeOption, 0))    
-----------------------------------------------------------------------------------------------------------------------    
-- b. IF TimeOption = 0    
--   take the VALUES of StartDate and EndDate which are user defined    
-- c. ELSE     
--   CALL spCMN_GETRelativeDate and pass the TimeOption Value    
--   The TimeOption Value is the RRD_Id in dbo.Report_Relative_Dates     
--   The spCMN_GETRelativeDate sp takes the RRD_Id and interprets the SQL code in    
--   the dbo.Report_Relative_Dates table and returns the calculated dates    
-----------------------------------------------------------------------------------------------------------------------    
IF @intTimeOption = 0     
BEGIN    
 -------------------------------------------------------------------------------------------------------------------    
 -- GET user defined start date    
 -------------------------------------------------------------------------------------------------------------------    
 SELECT @dtmRptStartTime = CONVERT(DATETIME, @p_vchstrStartDate)    
 -------------------------------------------------------------------------------------------------------------------    
 -- GET user defined end date    
 -------------------------------------------------------------------------------------------------------------------    
 SELECT @dtmRptEndTime = CONVERT(DATETIME, @p_vchstrEndDate)    
END     
ELSE    
BEGIN    
 EXEC spCmn_GetRelativeDate    
   @StartTimeStamp = @dtmRptStartTime OUTPUT,    
   @EndTimeStamp = @dtmRptEndTime OUTPUT,    
   @PrmRRDId =  @intTimeOption    
END    
--=====================================================================================================================    
-- GET the list of product units    
-- Validate the parameter @p_intWebLocalLocalFilterProdLinesOutputType    
--  0. @p_intWebLocalFilterProdLinesOutputType - All    
--  2. @p_intWebLocalFilterProdLinesOutputType - Bets    
--=====================================================================================================================    
--  0. @p_intWebLocalFilterProdLinesOutputType - All    
-----------------------------------------------------------------------------------------------------------------------    
IF @p_intWebLocalFilterProdLinesOutputType = 0    
BEGIN    
 -------------------------------------------------------------------------------------------------------------------    
 -- CHECK the strRptPUIdList    
 -- 0. @p_vchstrRptPUIdList <> NULL THEN Get the Prod Units that belong to the list    
  -- 1. @p_vchstrRptPLIdList <> NULL THEN Get the Prod Units that belong to the PL Id list    
  -- 2. @p_vchstrRptPLIdList =  NULL THEN Get all the Prod Units    
 -------------------------------------------------------------------------------------------------------------------    
 -- 0. @p_vchstrRptPUIdList <> NULL THEN Get the Prod Units that belong to the list    
 -------------------------------------------------------------------------------------------------------------------    
 IF @p_vchstrRptPUIdList IS NOT NULL AND UPPER(@p_vchstrRptPUIdList) <> '!NULL' AND UPPER(@p_vchstrRptPUIdList) <> 'ALL'    
 BEGIN    
  ---------------------------------------------------------------------------------------------------------------    
  -- SPLIT the values of the product units list    
  ---------------------------------------------------------------------------------------------------------------    
  TRUNCATE TABLE #TempParsingTable    
  INSERT INTO #TempParsingTable(RcdId, ValueVARCHAR100)    
  EXEC spCMN_ReportCollectionParsing     
    @PRMCollectionString =  @p_vchstrRptPUIdList,    
    @PRMFieldDelimiter = NULL,      
    @PRMRecordDelimiter = '|',    
    @PRMDataType01 = 'VARCHAR(100)'    
  ---------------------------------------------------------------------------------------------------------------    
  -- INSERT the values to the @tblProdUnitsTable    
  ---------------------------------------------------------------------------------------------------------------    
  INSERT INTO @tblProdUnitsTable(    
    ProdUnitId)    
  SELECT ValueVARCHAR100    
  FROM #TempParsingTable    
 END    
 ELSE IF @p_vchstrRptPLIdList IS NOT NULL AND UPPER(@p_vchstrRptPLIdList) <> '!NULL' AND UPPER(@p_vchstrRptPLIdList) <> 'ALL'    
 -------------------------------------------------------------------------------------------------------------------    
 -- 1. @p_vchstrRptPLIdList <> NULL THEN Get the Prod Units that belong to that product lines list    
 -------------------------------------------------------------------------------------------------------------------    
 BEGIN    
  ---------------------------------------------------------------------------------------------------------------    
  -- SPLIT the values of the product lines list    
  ---------------------------------------------------------------------------------------------------------------    
  TRUNCATE TABLE #TempParsingTable    
  INSERT INTO #TempParsingTable(RcdId, ValueVARCHAR100)    
  EXEC spCMN_ReportCollectionParsing     
    @PRMCollectionString =  @p_vchstrRptPLIdList,    
    @PRMFieldDelimiter = NULL,      
    @PRMRecordDelimiter = '|',    
    @PRMDataType01 = 'VARCHAR(100)'    
  ---------------------------------------------------------------------------------------------------------------    
  -- INSERT values into the @tblProdUnitsTable where PLId in @p_vchstrRptPLIdList    
  ---------------------------------------------------------------------------------------------------------------    
  INSERT INTO @tblProdUnitsTable(    
    ProdUnitId)    
  SELECT pu.PU_Id    
  FROM dbo.Prod_Units  pu WITH(NOLOCK)    
  JOIN #TempParsingTable  tpt ON tpt.ValueVARCHAR100 = pu.PL_Id    
 END    
 ELSE    
 -------------------------------------------------------------------------------------------------------------------    
 -- 2. @p_vchstrRptPLIdList =  NULL THEN Get all the Prod Units    
 -------------------------------------------------------------------------------------------------------------------    
 BEGIN    
  INSERT INTO @tblProdUnitsTable(    
    ProdUnitId)    
  SELECT DISTINCT(pu.PU_Id)    
  FROM dbo.Prod_Units  pu WITH(NOLOCK)      
 END    
END    
-----------------------------------------------------------------------------------------------------------------------    
--  2. @p_intWebLocalFilterProdLinesOutputType - Bets    
-----------------------------------------------------------------------------------------------------------------------    
ELSE   IF @p_intWebLocalFilterProdLinesOutputType = 2    
BEGIN    
  -------------------------------------------------------------------------------------------------------------------    
  -- CHECK the strRptPUIdList    
  -- 0. @p_vchstrRptPUIdList <> NULL THEN Get the Prod Units that belong to the list    
   -- 1. @p_vchstrRptPLIdList <> NULL THEN Get the Prod Units that belong to the PL Id list    
   -- 2. @p_vchstrRptPLIdList =  NULL THEN Get all the Prod Units    
  -------------------------------------------------------------------------------------------------------------------    
  -- 0. @p_vchstrRptPUIdList <> NULL THEN Get the Prod Units that belong to the list    
  -------------------------------------------------------------------------------------------------------------------    
  IF @p_vchstrRptPUIdList IS NOT NULL AND UPPER(@p_vchstrRptPUIdList) <> '!NULL' AND UPPER(@p_vchstrRptPUIdList) <> 'ALL'    
  BEGIN    
   ---------------------------------------------------------------------------------------------------------------    
   -- SPLIT the values of the product units list    
   ---------------------------------------------------------------------------------------------------------------    
   TRUNCATE TABLE #TempParsingTable    
   INSERT INTO #TempParsingTable(RcdId, ValueVARCHAR100)    
   EXEC spCMN_ReportCollectionParsing     
     @PRMCollectionString =  @p_vchstrRptPUIdList,    
     @PRMFieldDelimiter = NULL,      
     @PRMRecordDelimiter = '|',    
     @PRMDataType01 = 'VARCHAR(100)'    
   ---------------------------------------------------------------------------------------------------------------    
   -- INSERT the values to the @tblProdUnitsTable    
   ---------------------------------------------------------------------------------------------------------------    
   INSERT INTO @tblProdUnitsTable(    
     ProdUnitId)    
   SELECT ValueVARCHAR100    
   FROM #TempParsingTable    
  END    
  -------------------------------------------------------------------------------------------------------------------    
  -- 1. @p_vchstrRptPLIdList <> NULL THEN Get the Prod Units that belong to the PL Id list    
  -------------------------------------------------------------------------------------------------------------------    
  ELSE IF @p_vchstrRptPLIdList IS NOT NULL AND UPPER(@p_vchstrRptPLIdList) <> '!NULL' AND UPPER(@p_vchstrRptPLIdList) <> 'ALL'    
  BEGIN    
   ---------------------------------------------------------------------------------------------------------------    
   -- SPLIT the values of the product lines list    
   ---------------------------------------------------------------------------------------------------------------    
   TRUNCATE TABLE #TempParsingTable    
   INSERT INTO #TempParsingTable(RcdId, ValueVARCHAR100)    
   EXEC spCMN_ReportCollectionParsing     
     @PRMCollectionString =  @p_vchstrRptPLIdList,    
     @PRMFieldDelimiter = NULL,      
     @PRMRecordDelimiter = '|',    
     @PRMDataType01 = 'VARCHAR(100)'    
   --------------------------------------------------------------------------------------------------------------    
   -- INSERT the values to the @tblTempPLIdList    
   --------------------------------------------------------------------------------------------------------------    
   INSERT INTO @tblTempPLIdList (    
      PLId)    
   SELECT  pl.PL_Id    
   FROM  #TempParsingTable   tpt    
   JOIN dbo.Prod_Lines     pl WITH (NOLOCK)    
             ON tpt.ValueVARCHAR100 = pl.PL_Id    
   JOIN  dbo.Prod_Units     pu WITH (NOLOCK)    
             ON pl.pl_id = pu.pl_id    
   JOIN dbo.Table_Fields_Values  tfv WITH (NOLOCK)    
             ON pu.PU_Id = tfv.KeyId    
   JOIN dbo.Table_Fields   tf WITH (NOLOCK)    
             ON tf.Table_Field_Id  = tfv.Table_Field_Id    
   WHERE tf.Table_Field_Desc = @constUDPDescBatchUnit    
   --------------------------------------------------------------------------------------------------------------    
   -- INSERT the values to the @tblProdUnitsTable    
   --------------------------------------------------------------------------------------------------------------    
   INSERT INTO @tblProdUnitsTable(    
     ProdUnitId)    
   SELECT  DISTINCT(pu.PU_Id)    
   FROM @tblTempPLIdList  ls    
   JOIN  dbo.Prod_Units    pu WITH (NOLOCK)    
            ON ls.PLId    = pu.Pl_Id    
   JOIN dbo.Table_Fields_Values tfv WITH (NOLOCK)    
            ON pu.PU_Id    = tfv.KeyId    
   JOIN dbo.Table_Fields  tf WITH (NOLOCK)    
            ON tf.Table_Field_Id  = tfv.Table_Field_Id    
   WHERE tf.Table_Field_Desc = @constUDPDescConstraintUnit    
  END    
  ELSE    
  BEGIN    
  -------------------------------------------------------------------------------------------------------------------    
  -- 2. @p_vchstrRptPLIdList =  NULL THEN Get all the Prod Units    
  -------------------------------------------------------------------------------------------------------------------    
   -- INSERT the values to the @tblTempPLIdList    
   ---------------------------------------------------------------------------------------------------------------    
   INSERT INTO @tblTempPLIdList (    
      PLId)    
   SELECT  pl.PL_Id    
   FROM  dbo.Prod_Lines     pl WITH (NOLOCK)    
   JOIN  dbo.Prod_Units  pu WITH (NOLOCK)    
             ON pl.pl_id = pu.pl_id    
   JOIN dbo.Table_Fields_Values  tfv WITH (NOLOCK)    
             ON pu.PU_Id = tfv.KeyId    
   JOIN dbo.Table_Fields   tf WITH (NOLOCK)    
             ON tf.Table_Field_Id  = tfv.Table_Field_Id    
   WHERE tf.Table_Field_Desc = @constUDPDescBatchUnit     
   --------------------------------------------------------------------------------------------------------------    
   -- INSERT the values to the @tblProdUnitsTable    
   --------------------------------------------------------------------------------------------------------------    
   INSERT INTO @tblProdUnitsTable(    
     ProdUnitId)    
   SELECT  DISTINCT(pu.PU_Id)    
   FROM @tblTempPLIdList  ls    
   JOIN  dbo.Prod_Units    pu WITH (NOLOCK)    
            ON ls.PLId    = pu.Pl_Id    
   JOIN dbo.Table_Fields_Values tfv WITH (NOLOCK)    
            ON pu.PU_Id    = tfv.KeyId    
   JOIN dbo.Table_Fields  tf WITH (NOLOCK)    
            ON tf.Table_Field_Id  = tfv.Table_Field_Id    
   WHERE tf.Table_Field_Desc = @constUDPDescConstraintUnit    
  END    
END    
-------------------------------------------------------------------------------------------------------------------    
-- CHECK the Filter Date option    
-- Option:    
-- 0. Dont apply Filter by date and return just the products that belong to the pu_id of the @tblProdUnitsTable    
-- 1. Apply Filter by date and return all the products filtered by date from the production_starts table    
------------------------------------------------------------------------------------------------------------------    
-- 0. Dont apply Filter by date and return just the products that belong to the pu_id of the @tblProdUnitsTable    
------------------------------------------------------------------------------------------------------------------    
IF COALESCE(@p_intFilterByDate,0) = 0    
BEGIN    
 ---------------------------------------------------------------------------------------------------------------    
 -- Get the products from the PU_Products where the PU_Id belongs to the @tblProdUnitsTable table    
 ---------------------------------------------------------------------------------------------------------------    
 INSERT INTO #tblTempProducts(    
    ProductId,    
    ProdCode,    
    ProdDesc,    
    ProductGrpId,    
    ProductFamilyId)    
 SELECT DISTINCT    
   pup.Prod_Id,    
   p.Prod_Code,    
   p.Prod_Desc,    
   pgd.Product_Grp_Id,    
   p.Product_Family_Id       
 FROM dbo.PU_Products   pup WITH(NOLOCK)    
 JOIN @tblProdUnitsTable  tpu ON tpu.ProdUnitId = pup.PU_Id    
 JOIN dbo.Products   p WITH(NOLOCK)    
          ON pup.Prod_Id = p.Prod_Id    
 LEFT JOIN dbo.Product_Group_Data  pgd WITH(NOLOCK)    
          ON pup.Prod_Id = pgd.Prod_Id    
END    
------------------------------------------------------------------------------------------------------------------    
-- 1. Apply Filter by date and return all the products filtered by date from the production_starts table    
------------------------------------------------------------------------------------------------------------------    
ELSE IF COALESCE(@p_intFilterByDate,0) = 1    
BEGIN    
 --------------------------------------------------------------------------------------------------------------    
 -- PARSE the dates    
 --------------------------------------------------------------------------------------------------------------    
 SELECT  @vchStartDate = CONVERT(VARCHAR(25),@dtmRptStartTime,120),    
   @vchEndDate = CONVERT(VARCHAR(25),@dtmRptEndTime,120)    
--   ----------------------------------------------------------------------------------------------------------    
--   -- FILTER BY SHIFT    
--   ----------------------------------------------------------------------------------------------------------    
--   IF NOT @p_vchShiftsSelected IS NULL AND COALESCE(UPPER(@p_vchShiftsSelected),'ALL') <> 'ALL' AND LEN(@p_vchShiftsSelected) >= 0    
--   BEGIN    
--    -------------------------------------------------------------------------------------------------------    
--    -- SPLIT the values of the shift list    
--    -------------------------------------------------------------------------------------------------------    
--    TRUNCATE TABLE #TempParsingTable    
--    INSERT INTO #TempParsingTable(RcdId, ValueVARCHAR100)    
--    EXEC spCMN_ReportCollectionParsing     
--      @PRMCollectionString =  @p_vchShiftsSelected,    
--      @PRMFieldDelimiter = NULL,      
--      @PRMRecordDelimiter = ',',    
--      @PRMDataType01 = 'VARCHAR(100)'    
--    -------------------------------------------------------------------------------------------------------    
--    -- DELETE the not needed products    
--    -------------------------------------------------------------------------------------------------------    
--    DELETE FROM #tblTempProducts    
--    WHERE  Shift NOT IN (SELECT ValueVARCHAR100 FROM #TempParsingTable)    
--   END    
--   ----------------------------------------------------------------------------------------------------------    
--   -- FILTER BY TEAM    
--   ----------------------------------------------------------------------------------------------------------    
--   IF NOT @p_vchTeamsSelected IS NULL AND COALESCE(UPPER(@p_vchTeamsSelected),'ALL') <> 'ALL' AND LEN(@p_vchTeamsSelected) >= 0    
--   BEGIN    
--    -------------------------------------------------------------------------------------------------------    
--    -- SPLIT the values of the shift list    
--    -------------------------------------------------------------------------------------------------------    
--    TRUNCATE TABLE #TempParsingTable    
--    INSERT INTO #TempParsingTable(RcdId, ValueVARCHAR100)    
--    EXEC spCMN_ReportCollectionParsing     
--      @PRMCollectionString =  @p_vchTeamsSelected,    
--      @PRMFieldDelimiter = NULL,      
--      @PRMRecordDelimiter = ',',    
--      @PRMDataType01 = 'VARCHAR(100)'    
--    -------------------------------------------------------------------------------------------------------    
--    -- DELETE the not needed products    
--    -------------------------------------------------------------------------------------------------------    
--    DELETE FROM #tblTempProducts    
--    WHERE  Team NOT IN (SELECT ValueVARCHAR100 FROM #TempParsingTable)    
--   END    
-- END    
--      
--  ELSE     
 IF @p_intWebLocalFilterProdLinesOutputType = 2    
 --------------------------------------------------------------------------------------------------------------    
 -- CHECK if it is bets then call the function to get all the products needed    
 --------------------------------------------------------------------------------------------------------------    
 BEGIN    
   
  SELECT @PU_ID = (SELECT ProdUnitId FROM @tblProdUnitsTable)  
  ----------------------------------------------------------------------------------------------------------    
  -- INITIALIZE variables    
  ----------------------------------------------------------------------------------------------------------    
  SELECT  @intMaxCount = COUNT(PLId),    
    @i = 1,    
    @intPLId = 0    
  FROM @tblTempPLIdList    
  ----------------------------------------------------------------------------------------------------------    
  -- LOOP Through the lines to get the products    
  ----------------------------------------------------------------------------------------------------------    
  WHILE @i <= @intMaxCount    
  BEGIN    
   ------------------------------------------------------------------------------------------------------    
   -- GET the PLId from the @tblTempPLIdList table    
   ------------------------------------------------------------------------------------------------------    
   SELECT  @intPLId = PLId    
   FROM  @tblTempPLIdList    
   WHERE RcdIdx = @i    
   ------------------------------------------------------------------------------------------------------    
   -- INSERT values in the #tblTempProducts table    
   ------------------------------------------------------------------------------------------------------    
   INSERT  INTO #tblTempProducts    
     (ProductId,    
     ProdCode,    
     ProdDesc,    
     Shift,    
     Team)    
   SELECT UPProdId,    
     UPProdCode,    
     UPProdDesc,    
     BatchShift,    
     BatchTeam    
   FROM dbo.fnLocal_Bets_BatchData (@PU_ID, @vchStartDate, @vchEndDate, @intSplitRecords, @intIncludeShift)    
   ------------------------------------------------------------------------------------------------------    
   -- INCREMENT counter    
   ------------------------------------------------------------------------------------------------------    
   SET @i = @i + 1    
  END    
  ----------------------------------------------------------------------------------------------------------    
  -- GET Product Group Id and Product Family Id    
  ----------------------------------------------------------------------------------------------------------    
  UPDATE  #tblTempProducts    
  SET  ProductGrpId = pgd.Product_Grp_Id,    
    ProductFamilyId = p.Product_Family_Id    
  FROM #tblTempProducts tp    
  JOIN dbo.Product_Group_Data  pgd WITH(NOLOCK)    
           ON tp.ProductId = pgd.Prod_Id    
  JOIN dbo.Products   p WITH(NOLOCK)    
           ON tp.ProductId = p.Prod_Id    
--   ----------------------------------------------------------------------------------------------------------    
--   -- FILTER BY SHIFT    
--   ----------------------------------------------------------------------------------------------------------    
--   IF NOT @p_vchShiftsSelected IS NULL AND COALESCE(UPPER(@p_vchShiftsSelected),'ALL') <> 'ALL' AND LEN(@p_vchShiftsSelected) >= 0    
--   BEGIN    
--    -------------------------------------------------------------------------------------------------------    
--    -- SPLIT the values of the shift list    
--    -------------------------------------------------------------------------------------------------------    
--    TRUNCATE TABLE #TempParsingTable    
--    INSERT INTO #TempParsingTable(RcdId, ValueVARCHAR100)    
--    EXEC spCMN_ReportCollectionParsing     
--      @PRMCollectionString =  @p_vchShiftsSelected,    
--      @PRMFieldDelimiter = NULL,      
--      @PRMRecordDelimiter = ',',    
--      @PRMDataType01 = 'VARCHAR(100)'    
--    -------------------------------------------------------------------------------------------------------    
--    -- DELETE the not needed products    
--    -------------------------------------------------------------------------------------------------------    
--    DELETE FROM #tblTempProducts    
--    WHERE  Shift NOT IN (SELECT DISTINCT(ValueVARCHAR100) FROM #TempParsingTable)    
--   END    
--   ----------------------------------------------------------------------------------------------------------    
--   -- FILTER BY TEAM    
--   ----------------------------------------------------------------------------------------------------------    
--   IF NOT @p_vchTeamsSelected IS NULL AND COALESCE(UPPER(@p_vchTeamsSelected),'ALL') <> 'ALL' AND LEN(@p_vchTeamsSelected) >= 0    
--   BEGIN    
--    -------------------------------------------------------------------------------------------------------    
--    -- SPLIT the values of the shift list    
--    -------------------------------------------------------------------------------------------------------    
--    TRUNCATE TABLE #TempParsingTable    
--    INSERT INTO #TempParsingTable(RcdId, ValueVARCHAR100)    
--    EXEC spCMN_ReportCollectionParsing     
--      @PRMCollectionString =  @p_vchTeamsSelected,    
--      @PRMFieldDelimiter = NULL,      
--      @PRMRecordDelimiter = ',',    
--      @PRMDataType01 = 'VARCHAR(100)'    
--    -------------------------------------------------------------------------------------------------------    
--    -- DELETE the not needed products    
--    -------------------------------------------------------------------------------------------------------    
--    DELETE FROM #tblTempProducts    
--    WHERE  Team NOT IN (SELECT DISTINCT(ValueVARCHAR100) FROM #TempParsingTable)    
--   END    
  --Select * from #tblTempProducts --debugdel    
 END    
 ELSE     
 BEGIN    
  INSERT  INTO #tblTempProducts    
    (ProductId,    
     ProdCode,    
     ProdDesc,    
     ProductGrpId,    
     ProductFamilyId)    
  SELECT  DISTINCT(ps.Prod_Id),    
    p.Prod_Code,    
    p.Prod_Desc,    
    pgd.Product_Grp_Id,    
    p.Product_Family_Id      
  FROM dbo.Production_Starts ps WITH(NOLOCK)    
  JOIN @tblProdUnitsTable  tpu ON tpu.ProdUnitId = ps.PU_Id    
           AND (ps.Start_Time >= CONVERT(VARCHAR(25),@dtmRptStartTime,120)    
           AND ps.End_Time <= CONVERT(VARCHAR(25),@dtmRptEndTime,120))    
  JOIN dbo.Products   p WITH(NOLOCK)    
           ON ps.Prod_Id = p.Prod_Id    
  LEFT JOIN dbo.Product_Group_Data  pgd WITH(NOLOCK)    
           ON p.Prod_Id = pgd.Prod_Id    
 END    
END    
--=====================================================================================================================    
-- FILTER by Product Families Ids    
-- SPLIT the values of the product groups list    
-----------------------------------------------------------------------------------------------------------------------    
IF LEN(ISNULL(@p_strRptProductFamilyIdList,'')) > 0 AND UPPER(@p_strRptProductFamilyIdList) <> '!NULL' AND UPPER(@p_strRptProductFamilyIdList) <> 'ALL'    
BEGIN    
 TRUNCATE TABLE #TempParsingTable   INSERT INTO #TempParsingTable(RcdId, ValueVARCHAR100)    
 EXEC spCMN_ReportCollectionParsing     
   @PRMCollectionString =  @p_strRptProductFamilyIdList,    
   @PRMFieldDelimiter = NULL,      
   @PRMRecordDelimiter = '|',    
   @PRMDataType01 = 'VARCHAR(100)'    
 -------------------------------------------------------------------------------------------------------------------    
 -- DELETE all the products that dont belong to the product family id list    
 -------------------------------------------------------------------------------------------------------------------    
 DELETE  FROM #tblTempProducts    
 WHERE ProductFamilyId NOT IN     
 (SELECT ValueVARCHAR100    
 FROM #TempParsingTable)    
END    
--=====================================================================================================================    
-- FILTER by Product Group Ids    
-- SPLIT the values of the product groups list    
-----------------------------------------------------------------------------------------------------------------------    
-- GET Product Groups    
-----------------------------------------------------------------------------------------------------------------------    
INSERT INTO #tblTempProductGroup(    
  ProductGrpId,    
  ProductGrpDesc)    
SELECT  DISTINCT     
  pgd.Product_Grp_Id,    
  pg.Product_Grp_Desc    
FROM #tblTempProducts  tp    
JOIN dbo.Product_Group_Data pgd WITH(NOLOCK)    
         ON tp.ProductId = pgd.Prod_Id    
JOIN dbo.Product_Groups pg WITH (NOLOCK)    
        ON pg.Product_Grp_Id = pgd.Product_Grp_Id    
-----------------------------------------------------------------------------------------------------------------------    
IF LEN(ISNULL(@p_strRptProductGrpIdList,'')) > 0 AND UPPER(@p_strRptProductGrpIdList) <> '!NULL' AND UPPER(@p_strRptProductGrpIdList) <> 'ALL'    
BEGIN    
 TRUNCATE TABLE #TempParsingTable    
 INSERT INTO #TempParsingTable(RcdId, ValueVARCHAR100)    
 EXEC spCMN_ReportCollectionParsing     
   @PRMCollectionString =  @p_strRptProductGrpIdList,    
   @PRMFieldDelimiter = NULL,      
   @PRMRecordDelimiter = '|',    
   @PRMDataType01 = 'VARCHAR(100)'    
 -------------------------------------------------------------------------------------------------------------------    
 -- Get the Product Groups for the products     
 -------------------------------------------------------------------------------------------------------------------    
 INSERT INTO #tblTempProducts (    
    ProductGrpId,    
    ProductId,    
    ProdCode,    
 ProdDesc)    
 SELECT DISTINCT    
   pgd.Product_Grp_Id,    
   tp.ProductId,    
   tp.ProdCode,    
   tp.ProdDesc    
 FROM #tblTempProducts tp    
  JOIN dbo.Product_Group_Data pgd WITH (NOLOCK)    
           ON tp.ProductId = pgd.Prod_Id    
 -------------------------------------------------------------------------------------------------------------------    
 -- DELETE all product groups where Product Group Id IS NULL    
 -------------------------------------------------------------------------------------------------------------------    
 DELETE #tblTempProducts    
  WHERE ProductGrpId IS NULL    
 -------------------------------------------------------------------------------------------------------------------    
 -- DELETE all the products that don't belong to the product group id list    
 -------------------------------------------------------------------------------------------------------------------    
 DELETE #tblTempProducts     
 WHERE ProductGrpId NOT IN     
 ( SELECT ValueVARCHAR100    
  FROM #TempParsingTable)    
 -------------------------------------------------------------------------------------------------------------------    
 -- DELETE all the products groups that belong to the product group id list    
 -------------------------------------------------------------------------------------------------------------------    
 DELETE FROM #tblTempProductGroup    
 WHERE ProductGrpId IN (SELECT ValueVARCHAR100 FROM #TempParsingTable)    
END    
--=====================================================================================================================    
-- FILTER by Product Ids    
-- SPLIT the values of the product id list    
-----------------------------------------------------------------------------------------------------------------------    
IF LEN(ISNULL(@p_vchstrRptProdIdList,'')) > 0 AND UPPER(@p_vchstrRptProdIdList) <> '!NULL' AND UPPER(@p_vchstrRptProdIdList) <> 'ALL'    
BEGIN    
 TRUNCATE TABLE #TempParsingTable    
 INSERT INTO #TempParsingTable(RcdId, ValueVARCHAR100)    
 EXEC spCMN_ReportCollectionParsing     
   @PRMCollectionString =  @p_vchstrRptProdIdList,    
   @PRMFieldDelimiter = NULL,      
   @PRMRecordDelimiter = '|',    
   @PRMDataType01 = 'VARCHAR(100)'    
 -------------------------------------------------------------------------------------------------------------------    
 -- DELETE all the products that dont belong to the product list    
 -------------------------------------------------------------------------------------------------------------------    
 DELETE  FROM #tblTempProducts    
 WHERE ProductId IN     
 (SELECT ValueVARCHAR100    
 FROM #TempParsingTable)    
END    
-------------------------------------------------------------------------------------------------------------------    
-- Apply Search String if needed    
-------------------------------------------------------------------------------------------------------------------    
IF @p_vchSearchString IS NOT NULL AND LEN(@p_vchSearchString) > 0    
BEGIN    
 SELECT @nvchSqlStatement =  'DELETE FROM #tblTempProducts ' +    
        'WHERE'    
 ---------------------------------------------------------------------------------------------------------------    
 -- Search by code    
 ---------------------------------------------------------------------------------------------------------------    
 IF @p_intSearchBy = 1    
 BEGIN       
  SELECT @vchlikeclause = ' ProdCode NOT LIKE ''' + @p_vchSearchString + ''''    
 END    
 ---------------------------------------------------------------------------------------------------------------    
 -- Search by description    
 ---------------------------------------------------------------------------------------------------------------    
 IF @p_intSearchBy = 2    
 BEGIN    
  SELECT @vchlikeclause = ' ProdDesc NOT LIKE ''' + @p_vchSearchString + ''''    
 END    
 ---------------------------------------------------------------------------------------------------------------    
 -- CONCAT the statement    
 ---------------------------------------------------------------------------------------------------------------    
 SELECT @nvchSqlStatement = @nvchSqlStatement + @vchlikeclause    
 ---------------------------------------------------------------------------------------------------------------    
 -- Delete the values from the table    
 ---------------------------------------------------------------------------------------------------------------    
 EXEC sp_ExecuteSQL @nvchSqlStatement    
END    
--=====================================================================================================================     
-- RETURN values    
-- Option: 0 - Products  (Default Value)    
--   1 - Families    
--   2 - Product Group    
--=====================================================================================================================     
IF COALESCE(@p_intOption,0) = 0    
BEGIN    
 -------------------------------------------------------------------------------------------------------------------    
 -- GET Products    
 -- Rule:    
 -- CHECK Parameter @p_intSearchBy     
 -- Options: 1. Return ProdCode    
 --    2. Return ProdDesc    
 -------------------------------------------------------------------------------------------------------------------    
 -- CHECK Parameter @p_intSearchBy     
 -------------------------------------------------------------------------------------------------------------------    
 IF  COALESCE(@p_intSearchBy,1) = 1    
 BEGIN    
  ---------------------------------------------------------------------------------------------------------------    
  -- 1. Return ProdCode    
  ---------------------------------------------------------------------------------------------------------------    
  SELECT DISTINCT ProductId,ProdCode FROM #tblTempProducts    
 END    
 ELSE IF COALESCE(@p_intSearchBy,1) = 2    
 BEGIN    
  ---------------------------------------------------------------------------------------------------------------    
  -- 2. Return ProdDesc    
  ---------------------------------------------------------------------------------------------------------------    
  SELECT DISTINCT ProductId,ProdDesc FROM #tblTempProducts    
 END    
END    
ELSE IF COALESCE(@p_intOption,0) = 1    
BEGIN    
 -------------------------------------------------------------------------------------------------------------------    
 -- RETURN all the families    
 -------------------------------------------------------------------------------------------------------------------    
 SELECT  DISTINCT     
   pf.Product_Family_Desc,    
   tp.ProductFamilyId    
 FROM dbo.Product_Family pf WITH(NOLOCK)    
 JOIN #tblTempProducts tp    
         ON tp.ProductFamilyId = pf.Product_Family_Id    
END    
ELSE IF COALESCE(@p_intOption,0) = 2    
BEGIN    
 -------------------------------------------------------------------------------------------------------------------    
 -- RETURN all the product groups    
 -------------------------------------------------------------------------------------------------------------------    
 SELECT  DISTINCT     
   ProductGrpId,    
   ProductGrpDesc    
 FROM #tblTempProductGroup    
END    
--=====================================================================================================================     
-- DELETE Temporary tables    
--=====================================================================================================================     
DROP TABLE #tblTempProducts    
--=====================================================================================================================     
SET NOCOUNT ON    
--=====================================================================================================================     
RETURN

