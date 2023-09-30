 /*    
------------------------------------------------------------------------------------------------------------------  
------------------------------------------------------------------------------------------------------------------  
-- Version 1.0 Created: 2005-08-15 Jeff Jaeger  
------------------------------------------------------------------------------------------------------------------  
------------------------------------------------------------------------------------------------------------------  
  
This report generates a daily summary of various forms of energy used (steam, gas, oil, electricity, air, and water)   
by Paper Machine / Product.    
  
This sp will be called by RptEnergyDaySum.xlt   
  
  
------------------------------------------------------------------  
-- Calculations used in the result sets of this SP:  
------------------------------------------------------------------  
  
Eff. by PM:  
Steam Efficiency = sum(Total Steam) / sum(Total TAY)  
Total Steam Efficiency Tgt = sum(Total Steam by product * Total TAY by product) / sum(Total TAY)  
Gas Efficiency = sum(Total Gas) / sum(Total TAY)  
Total Gas Efficiency Tgt = sum(Total Gas by product * Total TAY by product) / sum(Total TAY)  
Oil Efficiency = sum(Total Oil) / sum(Total TAY)  
Total Oil Efficiency Tgt = sum(Total Oil by product * Total TAY by product) / sum(Total TAY)  
Air Efficiency = sum(Total Air) / sum(Total TAY)  
Total Air Efficiency Tgt = sum(Total Air by product * Total TAY by product) / sum(Total TAY)  
  
Total by PM:  
Drying Energy =   
(sum(Steam Usage) + Sum(Gas Usage) + sum(Oil Usage) + sum(Air Usage) + sum(Electricity Usage))/sum(Total TAY)  
  
Stm by PM:  
Steam Efficiency = sum(Total Steam) / sum(Total Tay)  
Total Steam Efficiency Tgt = sum(Total Steam by product * Total TAY by product) / sum(Total TAY)  
Avg Draw = sum(Total Steam) / sum(Hrs by product)  
Avg Draw = sum(Total Steam) / Hrs in report window  
  
Gas by PM:  
Gas Efficiency = sum(Total Gas) / sum(Total Tay)  
Total Gas Efficiency Tgt = sum(Total Gas by product * Total TAY by product) / sum(Total TAY)  
Avg Flow = sum(Total Gas) / sum(Hrs by product)  
Avg Flow = sum(Total Gas) / Hrs in report window  
  
Oil by PM:  
Oil Efficiency = sum(Total Oil) / sum(Total Tay)  
Total Oil Efficiency Tgt = sum(Total Oil by product * Total TAY by product) / sum(Total TAY)  
Avg Flow = sum(Total Oil) / sum(Hrs by product)  
Avg Flow = sum(Total Oil) / Hrs in report window  
  
Air by PM:  
Air Efficiency = sum(Total Air) / sum(Total Tay)  
Total Air Efficiency Tgt = sum(Total Air by product * Total TAY by product) / sum(Total TAY)  
HOt Air Efficiency = sum(Total Hot Air) / sum(Total Tay)  
Total Hot Air Efficiency Tgt = sum(Total Hot Air by product * Total TAY by product) / sum(Total TAY)  
Avg Flow = sum(Total Air) / sum(Hrs by product)  
Avg Flow = sum(Total Air) / Hrs in report window  
  
Electricity by PM:  
Electricity Efficiency = sum(Total Electricity) / sum(Total Tay)  
Total Electricity Efficiency Tgt = sum(Total Electricity by product * Total TAY by product) / sum(Total TAY)  
Avg Rate = sum(Total Electricity) / sum(Hrs by product)  
Avg Rate = sum(Total Electricity) / Hrs in report window  
  
Finance:  
Steam Efficiency = sum(Total Steam) / sum(Good Tonnes)   
Electricity Efficiency = sum(Total Electricity) / sum(Good Tonnes)  
Gas Efficiency = sum(Total Gas) / sum(Good Tonnes)  
  
Boiler Eff:  
Oil gpm = sum(Total Oil / report window in minutes)  
Efficiency % = sum(BTU In) / sum(BTU Out)  
Efficiency Tgt % = target value / 100  
Condensate Return % = (sum(Condensate Return) / sum(Total Steam for all boilers)) * 100  
  
  
------------------------------------------------------------------  
-- SP sections:  
------------------------------------------------------------------  
  
Additional comments can be found in each section.  
  
Section 1:  Declare program variables  
Section 2:  Declare table variables and temp tables  
Section 3:  Assign constant values  
Section 4:  Get local language ID  
Section 5:  Initialize temporary tables.  This minimizes recompiles.  
Section 6:  Check Input Parameters to make sure they are valid.  
Section 7:  Get the input parameter values out of the database  
Section 8:  Get information for ProdUnitList  
Section 9:  Get Production Starts  
Section 10: Populate the test table  
Section 11: If there are Error Messages, then return them without other result sets.  
Section 12: Results Set #1 - Return the empty Error Messages.    
Section 13: Results Set #2 -  return the report parameter values.  
Section 14: Results Set #3 & 4 - Return the result set for Eff Summary  
Section 15: Results Set #5 & 6 - Return the second result set for Eff Summary  
Section 16: Results Set #7 & 8 - Return the result set for PM Summary  
Section 17: Results Set #9 & 10 - Return the result set for Steam Summary  
Section 18: Results Set #11 & 12 - Return the result set for Gas Summary  
Section 19: Results Set #13 & 14 - Return the result set for Oil Summary  
Section 20: Results Set #15 & 16 - Return the result set for Air Summary  
Section 21: Results Set #17 & 18 - Return the result set for Electricity Summary  
Section 22: Results Set #19 & 20 - Return the result set for Finance Summary  
Section 23: Results Set #21 & 22 - Return the result set for Boiler Summary  
Section 24: Results Set #23 - Return the result set for Condensate Summary  
Section 25: Drop temp tables  
  
  
--------------------------------------------------------  
--  Edit History:  
--------------------------------------------------------  
  
/*  
  
2005-08-29 Jeff Jaeger Rev1.01   
- corrected the calc for Efficiency % to be BTU Out / BTU IN, instead of the other way around.  
- updated Condensate Return %, Efficiency %, and Efficiency % Tgt by adding / 100.  This was done because   
the template will format these columns as %.  
- corrected Efficiency % Tgr to use the target lower limit instead of the target upper limit.   
- cleaned up most of the dead code left over from initial development.     
  
2005-09-01 Jeff Jaeger Rev1.02  
-  adjusted the insert to @Tests so that result_on > @StartTime, not result_on >= @StartTime  
-  added lowerreject, target, and upperreject to #tests, and populated them from @targets.  then changed the way  
 that materials efficiency targets are pulled in the result sets.  they now take the max spec value instead of   
 doing a subquery against @tagets.  
  
2005-09-13 Jeff Jaeger Rev1.03  
- updated the values assigned to the last field in the totals for boiler efficiency, which will be Efficiency % Tgt  
in the xlt.  the value was null, but is now pulled from the result in @targets, where vartype is 'TOTALBOILEREFFICIENCYHR'  
-  corrected the method for assigning target values to test results.  
  
2005-09-15 Jeff Jaeger Rev1.04  
- moved the finance result sets to second to last.  
- added new Eff. Summary result sets.  
- added Drying Energy column to Total by PM results  
- added the Hot Air columns to Air by PM results  
- added calc for Efficiency Totals in totals for Steam, Gas, Oil, Air, and Elect.  
- updated the calcs for Avg Draw, Avg Flow, and Avg Rate for individual products on the sheets in which they appear.  
  
2005-09-21 Jeff Jaeger Rev1.05  
- updated the start and end times for @productionstarts.  
- corrected the calc for Avg Flow, Avg Draw, and Avg Rate in the base result sets (not the totals result sets).  
- corrected the calc for Efficiency Tgt %  
- updated comments and calc documentation.  
  
2005-09-27 Jeff Jaeger Rev1.06  
- updated datediff functions in the result sets where number of hours (hh) was being calculated.  changed this to   
 number of seconds (ss) with a division by 3600.0.  This was done so that the datediff result would not be an   
 integer.  when less than an hour was returned, it was being rounded to zero, causing a divide by zero error.  
- added a join to @productionstarts in Efficiency by PM and Totals by PM result sets  
- made the joins to @productionstarts in the result sets a LEFT join in order to pull in all test values  
- added Brand Date to result sets with Brand, so that result order can include the start date of the Brands.  
- added the second result set for Efficiency by PM and related total results.  
  
2005-09-30 Jeff Jaeger Rev1.07  
- corrected the calc for Avg Flow, Avg Draw, and Avg Rate in the base result sets (not the totals result sets).  
the summation around the division needed to be done separately on the numerator and the denominator.  
  
2005-10-03 Jeff Jaeger Rev1.08  
- another correction to Avg Flow, Avg Draw, and Avg Rate.  
  
2005-10-03 Jeff Jaeger Rev1.09  
- made a correction to Avg Draw for the Steam result set.  
  
2005-10-05 Jeff Jaeger Rev1.10  
- in the summary of totals, made the default of all efficiency targets NULL instead of zero.  
  
2005-10-06 Jeff Jaeger Rev1.11  
- corrected the check for BTU Out / BTU In  
  
2005-10-10 Jeff Jaeger Rev1.12  
 - Changed StartTime in #tests to ResultOn.  
 - Corrected date comparisons when referencing the #tests table.  
  
  
*/  
  
----------------------------------------------------------------------------------------------------------  
----------------------------------------------------------------------------------------------------------  
*/  
  
CREATE PROCEDURE dbo.spLocal_RptEnergyDaySum  
--declare  
  @StartTime  DATETIME,  -- Beginning period for the data.  
 @EndTime   DATETIME,  -- Ending period for the data.  
 @RptName   VARCHAR(100) -- Report_Definitions.RP_Name  
  
AS  
  
  
-------------------------------------------------------------------------------  
-- Control settings  
-------------------------------------------------------------------------------  
SET ANSI_WARNINGS OFF  
  
  
-------------------------------------------------------------------------------  
-- Declare testing parameters.  
-------------------------------------------------------------------------------  
  
  
/* MP  
  
SELECT    
@StartTime = '2005-10-06 00:00:00',   
@EndTime = '2005-10-07 00:00:00',   
@RptName = 'Energy Daily Summary Wed 0000 2400'  
  
*/  
  
