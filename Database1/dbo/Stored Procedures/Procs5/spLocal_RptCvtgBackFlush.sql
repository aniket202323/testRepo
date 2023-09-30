 --------------------------------------------------------------------------------------------------------------------------------------------------------  
--  
-- Version 2.31 Last Update: 2009-03-16 Jeff Jaeger  
--  
-- This SP will provide data required for SAP Backflushing.  
-- The report returns three result sets.  
-- 1.  Error Messages.  
-- 2.  Production data by line by product.    
-- 3.  Production data by pack system by product.    
--  
-- 2002-07-28   Vince King  
--  - Original procedure.  
--  
-- 2003-01-22 Vince King  
--  - Modified the Pack result set.  The production was not being summarized by product.  
--    Multiple lines were being reported for a single product ran more than once during  
--    the report period.  Added a GROUP BY statement to summarize data.  
--  
-- 2003-02-26 Vince King  
--  - Albany found a bug where the Good Units summarized was for the entire report period  
--    and not for the time of the product run.  Modified to select Tests rows by product  
--    start and end times.  
--  
-- 2003-10-10 Jeff Jaeger  
--  - Moved the input validations to before any temp tables are created.  
--    This prevents tables from being created before the parameters are validated.  
--    If an error occurs, no tables need to be dropped.  
  
-- 2004-05-12 Kim Hobbs  
--  - Removed/commented out any references to PM Roll Width to accommodate new   
--    genealogy model.  
  
-- 2004-11-04 Jeff Jaeger Rev2.2  
--  - removed unused code.  
--  - bringing this sp up to date with Checklist 110804.  
--  - changed temp tables to table variables where appropriate.  
--  - moved creation of temp tables and table variables to the top of the sp.  
--  - replaced ProdLinesCursor and TestCursor with more efficient insert and update to #tests.  
--  - replaced ProdPackCursor and TestsPackCursor with more efficient insert and update to #testspack.  
--  - replaced RunsPackUnitCursor with a more efficient update to @RunsPackUnit.  
--  - replaced ProdUnitsCursor with a more efficient insert to @Runs.  
--  - replacing these cursors has cut the runtime for the sp approximately in half.  
--  - note:  the last cursor, ProdRLinesCursor, could also be replaced, but I'm not going to spend the   
--  time to do it now.  
--  - added @UserName input parameter.  
--  - added variables and code for language translation.  
--  - added temp tables #ConvertingLine and #PackingLine for returning result sets.  
  
-- 2008-MAR-24 Langdon Davis Rev2.3  
--  -  Add dbo.  
--  - Added WITH(NOLOCK)  
--  - Added the starttime and endtime to the results sets.  
  
-- 2009-03-16 Jeff Jaeger Rev2.31  
--  - added Unit Scrap % to the Line results.  
  
  
--------------------------------------------------------------------------------------------------------------------------------------------------------  
CREATE  PROCEDURE dbo.spLocal_RptCvtgBackFlush  
--Declare  
 @StartTime   DateTime,     -- Beginning period for the data.  
 @EndTime    DateTime,     -- Ending period for the data.  
 @ProdLineList  nVarChar(4000),  -- Collection of Prod_Lines.PL_Id for converting lines delimited by "|".  
 @ProdPackList  nVarChar(4000),  -- Collection of Prod_Lines.PL_Id for packing lines delimited by "|".  
 @UserName   varchar(30)  
AS  
  
