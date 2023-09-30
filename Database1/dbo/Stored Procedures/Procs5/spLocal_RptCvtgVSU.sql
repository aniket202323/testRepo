  
  
/************************************************************************  
  
Author:  Steven Stier, Stier-Automation, LLC  
Last Update: 2009-05-27 Rev1.00  
  
Update History:  
  
2009-04-21 Steven Stier - Original  
2009-06-16 Steven Stier - Rollout  
2009-06-22 Steven Stier - Changed to show all product when @ReturnINProductGroup = 0  
2009-07-01 Steven Stier - need to return all production dates since the VSU Start date.  
2009-07-09 Steven Stier -  Fixed errors not sorting my Production Date on join and Get Min time stamp if not found  
------------------------------------------------------------------------------------------------------------  
-- SP sections:  [Note that additional comments can be found in each section.]  
------------------------------------------------------------------------------------------------------------  
  
Section 1:  Declare testing parameters.  
Section 2:  Declare variables  
Section 3:  Declare the table variables for the data  
Section 4:  Get @RawData  
Section 5:  Get @Results  
*************************************************************************/  
  
CREATE PROCEDURE [dbo].[spLocal_RptCvtgVSU]  
--declare  
 @LangID int,  
 @VSUStartDate  DATETIME,  
 @Line  varchar(100),  
 @ProductGroupList varchar(4000),  -- Collection of ProductGroups for converting lines delimited by "|".  
 @ReturnINProductGroup varchar(50) -- Should i return the data for only the times when the line ran a qualified product  
  
AS  
  
  
-------------------------------------------------------------------------------  
-- Control settings  
-------------------------------------------------------------------------------  
SET ANSI_WARNINGS OFF  
SET NOCOUNT ON  
  
-------------------------------------------------------------------------------  
-- Section 1: Declare testing parameters.  
-------------------------------------------------------------------------------  
  
/* Test  
  
SELECT   
 @LangID = 1,  
 @VSUStartDate = '2009-03-17 00:00:00',  
 @Line = 'TT AT08',  
 --@ProductGroupList = 'All',  -- Collection of ProductGroups for converting lines delimited by "|".  
 @ProductGroupList = 'CH Ultra Lexus 1-0 Mega Roll',  
 --@ProductGroupList = 'BTY MACH 5 Red Cal [All]',   
 --@ProductGroupList = 'BTY MACH 5 Red Cal [All]|BTY MACH 5 [All]',  
 --@ProductGroupList = 'xx',  
 @ReturnINProductGroup = '0'  
  
--exec spLocal_RptCvtgVSU 1,'2009-03-17 00:00:00','TT AT08','CH Ultra Lexus 1-0 Mega Roll','0'   
  
  
  
  
*/  
-- exec spLocal_RptCvtgVSU 1,'2009-03-01 00:00:00','TT OKK1','BTY MACH 5 [All]','1'  
  
--print 'start' + ' ' + convert(varchar(25),current_timestamp,108)  
  
--------------------------------------------------------  
-- Section 2: Declare variables  
--------------------------------------------------------  
  
declare  
  
@TimeDimID_Day      int,  
@SQL        nVARCHAR(4000),  
@now         datetime,  
@Plant        varchar(50),  
@DayType       varchar(50),  
@MinProductionDate     datetime,  
@Loopstarttime datetime,  
@Loopendtime datetime  
--  
-- @DayType variable is used to Indicate if we are using the  
-- 'Shiftday' or 'CalanderDay' Time slice  
--  
  
Select @DayType = 'CalendarDay'  
  
  
--print 'declare tables' + ' ' + convert(varchar(25),current_timestamp,108)  
  
----------------------------------------------------------------------------------  
-- Section 3: Declare table variables for the data  
----------------------------------------------------------------------------------  
  
declare @RawData table  
(  
 Line     varchar(50),  
 Team     varchar(10),  
 ProdGroup2    varchar(50),  
 ProdCode    varchar(25),  
 ProdDesc    varchar(50),   
 Linestatus    varchar(50),  
 ProductionDate   dateTime,  
 ProductionRuntime  float,   
 CvtgActualCases   float,   
 CvtgTargetCases   float,   
 StopsUnscheduledWndr int,   
 splitUnscheduledDT  float,   
 SplitUptime    float,  
 consumerELPDT   float,   
 ConsumerRLELPDT   float,   
 ConsumerPaperRT   float,   
 BrokeScrapNumerator  float,   
 BrokeScrapDenominator float,  
 BrokeScrapOffset  float)  
  