-------------------------------------------------------------------------------  
-- Section 1:  Declare program variables  
-------------------------------------------------------------------------------  
  
declare   
  
-- for development testing  
@ProdLineList     varchar(4000),  
  
-- for report parameters  
@UserName      VARCHAR(30),  -- User calling this report  
@RptTitle      VARCHAR(300),  -- Report title from Web Report.  
@RptPageOrientation   VARCHAR(50),  -- Report Page Orientation from Web Report.  
@RptPageSize     VARCHAR(50),   -- Report page Size from Web Report.  
@RptPercentZoom    INTEGER,    -- Percent Zoom from Web Report.  
@RptTimeout      VARCHAR(100),  -- Report Time from Web Report.  
@RptFileLocation    VARCHAR(300),  -- Report file location from WEb Report.  
@RptConnectionString   VARCHAR(300),  -- Connection String from Web Report.  
-- for Variable descriptions  
@ExtInfoTag      varchar(50),  
-- for language translation  
@LanguageId      INTEGER,  
@UserId       INTEGER,  
@LanguageParmId    INTEGER,  
-- for dynamic SQL  
@i         int,  
-- for result set validation  
@NoDataMsg       VARCHAR(100),  
@TooMuchDataMsg     VARCHAR(100)  
  
  
-----------------------------------------------------------------------------  
-- Section 2: Declare table variables and temp tables  
-----------------------------------------------------------------------------  
  
-----------------------------------------------------------------------------  
-- This table will hold all information needed about the paper machines  
-----------------------------------------------------------------------------  
  
-------------------------------------------------------------------------------  
-- Error Messages  
-------------------------------------------------------------------------------  
DECLARE @ErrorMessages TABLE ( ErrMsg VARCHAR(255) )  
  
  
-----------------------------------------------------------------------  
-- this table will hold Prod Lines data for Converting lines  
-----------------------------------------------------------------------  
  
DECLARE @ProdLines TABLE   
 (  
 PLId             INTEGER PRIMARY KEY,  
 PLDesc            VARCHAR(100),  
 ExtendedInfo          VARCHAR(255)  
 )  
  
  
-----------------------------------------------------------------------  
-- this table will hold Prod Units data for Converting lines  
-----------------------------------------------------------------------  
  
DECLARE @ProdUnits TABLE   
 (  
 PUId             INTEGER PRIMARY KEY,  
 PUDesc            VARCHAR(100),  
 masterunit           int,  
 PLId             INTEGER,  
 ExtendedInfo          VARCHAR(255),  
 PUType            varchar(20)  
 )  
  
  
---------------------------------------------------------------------------  
-- This table will hold all test results  
---------------------------------------------------------------------------  
  
---------------------------------------------------------------  
-- @ProductionStarts will hold the Production Starts information  
-- along with related product information  
---------------------------------------------------------------  
  
declare @ProductionStarts table  
 (  
 Start_Time           datetime,  
 End_Time            datetime,  
 Prod_ID            int,  
 Prod_Code           varchar(50),  
 Prod_Desc           varchar(50),  
 PU_ID             int--,  
 primary key (pu_id, prod_id, start_time)  
 )  
  
  
declare @Variables table  
 (  
 VarID             int,  
 VarDesc            varchar(100),  
 PUID             int,  
 ExtendedInfo          varchar(255)  
 primary key (varid)  
 )  
  
  
declare @Targets table  
 (  
 varid             int,  
 vardesc            varchar(100),  
 puid             int,  
 prodid            int,  
 starttime           datetime,  
 endtime            datetime,  
 lowerreject           float,  
 --target            float,  
 upperreject           float,  
 VarType            varchar(50)  
 )  
  
  
create table dbo.#Tests   
 (  
 VarId             INTEGER,  
 PUId             INTEGER,  
 ProdId            INTEGER,  
 ProdCode            VARCHAR(50),  
 Value             float,  
 VarType            varchar(50),  
 lowerreject           float,  
 --target            float,  
 upperreject           float,        
 ResultOn            DATETIME,  
 primary key (varid, resulton)  
 )  
  
  
declare @EffSummary table  
 (  
 [PM]             varchar(50),  
 [Brand]            varchar(50),  
 [Steam Eff. (Mlbs/TAY)]       float,  
 [Steam Eff. Trgt. (Mlbs/TAY)]     float,  
 [Gas Eff. (Mscf/TAY)]       float,  
 [Gas Eff. Trgt. (Mscf/TAY)]     float,  
 [Oil Eff. (gal/TAY)]        float,  
 [Oil Eff. Trgt. (gal/TAY)]      float,  
 [Air Eff. (Mlbs/TAY)]       float,  
 [Air Eff. Trgt. (Mlbs/TAY)]     float,  
 [Yankee (TAY)]          float,  
 [Brand Date]          datetime  
 )  
  
  
declare @EffSummary2 table  
 (  
 [PM]             varchar(50),  
 [Brand]            varchar(50),  
 [Hot Air Eff. (Mlbs/TAY)]      float,  
 [Hot Air Eff. Trgt. (Mlbs/TAY)]    float,  
 [Electricity Eff. (kWh/TAY)]     float,  
 [Electricity Eff. Trgt. (kWh/TAY)]   float,  
 [Yankee (TAY)]          float,  
 [Drying Energy (MMBTU/TAY)]     float,  
 [Downtime (Mins)]         float,  
 [Brand Date]          datetime  
 )  
  
  
declare @PMSummary table  
 (  
 [PM]             varchar(50),  
 [Brand]            varchar(50),  
 [Total Steam (Mlbs)]        float,  
 [Total Gas (Mscf)]        float,  
 [Turbine Air (Mlbs)]        float,  
 [Total Electricity (kWh)]      float,  
 [Total Oil (gal)]         float,  
 [Yankee (TAY)]          float,  
 [Drying Energy (MMBTU/TAY)]     float,  
 [Downtime (Mins)]         float,  
 [Brand Date]          datetime  
 )  
  
  
declare @SteamSummary table   
 (  
 [PM]             varchar(50),  
 [Brand]            varchar(50),  
 [Steam Eff. (Mlbs/TAY)]       float,  
 [Steam Eff. Trgt. (Mlbs/TAY)]     float,  
 [Total Steam (Mlbs)]        float,  
 [Yankee (TAY)]          float,  
 [Avg Draw (Mlbs/hr)]        float,  
 [Downtime (Mins)]         float,  
 [Brand Date]          datetime  
 )  
  
  
declare @GasSummary table   
 (  
 [PM]             varchar(50),  
 [Brand]            varchar(50),  
 [Gas Eff. (Mscf/TAY)]       float,  
 [Gas Eff. Trgt. (Mscf/TAY)]     float,  
 [Total Gas (Mscf)]        float,  
 [Yankee (TAY)]          float,  
 [Avg Flow (Mscf/hr)]        float,  
 [Downtime (Mins)]         float,  
 [Brand Date]          datetime  
 )  
  
  
declare @OilSummary table   
 (  
 [PM]             varchar(50),  
 [Brand]            varchar(50),  
 [Oil Eff. (gal/TAY)]        float,  
 [Oil Eff. Trgt. (gal/TAY)]      float,  
 [Total Oil (gal)]         float,  
 [Yankee (TAY)]          float,  
 [Avg Flow (gal/hr)]        float,  
 [Downtime (Mins)]         float,  
 [Brand Date]          datetime  
 )  
  
  
declare @AirSummary table   
 (  
 [PM]             varchar(50),  
 [Brand]            varchar(50),  
 [Air Eff. (Mlbs/TAY)]       float,  
 [Air Eff. Trgt. (Mlbs/TAY)]     float,  
 [Total Air (Mlbs)]        float,  
 [Hot Air Eff. (Mlbs/TAY)]      float,   
 [Hot Air Eff. Trgt. (Mlbs/TAY)]    float,   
 [Total Hot Air (Mlbs)]       float,  
 [Yankee (TAY)]          float,  
 [Avg Flow (Mlbs/hr)]        float,  
 [Downtime (Mins)]         float,  
 [Brand Date]          datetime  
 )  
  
  
declare @ElectricitySummary table   
 (  
 [PM]             varchar(50),  
 [Brand]            varchar(50),  
 [Electricity Eff. (kWh/TAY)]     float,  
 [Electricity Eff. Trgt. (kWh/TAY)]   float,  
 [Total Electricity (kWh)]      float,  
 [Yankee (TAY)]          float,  
 [Avg Rate (kWh/hr)]        float,  
 [Downtime (Mins)]         float,  
 [Brand Date]          datetime  
 )  
  
  
declare @FinanceSummary table   
 (  
 [PM]             varchar(50),  
 [Brand]            varchar(50),  
 [Good Tonnes (tonnes)]       float,  
 [Total Steam (MMlbs)]       float,  
 [Steam Eff. (MMlbs/tonnes)]     float,  
 [Total Electricity (kWh)]      float,  
 [Electricity Eff. (kWh/tonnes)]    float,  
 [Total Gas (Mscf)]        float,  
 [Gas Eff. (Mscf/tonnes)]      float,  
 [Brand Date]          datetime  
 )  
  
  
declare @BoilerSummary table   
 (  
 [Boiler]            varchar(50),  
 [Feedwater (Mlbs)]        float,  
 [Steam (Mlbs)]          float,  
 [Gas (Mscf)]          float,  
 [Oil (gal)]           float,  
 [Oil (gpm)]           float,  
 [Solid Fuel (tons)]        float,  
 [BTU In]            float,  
 [BTU Out]           float,  
 [Efficiency %]          float,  
 [Efficiency % Tgt]        float  
 )  
  
  
declare @CondensateSummary table  
 (  
 [RO Total Flow (Mlbs)]       float,  
 [Vent Steam (Mlbs)]        float,  
 [Condensate Return (Mlbs)]      float,  
 [Condensate Return %]       float  
 )  
  
  
