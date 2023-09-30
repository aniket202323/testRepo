 --------------------------------------------------------------------------------------------------------------------------------------------------------  
--  
-- Version 5.7 2004-APR-20 Langdon Davis  
--  
-- This SP will gather data for the specified date/time range for a program to display Line Status  
-- data for Proficy Client computers.  The data provided is:  
-- 2.  Stops data by line.    
-- 3.  Production data by line.    
--  
-- 2003-04-18 Vince King  
--  - Modified the code that sets the Rate Loss stops and effective downtime.  
--  
-- 2003-05-18 Vince King  
--  - Modified for the standard ELP Percent calculation.  
--  - Removed @SchedChangeOverId from the stored procedure, not used.  
--  
-- 2003-07-25 Vince King  
--  - Modified to exclude certain downtimes from the calcs.  Made changes to get ALL data and calcs  
--    in line with DDS/Stops.  
--  - Had to add the parameter @SchedHolidayCurtailId.  
--  
-- 2003-07-25  Vince King  
--  - Added new columns, Operations Ideal Stat Cases and Operations Efficiency.  
--  
-- 2003-08-26  Langdon Davis  
--  - Added NULL to the condition where OperationsRuntime is calculated.   
--  
-- 2003-09-15 Langdon Davis  
--  - Revised substantially to align logic, calculations and to some degree formatting, with the  
--  - noted in the Cvtg DDS-Stops comments for 2003-09-05,07 and 2003-09-13,14.  Some of these   
--  - changes are commented; many are not for the sake of brevity.  
--  
-- 2003-09-21,22 Langdon Davis  
--  - Modified Total and Good Units to pull in ACP numbers for Hanky production [similar to  
--    what was already being done for Puffs].  In the process, made generic the ACP variable   
--    names that had been Puffs PP07 specific.  
--  - Sync'd up sp version number with that of the template.  
--  - Modified logic to insure that Total Units var_id's are only identified for   
--    LINES.  This fixed an error with duplicate primary key on insertion into   
--                the #tests table that was coming from the having a var_id for both the line and  
--    pack pl_id's.  
--  - Added COALESCE statements to force CVPR, Operations Efficiency and AVG Stat CLD to 0 when NULL.  
--  - Added the calculation for MTBF to the results set.  It was AWOL.  
--  
-- 2003-09-26 Langdon Davis  
--  - Modified the descriptions for the German translations of VarGoodUnitsVN and   
--    VarTotalUnitsVN to refer to the Gesamt Kartons Lift [conveyor to the Whse]  
--           count instead of the Gesamt Kartons Focke [ACP count] variable.  
--  
-- 2003-10-20 Matthew Wells  
--  - Changed nvarchar to varchar b/c string comparison can be more expensive and MSI changed   
--    their recommendation  
--  - Streamlined data collection  
--  
-- 2003-10-20 Langdon Davis  
--  - Changed from 'Gesamt Kartons Lift' as the variable for both Good Units and  
--    Total Units, to the Total Units being the 'Soll Produktion' value [Total   
--    Sheets] off of the line.  Good Units remained the case count from the   
--    conveyor to the Whse, but was renamed from 'Gesamt Kartons Lift' to the   
--    generic 'Ist Produktion' [necessary to also pick up the Good Units from   
--    the Hand Pack operations].  
--  - Added code to convert the Good Units from the Whse conveyor from cases to  
--    sheets so that its UOM is consistent with that of the new Total Units.  
--  - Added code to bring in the counts from the Hand Pack Bundles and Hand  
--    Pack Cases master units, convert them to sheets, and add them to the   
--    Good Units [sheets] from the Whse conveyor value to get an overall  
--    Good Units production value.  
--  NOTE: The three changes noted above impact Neuss Hanky production only.  
--  - Moved the 'CONVERT' on various spec items from the calculations, to the   
--    initial SELECT [for consistency].  
--  
--2003-12-08 Langdon Davis  
--  - Modified declaration of @RollsInPack, @PacksInBundle, @SheetCount and  
--    @RollsPerLog from Integer, to Float to address problem with 0 values in   
--    the production results set.  
  
-- 2004-APR-20 Langdon Davis Rev5.7  
--  - Commented out the Spanish and French "translations" on Good Units and Total Units since they were  
--    just placeholders versus real values.  
--  - Added local language-based CASE statements to variable name assignments for 'Effective Downtime',  
--    and 'PM Roll Width' to accomodate Apizaco's use of Spanish descriptions on these variables.  
--------------------------------------------------------------------------------------------------------------------------------------------------------  
CREATE  PROCEDURE dbo.spLocal_ViewCvtgDDS  
 @StartTime   DateTime,  -- Beginning period for the data.  
 @EndTime   DateTime,  -- Ending period for the data.  
 @ProdLineList   VarChar(4000),  -- Collection of Prod_Lines.PL_Id for converting lines delimited by "|".  
 @DelayTypeList   VarChar(4000),  -- Collection of "DelayType=..." from Prod_Units.Extended_Info delimited by "|".  
 @ScheduleStr   VarChar(50),  -- Prefix from Event_Reason_Categories.ERC_Desc (portion prior to ":").  
 @CategoryStr   VarChar(50),  -- Prefix from Event_Reason_Categories.ERC_Desc (portion prior to ":").  
 @GroupCauseStr   VarChar(50),  -- Prefix from Event_Reason_Categories.ERC_Desc (portion prior to ":").  
 @SubSystemStr   VarChar(50),  -- Prefix from Event_Reason_Categories.ERC_Desc (portion prior to ":").  
 @CatMechEquipId   Int,   -- Event_Reason_Categories.ERC_Id for Category:Mechanical Equipment.  
 @CatElectEquipId  Int,   -- Event_Reason_Categories.ERC_Id for Category:Electrical Equipment.  
 @CatProcFailId   Int,   -- Event_Reason_Categories.ERC_Id for Category:Process/Operational.  
 @CatBlockStarvedId  Int,   -- Event_Reason_Categories.ERC_Id for Category:Blocked/Starved.  
 @CatELPId   Int,   -- Event_Reason_Categories.ERC_Id for Category:Paper (ELP).  
 @SchedPRPolyId   Int,   -- Event_Reason_Categories.ERC_Id for Schedule:PR/Poly Change.  
 @SchedUnscheduledId  Int,   -- Event_Reason_Categories.ERC_Id for Schedule:Unscheduled.  
 @SchedSpecialCausesId  Int,   -- Event_Reason_Categories.ERC_Id for Schedule:Special Causes.  
 @SchedEOProjectsId  Int,   -- Event_Reason_Categories.ERC_Id for Schedule:E.O./Projects.  
 @SchedBlockedStarvedId  Int,   -- Event_Reason_Categories.ERC_Id for Schedule:Blocked/Starved.  
  
  
 @SchedHolidayCurtailId  Int,   -- Event_Reason_Categories.ERC_Id for Schedule:Holiday/Curtail.  
  
  
 @DelayTypeRateLossStr  VarChar(100),  -- Prod_Units.Extended_Info string for the RateLoss Delay Type.  
 @PropCvtgProdFactorId  Int,   -- Product_Properties.Prop_Id for Property containing Stat Factor  
 @DefaultPMRollWidth  Float,    -- Default PM Roll Width.  Used when actual PM Roll  
         -- Width's are not available through genealogy.  
 @ConvertFtToMM   Float,   -- Conversion to change feet to mm/min., i.e. value is 304.8   
         -- (12 in/ft * 2.54 cm/in * 10 mm/cm) 1 is already using metric.  
 @ConvertInchesToMM  Float,   -- Conversion to change inches to millimeters. Value is 25.4 to  
         -- to convert or 1 if already using metric.  
 @BusinessType   Integer   -- 1=Tissue/Towel, 2=Napkins, 3=Facial  
  
AS  
  
-------------------------------------------------------------------------------  
-- Assign Report Parameters for SP testing locally.  
-------------------------------------------------------------------------------  
/*  
--Neuss  
Select  @StartTime = '2003-09-16 07:30:00'  
Select  @EndTime = '2003-09-16 19:30:00'  
Select @ProdLineList = '2|4'  
Select @DelayTypeList = 'CvtrDowntime|Downtime|RateLoss'  
Select @ScheduleStr = 'Schedule'  
Select @CategoryStr = 'Category'  
Select @GroupCauseStr = 'GroupCause'  
Select @SubSystemStr = 'Subsystem'  
Select @CatMechEquipId = 112  
Select @CatElectEquipId = 111  
Select @CatProcFailId = 102  
Select @CatBlockStarvedId = 133  
Select  @CatELPId = 115  
Select @SchedPRPolyId = 117  
Select  @SchedUnscheduledId = 109  
Select  @SchedSpecialCausesId = 103  
Select @SchedEOProjectsId = 144  
Select @SchedBlockedStarvedId = 119  
Select @SchedHolidayCurtailId = 149  
Select @DelayTypeRateLossStr = 'RateLoss'  
Select  @PropCvtgProdFactorId = 3  
Select  @DefaultPMRollWidth = 840  
Select  @ConvertFtToMM = 1  
Select @ConvertInchesToMM = 1  
Select  @BusinessType = 4  
*/  
  
SET ANSI_WARNINGS OFF  
  
-------------------------------------------------------------------------------  
-- Create temporary Error Messages and ResultSet tables.  
-------------------------------------------------------------------------------  
CREATE TABLE #ErrorMessages (  
 ErrMsg    varchar(255) )  
  
CREATE TABLE #Runs (  
 StartId    int PRIMARY KEY,  
 PUId    int,  
 ProdId    int,  
 StartTime   datetime,  
 EndTime    datetime )  
CREATE INDEX tc_StartId_StartTime  
 ON #Runs (StartId, StartTime)  
CREATE INDEX tc_StartId_EndTime  
 ON #Runs (StartId, EndTime)  
  
CREATE TABLE #Delays (  
 TEDetId    int PRIMARY KEY NONCLUSTERED,  
 PrimaryId   int,  
 SecondaryId   int,  
 PUId    int,  
 StartTime   datetime,  
 EndTime    datetime,  
 LocationId   int,  
 L1ReasonId   int,  
 L2ReasonId   int,  
 L3ReasonId   int,  
 L4ReasonId   int,  
 TEFaultId   int,  
 L1TreeNodeId   int,  
 L2TreeNodeId   int,  
 L3TreeNodeId   int,  
 L4TreeNodeId   int,  
 ProdId    int,  
 LineStatus   varchar(50),  
 Shift    varchar(10),  
 Crew    varchar(10),  
 ScheduleId   int,  
 CategoryId   int,  
 GroupCauseId   int,  
 SubSystemId   int,  
 DownTime   int,  
 ReportDownTime   int,  
 UpTime    int,  
 ReportUpTime   int,  
 Stops    int,  
 StopsUnscheduled  int,  
 Stops2m    int,  
 StopsMinor   int,  
 StopsEquipFails   int,  
 StopsProcessFailures  int,  
 StopsELP   int,  
 ReportELPDowntime  int,  
 StopsBlockedStarved  int,  
 ReportELPSchedDT  int,  
 UpTime2m   int,  
 StopsRateLoss   int,  
 ReportRLDowntime  float,  
 ReportRLELPDowntime  float,  
 InRptWindow   int )  
  
CREATE CLUSTERED INDEX td_PUId_StartTime ON #Delays (PUId, StartTime)  
--CREATE INDEX td_PUId_EndTime  
-- ON #Delays (PUId, EndTime)  
  
CREATE TABLE #ProdUnits (  
 PUId    int PRIMARY KEY,  
 PLId    int,  
 ExtendedInfo   varchar(255),  
 DelayType   varchar(100),  
 ScheduleUnit   int,  
 LineStatusUnit   int )  
  
CREATE TABLE #ProdLines (  
 PLId    int PRIMARY KEY,  
 VarGoodUnitsId   int,  
 VarTotalUnitsId   int,  
 VarPMRollWidthId  int,  
 PropLineProdFactorId  int,  
 VarEffDowntimeId  int,  
 TotalStops   int,  
 TotalUptime   int,  
 TotalDowntime   int,  
 TotalStopsUTGT2Min  int,  
 VarGoodUnitsACPOneId  int,  
 VarGoodUnitsACPTwoId  Int,  
 VarGoodUnitsHPBundlesId  Int,   
 VarGoodUnitsHPCasesId  Int,   
 PackOrLine   VarChar(100) )  
  
CREATE TABLE #DelayTypes (  
 DelayTypeDesc   varchar(100) PRIMARY KEY)  
  
CREATE TABLE #RunsLine (  
 PLId    int,  
 ProdId    int,  
 StartTime   datetime,  
 EndTime    datetime,  
 TotalUnits   int,  
 GoodUnits   int,  
 WebWidth   float,  
 SheetWidth   float,  
 LineSpeed   float,  
 RollsPerLog   int,  
 RollsInPack   int,  
 PacksInBundle   int,  
 SheetCount   int,  
 Runtime    float,  
 SheetLength   float,  
 StatFactor   float,  
 IdealUnits   int,  
 ActualUnits   Int )  
  