-------------------------------------------------------------------------------  
-- Assign Report Parameters for SP testing locally.  
-------------------------------------------------------------------------------  
/*  
--Mehoopany  
Select    
@StartTime = '2002-07-26 07:30:00',  
@EndTime = '2002-07-27 07:30:00',  
@ProdLineList = '68|72|73|74|75|119|136|135|145|108',  
@ProdPackList = '71|116|142'  
*/  
/*  
-- Cape  
Select    
@StartTime = '2002-07-26 07:30:00',  
@EndTime = '2002-07-27 07:30:00',  
@ProdLineList = '155|151|146|3|5|142|143',  
@ProdPackList = '6|147|139|154|140|153|141|152|148'  
*/  
--/*  
-- AY  
--Select    
--@StartTime  = '2009-03-06 07:00:00',  
--@EndTime  = '2009-03-07 07:00:00',  
--@ProdLineList  = '32|38|40|35|43|45|46|48|58|60|62|64',  
--@ProdPackList  = '33|39|41|36|44|47|50|59|61|63|65',  
--@UserName  = 'ComXClient'  
--*/  
/*  
-- AZ  
Select    
@StartTime  = '2004-11-06 07:00:00',  
@EndTime  = '2004-11-07 07:00:00',  
@ProdLineList  = '17|18|19|20|21|22|23|24|25',  
@ProdPackList  = '26|27|28|29',  
@UserName  = 'ComXClient'  
*/  
  
  
SET ANSI_WARNINGS OFF  
  
-------------------------------------------------------------------------------  
-- Check Input Parameters.  
-------------------------------------------------------------------------------  
  
declare @ErrorMessages table  
(  
 ErrMsg  nVarChar(255)   
)  
  
IF IsDate(@StartTime) <> 1  
BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@StartTime is not a Date.')  
 GOTO ReturnResultSets  
END  
IF IsDate(@EndTime) <> 1  
BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@EndTime is not a Date.')  
 GOTO ReturnResultSets  
END  
  
-- If the endtime is in the future, set it to current day.  This prevent zero records from being printed on report.  
IF @EndTime > GetDate()  
 SELECT @EndTime = CONVERT(VarChar(4),YEAR(GetDate())) + '-' + CONVERT(VarChar(2),MONTH(GetDate())) + '-' +   
     CONVERT(VarChar(2),DAY(GetDate())) + ' ' + CONVERT(VarChar(2),DATEPART(hh,@EndTime)) + ':' +   
     CONVERT(VarChar(2),DATEPART(mi,@EndTime))+ ':' + CONVERT(VarChar(2),DATEPART(ss,@EndTime))  
  
  
-------------------------------------------------------------------------------  
-- Create temporary Error Messages and ResultSet tables.  
-------------------------------------------------------------------------------  
  
declare @Runs table  
(  
 StartId    Int Primary Key,  
 PLId    Int,  
 PUId    Int,  
 ProdId    Int,  
 StartTime   DateTime,  
 EndTime    DateTime   
)  
  
declare @ProdUnits table  
(  
 PUId    Int Primary Key,  
 PUDesc    varchar(100),  
 PLId    Int,  
 VarGoodUnitsId   Int,  
 GoodUnits   Int,  
 PackOrLine   nVarChar(10)   
)  
  
  
declare @ProdLines table  
(  
 PLId    Int Primary Key,  
 VarGoodUnitsId   Int,  
 VarTotalUnitsId   Int,  
 PropLineProdFactorId  Int,  
 PackOrLine   nVarChar(10)   
)  
  
  
declare @RunsLine table   
(  
 PLId    Int,  
 ProdId    Int,  
 StartTime   DateTime,  
 EndTime    DateTime   
)  
  
  
declare @RunsPackUnit table  
(  
 PLId    Int,  
 PUId    Int,  
 ProdId    Int,  
 StartTime   DateTime,  
 EndTime    DateTime,  
 GoodUnits   Int   
)  
  
  
CREATE TABLE #Tests (  
 TestId   Int,  
 VarId   Int,  
 PLId   Int,  
 PUId   Int,  
 Value   Float,  
 StartTime  DateTime,  
 EndTime   DateTime )  
CREATE INDEX tt_VarId_StartTime  
 ON #Tests (VarId, StartTime)  
CREATE INDEX tt_VarId_EndTime  
 ON #Tests (VarId, EndTime)  
  
  
CREATE TABLE #TestsPack (  
 TestId   Int,  
 VarId   Int,  
 PLId   Int,  
 PUId   Int,  
 Value   Float,  
 StartTime  DateTime,  
 EndTime   DateTime )  