declare @Results table  
(   ProductionDate   dateTime,  
 ProductionRuntime  float,   
 CvtgActualCases  float,  
 CvtgTargetCases  float,  
 StopsUnscheduledWndr  float,  
 UptimeandUnscheduledDT  float,  
 BrokeScrapNumerator  float,  
 BrokeScrapDenominator  float,  
 AvgBrokeScrapeOffset  float,  
 ConsumerPaperRT  float,  
 ConsumerELPDTandConsumerRLELPDT  float)  
  
Declare @ProductionDates table  
(   ProductionDate   dateTime)  
  
  
select @now = getdate()  
  
--  
-- Get the TimeID for the Daytime timeslice we are looking for Either 'CalanderDay' or 'Shiftday'  
--  
SELECT @TimeDimID_Day = TimeDim_Id   
 FROM dbo.Local_PGMfg_TimeDim with (nolock)  
 WHERE TimeDim_Desc = @DayType  
  
---------------------------------------------------------------------  
-- Section 4: Get @RawData  
---------------------------------------------------------------------  
  
--print ' Get @RawData' + ' ' + convert(varchar(25),current_timestamp,108)  
--  
-- If the data requested is the In the Product Group List selected than   
--  use that selection in the query else get all the other data  
--  
If @ReturnINProductGroup = '1'  
 BEGIN  
  -- Get the Data from the Original Flat file  
  INSERT @RawData   
    (Line,  
    Team,  
    ProdGroup2,  
    ProdCode,  
    ProdDesc,   
    Linestatus,  
    ProductionDate,  
    ProductionRuntime,   
    CvtgActualCases,   
    CvtgTargetCases,   
    StopsUnscheduledWndr,   
    splitUnscheduledDT,   
    SplitUptime,  
    consumerELPDT,   
    ConsumerRLELPDT,   
    ConsumerPaperRT,   
    BrokeScrapNumerator,   
    BrokeScrapDenominator,  
    BrokeScrapOffset  
    )  
  Select Line,  
    Team,  
    ProdGroup2,  
    ProdCode,  
    ProdDesc,   
    Linestatus,  
    convert(datetime,TimeFrame),  
    ProductionRuntime,   
    CvtgActualCases,   
    CvtgTargetCases,   
    StopsUnscheduledWndr,   
    splitUnscheduledDT,   
    SplitUptime,  
    consumerELPDT,   
    ConsumerRLELPDT,   
    ConsumerPaperRT,   
    BrokeScrapNumerator,   
    BrokeScrapDenominator,  
    BrokeScrapOffset  
   FROM Local_PGMfg_MetricValueFlat  WITH(NOLOCK)  
   WHERE  Team <> 'ALL'  
     and CvtgTargetCases <> 0     
     and ProdGroup2 <> 'ALL'   
     and TimeDimID = @TimeDimID_Day     
     and PUDESC like '%Converter%'   
     and Linestatus like '%PR In:%'   
     and convert(datetime,TimeFrame) >= @VSUStartDate   
     and Line = @Line   
     and (CHARINDEX('|' + ProdGroup2 + '|','|' + @ProductGroupList + '|') > 0  
      OR  @ProductGroupList = 'All')  
   ORDER BY timeframe  
     
     
   -- To DO Check for existinace of table  
   if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[Local_PGMfg_MetricValueFlat_VSU]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)  
   BEGIN  
    -- Get the Minimum Production Date from the data  
    Select @MinProductionDate = (Select Min(ProductionDate) from @RawData)  
      
    IF coalesce(@MinProductionDate,0) = 0   
     BEGIN  
      Select @MinProductionDate = @now  
     END  
   INSERT @RawData   
    (Line,  
    Team,  
    ProdGroup2,  
    ProdCode,  
    ProdDesc,   
    Linestatus,  
    ProductionDate,  
    ProductionRuntime,   
    CvtgActualCases,   
    CvtgTargetCases,   
    StopsUnscheduledWndr,   
    splitUnscheduledDT,   
    SplitUptime,  
    consumerELPDT,   
    ConsumerRLELPDT,   
    ConsumerPaperRT,   
    BrokeScrapNumerator,   
    BrokeScrapDenominator,  
    BrokeScrapOffset)  
    Select Line,  
     Team,  
     ProdGroup2,  
     ProdCode,  
     ProdDesc,   
     Linestatus,  
     convert(datetime,TimeFrame),  
     ProductionRuntime,   
     CvtgActualCases,   
     CvtgTargetCases,   
     StopsUnscheduledWndr,   
     splitUnscheduledDT,   
     SplitUptime,  
     consumerELPDT,   
     ConsumerRLELPDT,   
     ConsumerPaperRT,   
     BrokeScrapNumerator,   
     BrokeScrapDenominator,  
     BrokeScrapOffset  
    FROM Local_PGMfg_MetricValueFlat_VSU  WITH(NOLOCK)  
    WHERE  Team <> 'ALL'  
      and CvtgTargetCases <> 0     
      and ProdGroup2 <> 'ALL'   
      and TimeDimID = @TimeDimID_Day     
      and PUDESC like '%Converter%'   
      and Linestatus like '%PR In:%'   
      and convert(datetime,TimeFrame) >= @VSUStartDate   
      and convert(datetime,TimeFrame) < @MinProductionDate  
      and Line = @Line   
      and (CHARINDEX('|' + ProdGroup2 + '|','|' + @ProductGroupList + '|') > 0  
       OR  @ProductGroupList = 'All')  
    ORDER BY timeframe  
   END  
  
  
  END  
 ELSE  
  BEGIN  
  
   INSERT @RawData   
    (Line,  
    Team,  
    ProdGroup2,  
    ProdCode,  
    ProdDesc,   
    Linestatus,  
    ProductionDate,  
    ProductionRuntime,   
    CvtgActualCases,   
    CvtgTargetCases,   
    StopsUnscheduledWndr,   
    splitUnscheduledDT,   
    SplitUptime,  
    consumerELPDT,   
    ConsumerRLELPDT,   
    ConsumerPaperRT,   
    BrokeScrapNumerator,   
    BrokeScrapDenominator,  
    BrokeScrapOffset  
    )  
  Select Line,  
    Team,  
    ProdGroup2,  
    ProdCode,  
    ProdDesc,   
    Linestatus,  
    convert(datetime,TimeFrame),  
    ProductionRuntime,   
    CvtgActualCases,   
    CvtgTargetCases,   
    StopsUnscheduledWndr,   
    splitUnscheduledDT,   
    SplitUptime,  
    consumerELPDT,   
    ConsumerRLELPDT,   
    ConsumerPaperRT,   
    BrokeScrapNumerator,   
    BrokeScrapDenominator,  
    BrokeScrapOffset  
   FROM Local_PGMfg_MetricValueFlat  WITH(NOLOCK)  
   WHERE  Team <> 'ALL'   
    and CvtgTargetCases <> 0   
    and ProdGroup2 <> 'ALL'   
    and TimeDimID = @TimeDimID_Day     
    and PUDESC like '%Converter%'   
    and Linestatus like '%PR In:%'   
    and convert(datetime,TimeFrame) >= @VSUStartDate  
    and Line = @Line   
    --and NOT ((CHARINDEX('|' + ProdGroup2 + '|','|' + @ProductGroupList + '|') > 0  
    --      OR  @ProductGroupList = 'All'))  
   ORDER BY timeframe  
  
  
      
   -- To DO Check for existinace of table  
   if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[Local_PGMfg_MetricValueFlat_VSU]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)  
   BEGIN  
    -- Get the Minimum Production Date from the data  
    Select @MinProductionDate = (Select Min(ProductionDate) from @RawData)  
      
    IF coalesce(@MinProductionDate,0) = 0   
     BEGIN  
      Select @MinProductionDate = @now  
     END  
  
     INSERT @RawData   
    (Line,  
    Team,  
    ProdGroup2,  
    ProdCode,  
    ProdDesc,   
    Linestatus,  
    ProductionDate,  
    ProductionRuntime,   
    CvtgActualCases,   
    CvtgTargetCases,   
    StopsUnscheduledWndr,   
    splitUnscheduledDT,   
    SplitUptime,  
    consumerELPDT,   
    ConsumerRLELPDT,   
    ConsumerPaperRT,   
    BrokeScrapNumerator,   
    BrokeScrapDenominator,  
    BrokeScrapOffset)  
    Select Line,  
     Team,  
     ProdGroup2,  
     ProdCode,  
     ProdDesc,   
     Linestatus,  
     convert(datetime,TimeFrame),  
     ProductionRuntime,   
     CvtgActualCases,   
     CvtgTargetCases,   
     StopsUnscheduledWndr,   
     splitUnscheduledDT,   
     SplitUptime,  
     consumerELPDT,   
     ConsumerRLELPDT,   
     ConsumerPaperRT,   
     BrokeScrapNumerator,   
     BrokeScrapDenominator,  
     BrokeScrapOffset  
    FROM Local_PGMfg_MetricValueFlat_VSU  WITH(NOLOCK)  
    WHERE  Team <> 'ALL'  
      and CvtgTargetCases <> 0     
      and ProdGroup2 <> 'ALL'   
      and TimeDimID = @TimeDimID_Day     
      and PUDESC like '%Converter%'   
      and Linestatus like '%PR In:%'   
      and convert(datetime,TimeFrame) >= @VSUStartDate   
      and convert(datetime,TimeFrame) < @MinProductionDate  
      and Line = @Line   
      --and NOT ((CHARINDEX('|' + ProdGroup2 + '|','|' + @ProductGroupList + '|') > 0  
         -- OR  @ProductGroupList = 'All'))  
    ORDER BY timeframe  
   END  
 END  
  
  
  
  