CREATE INDEX rl_PLId  
 ON #RunsLine (PLId)  
  
CREATE TABLE #Primaries (  
 TEDetId    int PRIMARY KEY,  
 PUId    int,  
 StartTime   datetime,  
 EndTime    datetime,  
 LastEndTime   datetime,  
 UpTime    int,  
 ReportUpTime   int,  
 TEPrimaryId   int IDENTITY)  
  
CREATE INDEX pr_TEPrimaryId ON #Primaries (TEPrimaryId)  
  
CREATE TABLE #Tests (  
 TestId   int PRIMARY KEY IDENTITY,  
 VarId   int,  
 PLId   int,  
 Value   float,  
 StartTime  datetime,  
 EndTime   datetime )  
CREATE INDEX tt_VarId_StartTime  
 ON #Tests (VarId, StartTime)  
--CREATE INDEX tt_VarId_EndTime  
-- ON #Tests (VarId, EndTime)  
  
CREATE TABLE #ProdRecordsShift (  
 PLId    int,  
 Shift    varchar(50),  
 Team    varchar(50),  
 ProductId   int,  
 Shift_StartTime   datetime,  
 Shift_EndTime   datetime,  
 TotalUnits   int,  
 GoodUnits   int,  
 RejectUnits   int,  
 WebWidth   float,  
 SheetWidth   float,  
 LineSpeed   float,  
 RollsPerLog   int,  
 RollsInPack   int,  
 PacksInBundle   int,  
 CartonsInCase   int,  
 SheetCount   Int,  
 ShipUnit   Int,  
 CalendarRuntime   float,  
 ProductionRuntime  float,  
 OperationsRuntime  float,  
 SheetLength   float,  
 StatFactor   float,  
 IdealUnits   int,  
 ActualUnits   int,  
 OperationsIdealUnits  int,  
 HolidayCurtailDT  Int )  
  
CREATE INDEX pr_PLId  
 ON #ProdRecordsShift (PLId)  
  
-------------------------------------------------------------------------------  
-- Declare program variables.  
-------------------------------------------------------------------------------  
DECLARE @SearchString   VarChar(4000),  
 @Position   Int,  
 @PartialString   VarChar(4000),  
 @Now    DateTime,  
 @@Id    Int,  
 @@ExtendedInfo   VarChar(255),  
 @PUDelayTypeStr   VarChar(100),  
 @PUScheduleUnitStr  VarChar(100),  
 @PULineStatusUnitStr  VarChar(100),  
 @@PUId    Int,  
 @@TimeStamp   DateTime,  
 @@LastEndTime   DateTime,  
 @VarGoodUnitsId   Int,  
 @VarGoodUnitsVN   VarChar(100),  
 @VarTotalUnitsId  Int,  
 @VarTotalUnitsVN  VarChar(100),  
 @VarPMRollWidthId  Int,  
 @VarPMRollWidthVN  VarChar(100),  
 @@PLId    Int,  
 @@VarGoodUnitsId  Int,  
 @@VarTotalUnitsId  Int,  
 @@VarPMRollWidthId  Int,  
 @@VarEffDowntimeId  Int,  
 @@ProdId   Int,  
 @@StartTime   datetime,  
 @@EndTime   datetime,  
 @@Shift    VarChar(50),  
 @@Team    VarChar(50),  
 @ProdCode   VarChar(100),  
 @CharId    Int,  
 @StatFactor   Float,  
 @RollsInPack   Float,  --FLD 12-08-2003  
 @PacksInBundle   Float,  --FLD 12-08-2003  
 @SheetCount   Float,  --FLD 12-08-2003  
 @SheetWidth   Float,  
 @SheetLength   Float,  
 @LineSpeedTarget  Float,  
 @CartonsInCase   Float,  
 @StatFactorSpecDesc  VarChar(100),  
 @RollsInPackSpecDesc  VarChar(100),  
 @PacksInBundleSpecDesc  VarChar(100),  
 @SheetCountSpecDesc  VarChar(100),  
 @SheetWidthSpecDesc  VarChar(100),  
 @SheetLengthSpecDesc  VarChar(100),  
 @LineSpeedTargetSpecDesc VarChar(100),  
 @LineSpeedTargetSpecId  int,  
 @CartonsInCaseSpecDesc  VarChar(100),  
 @CalendarRuntime  Float,  
 @ProductionRuntime  Float,  
 @OperationsRuntime  Float,  
 @TotalUnits    Int,  
 @GoodUnits   Int,  
 @RejectUnits   Int,  
 @RollWidth   Float,  
 @LineProdFactorDesc  VarChar(50),  
 @PropLineProdFactorId  Int,  
 @PLDesc    VarChar(100),  
 @IdealUnits   Float,  
 @ActualUnits   Float,  
 @OperationsIdealUnits  Integer,  
 @RollsPerLog   Float,  --FLD 12-08-2003  
 @CLD    Float,  
 @PropLineSpeedTargetId   Int,  
 @LinePropCharId   Int,  
 @DelayTypeDesc   VarChar(100),  
 @VarEffDowntimeId  Int,  
 @VarEffDowntimeVN  VarChar(100),  
 @VarGoodUnitsACPOneId  Int,  
 @VarGoodUnitsACPTwoId  Int,  
 @VarGoodUnitsHPBundlesId Int,  
 @VarGoodUnitsHPCasesId  Int,  
 @@VarGoodUnitsACPTwoId  Int,  
 @@VarGoodUnitsACPOneId  Int,  
 @@VarGoodUnitsHPBundlesId Int,  
 @@VarGoodUnitsHPCasesId  Int,  
 @@VarId    Int,  
 @@NextStartTime   datetime,  
 @PackOrLineStr   VarChar(100),  
 @PackOrLine   VarChar(100),  
 @HolidayCurtailDT  Float,  
 @ProdCvtgPUId   Integer,  
 @LocalLanguageDesc  VarChar(50),  
 @RangeStartTime   datetime,  
 @RangeEndTime   datetime,  
 @Max_TEDet_Id   int,  
 @Min_TEDet_Id   int,  
 @ShipUnit   Integer,  
 @ShipUnitSpecDesc  VarChar(100)   
   
SELECT  @LocalLanguageDesc = COALESCE((SELECT language_desc   
           FROM languages   
           WHERE language_id = (SELECT value  
              FROM site_parameters sp  
                                                        JOIN parameters p ON p.parm_id = sp.parm_id    
                                                            WHERE p.parm_name = 'LanguageNumber'))  
          , 'US English')  
  
  
SELECT @Now     = GetDate(),  
 @PUDelayTypeStr   = 'DelayType=',  
 @PUScheduleUnitStr   = 'ScheduleUnit=',  
 @PULineStatusUnitStr   = 'LineStatusUnit=',  
 @PackOrLineStr    = 'PackOrLine=',  
 @VarGoodUnitsVN   = CASE @LocalLanguageDesc   
      WHEN 'US English' THEN 'Good Units'  
      WHEN 'German'    THEN 'Ist Produktion'  
             --WHEN 'Spanish'    THEN 'Spanish Good Units'  
      --WHEN 'French'   THEN 'French Good Units'  
      ELSE 'Good Units' END,  
 @VarTotalUnitsVN   = CASE @LocalLanguageDesc   
      WHEN 'US English' THEN 'Total Units'  
      WHEN 'German'     THEN 'Soll Produktion'  
             --WHEN 'Spanish'    THEN 'Spanish Total Units'  
      --WHEN 'French'   THEN 'French Total Units'  
      ELSE 'Total Units' END,  
 --@VarPMRollWidthVN = 'PM Roll Width',  
 @VarPMRollWidthVN = CASE @LocalLanguageDesc   
     WHEN 'US English' THEN 'PM Roll Width'  
     --WHEN 'German'     THEN 'German PM Roll Width'  
            WHEN 'Spanish'    THEN 'PM Ancho Oficial de Bobina'  
     --WHEN 'French'   THEN 'French PM Roll Width'  
     ELSE 'PM Roll Width' END,  
 --@VarEffDowntimeVN = 'Effective Downtime',  
 @VarEffDowntimeVN = CASE @LocalLanguageDesc   
     WHEN 'US English' THEN 'Effective Downtime'  
     --WHEN 'German'     THEN 'German Effective Downtime'  
            WHEN 'Spanish'    THEN 'Tiempo de Paro Efectivo'  
     --WHEN 'French'   THEN 'French Effective Downtime'  
     ELSE 'Effective Downtime' END,  
 @StatFactorSpecDesc   = 'Stat Factor',  
 @PacksInBundleSpecDesc   = 'Packs In Bundle', --For NA T/T, is FP Items per Ship unit.  For Neuss  
 @SheetCountSpecDesc   = 'Sheet Count',  
 @SheetWidthSpecDesc   = 'Sheet Width',  
 @SheetLengthSpecDesc   = 'Sheet Length',  
 @LineProdFactorDesc   = 'Production Factors',  
 @LineSpeedTargetSpecDesc  = 'Line Speed Target',  
 @CartonsInCaseSpecDesc   = CASE @BusinessType  
      WHEN 4 THEN 'Bundles In Case' --Hankies, is literally what it says.  
      ELSE 'Cartons In Bundle' END,   
 @RollsInPackSpecDesc   = CASE @BusinessType  
      WHEN 1 THEN 'Rolls In Pack'  
      WHEN 2 THEN 'Packs In Pack' -- Changed description here.  
      WHEN 3 THEN 'Rolls In Pack'  
      ELSE 'Rolls In Pack' END,  
 @ShipUnitSpecDesc   = 'Ship Unit'  
  
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
  BEGIN  
  SELECT @PartialString  = RTrim(@SearchString),  
   @SearchString  = ''  
  END  
 ELSE  
  BEGIN  
  SELECT @PartialString  = RTrim(SubString(@SearchString, 1, @Position - 1)),  
   @SearchString  = LTrim(RTrim(Substring(@SearchString, (@Position + 1), Len(@SearchString))))  
  END   
  
 IF Len(@PartialString) > 0  
  BEGIN  
  IF IsNumeric(@PartialString) <> 1  
   BEGIN  
   INSERT #ErrorMessages (ErrMsg)  
   VALUES ('Parameter @ProdLineList contains non-numeric = ' + @PartialString)  
   GOTO ReturnResultSets  
   END  
  
  IF (SELECT Count(PLId) FROM #ProdLines WHERE PLId = Convert(Int, @PartialString)) = 0  
   BEGIN  
   SELECT  @VarGoodUnitsId   = NULL,  
    @VarTotalUnitsId   = NULL,  
    @VarPMRollWidthId   = NULL,  
    @PropLineProdFactorId   = NULL,  
    @VarEffDowntimeId   = NULL,  
    @VarGoodUnitsACPOneId   = NULL,  
    @VarGoodUnitsACPTwoId   = NULL,  
    @VarGoodUnitsHPBundlesId  = NULL,  
    @VarGoodUnitsHPCasesId   = NULL,  
    @PackOrLine = NULL      
  
   SELECT  @PLDesc  = PL_Desc,  
    @@ExtendedInfo = Extended_Info  
   FROM Prod_Lines  
   WHERE PL_Id = convert(int, @PartialString)  
  
   SELECT @Position = CharIndex(@PackOrLineStr, @@ExtendedInfo)  
   IF @Position > 0  
    BEGIN  
    SELECT @PackOrLine = LTrim(SubString(@@ExtendedInfo, @Position + Len(@PackOrLineStr), Len(@@ExtendedInfo)))  
    SELECT @Position = CharIndex(';', @PackOrLine)  
    IF @Position > 0  
     BEGIN  
     SELECT @PackOrLine = RTrim(SubString(@PackOrLine, 1, @Position - 1))  
     END  
    SELECT  @PackOrLine = @PackOrLine  
    END  
      
       SELECT @VarGoodUnitsId = v.Var_Id  
       FROM    Variables v  
        JOIN Prod_Units pu ON v.PU_Id = pu.PU_Id  
        JOIN Prod_Lines pl ON pu.PL_Id = pl.PL_Id  
       WHERE   v.Var_Desc = @VarGoodUnitsVN  
        AND v.Data_Type_Id IN (1,2)  
        AND pl.PL_Id = Convert(Int,@PartialString)  
        AND @PackOrLine = 'Line'      
  
       SELECT @VarGoodUnitsACPOneId = v.Var_Id  
       FROM    Variables v  
        JOIN Prod_Units pu ON v.PU_Id = pu.PU_Id  
        JOIN Prod_Lines pl ON pu.PL_Id = pl.PL_Id  
       WHERE   (v.Var_Desc = @VarGoodUnitsVN)  
        AND (v.Data_Type_Id IN (1,2))  
        AND pu.PU_Desc =(CASE WHEN @BusinessType = 3  
         THEN (LTRIM(RTRIM(REPLACE(@PLDesc,'PP ',''))) +   
        ' East Casepacker Production')  
         WHEN @BusinessType = 4  
         THEN (LTRIM(RTRIM(REPLACE(@PLDesc,'TT ',''))) +  
               ' Lift Production')  
         ELSE (LTRIM(RTRIM(REPLACE(@PLDesc,'XX ',''))) +  
        ' Xxxxx Production')  
         END)        
      
       SELECT @VarGoodUnitsACPTwoId = v.Var_Id  
       FROM    Variables v  
        JOIN Prod_Units pu ON v.PU_Id = pu.PU_Id  
        JOIN Prod_Lines pl ON pu.PL_Id = pl.PL_Id  
       WHERE   (v.Var_Desc = @VarGoodUnitsVN)  
         AND (v.Data_Type_Id IN (1,2))  
         AND pu.PU_Desc = (CASE WHEN @BusinessType = 3  
           THEN (LTRIM(RTRIM(REPLACE(@PLDesc,'PP ',''))) +  
          ' West Casepacker Production')  
           ELSE (LTRIM(RTRIM(REPLACE(@PLDesc,'XX ',''))) +  
          ' Xxxxx Production')  
           END)  
  
       SELECT @VarGoodUnitsHPBundlesId = v.Var_Id  
       FROM    Variables v  
        JOIN Prod_Units pu ON v.PU_Id = pu.PU_Id  
        JOIN Prod_Lines pl ON pu.PL_Id = pl.PL_Id  
       WHERE   (v.Var_Desc = @VarGoodUnitsVN)  
        AND (v.Data_Type_Id IN (1,2))  
        AND pu.PU_Desc = (CASE WHEN @BusinessType = 4  
                 THEN (LTRIM(RTRIM(REPLACE(@PLDesc,'TT ',''))) +  
         ' Hand Pack Bundles Production')  
          ELSE (LTRIM(RTRIM(REPLACE(@PLDesc,'XX ',''))) +  
         ' Xxxxx Production')  
          END)  
  
       SELECT @VarGoodUnitsHPCasesId = v.Var_Id  
       FROM    Variables v  
        JOIN Prod_Units pu ON v.PU_Id = pu.PU_Id  
        JOIN Prod_Lines pl ON pu.PL_Id = pl.PL_Id  
       WHERE   (v.Var_Desc = @VarGoodUnitsVN)  
        AND (v.Data_Type_Id IN (1,2))  
        AND pu.PU_Desc = (CASE WHEN @BusinessType = 4  
          THEN (LTRIM(RTRIM(REPLACE(@PLDesc,'TT ',''))) +  
         ' Hand Pack Cases Production')  
          ELSE (LTRIM(RTRIM(REPLACE(@PLDesc,'XX ',''))) +  
                ' Xxxxx Production')  
          END)         
  
       SELECT @VarTotalUnitsId = v.Var_Id  
       FROM    Variables v  
        JOIN Prod_Units pu ON v.PU_Id = pu.PU_Id  
        JOIN Prod_Lines pl ON pu.PL_Id = pl.PL_Id  
       WHERE   (v.Var_Desc = @VarTotalUnitsVN)  
        AND (v.Data_Type_Id IN (1,2))  
        AND (pl.PL_Id = Convert(Int,@PartialString))  
        AND (@PackOrLine = 'Line')    
  
       SELECT @VarPMRollWidthId = v.Var_Id  
       FROM    Variables v  
        JOIN Prod_Units pu ON v.PU_Id = pu.PU_Id  
        JOIN Prod_Lines pl ON pu.PL_Id = pl.PL_Id  
       WHERE   (v.Var_Desc = @VarPMRollWidthVN)  
        AND (v.Data_Type_Id IN (1,2))  
        AND (pl.PL_Id = Convert(Int,@PartialString))  
  
       SELECT @VarEffDowntimeId = v.Var_Id  
       FROM    Variables v  
        JOIN Prod_Units pu ON v.PU_Id = pu.PU_Id  
        JOIN Prod_Lines pl ON pu.PL_Id = pl.PL_Id  
       WHERE   (v.Var_Desc = @VarEffDowntimeVN)  
        AND (v.Data_Type_Id IN (1,2))  
        AND (pl.PL_Id = Convert(Int,@PartialString))  
  
       IF @BusinessType = 3 --Facial Uses PP prefix, Puffs Packaging  
        BEGIN  
        SELECT @PropLineProdFactorId = Prop_Id  
        FROM Product_Properties  
        WHERE Prop_Desc = LTRIM(RTRIM(REPLACE(@PLDesc,'PP ',''))) + ' ' + @LineProdFactorDesc  
        END  
       ELSE  
        BEGIN  
        SELECT @PropLineProdFactorId = Prop_Id  
        FROM Product_Properties  
        WHERE Prop_Desc = LTRIM(RTRIM(REPLACE(@PLDesc,'TT ',''))) + ' ' + @LineProdFactorDesc  
        END  
  
       INSERT  #ProdLines ( PLId,   
      VarGoodUnitsId,   
      VarTotalUnitsId,   
      VarPMRollWidthId,   
      PropLineProdFactorId,   
      VarEffDowntimeId,  
      VarGoodUnitsACPTwoId,   
      VarGoodUnitsACPOneId,   
      VarGoodUnitsHPBundlesId,   
      VarGoodUnitsHPCasesId,  
      PackOrLine)   
      VALUES (  Convert(Int, @PartialString),   
     @VarGoodUnitsId,   
     @VarTotalUnitsId,  
     @VarPMRollWidthId,   
     @PropLineProdFactorId,  
     @VarEffDowntimeId,  
     @VarGoodUnitsACPTwoId,   
     @VarGoodUnitsACPOneId,   
     @VarGoodUnitsHPBundlesId,   
     @VarGoodUnitsHPCasesId,  
     @PackOrLine)  
   END    
  END  
 END  
  