declare @SumTotals table   
 (  
 PM              varchar(50),  
 Total1            float,  
 Total2            float,  
 Total3            float,  
 Total4            float,  
 Total5            float,  
 Total6            float,  
 Total7            float,  
 Total8            float,  
 Total9            float,  
 Total10            float  
 )  
  
  
-------------------------------------------------------------------------------  
-- Section 3: Assign constant values  
-------------------------------------------------------------------------------  
  
select  
@ExtInfoTag   = 'NRGSumRpt=',  
@NoDataMsg    = GBDB.dbo.fnLocal_GlblTranslation('NO DATA meets the given criteria', @LanguageId),  
@TooMuchDataMsg  = GBDB.dbo.fnLocal_GlblTranslation('There are more results than can be displayed', @LanguageId)  
  
  
-------------------------------------------------------------------------------  
-- Section 4: Get local language ID  
-------------------------------------------------------------------------------  
  
SELECT   
@LanguageParmId  = 8,  
@LanguageId   = NULL  
  
SELECT @UserId = User_Id  
FROM dbo.Users  
WHERE UserName = @UserName  
  
SELECT @LanguageId =   
  CASE WHEN isnumeric(LTRIM(RTRIM(Value))) = 1   
    THEN CONVERT(FLOAT, LTRIM(RTRIM(Value)))  
    ELSE NULL  
    END  
FROM dbo.User_Parameters  
WHERE User_Id = @UserId  
AND Parm_Id = @LanguageParmId  
  
IF coalesce(@LanguageId,0) = 0  
 BEGIN  
 SELECT @LanguageId =   
    CASE WHEN isnumeric(LTRIM(RTRIM(Value))) = 1   
      THEN CONVERT(FLOAT, LTRIM(RTRIM(Value)))  
      ELSE NULL  
      END  
 FROM dbo.Site_Parameters  
 WHERE Parm_Id = @LanguageParmId  
  
 IF coalesce(@LanguageId,0) = 0  
  BEGIN  
  SELECT @LanguageId = 0  
  END  
 END  
  
  
---------------------------------------------------------------------------------------------------  
-- Section 5: Initialize temporary tables.  This minimizes recompiles.  
---------------------------------------------------------------------------------------------------  
  