--Select * from @RawData  
  
select  
@Loopstarttime = convert(datetime,convert(varchar(10),@VSUStartDate,101)),  
@Loopendtime = convert(datetime,convert(varchar(10),getdate(),101))  
   
while @LoopStartTime < @LoopEndTime  
begin  
   
    insert @ProductionDates  
    (  
        [ProductionDate]  
    )  
    select   
        convert(datetime,convert(varchar(10),@LoopStartTime,101))  
   
    select @LoopStartTime = dateadd(dd,1,@LoopStartTime)  
   
end  
  
  
  
---------------------------------------------------------------------  
--  Section 5:  Join the  @Results with the raw data  
---------------------------------------------------------------------  
Insert @Results  
 ([ProductionDate],  
 [ProductionRuntime],  
 [CvtgActualCases],  
 [CvtgTargetCases],  
 [StopsUnscheduledWndr],  
 [UptimeandUnscheduledDT],  
 [BrokeScrapNumerator],  
 [BrokeScrapDenominator],  
 [AvgBrokeScrapeOffset],  
 [ConsumerELPDTandConsumerRLELPDT],  
 [ConsumerPaperRT]  
 )  
 SELECT  
  convert(datetime,left(ProductionDate,11),120) [ProductionDate],  
  SUM(CONVERT(float,ProductionRunTime))/3600.00 [ProductionRuntime],  
  SUM(CONVERT(float,COALESCE(CvtgActualCases,0))) [CvtgActualCases],  
  SUM(CONVERT(float,COALESCE(CvtgTargetCases,0))) [CvtgTargetCases],  
  SUM(COALESCE(StopsUnscheduledWndr,0) * 24.0) [StopsUnscheduledWndr],  
  SUM(COALESCE(SplitUptime,0) + COALESCE(SplitUnscheduledDT,0.0))/3600.0 [UptimeandUnscheduledDT],  
  SUM(CONVERT(float,COALESCE(BrokeScrapNumerator,0))) [BrokeScrapNumerator],  
  SUM(CONVERT(float,COALESCE(BrokeScrapDenominator,0))) [BrokeScrapDenominator],  
  AVG(COALESCE(BrokeScrapOffset,0)) [AvgBrokeScrapeOffset],  
  SUM(CONVERT(float, COALESCE(ConsumerELPDT,0.0)) + CONVERT(float, COALESCE(ConsumerRLELPDT,0.0))) [ConsumerELPDTandConsumerRLELPDT],   
  SUM(CONVERT(float, COALESCE(ConsumerPaperRT,0.0))) [ConsumerPaperRT]  
 FROM @RawData  
 GROUP BY [ProductionDate]  
 ORDER BY [ProductionDate]  
  
  
SELECT pd.ProductionDate,  
 r.ProductionRuntime,  
 r.CvtgActualCases,  
 r.CvtgTargetCases,  
 r.StopsUnscheduledWndr,  
 r.UptimeandUnscheduledDT,  
 r.BrokeScrapNumerator,  
 r.BrokeScrapDenominator,  
 r.AvgBrokeScrapeOffset,  
 r.ConsumerELPDTandConsumerRLELPDT,  
 r.ConsumerPaperRT FROM @Results r  
 Right Join @ProductionDates pd on r.ProductionDate = pd.ProductionDate  
 ORDER BY pd.ProductionDate  
  
  
RETURN  