IF (SELECT Count(PLId) FROM #ProdLines) = 0  
 INSERT #ProdLines (PLId)  
  SELECT PL_Id  
   FROM Prod_Lines  
  
-------------------------------------------------------------------------------  
-- DelayTypeList  
-------------------------------------------------------------------------------  
SELECT @SearchString = LTrim(RTrim(@DelayTypeList))  
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
  AND (SELECT Count(DelayTypeDesc) FROM #DelayTypes WHERE DelayTypeDesc = @PartialString) = 0  
  INSERT #DelayTypes (DelayTypeDesc)   
   VALUES (@PartialString)  
END  
  
-------------------------------------------------------------------------------  
-- ProdUnitList  
-------------------------------------------------------------------------------  
INSERT #ProdUnits ( PUId,   
   PLId,   
   ExtendedInfo)  
SELECT pu.PU_Id,   
 pu.PL_Id,   
 pu.Extended_Info  
FROM Prod_Units pu  
 JOIN #ProdLines tpl ON pu.PL_Id = tpl.PLId  
 JOIN Event_Configuration ec ON pu.PU_Id = ec.PU_Id  
WHERE pu.Master_Unit IS NULL  
 AND ec.ET_Id = 2  
  
DECLARE ProdUnitCursor INSENSITIVE CURSOR FOR  
 (SELECT PUId, ExtendedInfo  
  FROM #ProdUnits)  
 FOR READ ONLY  
OPEN ProdUnitCursor  
FETCH NEXT FROM ProdUnitCursor INTO @@Id, @@ExtendedInfo  
WHILE @@Fetch_Status = 0  
BEGIN  
 SELECT @Position = CharIndex(@PUDelayTypeStr, @@ExtendedInfo)  
 IF @Position > 0  
 BEGIN  
  SELECT @PartialString = LTrim(SubString(@@ExtendedInfo, @Position + Len(@PUDelayTypeStr), Len(@@ExtendedInfo)))  
  SELECT @Position = CharIndex(';', @PartialString)  
  IF @Position > 0  
   SELECT @PartialString = RTrim(SubString(@PartialString, 1, @Position - 1))  
  SELECT  @DelayTypeDesc = @PartialString  
  UPDATE #ProdUnits  
   SET DelayType = @PartialString  
   WHERE PUId = @@Id  
 END  
 SELECT @Position = CharIndex(@PUScheduleUnitStr, @@ExtendedInfo)  
 IF @Position > 0  
 BEGIN  
  SELECT @PartialString = LTrim(SubString(@@ExtendedInfo, @Position + Len(@PUScheduleUnitStr), Len(@@ExtendedInfo)))  
  SELECT @Position = CharIndex(';', @PartialString)  
  IF @Position > 0  
   SELECT @PartialString = RTrim(SubString(@PartialString, 1, @Position - 1))  
  UPDATE #ProdUnits  
   SET ScheduleUnit = @PartialString  
   WHERE PUId = @@Id  
 END  
 SELECT @Position = CharIndex(@PULineStatusUnitStr, @@ExtendedInfo)  
 IF @Position > 0  
 BEGIN  
  SELECT @PartialString = LTrim(SubString(@@ExtendedInfo, @Position + Len(@PULineStatusUnitStr), Len(@@ExtendedInfo)))  
  SELECT @Position = CharIndex(';', @PartialString)  
  IF @Position > 0  
   SELECT @PartialString = RTrim(SubString(@PartialString, 1, @Position - 1))  
  UPDATE #ProdUnits  
   SET LineStatusUnit = @PartialString  
   WHERE PUId = @@Id  
 END  
  
 -------------------------------------------------------------------------------  
 -- Collect all the Production Run records for the reporting period for each  
 -- production unit.  Only include units with the correct DelayType.  
 -------------------------------------------------------------------------------  
 IF (SELECT COUNT(DelayTypeDesc) FROM #DelayTypes WHERE DelayTypeDesc = @DelayTypeDesc) > 0  
  INSERT #Runs (StartId, PUId, ProdId, StartTime, EndTime)  
   SELECT Start_Id, PU_Id, ps.Prod_Id, Start_Time, Coalesce(End_Time, @Now)  
    FROM Production_Starts ps  
     LEFT JOIN Products p ON ps.Prod_Id = p.Prod_Id  
     --LEFT JOIN Prod_Units pu ON ps.PU_Id = pu.PU_Id   FLD  
    WHERE PU_Id = @@Id  
    AND Start_Time < @EndTime  
    AND (End_Time > @StartTime  
     OR End_Time IS NULL)  
    AND (Prod_Desc <> 'No Grade' AND Prod_Code IS NOT NULL)  
    --AND (PU_Desc LIKE '%Converter Reliability%')  FLD  
  
 FETCH NEXT FROM ProdUnitCursor INTO @@Id, @@ExtendedInfo  
END  
CLOSE ProdUnitCursor  
DEALLOCATE ProdUnitCursor  
  
-------------------------------------------------------------------------------  
-- Filter the Production Unit list to only include the passed Delay Type list   
-- for the #ProdUnits and #Runs tables.  
-------------------------------------------------------------------------------  
  
IF (SELECT Count(DelayTypeDesc) FROM #DelayTypes) > 0  
  DELETE FROM #ProdUnits  
   WHERE DelayType NOT IN (SELECT DelayTypeDesc  
        FROM #DelayTypes)  
-------------------------------------------------------------------------------  
-- Collect all the Production Run records for the reporting period for each  
-- production line.  
-------------------------------------------------------------------------------  
INSERT #RunsLine (PLId, ProdId, StartTime, EndTime)  
 SELECT pl.PL_Id, ProdId,   
  (CASE WHEN StartTime < @StartTime THEN @StartTime ELSE StartTime END),  
  (CASE WHEN EndTime > @EndTime THEN @EndTime ELSE EndTime END)  
  FROM #Runs  
   JOIN Prod_Units pu ON #Runs.PUId = pu.PU_Id  
   JOIN Prod_Lines pl ON pu.PL_Id = pl.PL_Id  
  GROUP BY pl.PL_Id, ProdId, (CASE WHEN StartTime < @StartTime THEN @StartTime ELSE StartTime END),  
        (CASE WHEN EndTime > @EndTime THEN @EndTime ELSE EndTime END)  
  
-------------------------------------------------------------------------------  
-- Collect dataset filtered by report period and Production Units.  
-------------------------------------------------------------------------------  
INSERT INTO #Delays ( TEDetId,   
   PUId,   
   StartTime,   
   EndTime,   
   LocationId,  
   L1ReasonId,   
   L2ReasonId,   
   L3ReasonId,   
   L4ReasonId,   
   TEFaultId,  
   DownTime,  
   ReportDownTime,  
   InRptWindow)  
  
SELECT ted.TEDet_Id,   
 ted.PU_Id,   
 ted.Start_Time,   
 Coalesce(ted.End_Time, @Now),   
 ted.Source_PU_Id,  
 ted.Reason_Level1,   
 ted.Reason_Level2,   
 ted.Reason_Level3,   
 ted.Reason_Level4,   
 ted.TEFault_Id,  
 DateDiff(Second, ted.Start_Time, Coalesce(ted.End_Time, @Now)),  
 Coalesce(DATEDIFF(s,  (CASE WHEN ted.Start_Time <= @StartTime   
          THEN @StartTime   
          ELSE ted.Start_Time   
          END),   
    (CASE WHEN Coalesce(ted.End_Time, @Now) >= @EndTime   
          THEN @EndTime   
          ELSE Coalesce(ted.End_Time, @Now)   
          END)), 0.0),    
 CASE WHEN (   --Events that started outside the report window but ended within it.  
          (ted.Start_Time < @StartTime AND (Coalesce(ted.End_Time, @Now) >= @StartTime AND Coalesce(ted.End_Time, @Now) <= @EndTime))   
        OR --Events that started and ended within the report window.  
      (ted.Start_Time >= @StartTime AND Coalesce(ted.End_Time, @Now) <= @EndTime)   
        OR --Events that ended outside the report window but started within it.  
          (Coalesce(ted.End_Time, @Now) > @EndTime AND (ted.Start_Time >= @StartTime AND ted.Start_Time <= @EndTime))  
          OR --Events that span the entire report window  
   (ted.Start_Time < @StartTime and Coalesce(ted.End_Time, @Now) > @EndTime)  
   )   
  THEN  1  
  ELSE 0   
  END  
FROM Timed_Event_Details ted  
 INNER JOIN #ProdUnits tpu ON ted.PU_Id = tpu.PUId AND tpu.PUId > 0  
WHERE ted.Start_Time < @EndTime  
 AND (ted.End_Time >= @StartTime OR ted.End_Time IS NULL)  
  
-- Doing this allows us to utilize the clustered index on the temp table  
UPDATE ted  
SET PrimaryId = ted2.TEDet_Id,  
 SecondaryId = ted3.TEDet_Id  
FROM #Delays ted  
 LEFT JOIN Timed_Event_Details ted2 ON ted.PUId = ted2.PU_Id  
      AND ted.StartTime = ted2.End_Time  
      AND ted.TEDetId <> ted2.TEDet_Id  
 LEFT JOIN Timed_Event_Details ted3 ON ted.PUId = ted3.PU_Id  
      AND ted.EndTime = ted3.Start_Time  
      AND ted.TEDetId <> ted3.TEDet_Id  
WHERE ted2.TEDet_Id IS NOT NULL  
 OR ted3.TEDet_Id IS NOT NULL  
  
-------------------------------------------------------------------------------  
-- Add the detail records that span either end of this collection but may not be  
-- in the data set.  These are records related to multi-downtime events where only  
-- one of the set is within the Report Period.  
-------------------------------------------------------------------------------  
-- Multi-event downtime records that span prior to the Report Period.  
WHILE ( SELECT Count(td1.TEDetId)  
 FROM #Delays td1  
  LEFT JOIN #Delays td2 ON td1.PrimaryId = td2.TEDetId  
 WHERE td2.TEDetId IS NULL  
  AND td1.PrimaryId IS NOT NULL) > 0  
 BEGIN  
 INSERT #Delays ( TEDetId,   
    PUId,   
    StartTime,   
    EndTime,   
    LocationId,  
    L1ReasonId,   
    L2ReasonId,   
    L3ReasonId,   
    L4ReasonId,   
    TEFaultId,  
    DownTime,   
    ReportDownTime,  
    PrimaryId,   
    InRptWindow)  
  
 SELECT ted.TEDet_Id,   
  ted.PU_Id,   
  ted.Start_Time,   
  Coalesce(ted.End_Time, @Now),   
  ted.Source_PU_Id,  
  ted.Reason_Level1,   
  ted.Reason_Level2,   
  ted.Reason_Level3,   
  ted.Reason_Level4,   
  ted.TEFault_Id,  
  DateDiff(Second, ted.Start_Time, Coalesce(ted.End_Time, @Now)),   
  0,  
  ted2.TEDet_Id,  
  CASE WHEN (   --Events that started outside the report window but ended within it.  
       (ted.Start_Time < @StartTime AND (ted.End_Time >= @StartTime AND ted.End_Time <= @EndTime))   
                   OR --Events that started and ended within the report window.  
          (ted.Start_Time >= @StartTime AND ted.End_Time <= @EndTime)   
                   OR --Events that ended outside the report window but started within it.  
       (ted.End_Time > @EndTime AND (ted.Start_Time >= @StartTime AND ted.Start_Time <= @EndTime))  
       OR --Events that span the entire report window  
       (ted.Start_Time < @StartTime and ted.End_Time > @EndTime)  
     )  
   THEN  1  
   ELSE 0   
   END  
  
 FROM Timed_Event_Details ted  
  INNER JOIN #ProdUnits tpu ON ted.PU_Id = tpu.PUId  
  LEFT JOIN Timed_Event_Details ted2 ON ted.PU_Id = ted2.PU_Id  
       AND ted.Start_Time = ted2.End_Time  
       AND ted.TEDet_Id <> ted2.TEDet_Id  
 WHERE ted.TEDet_Id IN ( SELECT td1.PrimaryId  
    FROM #Delays td1  
     LEFT JOIN #Delays td2 ON td1.PrimaryId = td2.TEDetId  
    WHERE td2.TEDetId IS NULL  
     AND td1.PrimaryId IS NOT NULL)  
 END  
  
-- Multi-event downtime records that span after the Report Period.  
WHILE (SELECT Count(td1.TEDetId)  
  FROM #Delays td1  
  LEFT JOIN #Delays td2 ON td1.SecondaryId = td2.TEDetId  
  WHERE  td2.TEDetId IS NULL  
  AND  td1.SecondaryId IS NOT NULL) > 0  
 INSERT #Delays ( TEDetId,   
    PUId,   
    StartTime,   
    EndTime,   
    LocationId,  
    L1ReasonId,   
    L2ReasonId,   
    L3ReasonId,   
    L4ReasonId,   
    TEFaultId,  
    DownTime,   
    ReportDownTime,  
    SecondaryId,   
    InRptWindow)  
  
 SELECT ted.TEDet_Id,   
  ted.PU_Id,   
  ted.Start_Time,   
  Coalesce(ted.End_Time, @Now),   
  ted.Source_PU_Id,  
  ted.Reason_Level1,   
  ted.Reason_Level2,   
  ted.Reason_Level3,   
  ted.Reason_Level4,   
  ted.TEFault_Id,  
  DateDiff(Second, ted.Start_Time, Coalesce(ted.End_Time, @Now)),   
  0,  
  ted3.TEDet_Id,  
  CASE WHEN (   --Events that started outside the report window but ended within it.  
       (ted.Start_Time < @StartTime AND (ted.End_Time >= @StartTime AND ted.End_Time <= @EndTime))   
                   OR --Events that started and ended within the report window.  
          (ted.Start_Time >= @StartTime AND ted.End_Time <= @EndTime)   
                   OR --Events that ended outside the report window but started within it.  
       (ted.End_Time > @EndTime AND (ted.Start_Time >= @StartTime AND ted.Start_Time <= @EndTime))  
       OR --Events that span the entire report window  
       (ted.Start_Time < @StartTime and ted.End_Time > @EndTime)  
     )  
   THEN  1  
   ELSE 0   
   END  
  
 FROM Timed_Event_Details ted  
      JOIN #ProdUnits tpu ON ted.PU_Id = tpu.PUId  
      LEFT JOIN Timed_Event_Details ted3 ON ted.PU_Id = ted3.PU_Id  
          AND ted.End_Time = ted3.Start_Time  
   AND ted.TEDet_Id <> ted3.TEDet_Id  
 WHERE ted.TEDet_Id IN ( SELECT td1.SecondaryId  
    FROM #Delays td1  
     LEFT JOIN #Delays td2 ON td1.SecondaryId = td2.TEDetId  
    WHERE td2.TEDetId IS NULL  
     AND td1.SecondaryId IS NOT NULL)  
  
-- Get the maximum range for later queries  
SELECT @Max_TEDet_Id  = MAX(TEDetId) + 1,  
 @Min_TEDet_Id = MIN(TEDetId) - 1,  
 @RangeStartTime = MIN(StartTime),  
 @RangeEndTime = MAX(EndTime)  
FROM #Delays  
  
-------------------------------------------------------------------------------  
-- If the dataset has more than 65000 records, then send an error message and  
-- suspend processing.  This is because Excel can not handle more than 65536 rows  
-- in a spreadsheet.  
-------------------------------------------------------------------------------  
IF (SELECT Count(TEDetId)  
  FROM #Delays) > 65000  
BEGIN  
 INSERT #ErrorMessages (ErrMsg)  
  VALUES ('The dataset contains more than 65000 rows.  This exceeds the Excel limit.')  
 GOTO DropTables  
END  
  
-------------------------------------------------------------------------------  
-- Cycle through the dataset and ensure that all the PrimaryIds point to the  
-- actual Primary event.  
-------------------------------------------------------------------------------  
WHILE (SELECT Count(td1.TEDetId)  
  FROM #Delays td1  
  JOIN #Delays td2 ON td1.PrimaryId = td2.TEDetId  
  WHERE td2.PrimaryId IS NOT NULL) > 0  
 UPDATE td1  
  SET PrimaryId = td2.PrimaryId  
  FROM #Delays td1  
  JOIN #Delays td2 ON td1.PrimaryId = td2.TEDetId  
  WHERE td2.PrimaryId IS NOT NULL  
UPDATE #Delays  
 SET PrimaryId = TEDetId  
 WHERE PrimaryId IS NULL  
-------------------------------------------------------------------------------  
-- Add the Products to the dataset.  
-------------------------------------------------------------------------------  
UPDATE td  
 SET ProdId = ps.Prod_Id  
 FROM #Delays td  
 JOIN Production_Starts ps ON td.PUId = ps.PU_Id  
  AND td.StartTime >= ps.Start_Time  
  AND (td.StartTime < ps.End_Time  
   OR ps.End_Time IS NULL)  
-------------------------------------------------------------------------------  
-- Add the Shift and Crew to the dataset.  
-------------------------------------------------------------------------------  
UPDATE td  
 SET Shift  = cs.Shift_Desc,  
  Crew  = cs.Crew_Desc  
 FROM #Delays td  
 JOIN #ProdUnits tpu ON td.PUId = tpu.PUId  
 JOIN Crew_Schedule cs ON tpu.ScheduleUnit = cs.PU_Id  
  AND td.StartTime >= cs.Start_Time  
  AND td.StartTime < cs.End_Time  
-------------------------------------------------------------------------------  
-- Add the Line Status to the dataset.  
-------------------------------------------------------------------------------  
/*DECLARE DelaysCursor INSENSITIVE CURSOR FOR  
 (SELECT StartTime, PUId  
  FROM #Delays)  
 FOR READ ONLY  
OPEN DelaysCursor  
FETCH NEXT FROM DelaysCursor INTO @@Timestamp, @@PUId  
WHILE @@Fetch_Status = 0  
BEGIN  
 UPDATE td  
  SET LineStatus = (SELECT TOP 1 P.Phrase_Value  
     FROM Local_PG_Line_Status LS  
     JOIN Phrase P ON LS.Line_Status_Id = P.Phrase_Id  
     JOIN #ProdUnits pu ON pu.PUId = @@PUId  
     WHERE LS.Start_DateTime <= @@Timestamp  
      AND pu.LineStatusUnit = LS.Unit_Id  
     ORDER BY LS.Start_DateTime DESC)  
 FROM #Delays td  
 WHERE PUId = @@PUId AND StartTime = @@Timestamp  
 FETCH NEXT FROM DelaysCursor INTO @@Timestamp, @@PUId  
END  
CLOSE DelaysCursor  
DEALLOCATE DelaysCursor  
*/  
CREATE TABLE #LineStatusRaw ( PUId  int,  
    StartTime datetime,  
    PhraseId int)  
  
CREATE TABLE #LineStatus ( LSId  int PRIMARY KEY NONCLUSTERED IDENTITY ,  
    PUId  int,  
    StartTime datetime,  
    EndTime  datetime,  
    PhraseId int)  
  
CREATE CLUSTERED INDEX ls_PUId_StartTime  
 ON #LineStatus (PUId, StartTime)  
  
INSERT INTO #LineStatusRaw ( PUId,  
    PhraseId,  
    StartTime)  