CREATE INDEX tt_VarId_StartTime  
 ON #TestsPack (VarId, StartTime)  
CREATE INDEX tt_VarId_EndTime  
 ON #TestsPack (VarId, EndTime)  
  
  
declare @ProdRecords table  
(  
 PLId    Int,  
 ProductId   Int,  
 StartTime   datetime,  
 EndTime    datetime,  
 TotalUnits   Int,  
 GoodUnits   Int,  
 WebWidth   Float,  
 SheetWidth   Float,  
 LineSpeed   Float,  
 RollsPerLog   Int,  
 RollsInPack   Int,  
 PacksInBundle   Int,  
 SheetCount   Int,  
 Runtime    Float,  
 SheetLength   Float,  
 StatFactor   Float,  
 IdealUnits   Int,  
 ActualUnits   Int   
)  
  
create table #ConvertingLine  
(  
 [Line]   varchar(100),  
 [Product] varchar(100),  
 [Product Desc] varchar(100),  
 [Start Time] DateTime,  
 [End Time]  DateTime,  
 [Runtime] float,  
 [Total Units] int,  
 [Good Units] int,  
 [Reject Units] int,  
 [Unit Scrap %] float  
)  
  
create table #PackingLine  
(  
 [Line]   varchar(100),  
 [Prod Unit] varchar(100),  
 [Product Code] varchar(100),  
 [Product Desc] varchar(100),  
 [Start Time] DateTime,  
 [End Time]  DateTime,  
 [Runtime] float,  
 [Good Units] int  
)  
  
  
-------------------------------------------------------------------------------  
-- Declare program variables.  
-------------------------------------------------------------------------------  
  
DECLARE @SearchString   nVarChar(4000),  
 @Position   Int,  
 @PartialString   nVarChar(4000),  
 @Now    DateTime,  
 @@Id    Int,  
 @@ExtendedInfo   nVarChar(255),  
 @PUDelayTypeStr   nVarChar(100),  
 @PUScheduleUnitStr  nVarChar(100),  
 @PULineStatusUnitStr  nVarChar(100),  
 @@PUId    Int,  
 @@TimeStamp   DateTime,  
 @@LastEndTime   DateTime,  
 @VarGoodUnitsId   Int,  
 @VarGoodUnitsVN   nVarChar(100),  
 @VarTotalUnitsId  Int,  
 @VarTotalUnitsVN  nVarChar(100),  
 @VarEffDowntimeId  Int,  
 @VarEffDowntimeVN  nVarChar(100),  
 @@NextStartTime   datetime,  
 @@VarId    Int,  
 @@PLId    Int,  
 @@VarGoodUnitsId  Int,  
 @@VarTotalUnitsId  Int,  
 @@VarEffDowntimeId  Int,  
 @@ProdId   Int,  
 @@StartTime   datetime,  
 @@EndTime   datetime,  
 @@Shift    nVarChar(50),  
 @@Team    nVarChar(50),  
 @ProdCode   nVarChar(100),  
 @CharId    Int,  
 @StatFactor   Float,  
 @RollsInPack   Int,  
 @PacksInBundle   Int,  
 @SheetCount   Int,  
 @SheetWidth   Float,  
 @SheetLength   Float,  
 @LineSpeedTarget  Float,  
 @StatFactorSpecDesc  nVarChar(100),  
 @RollsInPackSpecDesc  nVarChar(100),  
 @PacksInBundleSpecDesc  nVarChar(100),  
 @SheetCountSpecDesc  nVarChar(100),  
 @SheetWidthSpecDesc  nVarChar(100),  
 @SheetLengthSpecDesc  nVarChar(100),  
 @LineSpeedTargetSpecDesc nVarChar(100),  
 @Runtime   Float,  
 @TotalUnits    Int,  
 @GoodUnits   Int,  
 @RollWidth   Float,  
 @LineProdFactorDesc  nVarChar(50),  
 @PropLineProdFactorId  Int,  
 @PLDesc    nVarChar(100),  
 @IdealUnits   Float,  
 @ActualUnits   Float,  
 @RollsPerLog   Int,  
 @CLD    Float,  
 @PropLineSpeedTargetId   Int,  
 @LinePropCharId   Int,  
 @LanguageId   integer,  
 @UserId    integer,  
 @LanguageParmId   integer,  
 @NoDataMsg    varchar(50),  
 @TooMuchDataMsg   varchar(50),  
 @SQL     varchar(8000)  
  
  