SET @i = (SELECT COUNT(*) FROM dbo.#tests)  
  
  
-------------------------------------------------------------------------------  
-- Section 6: Check Input Parameters to make sure they are valid.  
-------------------------------------------------------------------------------  
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
  
-- If the endtime is in the future, set it to current day.  This prevent zero records FROM being printed on report.  
IF @EndTime > GetDate()  
 BEGIN  
 SELECT @EndTime = CONVERT(VARCHAR(4),YEAR(GetDate())) + '-' + CONVERT(VARCHAR(2),MONTH(GetDate())) + '-' +   
     CONVERT(VARCHAR(2),DAY(GetDate())) + ' ' + CONVERT(VARCHAR(2),DATEPART(hh,GetDate())) + ':' +   
     CONVERT(VARCHAR(2),DATEPART(mi,GetDate()))+ ':' + CONVERT(VARCHAR(2),DATEPART(ss,GetDate()))  
 END  
  
  
-------------------------------------------------------------------  
-- Section 7: Get the input parameter values out of the database  
-------------------------------------------------------------------  
  
IF Len(@RptName) > 0   
BEGIN  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptProdLineList','',      @ProdLineList OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'Owner', '',         @UserName OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptTitle', '',       @RptTitle OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptPageOrientation', '',   @RptPageOrientation OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptPageSize', '',      @RptPageSize OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'intRptPercentZoom', '',     @RptPercentZoom OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'ReportTimeOut', '',      @RptTimeout OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'ServerFileLocation', '',    @RptFileLocation OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptConnectionString', '',   @RptConnectionString OUTPUT  
END  
ELSE     
BEGIN  
 INSERT INTO @ErrorMessages (ErrMsg)  
  SELECT 'No Report Name specified.'  
END  
  
--select @ProdLineList =  'MP1M|MP2M|MP3M|MP4M|MP5M|MP6M|MP7M|MP8M|MP UT NRG'   
  
-------------------------------------------------------------------------------  
-- Section 8: Get information for ProdUnitList  
-------------------------------------------------------------------------------  
  
insert @ProdLines  
 (  
 PLID,  
 PLDesc,  
 extendedinfo  
 )   
select   
 pl_id,  
 pl_desc,  
 extended_info  
from prod_lines  
where charindex('|' + replace(pl_desc, 'TT ', '') + '|', '|' + @ProdLineList + '|')>0  
option (keep plan)  
  
  
-- note that some values are parsed from the extended_info field  
INSERT @ProdUnits   
 (   
 PUId,  
 PUDesc,  
 MasterUnit,  
 PLId,  
 ExtendedInfo,  
 PUType  
 )  
SELECT   
 pu.PU_Id,  
 pu.PU_Desc,  
 pu.master_unit,  
 pu.PL_Id,  
 pu.Extended_Info,  
 case  
 when charindex('equipgroup=boiler', lower(pu.extended_info))>0  
 then 'boiler'  
 else 'pm'  
 end  
FROM dbo.Prod_Units pu  
join @ProdLines pl  
on pu.pl_id = pl.plid  
where pu_desc like '%production%' or pu_desc like '%materials%'  
option (keep plan)  
  
  
-------------------------------------------------------------------------------  
-- Section 9: Get Production Starts  
-------------------------------------------------------------------------------  
  
insert @ProductionStarts   
 (  
 Start_Time,  
 End_Time,  
 Prod_ID,  
 Prod_Code,  
 Prod_Desc,  
 PU_ID  
 )  
select ps.start_time,  
 coalesce(ps.end_time,@endtime),  
 ps.prod_id,  
 p.prod_code,  
 p.prod_desc,  
 ps.pu_id  
from dbo.production_starts ps  
join dbo.products p   
on ps.prod_id = p.prod_id  
join @produnits pu  
on start_time < @endtime  
and (ps.end_time > @starttime or ps.end_time is null)  
AND p.Prod_Desc <> 'No Grade'   
and pu.puid = ps.pu_id   
option (keep plan)  
  
update @productionstarts set   
 start_time = @starttime  
where start_time < @starttime  
  
update @productionstarts set   
 end_time = @endtime  
where end_time > @endtime  
  
  
----------------------------------------------------------------------------  
-- Section 10: Populate the test table  
----------------------------------------------------------------------------  
  
-- Compile the variables for this report  
  
 INSERT @Variables  
 select  
  Var_ID,  
  Var_desc,  
  pu_id,  
  Extended_Info  
 from dbo.variables v  
 join @produnits pu  
 on v.pu_id = pu.puid  
 where charindex(@ExtInfoTag,lower(extended_info))>0  
  
  
-- Certain test results need to be compiled for this report.  This section of code will   
-- hit the test table one time, and get all the data needed and put it into a temporary table.    
  
  
 INSERT dbo.#Tests   
  (   
  VarId,  
  PUId,  
  ProdId,   
  ProdCode,  
  Value,  
  VarType,  
  ResultOn  
  )  
 SELECT   
  t.Var_Id,  
  pu.PuId,  
  ps.Prod_Id,  
  p.Prod_Code,  
  t.Result,  
  dbo.fnLocal_GlblParseInfo(v.extendedinfo,'NRGSumRpt='),   
  t.Result_On  
 FROM  @ProdUnits pu  
 join @variables v  
 on pu.puid = v.puid  
 join dbo.tests t  
 on t.var_id = v.varid  
 and result_on <= @EndTime  
 AND result_on > @StartTime  
 and result is not null  
 JOIN production_starts ps    
 ON coalesce(masterunit,pu.PUId) = ps.PU_Id   
 AND ps.Start_Time < t.Result_On   
 AND (ps.End_Time >= t.Result_On or ps.end_time is null)  
 left JOIN Products p     
 on ps.prod_id = p.prod_id  
 --and prod_desc <> 'No Grade'  
 option (keep plan)  
  
  
insert @Targets  
select  
 distinct  
 v.var_id,  
 v.var_desc,  
 v.pu_id,  
 p.prod_id,  
 asp.effective_date,  
 coalesce(asp.expiration_date,@endtime),  
 asp.l_reject,  
 --asp.target,  
 asp.u_reject,  
 dbo.fnLocal_GlblParseInfo(v.extended_info,'GlblDesc=')  
from dbo.active_specs asp  
join dbo.characteristics c  
on asp.char_id = c.char_id   
join dbo.specifications s  
on asp.spec_id = s.spec_id  
join dbo.product_properties pp  
on s.prop_id = pp.prop_id  
join dbo.variables v  
on s.spec_id = v.spec_id  
join prod_units pu  
on v.pu_id = pu.pu_id  
left join dbo.products p on   
c.char_desc = p.prod_desc   
where (prop_desc like '% energy %' or prop_desc like '%ut config%')  
and asp.effective_date < @EndTime  
and (asp.expiration_date > @StartTime or asp.expiration_date is null)  
and v.extended_info like '%Hr;%'  
option (keep plan)  
  
  
update t set  
 lowerreject = tgt.lowerreject,  
 --target = tgt.target,  
 upperreject = tgt.upperreject  
from #tests t  
join @targets tgt  
on t.puid = tgt.puid  
and t.prodid = tgt.prodid  
and  (  
  (t.vartype = 'PMSTEAMTOTALHR' and tgt.vartype = 'STEAMEFFICIENCYHR') or  
  (t.vartype = 'PMGASTOTALHR' and tgt.vartype = 'GASEFFICIENCYHR') or  
  (t.vartype = '%PMOILTOTALHR%' and tgt.vartype = 'OILEFFICIENCYHR') or  
  (t.vartype = 'PMAIRTOTALHR' and tgt.vartype = 'AIREFFICIENCYHR') or  
  (t.vartype = 'PMWATERTOTALHR' and tgt.vartype = 'WATEREFFICIENCYHR') or  
  (t.vartype = 'PMELECTRICTOTALHR' and tgt.vartype = 'ELECTRICEFFICIENCYHR') or  
  (t.vartype = 'TOTALBOILEREFFICIENCYHR' and tgt.vartype = 'TOTALBOILEREFFICIENCYHR')   
  )  
  
-----------------------------------------------------------  
ReturnResultSets:  
-----------------------------------------------------------  
  
--select * from @productionstarts ps  
--where pu_id = 2276  
--select * from @produnits  
--select * from @variables   
--select * from @targets   
--select --*  
--datepart(dd,starttime),  
--sum(coalesce(value,0))  
--from #tests t  
--where vartype = 'PMTAYTOTALHR'  
--and puid = 2276  
--and datepart(dd,starttime) = 1  
  
----------------------------------------------------------------------------------------------------  
-- Section 11: If there are Error Messages, then return them without other result sets.  
----------------------------------------------------------------------------------------------------  
  
-- if there are errors FROM the parameter validation, then return them and skip the rest of the results  
  
IF (SELECT count(*) FROM @ErrorMessages) > 0  
 BEGIN  
 SELECT ErrMsg  
 FROM @ErrorMessages  
 END  
ELSE  
 BEGIN  
  
 -------------------------------------------------------------------------------  
 -- Section 12: Results Set #1 - Return the empty Error Messages.    
 -------------------------------------------------------------------------------  
  
 SELECT ErrMsg  
 FROM @ErrorMessages  
  
  
 -----------------------------------------------------------------------------  
 -- Section 13: Results Set #2 -  return the report parameter values.  
 ----------------------------------------------------------------------------  
  
 -----------------------------------------------------------------------------------------  
 -- This RS is used when Report Parameter values are required within the Excel Template.  
 -----------------------------------------------------------------------------------------  
  
 SELECT  
  @RptName [@RptName],  
  @RptTitle [@RptTitle],  
  @ProdLineList [@ProdLineList],  
  @UserName [@RptUser],  
  @RptPageOrientation [@RptPageOrientation],  
  @RptPageSize [@RptPageSize],  
  @RptPercentZoom [@RptPercentZoom],  
  @RptTimeout [@RptTimeout],  
  @RptFileLocation [@RptFileLocation],  
  @RptConnectionString [@RptConnectionString]  
  
  
 -------------------------------------------------------------------------------  
 -- All raw data.  Note that Excel can only handle a maximum of 65536 rows in a  
 -- spreadsheet.  Therefore, we send an error if there are more than that number.  
 -------------------------------------------------------------------------------  
  
  -------------------------------------------------------------------------------------------  
  -- Section 14: Results Set #3 & 4 - Return the result set for Eff Summary  
  -------------------------------------------------------------------------------------------  
  
  INSERT @EffSummary  
  SELECT   
   replace(pldesc,'TT ',''), -- PM  
   prodcode, -- Brand  
   case  
   when sum(  
      case  
      when t.VarType = 'PMTAYTOTALHR'  
      then t.value  
      else 0  
      end  
     )>0  
   then sum(  
      case  
      when t.VarType = 'PMSTEAMTOTALHR'  
      then t.value  
      else 0  
      end  
     )/  
     sum(  
      case  
      when t.VarType = 'PMTAYTOTALHR'  
      then t.value  
      else 0  
      end  
     )  
   else 0  
   end, -- Steam Eff.  
   max(  
    case  
    when t.VarType = 'PMSTEAMTOTALHR'  
    then upperreject  
    else null  
    end  
   ), -- Steam Eff Trgt.  
   case  
   when sum(  
      case  
      when t.VarType = 'PMTAYTOTALHR'  
      then t.value  
      else 0  
      end  
     )>0  
   then sum(  
      case  
      when t.VarType = 'PMGASTOTALHR'  
      then t.value  
      else 0  
      end  
     )/  
     sum(  
      case  
      when t.VarType = 'PMTAYTOTALHR'  
      then t.value  
      else 0  
      end  
     )  
   else 0  
   end, -- Gas Eff.  
   max(  
    case  
    when t.VarType = 'PMGASTOTALHR'  
    then upperreject  
    else null  
    end  
   ), -- Gas Eff Trgt.  
  
   case  
   when sum(  
      case  
      when t.VarType = 'PMTAYTOTALHR'  
      then t.value  
      else 0  
      end  
     )>0  
   then sum(  
      case  
      when t.VarType = 'PMOILTOTALHR'  
      then t.value  
      else 0  
      end  
     )/  
     sum(  
      case  
      when t.VarType = 'PMTAYTOTALHR'  
      then t.value  
      else 0  
      end  
     )  
   else 0  
   end, -- Oil Eff.  
   max(  
    case  
    when t.VarType = 'PMOILTOTALHR'  
    then upperreject  
    else null  
    end  
   ), -- Oil Eff Trgt.  
  
   case  
   when sum(  
      case  
      when t.VarType = 'PMTAYTOTALHR'  
      then t.value  
      else 0  
      end  
     )>0  
   then sum(  
      case  
      when t.VarType = 'PMAIRTOTALHR'  
      then t.value  
      else 0  
      end  
     )/  
     sum(  
      case  
      when t.VarType = 'PMTAYTOTALHR'  
      then t.value  
      else 0  
      end  
     )  
   else 0  
   end, -- Air Eff.  
   max(  
    case  
    when t.VarType = 'PMAIRTOTALHR'  
    then upperreject  
    else null  
    end  
   ), -- Air Eff Trgt.  
   sum(  
    case  
    when t.VarType = 'PMTAYTOTALHR'  
    then t.value  
    else 0  
    end  
   ), -- Total TAY  
   min(ps.start_time) -- Brand Date  
  FROM dbo.#tests t  
  join @produnits pu  
  on t.puid = pu.puid  
  join @prodlines pl  
  on pu.plid = pl.plid   
  left join @productionstarts ps  
  on ps.prod_id = t.prodid  
  and ps.pu_id = coalesce(pu.masterunit,pu.puid)  
  and t.resulton > ps.start_time   
  and t.resulton <= ps.end_time   
  where PUType = 'pm'  
  and pldesc not like '%nrg%'    
  --and t.starttime <= @EndTime  
  --AND t.starttime > @StartTime  
  GROUP BY pl.pldesc, t.prodcode  
  ORDER BY pl.pldesc, min(ps.start_time), t.prodcode   
  option (keep plan)  
  
  
  if (SELECT count(*) FROM @EffSummary) > 65000   
   begin  
   select @TooMuchDataMsg [User Notification Msg]  
   end  
  else  
   begin   
   if (SELECT count(*) FROM @EffSummary) = 0   
    begin  
    select @NoDataMsg [User Notification Msg]  
    end  
   else    
    begin  
    select *   
    from @EffSummary  
    order by [PM], [Brand Date]  
    end  
   end  
  
  insert @SumTotals  
  select   
   [PM],  
   case  
   when sum([Yankee (TAY)])>0  
   then sum([Steam Eff. (Mlbs/TAY)] * [Yankee (TAY)])/sum([Yankee (TAY)])  
   else 0  
   end, -- Total1: Steam Eff  
   case   
   when sum([Yankee (TAY)])>0  
   then sum([Steam Eff. Trgt. (Mlbs/TAY)] * [Yankee (TAY)])/sum([Yankee (TAY)])  
   else null  
   end, -- Total2: Steam Eff Tgt  
   case  
   when sum([Yankee (TAY)])>0  
   then sum([Gas Eff. (Mscf/TAY)] * [Yankee (TAY)])/sum([Yankee (TAY)])  
   else 0  
   end, -- Total3: Gas Eff  
   case   
   when sum([Yankee (TAY)])>0  
   then sum([Gas Eff. Trgt. (Mscf/TAY)] * [Yankee (TAY)])/sum([Yankee (TAY)])  
   else null  
   end, -- Total4: Gas Eff Tgt  
   case  
   when sum([Yankee (TAY)])>0  
   then sum([Oil Eff. (gal/TAY)] * [Yankee (TAY)])/sum([Yankee (TAY)])  
   else 0  
   end, -- Total5: Oil Eff  
   case   
   when sum([Yankee (TAY)])>0  
   then sum([Oil Eff. Trgt. (gal/TAY)] * [Yankee (TAY)])/sum([Yankee (TAY)])  
   else null  
   end, -- Total6: Oil Eff Tgt  
   case  
   when sum([Yankee (TAY)])>0  
   then sum([Air Eff. (Mlbs/TAY)] * [Yankee (TAY)])/sum([Yankee (TAY)])  
   else 0  
   end, -- Total7: Air Eff  
   case   
   when sum([Yankee (TAY)])>0  
   then sum([Air Eff. Trgt. (Mlbs/TAY)] * [Yankee (TAY)])/sum([Yankee (TAY)])  
   else null  
   end, -- Total8: Air Eff Tgt  
   null, -- Total9  
   null -- Total10  
  from @EffSummary  
  group by [PM]  
  
  
  select * from @SumTotals  
  order by [PM]  
  delete @SumTotals  
  
  
  -------------------------------------------------------------------------------------------  
  -- Section 15: Results Set #5 & 6 - Return the second result set for Eff Summary   
  -------------------------------------------------------------------------------------------  
  
  INSERT @EffSummary2  
  SELECT   
   replace(pldesc,'TT ',''), -- PM  
   prodcode, -- Brand  
   case  
   when sum(  
      case  
      when t.VarType = 'PMTAYTOTALHR'  
      then t.value  
      else 0  
      end  
     )>0  
   then sum(  
      case  
      when t.VarType = 'PMHOTAIRTOTALHR'  
      then t.value  
      else 0  
      end  
     )/  
     sum(  
      case  
      when t.VarType = 'PMTAYTOTALHR'  
      then t.value  
      else 0  
      end  
     )  
   else 0  
   end, -- Hot Air Eff. Mlbs/TAY   
   max(  
    case  
    when t.VarType = 'PMHOTAIRTOTALHR'  
    then upperreject  
    else null  
    end  
   ), -- Hot Air Eff Trgt.  
   case  
   when sum(  
      case  
      when t.VarType = 'PMTAYTOTALHR'  
      then t.value  
      else 0  
      end  
     )>0  
   then sum(  
      case  
      when t.VarType = 'PMELECTRICTOTALHR'  
      then t.value  
      else 0  
      end  
     )/  
     sum(  
      case  
      when t.VarType = 'PMTAYTOTALHR'  
      then t.value  
      else 0  
      end  
     )  
   else 0  
   end, -- Electricity Eff.  
   max(  
    case  
    when t.VarType = 'PMELECTRICTOTALHR'  
    then upperreject  
    else null  
    end  
   ), -- Electric Eff Trgt.  
   sum(  
    case  
    when t.VarType = 'PMTAYTOTALHR'  
    then t.value  
    else 0  
    end  
   ), -- Total TAY  
   case  
   when sum(  
      case  
      when t.VarType = 'PMTAYTOTALHR'  
      then t.value  
      else 0  
      end  
     )>0  
   then sum(  
      case  
      when t.VarType = 'PMSTEAMUSAGEHR'  
      or t.VarType = 'PMGASUSAGEHR'  
      or t.VarType = 'PMAIRUSAGEHR'  
      or t.VarType = 'PMELECTRICUSAGEHR'  
      or t.VarType = 'PMOILUSAGEHR'  
      then t.value  
      else 0  
      end  
     )/  
     sum(  
      case  
      when t.VarType = 'PMTAYTOTALHR'  
      then t.value  
      else 0  
      end  
     )  
   else 0  
   end,  -- Drying Energy   
   sum(  
    case  
    when t.VarType = 'PMDOWNTIMETOTALHR'  
    then t.value  
    else 0  
    end  
   ), -- Total Downtime  
   min(ps.start_time) -- Brand Date  
  FROM dbo.#tests t  
  join @produnits pu  
  on t.puid = pu.puid  
  join @prodlines pl  
  on pu.plid = pl.plid   
  left join @productionstarts ps  
  on ps.prod_id = t.prodid  
  and ps.pu_id = coalesce(pu.masterunit,pu.puid)  
  and t.resulton > ps.start_time   
  and t.resulton <= ps.end_time   
  where PUType = 'pm'  
  and pldesc not like '%nrg%'    
  GROUP BY pl.pldesc, t.prodcode  
  ORDER BY pl.pldesc, min(ps.start_time), t.prodcode   
  option (keep plan)  
  
  
  if (SELECT count(*) FROM @EffSummary2) > 65000   
   begin  
   select @TooMuchDataMsg [User Notification Msg]  
   end  
  else  
   begin   
   if (SELECT count(*) FROM @EffSummary2) = 0   
    begin  
    select @NoDataMsg [User Notification Msg]  
    end  
   else    
    begin  
    select *   
    from @EffSummary2  
    order by [PM], [Brand Date]  
    end  
   end  
  
  
  insert @SumTotals  
  select   
   [PM],  
   case  
   when sum([Yankee (TAY)])>0  
   then sum([Hot Air Eff. (Mlbs/TAY)] * [Yankee (TAY)])/sum([Yankee (TAY)])  
   else 0  
   end, -- Total1: Hot Air Eff  
   case   
   when sum([Yankee (TAY)])>0  
   then sum([Hot Air Eff. Trgt. (Mlbs/TAY)] * [Yankee (TAY)])/sum([Yankee (TAY)])  
   else null  
   end, -- Total2: Hot Air Eff Tgt  
   case  
   when sum([Yankee (TAY)])>0  
   then sum([Electricity Eff. (kWh/TAY)] * [Yankee (TAY)])/sum([Yankee (TAY)])  
   else 0  
   end, -- Total3: Electricity Eff  
   case   
   when sum([Yankee (TAY)])>0  
   then sum([Electricity Eff. Trgt. (kWh/TAY)] * [Yankee (TAY)])/sum([Yankee (TAY)])  
   else null  
   end, -- Total4: Electricity Eff Tgt  
   sum([Yankee (TAY)]), -- Total5: Yankee Tay  
   case  
   when sum([Yankee (TAY)])>0  
   then sum([Drying Energy (MMBTU/TAY)] * [Yankee (TAY)])/sum([Yankee (TAY)])  
   else 0  
   end, -- 6: Drying energy  
   sum([Downtime (Mins)]), -- Total7: Downtime  
   null, -- Total8  
   null, -- Total9  
   null -- Total10  
  from @EffSummary2  
  group by [PM]  
  
  
  select * from @SumTotals  
  order by [PM]  
  delete @SumTotals  
  
  
  -------------------------------------------------------------------------------------------  
  -- Section 16: Results Set #7 & 8 - Return the result set for PM Summary  
  -------------------------------------------------------------------------------------------  
  
  INSERT @PMSummary  
  SELECT   
   replace(pldesc,'TT ',''), -- PM  
   prodcode, -- Brand  
   sum(  
    case  
    when t.VarType = 'PMSTEAMTOTALHR'  
    then t.value  
    else 0  
    end  
   ), -- Total Steam  
   sum(  
    case  
    when t.VarType = 'PMGASTOTALHR'  
    then t.value  
    else 0  
    end  
   ), -- Total Gas  
   sum(  
    case  
    when t.VarType = 'PMAIRTOTALHR'  
    then t.value  
    else 0  
    end  
   ), -- Total Air  
   sum(  
    case  
    when t.VarType = 'PMELECTRICTOTALHR'  
    then t.value  
    else 0  
    end  
   ), -- Total Electricity   
   sum(  
    case  
    when t.VarType = 'PMOILTOTALHR'  
    then t.value  
    else 0  
    end  
   ), -- Total Oil  
   sum(  
    case  
    when t.VarType = 'PMTAYTOTALHR'  
    then t.value  
    else 0  
    end  
   ), -- Total TAY  
   case  
   when sum(  
      case  
      when t.VarType = 'PMTAYTOTALHR'  
      then t.value  
      else 0  
      end  
     )>0  
   then sum(  
      case  
      when t.VarType = 'PMSTEAMUSAGEHR'  
      or t.VarType = 'PMGASUSAGEHR'  
      or t.VarType = 'PMAIRUSAGEHR'  
      or t.VarType = 'PMELECTRICUSAGEHR'  
      or t.VarType = 'PMOILUSAGEHR'  
      then t.value  
      else 0  
      end  
     )/  
     sum(  
      case  
      when t.VarType = 'PMTAYTOTALHR'  
      then t.value  
      else 0  
      end  
     )  
   else 0  
   end,  -- Drying Energy   
   sum(  
    case  
    when t.VarType = 'PMDOWNTIMETOTALHR'  
    then t.value  
    else 0  
    end  
   ), -- Total Downtime  
   min(ps.start_time) -- Brand Date  
  FROM dbo.#tests t  
  join @produnits pu  
  on t.puid = pu.puid   
  join @prodlines pl  
  on pu.plid = pl.plid  
  left join @productionstarts ps  
  on ps.prod_id = t.prodid  
  and ps.pu_id = coalesce(pu.masterunit,pu.puid)  
  and t.resulton > ps.start_time   
  and t.resulton <= ps.end_time   
  where PUType = 'pm'    
  and pldesc not like '%nrg%'    
  GROUP BY pl.pldesc, t.prodcode  
  ORDER BY pl.pldesc, min(ps.start_time), t.prodcode  
  option (keep plan)  
  
  
  if (SELECT count(*) FROM @PMSummary) > 65000   
   begin  
   select @TooMuchDataMsg [User Notification Msg]  
   end  
  else  
   begin   
   if (SELECT count(*) FROM @PMSummary) = 0   
    begin  
    select @NoDataMsg [User Notification Msg]  
    end  
   else    
    begin  
    select *   
    from @PMSummary  
    order by [PM], [Brand Date]  
    end  
   end  
  
  insert @SumTotals  
  select   
   [PM],  
   sum([Total Steam (Mlbs)]), -- Total1: Total Steam  
   sum([Total Gas (Mscf)]), -- Total2: Total Gas  
   sum([Turbine Air (Mlbs)]), -- Total3: Turbine Air  
   sum([Total Electricity (kWh)]), -- Total4: Total Electricity  
   sum([Total Oil (gal)]), -- Total5: Total Oil   
   sum([Yankee (TAY)]), -- Total6: Yankee Tay  
   case  
   when sum([Yankee (TAY)])>0  
   then sum([Drying Energy (MMBTU/TAY)] * [Yankee (TAY)])/sum([Yankee (TAY)])  
   else 0  
   end, -- 7: Drying energy  
   sum([Downtime (Mins)]), -- Total8: Downtime  
   null, -- Total9  
   null -- Total10  
  from @PMSummary  
  group by [PM]  
  
  select * from @SumTotals  
  order by [PM]  
  delete @SumTotals  
  
  
  -------------------------------------------------------------------------------------------  
  -- Section 17: Results Set #9 & 10 - Return the result set for Steam Summary  
  -------------------------------------------------------------------------------------------  
  
  INSERT @SteamSummary  
  SELECT   
   replace(pldesc,'TT ',''), -- PM  
   prodcode, -- Brand  
   case  
   when sum(  
      case  
      when t.VarType = 'PMTAYTOTALHR'  
      then t.value  
      else 0  
      end  
     )>0  
   then sum(  
      case  
      when t.VarType = 'PMSTEAMTOTALHR'  
      then t.value  
      else 0  
      end  
     )/  
     sum(  
      case  
      when t.VarType = 'PMTAYTOTALHR'  
      then t.value  
      else 0  
      end  
     )  
   else 0  
   end, -- Steam Eff.  
   max(  
    case  
    when t.VarType = 'PMSTEAMTOTALHR'  
    then upperreject  
    else null  
    end  
   ), -- Steam Eff Trgt.  
   sum(  
    case  
    when t.VarType = 'PMSTEAMTOTALHR'  
    then t.value  
    else 0  
    end  
   ), -- Total Steam  
   sum(  
    case  
    when t.VarType = 'PMTAYTOTALHR'  
    then t.value  
    else 0  
    end  
   ), -- Total TAY  
   sum(  
    case  
    when t.VarType = 'PMSTEAMTOTALHR'  
    then t.value  
    else 0  
    end  
    / (datediff(ss,ps.start_time,ps.end_time)/3600.0)), -- Avg Draw  
   sum(  
    case  
    when t.VarType = 'PMDOWNTIMETOTALHR'  
    then t.value  
    else 0  
    end  
   ), -- Total Downtime  
   min(ps.start_time) -- Brand Date  
  FROM dbo.#tests t  
  join @produnits pu  
  on t.puid = pu.puid   
  join @prodlines pl  
  on pu.plid = pl.plid  
  left join @productionstarts ps  
  on ps.prod_id = t.prodid  
  and ps.pu_id = coalesce(pu.masterunit,pu.puid)  
  and t.resulton between ps.start_time and ps.end_time  
  where PUType = 'pm'    
  and pldesc not like '%nrg%'    
  GROUP BY pl.pldesc, t.prodcode, t.prodid  
  ORDER BY pl.pldesc, min(ps.start_time), t.prodcode, t.prodid  
  option (keep plan)  
  
  
  if (SELECT count(*) FROM @SteamSummary) > 65000   
   begin  
   select @TooMuchDataMsg [User Notification Msg]  
   end  
  else  
   begin   
   if (SELECT count(*) FROM @SteamSummary) = 0   
    begin  
    select @NoDataMsg [User Notification Msg]  
    end  
   else    
    begin  
    select *   
    from @SteamSummary  
    order by [PM], [Brand Date]  
    end  
   end  
  
  insert @SumTotals  
  select   
   [PM],  
   case   
   when sum([Yankee (TAY)])>0  
   then sum([Total Steam (Mlbs)])/sum([Yankee (TAY)])  
   else 0  
   end, -- Total1: Steam Eff  
   case   
   when sum([Yankee (TAY)])>0  
   then sum([Steam Eff. Trgt. (Mlbs/TAY)] * [Yankee (TAY)])/sum([Yankee (TAY)])  
   else null  
   end, -- Total2: Steam Eff Tgt  
   sum([Total Steam (Mlbs)]), -- Total3: Total Steam  
   sum([Yankee (TAY)]), -- Total4: Total Tay  
   sum([Total Steam (Mlbs)])/(datediff(ss,@starttime,@endtime)/3600.0), -- Total5: Avg Draw   
   sum([Downtime (Mins)]), -- Total6: Total Downtime  
   null, -- Total7  
   null, -- Total8  
   null, -- Total9  
   null -- Total10  
  from @SteamSummary  
  group by [PM]  
  
  
  select * from @SumTotals  
  order by [PM]  
  delete @SumTotals  
  
  
  -------------------------------------------------------------------------------------------  
  -- Section 18: Results Set #11 & 12 - Return the result set for Gas Summary  
  -------------------------------------------------------------------------------------------  
  
  INSERT @GasSummary  
  SELECT   
   replace(pldesc,'TT ',''), -- PM  
   prodcode, -- Brand  
   case  
   when sum(  
      case  
      when t.VarType = 'PMTAYTOTALHR'  
      then t.value  
      else 0  
      end  
     )>0  
   then sum(  
      case  
      when t.VarType = 'PMGASTOTALHR'  
      then t.value  
      else 0  
      end  
     )/  
     sum(  
      case  
      when t.VarType = 'PMTAYTOTALHR'  
      then t.value  
      else 0  
      end  
     )  
   else 0  
   end, -- Gas Eff.  
   max(  
    case  
    when t.VarType = 'PMGASTOTALHR'  
    then upperreject  
    else null  
    end  
   ), -- Gas Eff Trgt.  
   sum(  
    case  
    when t.VarType = 'PMGASTOTALHR'  
    then t.value  
    else 0  
    end  
   ), -- Total Gas  
   sum(  
    case  
    when t.VarType = 'PMTAYTOTALHR'  
    then t.value  
    else 0  
    end  
   ), -- Total TAY  
   sum(  
    case  
    when t.VarType = 'PMGASTOTALHR'  
    then t.value  
    else 0  
    end  
   --)/sum(  
   / (datediff(ss,ps.start_time,ps.end_time)/3600.0)), -- Avg Flow  
   sum(  
    case  
    when t.VarType = 'PMDOWNTIMETOTALHR'  
    then t.value  
    else 0  
    end  
   ), -- Total Downtime  
   min(ps.start_time) -- Brand Date  
  FROM dbo.#tests t  
  join @produnits pu  
  on t.puid = pu.puid   
  join @prodlines pl  
  on pu.plid = pl.plid  
  left join @productionstarts ps  
  on ps.prod_id = t.prodid  
  --and ps.pu_id = t.puid  
  and ps.pu_id = coalesce(pu.masterunit,pu.puid)  
  and t.resulton between ps.start_time and ps.end_time  
  where PUType = 'pm'    
  and pldesc not like '%nrg%'    
  GROUP BY pl.pldesc, t.prodcode, t.prodid  
  ORDER BY pl.pldesc, min(ps.start_time), t.prodcode, t.prodid  
  option (keep plan)  
  
  
  if (SELECT count(*) FROM @GasSummary) > 65000   
   begin  
   select @TooMuchDataMsg [User Notification Msg]  
   end  
  else  
   begin   
   if (SELECT count(*) FROM @GasSummary) = 0   
    begin  
    select @NoDataMsg [User Notification Msg]  
    end  
   else    
    begin  
    select *   
    from @GasSummary  
    order by [PM], [Brand Date]  
    end  
   end  
  
  insert @SumTotals  
  select   
   [PM],  
   case  
   when sum([Yankee (TAY)])>0  
   then sum([Total Gas (Mscf)])/sum([Yankee (TAY)])  
   else 0   
   end, -- Total1: Gas Eff  
   case   
   when sum([Yankee (TAY)])>0  
   then sum([Gas Eff. Trgt. (Mscf/TAY)] * [Yankee (TAY)])/sum([Yankee (TAY)])  
   else null  
   end, -- Total2: Gas Eff Tgt  
   sum([Total Gas (Mscf)]), -- Total3: Total Gas   
   sum([Yankee (TAY)]), -- Total4: Total TAY  
   sum([Total Gas (Mscf)])/(datediff(ss,@starttime,@endtime)/3600.0), -- Total5: Avg Flow  
   sum([Downtime (Mins)]), -- Total6: Total Downtime  
   null, -- Total7  
   null, -- Total8  
   null, -- Total9  
   null -- Total10  
  from @GasSummary  
  group by [PM]  
  
  
  select * from @SumTotals  
  order by [PM]  
  delete @SumTotals  
  
  
  -------------------------------------------------------------------------------------------  
  -- Section 19: Results Set #13 & 14 - Return the result set for Oil Summary  
  -------------------------------------------------------------------------------------------  
  
  INSERT @OilSummary  
  SELECT   
   replace(pldesc,'TT ',''), -- PM  
   prodcode, -- Brand  
   case  
   when sum(  
      case  
      when t.VarType = 'PMTAYTOTALHR'  
      then t.value  
      else 0  
      end  
     )>0  
   then sum(  
      case  
      when t.VarType = 'PMOILTOTALHR'  
      then t.value  
      else 0  
      end  
     )/  
     sum(  
      case  
      when t.VarType = 'PMTAYTOTALHR'  
      then t.value  
      else 0  
      end  
     )  
   else 0  
   end, -- Oil Eff.  
   max(  
    case  
    when t.VarType = 'PMOILTOTALHR'  
    then upperreject  
    else null  
    end  
   ), -- Oil Eff Trgt.  
   sum(  
    case  
    when t.VarType = 'PMOILTOTALHR'  
    then t.value  
    else 0  
    end  
   ), -- Total Oil  
   sum(  
    case  
    when t.VarType = 'PMTAYTOTALHR'  
    then t.value  
    else 0  
    end  
   ), -- Total TAY  
   sum(  
    case  
    when t.VarType = 'PMOILTOTALHR'  
    then t.value  
    else 0  
    end  
   --)/sum(  
   / (datediff(ss,ps.start_time,ps.end_time)/3600.0)), -- Avg Flow  
   sum(  
    case  
    when t.VarType = 'PMDOWNTIMETOTALHR'  
    then t.value  
    else 0  
    end  
   ), -- Total Downtime  
   min(ps.start_time) -- Brand Date  
  FROM dbo.#tests t  
  join @produnits pu  
  on t.puid = pu.puid   
  join @prodlines pl  
  on pu.plid = pl.plid  
  left join @productionstarts ps  
  on ps.prod_id = t.prodid  
  --and ps.pu_id = t.puid  
  and ps.pu_id = coalesce(pu.masterunit,pu.puid)  
  and t.resulton between ps.start_time and ps.end_time  
  where PUType = 'pm'    
  and pldesc not like '%nrg%'    
  GROUP BY pl.pldesc, t.prodcode, t.prodid  
  ORDER BY pl.pldesc, min(ps.start_time), t.prodcode, t.prodid  
  option (keep plan)  
  
  
  if (SELECT count(*) FROM @OilSummary) > 65000   
   begin  
   select @TooMuchDataMsg [User Notification Msg]  
   end  
  else  
   begin   
   if (SELECT count(*) FROM @OilSummary) = 0   
    begin  
    select @NoDataMsg [User Notification Msg]  
    end  
   else    
    begin  
    select *   
    from @OilSummary  
    order by [PM], [Brand Date]  
    end  
   end  
  
  insert @SumTotals  
  select   
   [PM],  
   case  
   when sum([Yankee (TAY)])>0  
   then sum([Total Oil (gal)])/sum([Yankee (TAY)])  
   else 0  
   end, -- Total1: Oil Eff  
   case   
   when sum([Yankee (TAY)])>0  
   then sum([Oil Eff. Trgt. (gal/TAY)] * [Yankee (TAY)])/sum([Yankee (TAY)])  
   else null  
   end, -- Total2: Oil Eff Tgt  
   sum([Total Oil (gal)]), -- Total3: Total Oil  
   sum([Yankee (TAY)]), -- Total4: Total TAY  
   sum([Total Oil (gal)])/(datediff(ss,@starttime,@endtime)/3600.0), -- Total5: Avg Flow  
   sum([Downtime (Mins)]), -- Total6: Total Downtime  
   null, -- Total7  
   null, -- Total8  
   null, -- Total9  
   null -- Total10  
  from @OilSummary  
  group by [PM]  
  
  
  select * from @SumTotals  
  order by [PM]  
  delete @SumTotals  
  
  
  -------------------------------------------------------------------------------------------  
  -- Section 20: Results Set #15 & 16 - Return the result set for Air Summary  
  -------------------------------------------------------------------------------------------  
  
  INSERT @AirSummary  
  SELECT   
   replace(pldesc,'TT ',''), -- PM  
   prodcode, -- Brand  
   case  
   when sum(  
      case  
      when t.VarType = 'PMTAYTOTALHR'  
      then t.value  
      else 0  
      end  
     )>0  
   then sum(  
      case  
      when t.VarType = 'PMAIRTOTALHR'  
      then t.value  
      else 0  
      end  
     )/  
     sum(  
      case  
      when t.VarType = 'PMTAYTOTALHR'  
      then t.value  
      else 0  
      end  
     )  
   else 0  
   end, -- Air Eff.  
   max(  
    case  
    when t.VarType = 'PMAIRTOTALHR'  
    then upperreject  
    else null  
    end  
   ), -- Air Eff Trgt.  
   sum(  
    case  
    when t.VarType = 'PMAIRTOTALHR'  
    then t.value  
    else 0  
    end  
   ), -- Total Air  
   case  
   when sum(  
      case  
      when t.VarType = 'PMTAYTOTALHR'  
      then t.value  
      else 0  
      end  
     )>0  
   then sum(  
      case  
      when t.VarType = 'PMHOTAIRTOTALHR'  
      then t.value  
      else 0  
      end  
     )/  
     sum(  
      case  
      when t.VarType = 'PMTAYTOTALHR'  
      then t.value  
      else 0  
      end  
     )  
   else 0  
   end, -- Hot Air Eff. Mlbs/TAY   
   max(  
    case  
    when t.VarType = 'PMHOTAIRTOTALHR'  
    then upperreject  
    else null  
    end  
   ), -- Hot Air Eff Trgt.  
   sum(  
    case  
    when t.VarType = 'PMHOTAIRTOTALHR'  
    then t.value  
    else 0  
    end  
   ), -- Total Hot Air Mlbs  
   sum(  
    case  
    when t.VarType = 'PMTAYTOTALHR'  
    then t.value  
    else 0  
    end  
   ), -- Total TAY  
   sum(  
    case  
    when t.VarType = 'PMAIRTOTALHR'  
    then t.value  
    else 0  
    end  
   --)/sum(  
   / (datediff(ss,ps.start_time,ps.end_time)/3600.0)), -- Avg Flow  
   sum(  
    case  
    when t.VarType = 'PMDOWNTIMETOTALHR'  
    then t.value  
    else 0  
    end  
   ), -- Total Downtime  
   min(ps.start_time) -- Brand Date  
  FROM dbo.#tests t  
  join @produnits pu  
  on t.puid = pu.puid   
  join @prodlines pl  
  on pu.plid = pl.plid  
  left join @productionstarts ps  
  on ps.prod_id = t.prodid  
  --and ps.pu_id = t.puid  
  and ps.pu_id = coalesce(pu.masterunit,pu.puid)  
  and t.resulton between ps.start_time and ps.end_time  
  where PUType = 'pm'    
  and pldesc not like '%nrg%'    
  GROUP BY pl.pldesc, t.prodcode, t.prodid  
  ORDER BY pl.pldesc, min(ps.start_time), t.prodcode, t.prodid  
  option (keep plan)  
  
  
  
  if (SELECT count(*) FROM @AirSummary) > 65000   
   begin  
   select @TooMuchDataMsg [User Notification Msg]  
   end  
  else  
   begin   
   if (SELECT count(*) FROM @AirSummary) = 0   
    begin  
    select @NoDataMsg [User Notification Msg]  
    end  
   else    
    begin  
    select *   
    from @AirSummary  
    order by [PM], [Brand Date]  
    end  
   end  
  
  insert @SumTotals  
  select   
   [PM],  
   case  
   when sum([Yankee (TAY)])>0  
   then sum([Total Air (Mlbs)])/sum([Yankee (TAY)])  
   else 0  
   end, -- Total1: Air Eff  
   case   
   when sum([Yankee (TAY)])>0  
   then sum([Air Eff. Trgt. (Mlbs/TAY)] * [Yankee (TAY)])/sum([Yankee (TAY)])  
   else null  
   end, -- Total2: Air Eff Tgt  
   sum([Total Air (Mlbs)]), -- Total3: Total Air  
   case  
   when sum([Yankee (TAY)])>0  
   then sum([Total Hot Air (Mlbs)])/sum([Yankee (TAY)])  
   else 0  
   end, -- Total4: Hot Air Eff  
   case   
   when sum([Yankee (TAY)])>0  
   then sum([Hot Air Eff. Trgt. (Mlbs/TAY)] * [Yankee (TAY)])/sum([Yankee (TAY)])  
   else null  
   end, -- Total5: Hot Air Eff tgt  
   sum([Total Hot Air (Mlbs)]), -- Total6: Total Hot Air  
   sum([Yankee (TAY)]), -- Total7: Yankee Tay  
   sum([Total Air (Mlbs)])/(datediff(ss,@starttime,@endtime)/3600.0), -- Total8: Avg Flow  
   sum([Downtime (Mins)]), -- Total9: Downtime  
   null -- Total10  
  from @AirSummary  
  group by [PM]  
  
  
  select * from @SumTotals  
  order by [PM]  
  delete @SumTotals  
  
  
  -------------------------------------------------------------------------------------------  
  -- Section 21: Results Set #17 & 18 - Return the result set for Electricity Summary  
  -------------------------------------------------------------------------------------------  
  
  INSERT @ElectricitySummary  
  SELECT   
   replace(pldesc,'TT ',''), -- PM  
   prodcode, -- Brand  
   case  
   when sum(  
      case  
      when t.VarType = 'PMTAYTOTALHR'  
      then t.value  
      else 0  
      end  
     )>0  
   then sum(  
      case  
      when t.VarType = 'PMELECTRICTOTALHR'  
      then t.value  
      else 0  
      end  
     )/  
     sum(  
      case  
      when t.VarType = 'PMTAYTOTALHR'  
      then t.value  
      else 0  
      end  
     )  
   else 0  
   end, -- Electricity Eff.  
   max(  
    case  
    when t.VarType = 'PMELECTRICTOTALHR'  
    then upperreject  
    else null  
    end  
   ), -- Electric Eff Trgt.  
   sum(  
    case  
    when t.VarType = 'PMELECTRICTOTALHR'  
    then t.value  
    else 0  
    end  
   ), -- Total Electricity  
   sum(  
    case  
    when t.VarType = 'PMTAYTOTALHR'  
    then t.value  
    else 0  
    end  
   ), -- Total TAY  
   sum(  
    case  
    when t.VarType = 'PMELECTRICTOTALHR'  
    then t.value  
    else 0  
    end  
   --)/sum(  
   / (datediff(ss,ps.start_time,ps.end_time)/3600.0)), -- Avg Flow  
   sum(  
    case  
    when t.VarType = 'PMDOWNTIMETOTALHR'  
    then t.value  
    else 0  
    end  
   ), -- Total Downtime  
   min(ps.start_time) -- Brand Date  
  FROM dbo.#tests t  
  join @produnits pu  
  on t.puid = pu.puid   
  join @prodlines pl  
  on pu.plid = pl.plid  
  left join @productionstarts ps  
  on ps.prod_id = t.prodid  
  --and ps.pu_id = t.puid  
  and ps.pu_id = coalesce(pu.masterunit,pu.puid)  
  and t.resulton between ps.start_time and ps.end_time  
  where PUType = 'pm'    
  and pldesc not like '%nrg%'    
  GROUP BY pl.pldesc, t.prodcode, t.prodid  
  ORDER BY pl.pldesc, min(ps.start_time), t.prodcode, t.prodid  
  option (keep plan)  
  
  
  if (SELECT count(*) FROM @ElectricitySummary) > 65000   
   begin  
   select @TooMuchDataMsg [User Notification Msg]  
   end  
  else  
   begin   
   if (SELECT count(*) FROM @ElectricitySummary) = 0   
    begin  
    select @NoDataMsg [User Notification Msg]  
    end  
   else    
    begin  
    select *   
    from @ElectricitySummary  
    order by [PM], [Brand Date]  
    end  
   end  
  
  insert @SumTotals  
  select   
   [PM],  
   case  
   when sum([Yankee (TAY)])>0  
   then sum([Total Electricity (kWh)])/sum([Yankee (TAY)])  
   else 0  
   end, -- Total1: Electricity Eff  
   case   
   when sum([Yankee (TAY)])>0  
   then sum([Electricity Eff. Trgt. (kWh/TAY)] * [Yankee (TAY)])/sum([Yankee (TAY)])  
   else null  
   end, -- Total2: Electricity Eff Tgt  
   sum([Total Electricity (kWh)]), -- Total3: Total Electricity  
   sum([Yankee (TAY)]), -- Total4: Total TAY  
   sum([Total Electricity (kWh)])/(datediff(ss,@starttime,@endtime)/3600.0), -- Total5: Avg Rate  
   sum([Downtime (Mins)]), -- Total6: Total Downtime  
   null, -- Total7  
   null, -- Total8  
   null, -- Total9  
   null -- Total10  
  from @ElectricitySummary  
  group by [PM]  
  
  select * from @SumTotals  
  order by [PM]  
  delete @SumTotals  
  
  
  -------------------------------------------------------------------------------------------  
  -- Section 22: Results Set #19 & 20 - Return the result set for Finance Summary  
  -------------------------------------------------------------------------------------------  
  
  INSERT @FinanceSummary  
  SELECT   
   replace(pldesc,'TT ',''), -- PM  
   prodcode, -- Brand  
   sum(  
    case  
    when t.VarType = 'PMTONSGOODTOTALDAY'  
    then t.value  
    else 0  
    end  
   ), -- Good Tonnes   
   sum(  
    case  
    when t.VarType = 'PMSTEAMTOTALDAY'  
    then t.value  
    else 0  
    end  
   ), -- Total Steam  
   case  
   when sum(  
      case  
      when t.VarType = 'PMTONSGOODTOTALDAY'  
      then t.value  
      else 0  
      end  
     )>0  
   then sum(  
      case  
      when t.VarType = 'PMSTEAMTOTALDAY'  
      then t.value  
      else 0  
      end  
     )/  
     sum(  
      case  
      when t.VarType = 'PMTONSGOODTOTALDAY'  
      then t.value  
      else 0  
      end  
     )  
   else 0  
   end, -- Steam Eff.  
   sum(  
    case  
    when t.VarType = 'PMELECTRICTOTALDAY'  
    then t.value  
    else 0  
    end  
   ), -- Total Electricity   
   case  
   when sum(  
      case  
      when t.VarType = 'PMTONSGOODTOTALDAY'  
      then t.value  
      else 0  
      end  
     )>0  
   then sum(  
      case  
      when t.VarType = 'PMELECTRICTOTALDAY'  
      then t.value  
      else 0  
      end  
     )/  
     sum(  
      case  
      when t.VarType = 'PMTONSGOODTOTALDAY'  
      then t.value  
      else 0  
      end  
     )  
   else 0  
   end, -- Electricity Eff.  
   sum(  
    case  
    when t.VarType = 'PMGASTOTALDAY'  
    then t.value  
    else 0  
    end  
   ), -- Total Gas   
   case  
   when sum(  
      case  
      when t.VarType = 'PMTONSGOODTOTALDAY'  
      then t.value  
      else 0  
      end  
     )>0  
   then sum(  
      case  
      when t.VarType = 'PMGASTOTALDAY'  
      then t.value  
      else 0  
      end  
     )/  
     sum(  
      case  
      when t.VarType = 'PMTONSGOODTOTALDAY'  
      then t.value  
      else 0  
      end  
     )  
   else 0  
   end, -- Gas Eff.  
   min(ps.start_time) -- Brand Date  
  FROM dbo.#tests t  
  join @produnits pu  
  on t.puid = pu.puid  
  join @prodlines pl  
  on pu.plid = pl.plid   
  left join @productionstarts ps  
  on ps.prod_id = t.prodid  
  --and ps.pu_id = t.puid  
  and ps.pu_id = coalesce(pu.masterunit,pu.puid)  
  and t.resulton between ps.start_time and ps.end_time  
  where PUType = 'pm'  
  and pldesc not like '%nrg%'    
  GROUP BY pl.pldesc, t.prodcode    
  ORDER BY pl.pldesc, min(ps.start_time), t.prodcode  
  option (keep plan)  
  
  
  if (SELECT count(*) FROM @FinanceSummary) > 65000   
   begin  
   select @TooMuchDataMsg [User Notification Msg]  
   end  
  else  
   begin   
   if (SELECT count(*) FROM @FinanceSummary) = 0   
    begin  
    select @NoDataMsg [User Notification Msg]  
    end  
   else    
    begin  
    select *   
    from @FinanceSummary  
    order by [PM], [Brand Date]  
    end  
   end  
  
  insert @SumTotals  
  select  
   PM,   
   sum([Good Tonnes (tonnes)]), -- Total1:  Total Good   
   sum([Total Steam (MMlbs)]), -- Total2:  Total Steam  
   case  
   when sum([Good Tonnes (tonnes)])>0  
   then sum([Total Steam (MMlbs)])/sum([Good Tonnes (tonnes)])  
   else 0  
   end,  -- Total3: Steam Eff  
   sum([Total Electricity (kWh)]), -- Total4: Total Electricity  
   case  
   when sum([Good Tonnes (tonnes)])>0  
   then sum([Total Electricity (kWh)])/sum([Good Tonnes (tonnes)])  
   else 0  
   end,  -- Total5: Electricity Eff  
   sum([Total Gas (Mscf)]), -- Total6: Total Gas  
   case  
   when sum([Good Tonnes (tonnes)])>0  
   then sum([Total Gas (Mscf)])/sum([Good Tonnes (tonnes)])  
   else 0  
   end,  -- Total7: Gas Eff  
   null, -- Total8  
   null, -- Total9  
   null -- Total10  
  from @FinanceSummary  
  group by [PM]  
  
  select * from @SumTotals  
  order by [PM]  
  delete @SumTotals  
  
  
  -------------------------------------------------------------------------------------------  
  -- Section 23: Results Set #21 & 22 - Return the result set for Boiler Summary  
  -------------------------------------------------------------------------------------------  
  
  INSERT @BoilerSummary  
  SELECT   
   pudesc, -- Boiler  
   sum(  
    case  
    when t.VarType = 'BLRFEEDWATERTOTALHR'  
    then t.value  
    else 0  
    end  
   ), -- Total Feedwater  
   sum(  
    case  
    when t.VarType = 'BLRSTEAMTOTALHR'  
    then t.value  
    else 0  
    end  
   ), -- Total Steam  
   sum(  
    case  
    when t.VarType = 'BLRGASTOTALHR'  
    then t.value  
    else 0  
    end  
   ), -- Total Gas  
   sum(  
    case  
    when t.VarType = 'BLROILTOTALHR'  
    then t.value  
    else 0  
    end  
   ), -- Total Oil  
   sum(  
    case  
    when t.VarType = 'BLROILTOTALHR'  
    then t.value  
    else 0  
    end  
   )/datediff(n,@starttime,@endtime), -- GPM  
   sum(  
    case  
    when t.VarType = 'BLRPWTTOTALHR'  
    then t.value  
    else 0  
    end  
   ), -- Total Solid Fuels   
   sum(  
    case  
    when t.VarType = 'BLRBTUINTOTALHR'  
    then t.value  
    else 0  
    end  
   ), -- Total BTU In  
   sum(  
    case  
    when t.VarType = 'BLRBTUOUTTOTALHR'  
    then t.value  
    else 0  
    end  
   ), -- Total BTU Out  
   case  
   when sum(  
      case  
      when t.VarType = 'BLRBTUINTOTALHR'  
      then t.value  
      else 0  
      end  
     ) > 0  
   then sum(  
      case  
      when t.VarType = 'BLRBTUOUTTOTALHR'  
      then t.value  
      else 0  
      end  
     )/  
     sum(  
      case  
      when t.VarType = 'BLRBTUINTOTALHR'  
      then t.value  
      else 0  
      end  
     )  
   else 0  
   end, -- Efficiency %  
   (  
   select top 1 lowerreject  
   from @targets tgt  
   where tgt.puid = t.puid  
   and VarType like '%EFFICIENCYHR'  
   order by starttime desc  
   )/100 -- Efficiency % Trgt.  
   -- the template formats columns with '%' in the header as percentage  
   -- so we have to divide by 100 here.  
  FROM dbo.#tests t  
  join @produnits pu  
  on t.puid = pu.puid   
  join @prodlines pl  
  on pu.plid = pl.plid  
  where PUType = 'boiler'    
  GROUP BY pu.pudesc, t.puid  
  ORDER BY pu.pudesc, t.puid  
  option (keep plan)  
  
  
  if (SELECT count(*) FROM @BoilerSummary) > 65000   
   begin  
   select @TooMuchDataMsg [User Notification Msg]  
   end  
  else  
   begin   
   if (SELECT count(*) FROM @BoilerSummary) = 0   
    begin  
    select @NoDataMsg [User Notification Msg]  
    end  
   else    
    begin  
    select *   
    from @BoilerSummary  
    order by [Boiler]  
    end  
   end  
  
  insert @SumTotals  
  select   
   '',  
   sum([Feedwater (Mlbs)]), -- Total1: Total Feedwater  
   sum([Steam (Mlbs)]), -- Total2: Total Steam  
   sum([Gas (Mscf)]), -- Total3: Total Gas  
   sum([Oil (gal)]), -- Total4: Total Oil  
   sum([Oil (gal)])/datediff(n,@starttime,@endtime), -- Total5: Total Oil gpm  
   sum([Solid Fuel (tons)]), -- Total6: Total Solid Fuels  
   sum([BTU In]), -- Total7: Total BTU In  
   sum([BTU Out]), -- Total8: Total BTU Out  
   case  
   when sum([BTU IN]) > 0  
   then sum([BTU Out])/sum([BTU In])  
   else 0   
   end, -- Total9: Efficiency %   
   (select lowerreject from @targets tgt where vartype = 'TOTALBOILEREFFICIENCYHR')/100 -- Total10: Efficiency % Trgt  
  from @BoilerSummary  
  
  select * from @SumTotals  
  order by [PM]  
  
  
  -------------------------------------------------------------------------------------------  
  -- Section 24: Results Set #22 - Return the result set for Condensate Summary  
  -------------------------------------------------------------------------------------------  
  
  insert @CondensateSummary  
  select  
   sum(  
    case  
    when t.VarType = 'BLRROTOTALHR'  
    then t.value  
    else 0  
    end  
   ), -- Total RO  
   sum(  
    case  
    when t.VarType = 'BLRVENTSTEAMTOTALHR'  
    then t.value  
    else 0  
    end  
   ), -- Total Vent Steam   
   sum(  
    case  
    when t.VarType = 'BLRCONDRETTOTALHR'  
    then t.value  
    else 0  
    end  
   ), -- Condensate Return  
   case  
   when (select Total2 from @SumTotals) > 0  
   then (sum(  
     case  
     when t.VarType = 'BLRCONDRETTOTALHR'  
     then t.value  
     else 0  
     end  
     )/(select Total2 from @SumTotals ))  
     -- the original formula called for multiplication by 100  
     -- but the template formats columns with '%' in the header as percentage  
     -- so we removed the multiplication  
   else 0  
   end -- Condensate Return %    
  FROM dbo.#tests t  
  join @produnits pu  
  on t.puid = pu.puid   
  join @prodlines pl  
  on pu.plid = pl.plid  
  option (keep plan)  
  
  select * from @CondensateSummary  
  
  
 end  
  
  
-------------------------------------------------------------------------------------------  
-- Section 25: Drop temp tables  
-------------------------------------------------------------------------------------------  
  
Finished:  
  
drop table dbo.#tests  
  
  
RETURN  
  