SELECT pu.PUId,  
 ls.Line_Status_Id,  
 ls.Start_DateTime  
FROM Local_PG_Line_Status ls  
 INNER JOIN #ProdUnits pu ON ls.Unit_Id = pu.LineStatusUnit AND pu.PUId > 0  
WHERE ls.Start_DateTime >= @RangeStartTime  
 AND ls.Start_DateTime < @RangeEndTime  
  
INSERT INTO #LineStatusRaw ( PUId,  
    PhraseId,  
    StartTime)  
SELECT pu.PUId,  
 ls.Line_Status_Id,  
 max(ls.Start_DateTime)  
FROM Local_PG_Line_Status ls  
 INNER JOIN #ProdUnits pu ON ls.Unit_Id = pu.LineStatusUnit AND pu.PUId > 0  
WHERE ls.Start_DateTime < @RangeStartTime  
GROUP BY  pu.PUId,  
  ls.Line_Status_Id  
  
INSERT INTO #LineStatus ( PUId,  
    PhraseId,  
    StartTime)  
SELECT PUId,  
 PhraseId,  
 StartTime  
FROM #LineStatusRaw  
ORDER BY PUId, StartTime  
  
UPDATE ls1  
SET EndTime = CASE  WHEN ls1.PUId = ls2.PUId THEN ls2.StartTime  
   ELSE NULL  
   END  