SELECT @Now = GetDate(),  
 @VarGoodUnitsVN = 'Good Units',  
 @VarTotalUnitsVN = 'Total Units',  
 @VarEffDowntimeVN = 'Effective Downtime',  
 @StatFactorSpecDesc = 'Stat Factor',  
  
 @PacksInBundleSpecDesc = 'Packs In Bundle',  
 @SheetCountSpecDesc = 'Sheet Count',  
 @SheetWidthSpecDesc = 'Sheet Width',  
 @SheetLengthSpecDesc = 'Sheet Length',  
 @LineProdFactorDesc = 'Production Factors',  
 @LineSpeedTargetSpecDesc = 'Line Speed Target'  
  
  
select   @LanguageParmID  = 8,  
@LanguageId  = NULL  
  
SELECT @UserId = User_Id  
FROM dbo.Users WITH(NOLOCK)  
WHERE UserName = @UserName  
  
SELECT @LanguageId = CASE   
WHEN isnumeric(ltrim(rtrim(Value))) = 1   
THEN convert(float, ltrim(rtrim(Value)))  
    ELSE NULL  
    END  
FROM dbo.User_Parameters WITH(NOLOCK)  
WHERE User_Id = @UserId  
 AND Parm_Id = @LanguageParmId  
  
  
-- updated for efficiency 061004  
IF @LanguageId IS NULL  
  
  SELECT @LanguageId = CASE   
WHEN isnumeric(ltrim(rtrim(Value))) = 1   
THEN convert(float, ltrim(rtrim(Value)))  
     ELSE NULL  
     END  
  FROM dbo.Site_Parameters WITH(NOLOCK)  
  WHERE Parm_Id = @LanguageParmId  
  
-- updated for efficiency 061004  
IF @LanguageId IS NULL  
  
  SELECT @LanguageId = 0  
  
  
select @NoDataMsg = GBDB.dbo.fnLocal_GlblTranslation('NO DATA meets the given criteria', @LanguageId)  
select @TooMuchDataMsg = GBDB.dbo.fnLocal_GlblTranslation('There are more results than can be displayed', @LanguageId)  
  
  
-------------------------------------------------------------------------------  
-- Parse the passed lists into temporary tables.  
-------------------------------------------------------------------------------  
-------------------------------------------------------------------------------  
-- ProdLineList  
-------------------------------------------------------------------------------  
  
SELECT @SearchString = LTrim(RTrim(@ProdLineList))  
WHILE Len(@SearchString) > 0  
BEGIN  
 SELECT @Position = CharIndex('|', @SearchString)  
 IF  @Position = 0  
  SELECT @PartialString = RTrim(@SearchString),  
   @SearchString = ''  
 ELSE  
  SELECT @PartialString = RTrim(SubString(@SearchString, 1, @Position - 1)),  
   @SearchString = LTrim(RTrim(Substring(@SearchString, (@Position + 1), Len(@SearchString))))  
 IF Len(@PartialString) > 0  
 BEGIN  
  IF IsNumeric(@PartialString) <> 1  
  BEGIN  
   INSERT @ErrorMessages (ErrMsg)  
    VALUES ('Parameter @ProdLineList contains non-numeric = ' + @PartialString)  
   GOTO ReturnResultSets  
  END  
  IF (SELECT Count(PLId) FROM @ProdLines WHERE PLId = Convert(Int, @PartialString)) = 0  
   BEGIN  
    SELECT @VarGoodUnitsId = v.Var_Id  
     FROM  dbo.Variables v WITH(NOLOCK)  
      JOIN dbo.Prod_Units pu  WITH(NOLOCK) ON v.PU_Id = pu.PU_Id  
      JOIN dbo.Prod_Lines pl  WITH(NOLOCK) ON pu.PL_Id = pl.PL_Id  
     WHERE (v.Var_Desc = @VarGoodUnitsVN)  
      AND (v.Data_Type_Id IN (1,2))  
      AND (pl.PL_Id = Convert(Int,@PartialString))  
  
    SELECT @VarTotalUnitsId = v.Var_Id  
     FROM  dbo.Variables v  WITH(NOLOCK)  
      JOIN dbo.Prod_Units pu  WITH(NOLOCK) ON v.PU_Id = pu.PU_Id  
      JOIN dbo.Prod_Lines pl  WITH(NOLOCK) ON pu.PL_Id = pl.PL_Id  
     WHERE (v.Var_Desc = @VarTotalUnitsVN)  
      AND (v.Data_Type_Id IN (1,2))  
      AND (pl.PL_Id = Convert(Int,@PartialString))  
  
    SELECT @PLDesc = PL_Desc FROM dbo.Prod_Lines  WITH(NOLOCK) WHERE PL_Id = Convert(Int, @PartialString)  
  
    SELECT @PropLineProdFactorId = Prop_Id  
     FROM dbo.Product_Properties WITH(NOLOCK)  
     Where Prop_Desc = LTRIM(RTRIM(REPLACE(@PLDesc,'TT',''))) + ' ' + @LineProdFactorDesc  
  
    INSERT @ProdLines (PLId, VarGoodUnitsId, VarTotalUnitsId,   
       PropLineProdFactorId, PackOrLine)   
    VALUES (Convert(Int, @PartialString), @VarGoodUnitsId, @VarTotalUnitsId,  
       @PropLineProdFactorId, 'Line')  
   END  
 END  
END  
  
-------------------------------------------------------------------------------  
-- ProdPackList  
-------------------------------------------------------------------------------  
  
SELECT @SearchString = LTrim(RTrim(@ProdPackList))  
WHILE Len(@SearchString) > 0  
BEGIN  
 SELECT @Position = CharIndex('|', @SearchString)  
 IF  @Position = 0  
  SELECT @PartialString = RTrim(@SearchString),  
   @SearchString = ''  
 ELSE  
  SELECT @PartialString = RTrim(SubString(@SearchString, 1, @Position - 1)),  
   @SearchString = LTrim(RTrim(Substring(@SearchString, (@Position + 1), Len(@SearchString))))  
 IF Len(@PartialString) > 0  
 BEGIN  
  IF IsNumeric(@PartialString) <> 1  
  BEGIN  
   INSERT @ErrorMessages (ErrMsg)  
    VALUES ('Parameter @ProdLineList contains non-numeric = ' + @PartialString)  
   GOTO ReturnResultSets  
  END  
  
    INSERT @ProdLines (PLId, PackOrLine)   
    VALUES ((Convert(Int, @PartialString)), 'Pack')  
 END  
END  
  
-------------------------------------------------------------------------------  
-- ProdUnitList  
-------------------------------------------------------------------------------  
INSERT @ProdUnits (PUId, PUDesc, PLId, PackOrLine)  
 SELECT pu.PU_Id, pu.PU_Desc, pu.PL_Id, tpl.PackOrLine  
  FROM dbo.Prod_Units pu WITH(NOLOCK)  
  JOIN @ProdLines tpl ON pu.PL_Id = tpl.PLId  
  WHERE pu.Master_Unit IS NULL  
  
  
 INSERT @Runs (StartId, PLId, PUId, ProdId, StartTime, EndTime)  
  SELECT Start_Id, PLId, ps.PU_Id, ps.Prod_Id, Start_Time, Coalesce(End_Time, @Now)  
   FROM dbo.Production_Starts ps WITH(NOLOCK)  
    LEFT JOIN dbo.Products p  WITH(NOLOCK) ON ps.Prod_Id = p.Prod_Id  
    LEFT JOIN @ProdUnits pu ON ps.PU_Id = pu.PUId  
   WHERE Start_Time < @EndTime  
   AND (End_Time > @StartTime  
    OR End_Time IS NULL)  
   AND (Prod_Desc <> 'No Grade' AND Prod_Code IS NOT NULL)  
   AND pu.PUDesc LIKE '%Production%'  
  
  
 UPDATE @ProdUnits SET  
  VarGoodUnitsId =  (  
     SELECT Var_Id   
     FROM dbo.Variables v WITH(NOLOCK)   
     WHERE Var_Desc = @VarGoodUnitsVN  
     AND v.PU_Id = puId  
     )  
      
  