FROM #LineStatus ls1  
    INNER JOIN #LineStatus ls2 ON ls2.LSId = (ls1.LSId - 1)   
WHERE ls1.LSId > 1  
  
UPDATE td  
SET LineStatus = p.Phrase_Value  
FROM #Delays td  
 INNER JOIN #LineStatus ls ON  td.PUId = ls.PUId  
     AND td.StartTime >= ls.StartTime  
     AND (td.StartTime < ls.EndTime OR ls.EndTime IS NULL)  
 INNER JOIN Phrase p ON ls.PhraseId = p.Phrase_Id  
  
DROP TABLE #LineStatusRaw  
DROP TABLE #LineStatus  
  
-------------------------------------------------------------------------------  
-- Retrieve the Tree Node Ids so we can get the associated categories.  
-------------------------------------------------------------------------------  
-- Level 1.  
-------------------------------------------------------------------------------  
UPDATE td  
 SET L1TreeNodeId = ertd.Event_Reason_Tree_Data_Id  
 FROM #Delays td  
 JOIN Prod_Events pe ON td.LocationId = pe.PU_Id  
  AND pe.Event_Type = 2  
 JOIN Event_Reason_Tree_Data ertd ON pe.Name_Id = ertd.Tree_Name_Id  
  AND ertd.Event_Reason_Level = 1  
  AND ertd.Event_Reason_Id = td.L1ReasonId  
-------------------------------------------------------------------------------  
-- Level 2.  
-------------------------------------------------------------------------------  
UPDATE td  
 SET L2TreeNodeId = ertd.Event_Reason_Tree_Data_Id  
 FROM #Delays td  
 JOIN Event_Reason_Tree_Data ertd ON td.L1TreeNodeId = ertd.Parent_Event_R_Tree_Data_Id  
  AND ertd.Event_Reason_Level = 2  
  AND ertd.Event_Reason_Id = td.L2ReasonId  
-------------------------------------------------------------------------------  
-- Level 3.  
-------------------------------------------------------------------------------  
UPDATE td  
 SET L3TreeNodeId = ertd.Event_Reason_Tree_Data_Id  
 FROM #Delays td  
 JOIN Event_Reason_Tree_Data ertd ON td.L2TreeNodeId = ertd.Parent_Event_R_Tree_Data_Id  
  AND ertd.Event_Reason_Level = 3  
  AND ertd.Event_Reason_Id = td.L3ReasonId  
-------------------------------------------------------------------------------  
-- Level 4.  
-------------------------------------------------------------------------------  
UPDATE td  
 SET L4TreeNodeId = ertd.Event_Reason_Tree_Data_Id  
 FROM #Delays td  
 JOIN Event_Reason_Tree_Data ertd ON td.L3TreeNodeId = ertd.Parent_Event_R_Tree_Data_Id  
  AND ertd.Event_Reason_Level = 4  
  AND ertd.Event_Reason_Id = td.L4ReasonId  
-------------------------------------------------------------------------------  
-- Retrieve the Schedule, Category, GroupCause and SubSystem categories for the  
-- lowest point on the tree.  NOTE:  This is different than the DDS-Stops code   
-- for some reason.  I think it is because we don't need to worry about the history  
-- bit since this is a "real-time" report.  
-------------------------------------------------------------------------------  
UPDATE td  
 SET ScheduleId = erc.ERC_Id  
  
 FROM #Delays td  
 JOIN Event_Reason_Category_Data ercd  
  ON Coalesce(td.L4TreeNodeId, td.L3TreeNodeId, td.L2TreeNodeId, td.L1TreeNodeId) = ercd.Event_Reason_Tree_Data_Id  
 JOIN Event_Reason_Catagories erc ON ercd.ERC_Id = erc.ERC_Id  
  AND erc.ERC_Desc LIKE @ScheduleStr + '%'  
  
UPDATE td  
 SET CategoryId = erc.ERC_Id  
 FROM #Delays td  
 JOIN Event_Reason_Category_Data ercd  
  ON Coalesce(td.L4TreeNodeId, td.L3TreeNodeId, td.L2TreeNodeId, td.L1TreeNodeId) = ercd.Event_Reason_Tree_Data_Id  
 JOIN Event_Reason_Catagories erc ON ercd.ERC_Id = erc.ERC_Id  
  AND erc.ERC_Desc LIKE @CategoryStr + '%'  
  
-------------------------------------------------------------------------------  
-- Populate a separate temporary table that only contains the Primary records.  
-- This allows us to retrieve the EndTime of the previous downtime  
-- event which is used to calculate UpTime.  
-------------------------------------------------------------------------------  
INSERT #Primaries ( TEDetId,  
   PUId,  
   StartTime,  
   EndTime,  
   LastEndTime,  
   UpTime,  
   ReportUpTime)  
SELECT td1.TEDetId,  
 td1.PUId,  
 MIN(td2.StartTime),  
 MAX(td2.EndTime),  
 @StartTime,  
 datediff(s, @StartTime, MIN(td2.StartTime)),  
 datediff(s, @StartTime, MIN(td2.StartTime))  
FROM #Delays td1  
 INNER JOIN #Delays td2 ON td1.TEDetId = td2.PrimaryId  
WHERE td1.TEDetId = td1.PrimaryId  
GROUP BY td1.TEDetId,  
  td1.PUId  
ORDER BY td1.PUId, MIN(td2.StartTime) ASC  
  
UPDATE p1  
SET LastEndTime = CASE WHEN p1.PUId = p2.PUId THEN p2.EndTime  
    ELSE @StartTime  
    END,  
 Uptime  = CASE  WHEN p1.PUId = p2.PUId THEN datediff(s, p2.EndTime, p1.StartTime)  
    WHEN p1.StartTime > @StartTime THEN datediff(s,@StartTime, p1.StartTime)  
    ELSE 0  
    END,  
 ReportUptime = CASE  WHEN p1.PUId = p2.PUId THEN datediff(s, p2.EndTime, p1.StartTime)  
    WHEN p1.StartTime > @StartTime THEN datediff(s,@StartTime, p1.StartTime)  
    ELSE 0  
    END  
FROM #Primaries p1  
    INNER JOIN #Primaries p2 ON p2.TEPrimaryId = (p1.TEPrimaryId - 1)   
WHERE p1.TEPrimaryId > 1  
  
/*  
DECLARE PrimariesCursor INSENSITIVE CURSOR FOR  
 (SELECT TEDetId, PUId, StartTime  
  FROM #Primaries)  
 FOR READ ONLY  
OPEN PrimariesCursor  
FETCH NEXT FROM PrimariesCursor INTO @@Id, @@PUId, @@TimeStamp  
WHILE @@Fetch_Status = 0  
BEGIN  
 SELECT @@PLId = PL_Id FROM Prod_Units WHERE PU_Id = @@PUId  
 SELECT @@LastEndTime = NULL  
 SELECT @@LastEndTime = Max(EndTime)  
  FROM #Primaries ted  
  WHERE PUId = @@PUId  
  AND EndTime <= @@TimeStamp  
  AND EndTime > DateAdd(Month, -1, @@TimeStamp)  
  
 SELECT @@LastEndTime = CASE WHEN @@LastEndTime IS NULL THEN @StartTime ELSE @@LastEndTime END  
 UPDATE #Primaries  
  SET LastEndTime = @@LastEndTime,  
   UpTime = DateDiff(Second, @@LastEndTime, @@TimeStamp),  
   ReportUpTime = DateDiff(Second,  
    (CASE WHEN @@LastEndTime < @StartTime THEN @StartTime ELSE @@LastEndTime END),  
    (CASE WHEN @@TimeStamp < @StartTime THEN @StartTime ELSE @@TimeStamp END))  
  WHERE TEDetId = @@Id  
 FETCH NEXT FROM PrimariesCursor INTO @@Id, @@PUId, @@TimeStamp  
END  
CLOSE PrimariesCursor  
DEALLOCATE PrimariesCursor  
*/  
  
UPDATE td  
 SET UpTime = tp.UpTime,  
  ReportUptime = tp.ReportUptime  
 FROM #Delays td  
 JOIN #Primaries tp ON td.TEDetId = tp.TEDetId  
  
-------------------------------------------------------------------------------  
-- Calculate the Statistics on the dataset and set NULL Uptimes to zero.  
-------------------------------------------------------------------------------  
UPDATE td  
 SET Stops =   CASE WHEN tpu.DelayType <> @DelayTypeRateLossStr  
       AND (td.CategoryId <> @CatBlockStarvedId OR td.CategoryId IS NULL)  
       AND (td.StartTime >= @StartTime)  
       THEN 1  
      ELSE 0  
      END,  
  StopsUnscheduled = CASE WHEN tpu.DelayType <> @DelayTypeRateLossStr  
       AND (td.CategoryId <> @CatBlockStarvedId OR td.CategoryId IS NULL)  
       AND (td.ScheduleId = @SchedUnscheduledId OR td.ScheduleId IS NULL)  
       AND (td.StartTime >= @StartTime)  
      THEN 1  
      ELSE 0  
      END,  
  Stops2m =  CASE WHEN td.DownTime < 120  
       AND tpu.DelayType <> @DelayTypeRateLossStr  
       AND (td.CategoryId <> @CatBlockStarvedId OR td.CategoryId IS NULL)  
       AND (td.ScheduleId = @SchedUnscheduledId OR td.ScheduleId IS NULL)  
       AND (td.StartTime >= @StartTime)  
      THEN 1  
      ELSE 0  
      END,  
  StopsMinor =  CASE WHEN td.DownTime < 600  
       AND tpu.DelayType <> @DelayTypeRateLossStr  
       AND (td.CategoryId <> @CatBlockStarvedId OR td.CategoryId IS NULL)  
       AND (td.ScheduleId = @SchedUnscheduledId OR td.ScheduleId IS NULL)  
       AND (td.StartTime >= @StartTime)  
      THEN 1  
      ELSE 0  
      END,  
  StopsEquipFails = CASE WHEN td.DownTime >= 600  
       AND tpu.DelayType <> @DelayTypeRateLossStr  
       AND td.CategoryId IN (@CatMechEquipId, @CatElectEquipId)  
       AND (td.ScheduleId = @SchedUnscheduledId OR td.ScheduleId IS NULL)  
       AND (td.StartTime >= @StartTime)  
      THEN 1  
      ELSE 0  
      END,  
  StopsELP =  CASE WHEN tpu.DelayType <> @DelayTypeRateLossStr  
       AND (td.CategoryId = @CatELPId)  
       AND (td.StartTime >= @StartTime)  
      THEN 1  
      ELSE 0  
      END,  
  StopsBlockedStarved = CASE WHEN td.CategoryId = @CatBlockStarvedId  
       AND tpu.DelayType <> @DelayTypeRateLossStr  
       AND (td.StartTime >= @StartTime)  
      THEN 1  
      ELSE 0  
      END,  
  UpTime2m =  CASE WHEN td.UpTime < 120  
       AND tpu.DelayType <> @DelayTypeRateLossStr  
       AND (td.CategoryId <> @CatBlockStarvedId OR td.CategoryId IS NULL)  
       AND (td.StartTime >= @StartTime)  
      THEN 1  
      ELSE 0  
      END,  
  StopsProcessFailures = CASE WHEN td.DownTime >= 600  
       AND  tpu.DelayType <> @DelayTypeRateLossStr  
       AND (td.ScheduleId = @SchedUnScheduledId OR td.ScheduleId IS NULL)  
       AND (td.CategoryId NOT IN (@CatMechEquipId, @CatElectEquipId, @CatBlockStarvedId) OR td.CategoryId IS NULL)  
       AND (td.StartTime >= @StartTime)  
      THEN 1  
      ELSE 0  
      END,  
  ReportELPDowntime = CASE WHEN tpu.DelayType <> @DelayTypeRateLossStr  
       AND (td.CategoryId <> @CatBlockStarvedId OR td.CategoryId IS NULL)  
       AND (td.CategoryId = @CatELPId)  
      THEN td.ReportDownTime  
      ELSE 0  
      END  
 FROM #Delays td  
 JOIN #ProdUnits tpu ON td.PUId = tpu.PUId  
 WHERE  td.TEDetId = td.PrimaryId  
  
UPDATE td  
  SET  ReportELPSchedDT =  (CASE WHEN td.ScheduleId NOT IN (@SchedSpecialCausesId, @SchedUnscheduledId, @SchedPRPolyId,   
        @SchedEOProjectsId, @SchedBlockedStarvedId)   
      THEN td.ReportDowntime  
     ELSE 0  
     END)  
 FROM #Delays td  
 --WHERE td.PUDesc LIKE '%Converter%'   FLD  
  