-------------------------------------------------------------------------------  
-- Collect all the Production Run records for the reporting period for each  
-- production line.  
-------------------------------------------------------------------------------  
  
INSERT @RunsLine (PLId, ProdId, StartTime, EndTime)  
 SELECT pl.PL_Id, ProdId,   
  (CASE WHEN StartTime < @StartTime THEN @StartTime ELSE StartTime END),  
  (CASE WHEN EndTime > @EndTime THEN @EndTime ELSE EndTime END)  
  FROM @Runs r  
   JOIN dbo.Prod_Units pu  WITH(NOLOCK) ON r.PUId = pu.PU_Id  
   JOIN dbo.Prod_Lines pl  WITH(NOLOCK) ON pu.PL_Id = pl.PL_Id  
  GROUP BY pl.PL_Id, ProdId, (CASE WHEN StartTime < @StartTime THEN @StartTime ELSE StartTime END),  
        (CASE WHEN EndTime > @EndTime THEN @EndTime ELSE EndTime END)  
  
-------------------------------------------------------------------------------  
-- Collect all the Production Run records for the reporting period for each  
-- Pack Prod Unit.  
-------------------------------------------------------------------------------  
  
INSERT @RunsPackUnit (PLId, PUId, ProdId, StartTime, EndTime)  
 SELECT pU.PLId, pu.PUId, ProdId,   
  (CASE WHEN StartTime < @StartTime THEN @StartTime ELSE StartTime END),  
  (CASE WHEN EndTime > @EndTime THEN @EndTime ELSE EndTime END)  
  FROM @Runs r  
   JOIN @ProdUnits pu ON r.PUId = pu.PUId  
  WHERE pu.PackOrLine = 'Pack' AND VarGoodUnitsId IS NOT NULL  
  GROUP BY pu.PLId, pu.PUId, ProdId, (CASE WHEN StartTime < @StartTime THEN @StartTime ELSE StartTime END),  
        (CASE WHEN EndTime > @EndTime THEN @EndTime ELSE EndTime END)  
  
--*******************************************************************************************************************--  
-- Process all the Test requirements.  
--*******************************************************************************************************************--  
-------------------------------------------------------------------------------  
-- Collect all the Test records for the reporting period.  
-------------------------------------------------------------------------------  
  
INSERT #Tests (TestId, VarId, PLId, Value, StartTime)  
 SELECT Test_Id, t.Var_Id, pl.PLId, Convert(Float, Result), Result_On  
  FROM dbo.Tests t WITH(NOLOCK)  
   JOIN dbo.Variables v  WITH(NOLOCK) ON t.Var_Id = v.Var_Id  
   JOIN @ProdUnits pu ON v.PU_Id = pu.PUId  
   JOIN @ProdLines pl ON pu.PLId = pl.PLId  
  WHERE t.Var_Id IN (pl.VarGoodUnitsId, pl.VarTotalUnitsId)    
  AND Result_On > @StartTime  
  AND Result_On <= @EndTime  
  
  
update #tests set  
 Endtime =   
 coalesce((  
 select min(t2.StartTime)  
 from #tests t2  
 where t2.StartTime > #tests.StartTime  
 and t2.varid = #tests.varid  
 and t2.StartTime < @Now  
 ),@Now)  
  
  
-------------------------------------------------------------------------------------  
-- Collect all the Test records for the reporting period for Pack production units.  
-------------------------------------------------------------------------------------  
  
 INSERT #TestsPack (TestId, VarId, PLId, PUId, Value, StartTime)  
  SELECT Test_Id, t.Var_Id, pl.PLId, pu.PUId, Convert(Float, Result), Result_On  
   FROM dbo.Tests t WITH(NOLOCK)  
    JOIN dbo.Variables v  WITH(NOLOCK) ON t.Var_Id = v.Var_Id  
    JOIN @ProdUnits pu ON v.PU_Id = pu.PUId  
    JOIN @ProdLines pl ON pu.PLId = pl.PLId  
   WHERE t.Var_Id = pu.VarGoodUnitsId  
   AND Result_On > @StartTime  
   AND Result_On <= @EndTime  
   and  pu.PackOrLine = 'Pack'  
   --AND  VarGoodUnitsId IS NOT NULL  
  
  
update #testspack set  
 Endtime =   
 coalesce((  
 select min(t2.StartTime)  
 from #testspack t2  
 where t2.StartTime > #testspack.StartTime  
 and t2.varid = #testspack.varid  
 and t2.StartTime < @Now  
 ),@Now)  
  
  
-------------------------------------------------------------------------------  
-- Update the @RunsPackUnit table with Good Units.  
-------------------------------------------------------------------------------  
  
 UPDATE rpu SET   
  GoodUnits =  (  
    SELECT  SUM(CONVERT(INTEGER, Value))   
    FROM #TestsPack tp  
    WHERE  tp.PUId = rpu.PUId   
    AND tp.StartTime > rpu.StartTime  
    AND tp.StartTime <= rpu.EndTime  
    )  
 from @RunsPackUnit rpu  
  
  
-------------------------------------------------------------------------------  
-- Now summarize the results into the @ProdRecords table for each Line/Shift.  
-------------------------------------------------------------------------------  
  
DECLARE ProdRLinesCursor INSENSITIVE CURSOR FOR  
 (SELECT rl.PLId, ProdId, StartTime, EndTime  
  FROM @RunsLine rl  
  JOIN @ProdLines pl ON rl.PLId = pl.PLId  
  WHERE PackOrLine = 'Line')  
 FOR READ ONLY  
OPEN ProdRLinesCursor  
FETCH NEXT FROM ProdRLinesCursor INTO @@PLId, @@ProdId, @@StartTime, @@EndTime  
WHILE @@Fetch_Status = 0  
BEGIN  
  
 SELECT @GoodUnits = NULL  
  
 SELECT @ProdCode = Prod_Code  
  FROM Products  
  WHERE Prod_Id = @@ProdId  
  
 SELECT @Runtime = (CONVERT(Float,DATEDIFF(ss,@@StartTime, @@EndTime))) / 60 --convert runtime to minutes.  
  
 SELECT @TotalUnits = (SELECT Sum(Coalesce(Value, 0))  
    FROM #Tests t  
     LEFT JOIN @ProdLines pl ON t.PLId = pl.PLId  
    Where VarId = VarTotalUnitsId AND t.PLId = @@PLId  
     AND t.StartTime > @@StartTime AND t.StartTime <= @@EndTime)  
 SELECT @GoodUnits = (SELECT Sum(Coalesce(Value, 0))  
    FROM #Tests t  
     JOIN @ProdLines pl ON t.PLId = pl.PLId  
    Where VarId = VarGoodUnitsId AND t.PLId = @@PLId  
     AND t.StartTime > @@StartTime AND t.StartTime <= @@EndTime)  
  
 INSERT @ProdRecords (PLId, ProductId, StartTime, EndTime,    
     Runtime, TotalUnits, GoodUnits)  
   SELECT @@PLId, @@ProdId, @@StartTime, @@EndTime,   
    @Runtime, @TotalUnits, @GoodUnits  
  
 FETCH NEXT FROM ProdRLinesCursor INTO @@PLId, @@ProdId, @@StartTime, @@EndTime  