DropTables:  
   
--*******************************************************************************************************************--  
-- Process all the Test requirements.  
--*******************************************************************************************************************--  
-------------------------------------------------------------------------------  
-- Collect all the Test records for the reporting period.  
-------------------------------------------------------------------------------  
-- Testing...  
INSERT #Tests ( VarId,  
  PLId,  
  Value,  
  StartTime,  
  EndTime)  
SELECT t.Var_Id,  
 pl.PLId,  
 convert(float, t.Result),  
 t.Result_On,  
 @Now  
FROM Tests t  
 INNER JOIN #ProdLines pl ON pl.VarGoodUnitsId   = t.Var_Id  
     OR pl.VarTotalUnitsId   = t.Var_Id  
     OR pl.VarPMRollWidthId   = t.Var_Id  
     OR pl.VarEffDowntimeId   = t.Var_Id  
     OR pl.VarGoodUnitsACPTwoId  = t.Var_Id  
     OR pl.VarGoodUnitsACPOneId  = t.Var_Id  
     OR pl.VarGoodUnitsHPBundlesId = t.Var_Id  
     OR pl.VarGoodUnitsHPCasesId = t.Var_Id  
WHERE t.Result_On > @StartTime  
 AND t.Result_On <= @EndTime  
ORDER BY t.Var_Id, t.Result_On DESC  
  
UPDATE t1  
SET EndTime = CASE WHEN t1.VarId = t2.VarId THEN t2.StartTime  
   ELSE @EndTime  
   END  
FROM #Tests t1  
    INNER JOIN #Tests t2 ON t2.TestId = (t1.TestId - 1)   
WHERE t1.TestId > 1  
  
/*  
DECLARE ProdLinesCursor INSENSITIVE CURSOR FOR  
 (SELECT PLId, VarGoodUnitsId, VarTotalUnitsId, VarPMRollWidthId, VarEffDowntimeId,   
   VarGoodUnitsACPTwoId, VarGoodUnitsACPOneId,  
   VarGoodUnitsHPBundlesId, VarGoodUnitsHPCasesId  
  FROM #ProdLines)   FOR READ ONLY  
OPEN ProdLinesCursor  
FETCH NEXT FROM ProdLinesCursor INTO @@Id, @@VarGoodUnitsId, @@VarTotalUnitsId, @@VarPMRollWidthId,   
      @@VarEffDowntimeId,  
      @@VarGoodUnitsACPTwoId, @@VarGoodUnitsACPOneId,  
      @@VarGoodUnitsHPBundlesId, @@VarGoodUnitsHPCasesId  
WHILE @@Fetch_Status = 0  
BEGIN    
 INSERT #Tests (TestId, VarId, PLId, Value, StartTime)  
  SELECT Test_Id, t.Var_Id, pl.PL_Id, Convert(Float, Result), Result_On  
   FROM Tests t  
    JOIN Variables v ON t.Var_Id = v.Var_Id  
    JOIN Prod_Units pu ON v.PU_Id = pu.PU_Id  
    JOIN Prod_Lines pl ON pu.PL_Id = pl.PL_Id  
   WHERE t.Var_Id IN (@@VarGoodUnitsId, @@VarTotalUnitsId, @@VarPMRollWidthId,   
       @@VarEffDowntimeId,  
       @@VarGoodUnitsACPTwoId, @@VarGoodUnitsACPOneId,  
       @@VarGoodUnitsHPBundlesId, @@VarGoodUnitsHPCasesId)  
   AND Result_On > @StartTime  
   AND Result_On <= @EndTime  
  
 FETCH NEXT FROM ProdLinesCursor INTO @@Id, @@VarGoodUnitsId, @@VarTotalUnitsId, @@VarPMRollWidthId,   
      @@VarEffDowntimeId,  
      @@VarGoodUnitsACPTwoId, @@VarGoodUnitsACPOneId,  
      @@VarGoodUnitsHPBundlesId, @@VarGoodUnitsHPCasesId  
END  
CLOSE ProdLinesCursor  
DEALLOCATE ProdLinesCursor  
  
DECLARE TestsCursor INSENSITIVE CURSOR FOR  
 (SELECT TestId, VarId, StartTime  
  FROM #Tests)  
 FOR READ ONLY  
OPEN TestsCursor  
FETCH NEXT FROM TestsCursor INTO @@Id, @@VarId, @@TimeStamp  
WHILE @@Fetch_Status = 0  
BEGIN  
 SELECT @@NextStartTime = NULL  
 SELECT @@NextStartTime = Min(StartTime)  
  FROM #Tests  
  WHERE VarId = @@VarId  
  AND StartTime > @@TimeStamp  
  AND StartTime < @Now  
 UPDATE #Tests  
  SET EndTime = Coalesce(@@NextStartTime, @Now)  
  WHERE TestId = @@Id  
 FETCH NEXT FROM TestsCursor INTO @@Id, @@VarId, @@TimeStamp  
END  
CLOSE TestsCursor  
DEALLOCATE TestsCursor  
*/  
-------------------------------------------------------------------------------  
-- Update the RateLoss ReportDowntime to be equal to the Effective Downtime  
-- from the #Tests table.  Note: Effective Downtime is already in minutes!  
-- Set ReportDowntime and ReportUptime = 0 so that they will not be  
-- included in Total Report Time.  
-------------------------------------------------------------------------------  
  
 UPDATE td   
  SET  ReportRLDowntime  = (t.Value),  
       ReportDowntime    = 0,  
   ReportUptime   = 0,  
   StopsRateLoss  = 1,  
   ReportRLELPDowntime  = CASE WHEN td.CategoryId = @CatELPId THEN t.Value ELSE 0 END  
  
 FROM #Delays td  
   JOIN #ProdUnits pu ON td.PUID = pu.PUID  
   JOIN #ProdLines pl ON pu.PLID = pl.PLID  
  LEFT  JOIN #Tests t ON (td.StartTime = t.StartTime)   
     AND (pl.VarEffDowntimeId = t.VarId)  
 WHERE pu.DelayType = @DelayTypeRateLossStr  
-------------------------------------------------------------------------------  
-- Now summarize the results into the #ProdRecordsShift table for each Line/Shift.  
-------------------------------------------------------------------------------  
DECLARE ProdRLinesShiftCursor INSENSITIVE CURSOR FOR  
SELECT pl.PL_Id, ProdId, StartTime, EndTime,   
 VarGoodUnitsACPTwoId, VarGoodUnitsACPOneId,   
 VarGoodUnitsHPBundlesId, VarGoodUnitsHPCasesId  
FROM #RunsLine rl  
 JOIN Prod_Lines pl ON rl.PLId = pl.PL_Id  
 JOIN #ProdLines ppl ON rl.PLId = ppl.PLId  
  --WHERE ppl.PackOrLine <> 'Pack')    
FOR READ ONLY  
OPEN ProdRLinesShiftCursor  
  
FETCH NEXT FROM ProdRLinesShiftCursor INTO  @@PLId,   
      @@ProdId,   
      @@StartTime,   
        @@EndTime,   
      @@VarGoodUnitsACPTwoId,   
      @@VarGoodUnitsACPOneId,  
        @@VarGoodUnitsHPBundlesId,   
      @@VarGoodUnitsHPCasesId  
WHILE @@Fetch_Status = 0  
 BEGIN  
 SELECT  @HolidayCurtailDT  = NULL,  
  @CalendarRuntime  = NULL,  
  @ProductionRuntime  = NULL,  
  @OperationsRuntime  = NULL,  
  @OperationsIdealUnits  = NULL  
   
 SELECT @ProdCode = Prod_Code  
 FROM Products  
 WHERE Prod_Id = @@ProdId  
  
 SELECT @CharId = Char_Id  
 FROM Characteristics  
 WHERE  Char_Desc = @ProdCode  
  AND Prop_Id = @PropCvtgProdFactorId  
  
 SELECT @PropLineSpeedTargetId = PropLineProdFactorId  
 FROM #ProdLines  
 WHERE PLId = @@PLId  
  
 SELECT @LinePropCharId = Char_Id  
 FROM Characteristics  
 WHERE  Char_Desc = @ProdCode  
  AND Prop_Id = @PropLineSpeedTargetId  
  
 SELECT @StatFactor = CONVERT(FLOAT, Target)     
 FROM Active_Specs a  
  JOIN Specifications sp ON a.Spec_Id = sp.Spec_Id  
 WHERE sp.Prop_Id = @PropCvtgProdFactorId   
  AND Spec_Desc = @StatFactorSpecDesc  
  AND a.Char_Id = @CharId  
  AND Effective_Date <= @StartTime  
  AND (Expiration_Date > @StartTime OR Expiration_Date IS NULL)  
  
 SELECT @RollsInPack = CONVERT(FLOAT, Target)    
 FROM Active_Specs a  
  JOIN Specifications sp ON a.Spec_Id = sp.Spec_Id  
 WHERE sp.Prop_id = @PropCvtgProdFactorId   
  AND Spec_Desc = @RollsInPackSpecDesc  
  AND a.Char_Id = @CharId  
  AND Effective_Date <= @StartTime  
  AND (Expiration_Date > @StartTime OR Expiration_Date IS NULL)  
  
 SELECT @PacksInBundle = CONVERT(FLOAT, Target)  
 FROM Active_Specs a  
  JOIN Specifications sp ON a.Spec_Id = sp.Spec_Id  
 WHERE  sp.Prop_id = @PropCvtgProdFactorId   
  AND Spec_Desc = @PacksInBundleSpecDesc  
  AND a.Char_Id = @CharId  
  AND Effective_Date <= @StartTime  
  AND (Expiration_Date > @StartTime OR Expiration_Date IS NULL)  
  
 SELECT @SheetCount = CONVERT(FLOAT, Target)  
 FROM Active_Specs a  
  JOIN Specifications sp ON a.Spec_Id = sp.Spec_Id  
 WHERE  sp.Prop_id = @PropCvtgProdFactorId   
  AND Spec_Desc = @SheetCountSpecDesc  
  AND a.Char_Id = @CharId  
  AND Effective_Date <= @StartTime  
  AND (Expiration_Date > @StartTime OR Expiration_Date IS NULL)  
  
 SELECT @ShipUnit = CONVERT(FLOAT, Target)   
 FROM Active_Specs a  
  JOIN Specifications sp ON a.Spec_Id = sp.Spec_Id  
 WHERE  sp.Prop_id = @PropCvtgProdFactorId   
  AND Spec_Desc = @ShipUnitSpecDesc  
  AND a.Char_Id = @CharId  
  AND Effective_Date <= @StartTime  
  AND (Expiration_Date > @StartTime OR Expiration_Date IS NULL)  
  
 SELECT @SheetWidth = CONVERT(FLOAT, Target)   
 FROM Active_Specs a  
  JOIN Specifications sp ON a.Spec_Id = sp.Spec_Id  
 WHERE  sp.Prop_id = @PropCvtgProdFactorId   
  AND Spec_Desc = @SheetWidthSpecDesc  
  AND a.Char_Id = @CharId  
  AND Effective_Date <= @StartTime  
  AND (Expiration_Date > @StartTime OR Expiration_Date IS NULL)  
  
 SELECT @SheetLength = CONVERT(FLOAT, Target)  
 FROM Active_Specs a  
  JOIN Specifications sp ON a.Spec_Id = sp.Spec_Id  
 WHERE  sp.Prop_id = @PropCvtgProdFactorId   
  AND Spec_Desc = @SheetLengthSpecDesc  
  AND a.Char_Id = @CharId  
  AND Effective_Date <= @StartTime  
  AND (Expiration_Date > @StartTime OR Expiration_Date IS NULL)  
  
 SELECT @CartonsInCase = CONVERT(FLOAT, Target)  
 FROM Active_Specs a  
  JOIN Specifications sp ON a.Spec_Id = sp.Spec_Id  
 WHERE  sp.Prop_id = @PropCvtgProdFactorId   
  AND Spec_Desc = @CartonsInCaseSpecDesc  
  AND a.Char_Id = @CharId  
  AND Effective_Date <= @StartTime  
  AND (Expiration_Date > @StartTime OR Expiration_Date IS NULL)  
  
 SELECT @LineSpeedTarget = CONVERT(FLOAT, Target)  
 FROM Active_Specs a  
  JOIN Specifications sp ON a.Spec_Id = sp.Spec_Id  
 WHERE  sp.Prop_id = @PropLineSpeedTargetId   
  AND Spec_Desc = @LineSpeedTargetSpecDesc  
  AND a.Char_Id = @LinePropCharId  
  AND Effective_Date <= @StartTime  
  AND (Expiration_Date > @StartTime OR Expiration_Date IS NULL)  
  
 SELECT @ProdCvtgPUId = PU_Id  
 FROM Prod_Units  
 WHERE PL_Id = @@PLId  
  AND PU_Desc LIKE '%Converter Reliability%'  
  
 SELECT @CalendarRuntime = (CONVERT(Float,DATEDIFF(ss,@@StartTime, @@EndTime))) / 60.0 --convert runtime to minutes.  
  
 --NOTE: Can't just use td.ReportDowntime here because the event may span a shift.  Must use comparison to shift start and end  
        --      times (@@StartTime and @@EndTime).  Is analogous to what was originally done with the events versus the report window  
 --      start and end times when calculating td.ReportDowntime.    
 SELECT @HolidayCurtailDT = coalesce(sum(convert(float,datediff(s, CASE WHEN td.StartTime <= @@StartTime THEN @@StartTime   
          ELSE td.StartTime  
          END,   
            CASE WHEN td.EndTime >= @@EndTime THEN @@EndTime   
          ELSE td.EndTime   
          END))) / 60.0, 0.0)  
 FROM #Delays td  
 WHERE  td.PUId = @ProdCvtgPUId   
  AND   td.ScheduleId = @SchedHolidayCurtailId   
  AND (   --Events that started outside the shift window but ended within it.  
   (td.StartTime < @@StartTime AND (td.EndTime >= @@StartTime AND td.EndTime <= @@EndTime))  
   OR --Events that started and ended within the shift window.  
   (td.StartTime >= @@StartTime AND td.EndTime <= @@EndTime)   
   OR --Events that ended outside the shift window but started within it.  
   (td.EndTime > @@EndTime AND (td.StartTime >= @@StartTime AND td.StartTime <= @@EndTime))  
   OR --Events that span the entire shift window  
   (td.StartTime < @@StartTime and td.EndTime > @@EndTime)  
   )  
  
  
 SELECT @ProductionRuntime = @CalendarRuntime - @HolidayCurtailDT  
  
  
 SELECT @OperationsRuntime = @CalendarRuntime - (Coalesce((SELECT SUM(CONVERT(Float,DATEDIFF(ss, (CASE WHEN td.StartTime <= @@StartTime   
                   THEN @@StartTime   
                   ELSE td.StartTime END),   
                 (CASE WHEN td.EndTime >= @@EndTime   
                   THEN @@EndTime   
                   ELSE td.EndTime END)))) / 60.0  
                 FROM #Delays td   
                 WHERE td.PUId = @ProdCvtgPUId     
          AND (td.ScheduleId NOT IN (@SchedPRPolyId, @SchedUnscheduledId)  
                 AND td.ScheduleId IS NOT NULL)   
          AND (   --Events that started outside the shift window but ended within it.  
                     (td.StartTime < @@StartTime AND (td.EndTime >= @@StartTime AND td.EndTime <= @@EndTime))  
                                OR --Events that started and ended within the shift window.  
                                             (td.StartTime >= @@StartTime AND td.EndTime <= @@EndTime)   
                                                       OR --Events that ended outside the shift window but started within it.  
                                          (td.EndTime > @@EndTime AND (td.StartTime >= @@StartTime AND td.StartTime <= @@EndTime))  
                                           OR --Events that span the entire shift window  
                                          (td.StartTime < @@StartTime and td.EndTime > @@EndTime)  
                                           )  
                        ), 0.0))  
  
  
 SELECT @TotalUnits = CASE WHEN @BusinessType = 1 or @BusinessType = 2 or @BusinessType = 4  
                                  THEN (SELECT Coalesce(Sum(Coalesce(Value, 0)),0)  
            FROM #Tests t  
     LEFT JOIN #ProdLines pl ON t.PLId = pl.PLId  
            WHERE VarId = VarTotalUnitsId AND t.PLId = @@PLId  
     AND t.StartTime > @@StartTime AND t.StartTime <= @@EndTime)  
                                  WHEN @BusinessType = 3  
                           THEN (SELECT Coalesce(Sum(Coalesce(Value, 0)),0)  
     FROM #Tests t  
     WHERE VarId IN (@@VarGoodUnitsACPTwoId, @@VarGoodUnitsACPOneId)  
     AND t.StartTime > @@StartTime AND t.StartTime <= @@EndTime)  
                           ELSE  NULL  
                           END  
  
 SELECT @GoodUnits = CASE WHEN @BusinessType = 1 or @BusinessType = 2  
                                 THEN (SELECT Coalesce(Sum(Coalesce(Value, 0)),0)  
           FROM #Tests t  
           LEFT JOIN #ProdLines pl ON t.PLId = pl.PLId  
           WHERE VarId = VarGoodUnitsId AND t.PLId = @@PLId  
           AND t.StartTime > @@StartTime AND t.StartTime <= @@EndTime)  
                                 WHEN @BusinessType = 3  
                          THEN (SELECT Coalesce(Sum(Coalesce(Value, 0)),0)  
           FROM #Tests t  
           WHERE VarId IN (@@VarGoodUnitsACPTwoId, @@VarGoodUnitsACPOneId)  
           AND t.StartTime > @@StartTime AND t.StartTime <= @@EndTime)  
     WHEN @BusinessType = 4  
                          THEN ((SELECT Coalesce(Sum(Coalesce(Value, 0)  
           * @SheetCount   
                  * @PacksInBundle   
           * @CartonsInCase)  
           ,0)  
            FROM #Tests t  
            WHERE VarId IN (@@VarGoodUnitsACPTwoId, @@VarGoodUnitsACPOneId)  
            AND t.StartTime > @@StartTime AND t.StartTime <= @@EndTime)  
                              + (SELECT Coalesce(Sum(Coalesce(Value, 0)  
                  * @SheetCount  
           * @PacksInBundle  
                  * @CartonsInCase  
                  * @ShipUnit)  
           ,0)  
            FROM #Tests t  
     WHERE VarId IN (@@VarGoodUnitsHPBundlesId, @@VarGoodUnitsHPCasesId)  
            AND t.StartTime > @@StartTime AND t.StartTime <= @@EndTime))  
                          ELSE  NULL  
                          END  
/*  
 IF @BusinessType = 3 or @BusinessType = 4  
  SELECT @GoodUnitsACP = (SELECT Sum(Coalesce(Value, 0))  
           FROM #Tests t  
           WHERE VarId IN (@@VarGoodUnitsACPTwoId, @@VarGoodUnitsACPOneId)  
           AND t.StartTime > @@StartTime AND t.StartTime <= @@EndTime)*/  
     
  
 SELECT @RejectUnits = (@TotalUnits - @GoodUnits)  
  
 SELECT @RollWidth = (SELECT Avg(Value)  
    FROM #Tests t  
     JOIN #ProdLines pl ON t.PLId = pl.PLId  
    Where VarId = VarPMRollWidthId AND t.PLId = @@PLId  
     AND t.StartTime > @@StartTime AND t.StartTime <= @@EndTime  
     AND (Value < @DefaultPMRollWidth*1.1))  --Filter out values greater than 110% of the default  
          --PM Roll Width.  
  
 SELECT @RollWidth = CASE WHEN (@RollWidth = 0 OR @RollWidth IS NULL) THEN @DefaultPMRollWidth ELSE @RollWidth END  
  
 SELECT @RollsPerLog = FLOOR((@RollWidth * @ConvertInchesToMM) / @SheetWidth)  
  
 SELECT @IdealUnits = CASE @BusinessType  
        WHEN 3 THEN --Facial, Line Speed Target is Cartons/Min.  
        (CONVERT(INTEGER,@LineSpeedTarget) * (1/CONVERT(FLOAT,@RollsInPack)) * (1/CONVERT(FLOAT,@PacksInBundle)) *  
         @ProductionRuntime * @StatFactor)  
  
        WHEN 4 THEN --Hanky lines in Neuss  
        ((@LineSpeedTarget) / (@StatFactor)) * @ProductionRuntime   
                      --@StatFactor is really StatUnit in Neuss!!!  
  
        ELSE        --Tissue/Towel/Napkins  
        CONVERT(INTEGER,@LineSpeedTarget * @ConvertFtToMM * (1/CONVERT(FLOAT,@SheetCount)) *  
        (1/CONVERT(FLOAT,@SheetLength)) * CONVERT(FLOAT,@RollsPerLog) *   
        @ProductionRuntime * (1/CONVERT(FLOAT,@RollsInPack)) * (1/CONVERT(FLOAT,@PacksInBundle)) *  
        @StatFactor)   
        END   
  
 SELECT @OperationsIdealUnits = CASE @BusinessType  
        WHEN 3 THEN --Facial, Line Speed Target is Cartons/Min.  
       (CONVERT(INTEGER,@LineSpeedTarget) * (1/CONVERT(FLOAT,@RollsInPack)) * (1/CONVERT(FLOAT,@PacksInBundle)) *  
        @OperationsRuntime * @StatFactor)  
  
        WHEN 4 THEN --Hanky lines in Neuss  
       ((@LineSpeedTarget) / (@StatFactor)) * @OperationsRuntime   
              --@StatFactor is really StatUnit in Neuss!!!  
  
        ELSE  --Tissue/Towel/Napkins  
       CONVERT(INTEGER,@LineSpeedTarget * @ConvertFtToMM * (1/CONVERT(FLOAT,@SheetCount)) *  
      (1/CONVERT(FLOAT,@SheetLength)) * CONVERT(FLOAT,@RollsPerLog) *   
       @OperationsRuntime * (1/CONVERT(FLOAT,@RollsInPack)) * (1/CONVERT(FLOAT,@PacksInBundle)) *  
       @StatFactor)   
        END   
  
 SELECT @ActualUnits = CASE @BusinessType  
    
         WHEN 1  THEN --Tissue/Towel  
          @GoodUnits * @RollsPerLog * (1/@RollsInPack) *  
          (1/@PacksInBundle) * @StatFactor  
    
         WHEN 2 THEN --Napkins  GoodUnits = Stacks, no conversion needed.  
          @GoodUnits * (1/@RollsInPack) *  
          (1/@PacksInBundle) * @StatFactor  
    
         WHEN 3 THEN --Facial (Convert Good Units on ACP to Stat)  
          @GoodUnits * @StatFactor  
   
         WHEN 4 THEN  --Hanky Lines in Neuss.  Good Units = Sheets.  
          @GoodUnits / @StatFactor   
       --@StatFactor is really StatUnit [sheets per stat] in Neuss!!!  
  
         ELSE     --Else default to the Tissue/Towel Calc.  
          @GoodUnits * @RollsPerLog * (1/@RollsInPack) *  
         (1/@PacksInBundle) * @StatFactor  
         
         END    
  
 INSERT #ProdRecordsShift (PLId, ProductId, Shift_StartTime, Shift_EndTime, StatFactor, RollsPerLog,  
     RollsInPack, PacksInBundle, SheetCount, ShipUnit, SheetWidth, SheetLength, CartonsInCase,  
     CalendarRuntime, ProductionRuntime, OperationsRuntime, TotalUnits,   
     GoodUnits, RejectUnits, LineSpeed, IdealUnits, ActualUnits, OperationsIdealUnits,   
     WebWidth, HolidayCurtailDT)  
  
  
   SELECT @@PLId,  @@ProdId, @@StartTime, @@EndTime,   
    @StatFactor, @RollsPerLog, @RollsInPack, @PacksInBundle, @SheetCount, @ShipUnit, @SheetWidth,   
    @SheetLength, @CartonsInCase, @CalendarRuntime, @ProductionRuntime,   
    @OperationsRuntime, @TotalUnits, @GoodUnits, @RejectUnits, @LineSpeedTarget,  
    @IdealUnits, @ActualUnits, @OperationsIdealUnits, @RollWidth, @HolidayCurtailDT  
  
  
  
 FETCH NEXT FROM ProdRLinesShiftCursor INTO @@PLId, @@ProdId, @@StartTime,   
             @@EndTime,   
           @@VarGoodUnitsACPTwoId, @@VarGoodUnitsACPOneId,  
           @@VarGoodUnitsHPBundlesId, @@VarGoodUnitsHPCasesId  
END  
CLOSE  ProdRLinesShiftCursor  
DEALLOCATE ProdRLinesShiftCursor  
  