END  
CLOSE  ProdRLinesCursor  
DEALLOCATE ProdRLinesCursor  
  
ReturnResultSets:  
  
 ----------------------------------------------------------------------------------------------------  
 -- Error Messages.  
 ----------------------------------------------------------------------------------------------------  
  
 -- if there are errors from the parameter validation, then return them and skip the rest of the results  
  
 if (select count(*) from @ErrorMessages) > 0  
  
 begin  
  
  SELECT ErrMsg  
  FROM @ErrorMessages  
  
 end  
  
 else  
  
 begin  
  
  
 -------------------------------------------------------------------------------  
 -- Error Messages.  
 -------------------------------------------------------------------------------  
 SELECT ErrMsg  
  FROM @ErrorMessages  
  
 -------------------------------------------------------------------------------  
 -- Result Set for data by Converting Line and Product.  
 -------------------------------------------------------------------------------  
 insert #ConvertingLine  
 SELECT  pl.PL_Desc [Line],  
    p.Prod_Code [Product],  
    p.Prod_Desc [Product Desc],  
    pr.StartTime [Start time],  
    pr.EndTime [End Time],  
    pr.Runtime [Runtime],   
    pr.TotalUnits [Total Units],  
    pr.GoodUnits [Good Units],  
    pr.TotalUnits - pr.GoodUnits [Reject Units],  
     case  
     when pr.TotalUnits > 0  
     then convert(float,(pr.TotalUnits - coalesce(pr.GoodUnits,0))) / convert(float,pr.TotalUnits)  
     else 0.0  
     end [Unit Broke %]  
 FROM  @ProdRecords pr  
 LEFT  JOIN dbo.Prod_Lines pl  WITH(NOLOCK) ON pr.PLId = pl.PL_Id  
 LEFT JOIN dbo.Products p  WITH(NOLOCK) ON pr.ProductId = p.Prod_Id  
 ORDER  BY pl.PL_Desc, pr.StartTime ASC, p.Prod_Code  
  
 select @SQL =   
 case  
 when (select count(*) from #ConvertingLine) > 65000 then   
 'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
 when (select count(*) from #ConvertingLine) = 0 then   
 'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
 else GBDB.dbo.fnLocal_RptTableTranslation('#ConvertingLine', @LanguageId)  
 end  
  
 Exec (@SQL)   
  
 -------------------------------------------------------------------------------  
 -- Result Set for data by Packing Line/Production Unit and Product.  
 -------------------------------------------------------------------------------  
 insert #PackingLine  
 SELECT  PL_Desc [Line],  
    PU_Desc [Prod Unit],  
    Prod_Code [Product Code],   
    Prod_Desc [Product Desc],  
    rpu.StartTime [Start Time],  
    rpu.EndTime [End Time],  
    SUM((CONVERT(Float,DATEDIFF(ss,rpu.StartTime, rpu.EndTime))) / 60.0) [Runtime],  
    SUM(GoodUnits) [Good Units]  
 FROM  @RunsPackUnit rpu  
 LEFT JOIN dbo.Prod_Units pu  WITH(NOLOCK) ON rpu.PUId = pu.PU_Id  
 LEFT JOIN dbo.Prod_Lines pl  WITH(NOLOCK) ON rpu.PLId = pl.PL_Id  
 LEFT JOIN dbo.Products p  WITH(NOLOCK) ON rpu.ProdId = p.Prod_Id  
 GROUP BY PL_Desc, PU_Desc, Prod_Code, Prod_Desc, StartTime, EndTime  
 ORDER BY PL_Desc, PU_Desc, rpu.StartTime ASC  
  
 select @SQL =   
 case  
 when (select count(*) from #PackingLine) > 65000 then   
 'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
 when (select count(*) from #PackingLine) = 0 then   
 'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
 else GBDB.dbo.fnLocal_RptTableTranslation('#PackingLine', @LanguageId)  
 end  
  
 Exec (@SQL)   
  
 end  
  
  
drop table #tests  
drop table #testspack  
drop table #ConvertingLine  
drop table #PackingLine  
  