ReturnResultSets:  
  -----------------------------------------------------------------------------  
  -- Return the stops result set for Line.  
  -----------------------------------------------------------------------------  
  SELECT pl.PL_Desc [Line],  
   SUM(CONVERT(FLOAT,td.ReportDowntime)/60.0) - SUM(CASE WHEN td.ScheduleId = @SchedHolidayCurtailId   
               THEN CONVERT(FLOAT,td.ReportDowntime)/60.0  
               ELSE 0 END) [Downtime],  
  
   CASE WHEN ((CONVERT(FLOAT, DATEDIFF(Second, @StartTime, @EndTime)) / 60.0)   
      - SUM(CONVERT(FLOAT,td.ReportDowntime)/60.0)) > 0  
        THEN ((CONVERT(FLOAT, DATEDIFF(Second, @StartTime, @EndTime)) / 60.0)   
      - SUM(CONVERT(FLOAT,td.ReportDowntime)/60.0))  
        ELSE 0 END [Uptime],  
  
   CASE WHEN (CONVERT(FLOAT, DATEDIFF(Second, @StartTime, @EndTime)) / 60.0   
       - SUM(CASE WHEN td.ScheduleId = @SchedHolidayCurtailId   
           THEN CONVERT(FLOAT,td.ReportDowntime)/60.0  
           ELSE 0 END)) > 0  
        AND  (CONVERT(FLOAT, DATEDIFF(Second, @StartTime, @EndTime)) / 60.0   
       - SUM(CONVERT(FLOAT,td.ReportDowntime)/60.0)) > 0  
        THEN (CONVERT(FLOAT, DATEDIFF(Second, @StartTime, @EndTime)) / 60.0   
       - SUM(CONVERT(FLOAT,td.ReportDowntime)/60.0))   
     /(CONVERT(FLOAT, DATEDIFF(Second, @StartTime, @EndTime)) / 60.0   
       - SUM(CASE WHEN td.ScheduleId = @SchedHolidayCurtailId   
           THEN CONVERT(FLOAT,td.ReportDowntime)/60.0  
           ELSE 0 END))  
        ELSE 0 END [Availability],  
  
   Sum(Coalesce(td.Stops, 0)) [Total Stops],  
   Sum(Coalesce(td.StopsUnscheduled, 0)) [Unscheduled Stops],  
   Sum(Coalesce(td.StopsMinor, 0)) [Minor Stops],  
   Sum(Coalesce(td.StopsEquipFails, 0)) [Equipment Failures], --Name change from 'Breakdowns'. FLD 09-15-2003  
   Sum(Coalesce(td.StopsProcessFailures, 0)) [Process Failures],  
   Sum(Coalesce(td.StopsELP, 0)) [ELP Stops],  
     
   ROUND(Sum(CONVERT(FLOAT,Coalesce(td.ReportELPDownTime, 0))/60.0),2) [ELP Minutes],  
  
   CASE WHEN (SUM(CONVERT(FLOAT, DATEDIFF(Second, @StartTime, @EndTime)) / 60.0)   
       - SUM(CONVERT(FLOAT, Coalesce(td.ReportELPSchedDT, 0)) / 60.0))   
        > 0.0 THEN (SUM(CONVERT(FLOAT, Coalesce(td.ReportELPDowntime, 0)) / 60.0)   
      + SUM(CASE WHEN (td.CategoryId = @CatELPId   
                AND StopsRateLoss = 1)  
                --AND PUDesc LIKE '%Converter%')   
          THEN Coalesce(td.ReportRLDowntime, 0)   
          ELSE 0 END))   
      / ((CONVERT(FLOAT, DATEDIFF(Second, @StartTime, @EndTime)) / 60.0)   
         - SUM(CONVERT(FLOAT, Coalesce(td.ReportELPSchedDT, 0)) / 60.0))  
       ELSE 0 END [ELP Percent],  
  
   CASE WHEN (SUM(CONVERT(FLOAT, (CASE WHEN (td.ScheduleId <> @SchedHolidayCurtailId   
          OR td.ScheduleId IS NULL)   
           THEN (Coalesce(td.Stops,0))  
           ELSE 0 END))))   
        > 0 THEN ROUND(1 - ((SUM(CONVERT(FLOAT, (CASE WHEN (td.ScheduleId <> @SchedHolidayCurtailId   
           OR td.ScheduleId IS NULL)   
            AND td.Uptime2m = 1   
            THEN (Coalesce(td.Stops,0))  
            ELSE 0 END))))  
       /(SUM(CONVERT(FLOAT, (CASE WHEN (td.ScheduleId <> @SchedHolidayCurtailId   
            OR td.ScheduleId IS NULL)   
             THEN (Coalesce(td.Stops,0))  
               ELSE 0 END))))), 2)   
        ELSE 0.0 END [R(2)],  
  
   CASE WHEN SUM(CASE WHEN (td.ScheduleId <> @SchedHolidayCurtailId   
       OR td.ScheduleId IS NULL)   
        THEN Coalesce(CONVERT(FLOAT,td.Stops),0)   
        ELSE 0.0 END)   
        > 0 THEN ROUND(CASE WHEN ((CONVERT(FLOAT, DATEDIFF(Second, @StartTime, @EndTime)) / 60.0))   
       - (SUM(CONVERT(FLOAT,td.ReportDowntime)) /60.0)   
       < 0.0 THEN 0  
              ELSE (((CONVERT(FLOAT, DATEDIFF(Second, @StartTime, @EndTime)) / 60.0))  
       - (SUM(CONVERT(FLOAT,td.ReportDowntime)/60.0)))   
              END  
                / SUM(CASE WHEN (td.ScheduleId <> @SchedHolidayCurtailId   
                   OR td.ScheduleId IS NULL)   
                    THEN Coalesce(CONVERT(FLOAT,td.Stops),0)   
                    ELSE 0.0 END),2)   
       ELSE 0 END [MTBF],  
  
   CASE WHEN Sum(CASE WHEN (td.ScheduleId <> @SchedHolidayCurtailId   
       OR td.ScheduleId IS NULL)   
        THEN Coalesce(CONVERT(FLOAT,td.Stops),0)   
        ELSE 0.0 END)   
        > 0 THEN ((SUM(CONVERT(FLOAT,td.ReportDowntime)/60.0))    
            -(SUM(CASE WHEN td.ScheduleId = @SchedHolidayCurtailId   
         THEN CONVERT(FLOAT,td.ReportDowntime)/60.0  
         ELSE 0 END)))   
     / (Sum(CASE WHEN (td.ScheduleId <> @SchedHolidayCurtailId   
         OR td.ScheduleId IS NULL)   
          THEN Coalesce(CONVERT(FLOAT,td.Stops),0)   
          ELSE 0.0 END))  
        ELSE 0.0 END [MTTR],  
  
   SUM(Coalesce(td.StopsRateLoss,0)) [Rate Loss Stops],  
   SUM(CONVERT(FLOAT, Coalesce(td.ReportRLDowntime, 0))) [Rate Loss Downtime],  
  
   CASE WHEN ((CONVERT(FLOAT, DATEDIFF(Second, @StartTime, @EndTime)) / 60.0)   
       - (SUM(CASE WHEN td.ScheduleId = @SchedHolidayCurtailId   
            THEN CONVERT(FLOAT,td.ReportDowntime)/60.0  
            ELSE 0 END)))  
        > 0   
        THEN ((SUM(CONVERT(FLOAT, Coalesce(td.ReportRLDowntime, 0))))   
      / ((CONVERT(FLOAT, DATEDIFF(Second, @StartTime, @EndTime)) / 60.0)  
           - (SUM(CASE WHEN td.ScheduleId = @SchedHolidayCurtailId   
                THEN CONVERT(FLOAT,td.ReportDowntime)/60.0  
                ELSE 0 END))))  
        ELSE 0 END [Rate Loss Percent],  
  
   (CASE WHEN (CONVERT(FLOAT, DATEDIFF(Second, @StartTime, @EndTime)) / 60.0   
       - SUM(CASE WHEN td.ScheduleId = @SchedHolidayCurtailId   
           THEN CONVERT(FLOAT,td.ReportDowntime)/60.0  
           ELSE 0 END)) > 0  
        AND  (CONVERT(FLOAT, DATEDIFF(Second, @StartTime, @EndTime)) / 60.0   
       - SUM(CONVERT(FLOAT,td.ReportDowntime)/60.0)) > 0  
        THEN (CONVERT(FLOAT, DATEDIFF(Second, @StartTime, @EndTime)) / 60.0   
       - SUM(CONVERT(FLOAT,td.ReportDowntime)/60.0))   
     /(CONVERT(FLOAT, DATEDIFF(Second, @StartTime, @EndTime)) / 60.0   
       - SUM(CASE WHEN td.ScheduleId = @SchedHolidayCurtailId   
           THEN CONVERT(FLOAT,td.ReportDowntime)/60.0  
           ELSE 0 END))  
        ELSE 0 END)  
   - (CASE WHEN ((CONVERT(FLOAT, DATEDIFF(Second, @StartTime, @EndTime)) / 60.0)   
       - (SUM(CASE WHEN td.ScheduleId = @SchedHolidayCurtailId   
            THEN CONVERT(FLOAT,td.ReportDowntime)/60.0  
            ELSE 0 END)))  
        > 0   
        THEN ((SUM(CONVERT(FLOAT, Coalesce(td.ReportRLDowntime, 0))))   
      / ((CONVERT(FLOAT, DATEDIFF(Second, @StartTime, @EndTime)) / 60.0)  
           - (SUM(CASE WHEN td.ScheduleId = @SchedHolidayCurtailId   
                THEN CONVERT(FLOAT,td.ReportDowntime)/60.0  
                ELSE 0 END))))  
        ELSE 0 END) [Rate Loss Availability] --Availability - Rate Loss Percent  
  
   FROM  #Delays td  
   JOIN  #ProdUnits pu ON td.PUId = pu.PUId  
   JOIN  Prod_Lines pl ON pu.PLId = pl.PL_Id  
   LEFT  JOIN  Timed_Event_Fault tef on (td.TEFaultID = TEF.TEFault_ID)  
   WHERE td.InRptWindow = 1  
   GROUP BY pl.PL_Desc  
   ORDER BY pl.PL_Desc  
  -----------------------------------------------------------------------------  
  -- Return the production result set for Line.  
  -----------------------------------------------------------------------------  
  SELECT  pl.PL_Desc [Line],  
   CASE WHEN CONVERT(Integer,SUM(pr.TotalUnits)) > 0 THEN   
         CONVERT(Integer,SUM(pr.TotalUnits))   
    ELSE 0 END [Total Units],  
   CASE WHEN CONVERT(Integer,SUM(pr.GoodUnits)) > 0 THEN    
    CONVERT(Integer,SUM(pr.GoodUnits))   
    ELSE 0 END [Good Units],  
   CASE WHEN CONVERT(Integer,SUM(pr.RejectUnits)) > 0   
        THEN CONVERT(Integer,SUM(pr.RejectUnits))  
        ELSE 0 END [Reject Units],  
   CASE WHEN CONVERT(Float,SUM(pr.TotalUnits)) > 0   
        THEN CONVERT(Float,SUM(pr.RejectUnits))   
      / CONVERT(Float,SUM(pr.TotalUnits))  
        ELSE 0 END [Unit Broke],  
   CASE WHEN CONVERT(Integer,SUM(pr.ActualUnits)) IS NULL THEN 0  
    ELSE CONVERT(Integer,SUM(pr.ActualUnits)) END [Actual Stat Cases],  
   CASE WHEN CONVERT(Integer,SUM(pr.IdealUnits)) IS NULL OR CONVERT(Integer,SUM(pr.IdealUnits)) < 0 THEN 0  
    ELSE CONVERT(Integer,SUM(pr.IdealUnits)) END [Reliability Ideal Stat Cases],  
   CONVERT(Integer,SUM(pr.OperationsIdealUnits)) [Operations Ideal Stat Cases],  
   COALESCE ((CASE WHEN SUM(CONVERT(FLOAT,pr.IdealUnits)) > 0   
                   THEN SUM(CONVERT(FLOAT,pr.ActualUnits))   
                 / SUM(CONVERT(FLOAT,pr.IdealUnits))  
                   ELSE 0 END), 0) [CVPR],  
   COALESCE ((CASE WHEN SUM(CONVERT(FLOAT,pr.OperationsIdealUnits)) > 0   
                   THEN SUM(CONVERT(FLOAT,pr.ActualUnits))   
                 / SUM(CONVERT(FLOAT,pr.OperationsIdealUnits))  
                   ELSE 0 END), 0) [Operations Efficiency],  
   COALESCE ((CASE WHEN SUM(pr.ProductionRuntime) > 0   
                   THEN CONVERT(INTEGER,SUM(pr.ActualUnits)   
                 * ((24 * 60) / SUM(pr.ProductionRuntime)))  
                   ELSE 0 END), 0) [Avg Stat CLD]  
   FROM #ProdRecordsShift pr  
   LEFT JOIN Prod_Lines pl ON pr.PLId = pl.PL_Id  
   LEFT JOIN #ProdLines ppl ON pr.PLId = ppl.PLId  
  
   --WHERE ppl.PackOrLine <> 'Pack'  
   GROUP BY pl.PL_Desc, ppl.PackOrLine  
   ORDER BY pl.PL_Desc, ppl.PackOrLine  
  
--Drop Tables.  
 DROP TABLE #ErrorMessages  
 DROP TABLE #ProdUnits  
 DROP TABLE #Delays  
 DROP TABLE #Tests  
 DROP TABLE  #Runs  
 DROP TABLE #ProdLines  
 DROP TABLE  #RunsLine  
 DROP TABLE #ProdRecordsShift  
   
 DROP TABLE #DelayTypes  
 DROP TABLE #Primaries  
  
Finished:  
 RETURN  
  
