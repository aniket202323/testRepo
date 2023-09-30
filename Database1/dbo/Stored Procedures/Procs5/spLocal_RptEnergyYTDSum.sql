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
  
Steam:  
Condensate Return = sum(Blr Cond Ret Total Day) / sum(Blr Sum Steam Total Day)  
Boiler Efficiency = sum(Blr BTU In Total Day) / sum(Blr BTU Out Day)  
  
H2O_W H2O:  
Water = sum(PM Water Total Day) / sum(PM TAY Total Day)  
  
  
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
Section 9:  Populate the test table  
Section 10: If there are Error Messages, then return them without other result sets.  
Section 11: Results Set #1 - Return the empty Error Messages.    
Section 12: Results Set #2 -  return the report parameter values.  
Section 13: Results Set #3 - Return the result set for Dry Energy  
Section 14: Results Set #4 - Return the result set for Steam  
Section 15: Results Set #5 - Return the result set for Cogen  
Section 16: Results Set #6 - Return the result set for H2O_W  
Section 17: Results Set #7 - Return the result set for Chill H20  
Section 18: Results Set #8 - Return the result set for Comp. Air  
Section 19: Drop temp tables  
  
  
--------------------------------------------------------  
--  Edit History:  
--------------------------------------------------------  
  
/*  
  
2005-10-06 Jeff Jaeger Rev1.01  
 - updated the calc for condensate return.  
 -  added code to update the Units in the Steam result set.  
  
2005-10-10 Jeff Jaeger Rev1.02  
 - Changed StartTime in #tests to ResultOn.  
 - Corrected date comparisons when referencing the #tests table.  
 - When summing test values according to the month in result sets, added code to subtract one second from the   
  resulton value.  This is so that the test result initiated within the month but ending at the start of the next month   
  will be included in the summation.  
  
2006-JUL-07 Langdon Davis Rev1.03  
 - Changed RptLabel from VARCHAR(50) to VARCHAR(255).  
*/  
  
----------------------------------------------------------------------------------------------------------  
----------------------------------------------------------------------------------------------------------  
*/  
  
CREATE PROCEDURE dbo.spLocal_RptEnergyYTDSum  
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
@StartTime = '2005-07-01', --'2005-07-01 00:00:00',   
@EndTime = '2005-08-01', --'2006-06-01 00:00:00',   
@RptName = 'Energy YTD Summary for Testing' --'Save For Development Testing'  
  
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
 PLDesc            VARCHAR(100)  
 )  
  
  
-----------------------------------------------------------------------  
-- this table will hold Prod Units data for Converting lines  
-----------------------------------------------------------------------  
  
DECLARE @ProdUnits TABLE   
 (  
 PUId             INTEGER PRIMARY KEY,  
 PUDesc            VARCHAR(100),  
 RptLabel            varchar(255),  
 masterunit           int,  
 PLId             INTEGER  
 )  
  
  
---------------------------------------------------------------------------  
-- This table will hold all test results  
---------------------------------------------------------------------------  
  
declare @Variables table  
 (  
 VarID             int,  
 VarDesc            varchar(100),  
 Units             varchar(50),  
 PUID             int,  
 ExtendedInfo          varchar(255)  
 primary key (varid)  
 )  
  
  
create table dbo.#Tests   
 (  
 VarId             INTEGER,  
 puid             int,  
 Value             float,  
 VarType            varchar(25),  
 ResultOn            DATETIME,  
 primary key (varid, ResultOn)  
 )  
  
  
declare @Results table  
 (  
 [PM]             varchar(50),  
 [PUID]            int,  
 [OrderID]           int,  
 [VarDesc]           varchar(100),  
 [Units]            varchar(50),  
 [Jul]             float,  
 [Aug]             float,  
 [Sep]             float,  
 [Oct]             float,  
 [Nov]             float,  
 [Dec]             float,  
 [Jan]             float,  
 [Feb]             float,  
 [Mar]             float,  
 [Apr]             float,  
 [May]             float,  
 [Jun]             float  
 )  
  
  
-------------------------------------------------------------------------------  
-- Section 3: Assign constant values  
-------------------------------------------------------------------------------  
  
select  
@ExtInfoTag   = 'UtilCEORpt=',  
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
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptProdLineList','',     @ProdLineList OUTPUT  
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
  
--select @ProdLineList --=  'MP1M|MP2M|MP3M|MP4M|MP5M|MP6M|MP7M|MP8M|MP UT NRG|MP UT Cogen Usage|MP UT WWT Usage'   
  
-------------------------------------------------------------------------------  
-- Section 8: Get information for ProdUnitList  
-------------------------------------------------------------------------------  
  
insert @ProdLines  
select   
 pl_id,  
 pl_desc  
from prod_lines  
where charindex('|' + replace(pl_desc, 'TT ', '') + '|', '|' + @ProdLineList + '|')>0  
option (keep plan)  
  
  
-- note that some values are parsed from the extended_info field  
INSERT @ProdUnits   
SELECT   
 pu.PU_Id,  
 pu.PU_Desc,  
 dbo.fnLocal_GlblParseInfoWithSpaces(pu.extended_info,'UTILCEORpt='),  
 pu.master_unit,  
 pu.PL_Id  
FROM dbo.Prod_Units pu  
join @ProdLines pl  
on pu.pl_id = pl.plid  
where pu_desc like '%production%' or pu_desc like '%materials%' or pu_desc like '%usage%'  
option (keep plan)  
  
  
----------------------------------------------------------------------------  
-- Section 9: Populate the test table  
----------------------------------------------------------------------------  
  
-- Compile the variables for this report  
  
 INSERT @Variables  
 select  
  Var_ID,  
  Var_desc,  
  eng_units,  
  pu_id,  
  Extended_Info  
 from dbo.variables v  
 join @produnits pu  
 on v.pu_id = pu.puid  
 where charindex(@ExtInfoTag,lower(extended_info))>0  
  
  
-- Certain test results need to be compiled for this report.  This section of code will   
-- hit the test table one time, and get all the data needed and put it into a temporary table.    
  
  
 INSERT dbo.#Tests   
 SELECT  
  t.Var_Id,  
  pu.puid,   
  t.Result,  
  dbo.fnLocal_GlblParseInfo(v.extendedinfo,'UTILCEORpt='),   
  t.Result_On  
 FROM  @ProdUnits pu  
 join @variables v  
 on pu.puid = v.puid  
 join dbo.tests t  
 on t.var_id = v.varid  
 and result_on <= @EndTime  
 AND result_on > @StartTime  
 and result is not null  
 option (keep plan)  
  
 update dbo.#tests   
  set vartype = 'PMUSAGE'  
 where vartype like '%pm%usage%'  
  
  
-----------------------------------------------------------  
ReturnResultSets:  
-----------------------------------------------------------  
  
--select * from @produnits  
--select extendedinfo from @variables v   
--select *  
--datepart(dd,starttime),  
--sum(coalesce(value,0))   
--from #tests t  
--where vartype = 'PMTAYTOTALDAY'  
--and puid = 2276  
--and datepart(mm,starttime) = 9  
--and datepart(dd,starttime) = 1  
  
----------------------------------------------------------------------------------------------------  
-- Section 10: If there are Error Messages, then return them without other result sets.  
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
 -- Section 11: Results Set #1 - Return the empty Error Messages.    
 -------------------------------------------------------------------------------  
  
 SELECT ErrMsg  
 FROM @ErrorMessages  
  
  
 -----------------------------------------------------------------------------  
 -- Section 12: Results Set #2 -  return the report parameter values.  
 ----------------------------------------------------------------------------  
  
 -----------------------------------------------------------------------------------------  
 -- This RS is used when Report Parameter values are required within the Excel Template.  
 -----------------------------------------------------------------------------------------  
  
 SELECT  
  (select value from site_parameters where parm_id = 12) [ServerName],  
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
  -- Section 13: Results Set #3 - Return the result set for Dry Energy  
  -------------------------------------------------------------------------------------------  
  
   
  insert @Results  
  select  
   ltrim(rtrim(right(pldesc,len(pldesc) -5))), -- [PM]  
   pu.PUID,   
   case  
    when vartype = 'PMTAYTOTALDAY'  
    then 1  
    when vartype = 'PMSTEAMTOTALDAY'  
    then 2  
    when vartype = 'PMGASTOTALDAY'  
    then 3  
    when vartype = 'PMAIRTOTALDAY'  
    then 4  
    when vartype = 'PMELECTRICTOTALDAY'  
    then 5  
    when vartype = 'PMOILTOTALDAY'  
    then 6  
    when vartype = 'PMUSAGE'  
    then 7  
    else 8  
   end, --[OrderID]  
   vartype, -- [VarDesc]  
   units, --[Units],  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 7  
   then value  
   else  0  
   end), --[Jul]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 8  
   then value  
   else  0  
   end), --[Aug]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 9  
   then value  
   else  0  
   end), --[Sep]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 10  
   then value  
   else  0  
   end), --[Oct]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 11  
   then value  
   else  0  
   end), --[Nov]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 12  
   then value  
   else  0  
   end), --[Dec]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 1  
   then value  
   else  0  
   end), --[Jan]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 2  
   then value  
   else  0  
   end), --[Feb]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 3  
   then value  
   else  0  
   end), --[Mar]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 4  
   then value  
   else  0  
   end), --[Apr]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 5  
   then value  
   else  0  
   end), --[May]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 6  
   then value  
   else  0  
   end) --[Jun]  
  FROM @variables v  
  join dbo.#tests t  
  on v.varid = t.varid  
  join @produnits pu  
  on v.puid = pu.puid  
  join @prodlines pl  
  on pu.plid = pl.plid   
  where t.vartype = 'PMTAYTOTALDAY'  
  or t.vartype = 'PMSTEAMTOTALDAY'  
  or t.vartype = 'PMGASTOTALDAY'  
  or t.vartype = 'PMOILTOTALDAY'  
  or t.vartype = 'PMAIRTOTALDAY'  
  or t.vartype = 'PMELECTRICTOTALDAY'  
  or t.vartype = 'PMUSAGE'  
  GROUP BY pldesc,vartype,units,pu.puid  
  ORDER BY pldesc,vartype,units,pu.puid  
  option (keep plan)  
  
  -- Divide summarized values by Total TAY  
  update r1 set  
   [Jul] =  (  
      select  case  
         when r2.[Jul] > 0   
         then r1.[Jul] / r2.[Jul]   
         else 0  
         end  
      from @Results r2   
      where r1.pm = r2.pm   
      and r2.[OrderID] = 1  
      ),  
   [Aug] =  (  
      select  case  
         when r2.[Aug] > 0   
         then r1.[Aug] / r2.[Aug]   
         else 0  
         end  
      from @Results r2   
      where r1.pm = r2.pm   
      and r2.[OrderID] = 1  
      ),  
   [Sep] = (  
      select  case  
         when r2.[Sep] > 0   
         then r1.[Sep] / r2.[Sep]   
         else 0  
         end  
      from @Results r2   
      where r1.pm = r2.pm   
      and r2.[OrderID] = 1  
      ),  
   [Oct] = (  
      select  case  
         when r2.[Oct] > 0   
         then r1.[Oct] / r2.[Oct]   
         else 0  
         end  
      from @Results r2   
      where r1.pm = r2.pm   
      and r2.[OrderID] = 1  
      ),  
   [Nov] = (  
      select  case  
         when r2.[Nov] > 0   
         then r1.[Nov] / r2.[Nov]   
         else 0  
         end  
      from @Results r2   
      where r1.pm = r2.pm   
      and r2.[OrderID] = 1  
      ),  
   [Dec] = (  
      select  case  
         when r2.[Dec] > 0   
         then r1.[Dec] / r2.[Dec]   
         else 0  
         end  
      from @Results r2   
      where r1.pm = r2.pm   
      and r2.[OrderID] = 1  
      ),  
   [Jan] = (  
      select  case  
         when r2.[Jan] > 0   
         then r1.[Jan] / r2.[Jan]   
         else 0  
         end  
      from @Results r2   
      where r1.pm = r2.pm   
      and r2.[OrderID] = 1  
      ),  
   [Feb] = (  
      select  case  
         when r2.[Feb] > 0   
         then r1.[Feb] / r2.[Feb]   
         else 0  
         end  
      from @Results r2   
      where r1.pm = r2.pm   
      and r2.[OrderID] = 1  
      ),  
   [Mar] = (  
      select  case  
         when r2.[Mar] > 0   
         then r1.[Mar] / r2.[Mar]   
         else 0  
         end  
      from @Results r2   
      where r1.pm = r2.pm   
      and r2.[OrderID] = 1  
      ),  
   [Apr] = (  
      select  case  
         when r2.[Apr] > 0   
         then r1.[Apr] / r2.[Apr]   
         else 0  
         end  
      from @Results r2   
      where r1.pm = r2.pm   
      and r2.[OrderID] = 1  
      ),  
   [May] = (  
      select  case  
         when r2.[May] > 0   
         then r1.[May] / r2.[May]   
         else 0  
         end  
      from @Results r2   
      where r1.pm = r2.pm   
      and r2.[OrderID] = 1  
      ),  
   [Jun] = (  
      select  case  
         when r2.[Jun] > 0   
         then r1.[Jun] / r2.[Jun]   
         else 0  
         end  
      from @Results r2   
      where r1.pm = r2.pm   
      and r2.[OrderID] = 1  
      ),  
   [Units] =  (  
       select r1.units + '/' + r2.units  
       from @Results r2  
       where r1.pm=r2.pm  
       and r2.[OrderID] = 1   
       )  
  from @Results r1  
  where r1.[OrderID] > 1  
  
  
  if (SELECT count(*) FROM @Results) > 65000   
   begin  
   select @TooMuchDataMsg [User Notification Msg]  
   end  
  else  
   begin   
   if (SELECT count(*) FROM @Results) = 0   
    begin  
    select @NoDataMsg [User Notification Msg]  
    end  
   else    
    begin  
    select *   
    from @Results  
    order by [PM], [OrderID]  
    end  
   end  
  
 delete @Results  
  
  
  -------------------------------------------------------------------------------------------  
  -- Section 14: Results Set #4 - Return the result set for Steam  
  -------------------------------------------------------------------------------------------  
  
   
  insert @Results  
  select  
   ltrim(rtrim(right(pldesc,len(pldesc) -5))), -- [PM]  
   pu.PUID,  
   case  
    when vartype = 'BLRCONDRETTOTALDAY'  
    then 1  
    when vartype = 'BLRVENTSTEAMTOTALDAY'  
    then 2  
    when vartype = 'BLRBTUOUTTOTALDAY'  
    then 3  
    when vartype = 'BLRSUMSTEAMTOTALDAY'  
    then 4  
    when vartype = 'BLRBTUINTOTALDAY'  
    then 5  
    else 0  
   end, --[OrderID]  
   coalesce(RptLabel,vardesc), --[VarDesc],  
   units, --[Units],  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 7  
   then value  
   else  0  
   end), --[Jul]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 8  
   then value  
   else  0  
   end), --[Aug]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 9  
   then value  
   else  0  
   end), --[Sep]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 10  
   then value  
   else  0  
   end), --[Oct]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 11  
   then value  
   else  0  
   end), --[Nov]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 12  
   then value  
   else  0  
   end), --[Dec]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 1  
   then value  
   else  0  
   end), --[Jan]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 2  
   then value  
   else  0  
   end), --[Feb]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 3  
   then value  
   else  0  
   end), --[Mar]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 4  
   then value  
   else  0  
   end), --[Apr]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 5  
   then value  
   else  0  
   end), --[May]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 6  
   then value  
   else  0  
   end) --[Jun]  
  FROM @variables v  
  join dbo.#tests t  
  on v.varid = t.varid  
  join @produnits pu  
  on v.puid = coalesce(pu.puid,masterunit)  
  join @prodlines pl  
  on pu.plid = pl.plid   
  where t.vartype = 'BLRCONDRETTOTALDAY'  
  or t.vartype = 'BLRVENTSTEAMTOTALDAY'  
  or t.vartype = 'BLRBTUINTOTALDAY'  
  or t.vartype = 'BLRSUMSTEAMTOTALDAY'  
  or t.vartype = 'BLRBTUOUTTOTALDAY'  
  GROUP BY pldesc,vartype,coalesce(RptLabel,vardesc),units,pu.puid  
  ORDER BY pldesc,vartype,coalesce(RptLabel,vardesc),units,pu.puid  
  option (keep plan)  
  
  update @results set  
   units = '%'  
  where [OrderID] = 1   
  or [OrderId] = 3  
  
  
  -- Calc Condensate Return  
  update r1 set  
   [Jul] =  (  
      select  case  
         when r2.[Jul] > 0  
         then r1.[Jul] / r2.[Jul]  
         else 0  
         end  
      from   @Results r2  
      where  r1.puid = r2.puid  
      and  r2.[OrderID] = 4  
      ),  
   [Aug] =  (  
      select  case  
         when r2.[Aug] > 0  
         then r1.[Aug] / r2.[Aug]  
         else 0  
         end  
      from   @Results r2  
      where  r1.puid = r2.puid  
      and  r2.[OrderID] = 4  
      ),  
   [Sep] =  (  
      select  case  
         when r2.[Sep] > 0  
         then r1.[Sep] / r2.[Sep]  
         else 0  
         end  
      from   @Results r2  
      where  r1.puid = r2.puid  
      and  r2.[OrderID] = 4  
      ),  
   [Oct] =  (  
      select  case  
         when r2.[Oct] > 0  
         then r1.[Oct] / r2.[Oct]  
         else 0  
         end  
      from   @Results r2  
      where  r1.puid = r2.puid  
      and  r2.[OrderID] = 4  
      ),  
   [Nov] =  (  
      select  case  
         when r2.[Nov] > 0  
         then r1.[Nov] / r2.[Nov]  
         else 0  
         end  
      from   @Results r2  
      where  r1.puid = r2.puid  
      and  r2.[OrderID] = 4  
      ),  
   [Dec] =  (  
      select  case  
         when r2.[Dec] > 0  
         then r1.[Dec] / r2.[Dec]  
         else 0  
         end  
      from   @Results r2  
      where  r1.puid = r2.puid  
      and  r2.[OrderID] = 4  
      ),  
   [Jan] =  (  
      select  case  
         when r2.[Jan] > 0  
         then r1.[Jan] / r2.[Jan]  
         else 0  
         end  
      from   @Results r2  
      where  r1.puid = r2.puid  
      and  r2.[OrderID] = 4  
      ),  
   [Feb] =  (  
      select  case  
         when r2.[Feb] > 0  
         then r1.[Feb] / r2.[Feb]  
         else 0  
         end  
      from   @Results r2  
      where  r1.puid = r2.puid  
      and  r2.[OrderID] = 4  
      ),  
   [Mar] =  (  
      select  case  
         when r2.[Mar] > 0  
         then r1.[Mar] / r2.[Mar]  
         else 0  
         end  
      from   @Results r2  
      where  r1.puid = r2.puid  
      and  r2.[OrderID] = 4  
      ),  
   [Apr] =  (  
      select  case  
         when r2.[Apr] > 0  
         then r1.[Apr] / r2.[Apr]  
         else 0  
         end  
      from   @Results r2  
      where  r1.puid = r2.puid  
      and  r2.[OrderID] = 4  
      ),  
   [May] =  (  
      select  case  
         when r2.[May] > 0  
         then r1.[May] / r2.[May]  
         else 0  
         end  
      from   @Results r2  
      where  r1.puid = r2.puid  
      and  r2.[OrderID] = 4  
      ),  
   [Jun] =  (  
      select  case  
         when r2.[Jun] > 0  
         then r1.[Jun] / r2.[Jun]  
         else 0  
         end  
      from   @Results r2  
      where  r1.puid = r2.puid  
      and  r2.[OrderID] = 4  
      )  
  from @Results r1  
  where r1.[OrderID] = 1  
  
  -- Calc boiler efficiency  
  update r1 set  
   [Jul] =  (  
      select  case  
         when r2.[Jul] > 0  
         then r1.[Jul] / r2.[Jul]  
         else 0  
         end  
      from   @Results r2  
      where  r1.puid = r2.puid  
      and  r2.[OrderID] = 5  
      ),  
   [Aug] =  (  
      select  case  
         when r2.[Aug] > 0  
         then r1.[Aug] / r2.[Aug]  
         else 0  
         end  
      from   @Results r2  
      where  r1.puid = r2.puid  
      and  r2.[OrderID] = 5  
      ),  
   [Sep] =  (  
      select  case  
         when r2.[Sep] > 0  
         then r1.[Sep] / r2.[Sep]  
         else 0  
         end  
      from   @Results r2  
      where  r1.puid = r2.puid  
      and  r2.[OrderID] = 5  
      ),  
   [Oct] =  (  
      select  case  
         when r2.[Oct] > 0  
         then r1.[Oct] / r2.[Oct]  
         else 0  
         end  
      from   @Results r2  
      where  r1.puid = r2.puid  
      and  r2.[OrderID] = 5  
      ),  
   [Nov] = (  
      select  case  
         when r2.[Nov] > 0  
         then r1.[Nov] / r2.[Nov]  
         else 0  
         end  
      from   @Results r2  
      where  r1.puid = r2.puid  
      and  r2.[OrderID] = 5  
      ),  
   [Dec] =  (  
      select  case  
         when r2.[Dec] > 0  
         then r1.[Dec] / r2.[Dec]  
         else 0  
         end  
      from   @Results r2  
      where  r1.puid = r2.puid  
      and  r2.[OrderID] = 5  
      ),  
   [Jan] =  (  
      select  case  
         when r2.[Jan] > 0  
         then r1.[Jan] / r2.[Jan]  
         else 0  
         end  
      from   @Results r2  
      where  r1.puid = r2.puid  
      and  r2.[OrderID] = 5  
      ),  
   [Feb] =  (  
      select  case  
         when r2.[Feb] > 0  
         then r1.[Feb] / r2.[Feb]  
         else 0  
         end  
      from   @Results r2  
      where  r1.puid = r2.puid  
      and  r2.[OrderID] = 5  
      ),  
   [Mar] =  (  
      select  case  
         when r2.[Mar] > 0  
         then r1.[Mar] / r2.[Mar]  
         else 0  
         end  
      from   @Results r2  
      where  r1.puid = r2.puid  
      and  r2.[OrderID] = 5  
      ),  
   [Apr] =  (  
      select  case  
         when r2.[Apr] > 0  
         then r1.[Apr] / r2.[Apr]  
         else 0  
         end  
      from   @Results r2  
      where  r1.puid = r2.puid  
      and  r2.[OrderID] = 5  
      ),  
   [May] =  (  
      select  case  
         when r2.[May] > 0  
         then r1.[May] / r2.[May]  
         else 0  
         end  
      from   @Results r2  
      where  r1.puid = r2.puid  
      and  r2.[OrderID] = 5  
      ),  
   [Jun] =  (  
      select  case  
         when r2.[Jun] > 0  
         then r1.[Jun] / r2.[Jun]  
         else 0  
         end  
      from   @Results r2  
      where  r1.puid = r2.puid  
      and  r2.[OrderID] = 5  
      )  
  from @Results r1  
  where r1.[OrderID] = 3  
  
  
  
  if (SELECT count(*) FROM @Results where [OrderID] < 4) > 65000   
   begin  
   select @TooMuchDataMsg [User Notification Msg]  
   end  
  else  
   begin   
   if (SELECT count(*) FROM @Results) = 0   
    begin  
    select @NoDataMsg [User Notification Msg]  
    end  
   else    
    begin  
    select *   
    from @Results  
    where [OrderID] < 4  
    order by [PM], [OrderID], [VarDesc]  
    end  
   end  
  
 delete @Results  
  
  
  -------------------------------------------------------------------------------------------  
  -- Section 15: Results Set #5 - Return the result set for Cogen  
  -------------------------------------------------------------------------------------------  
  
   
  insert @Results  
  select  
   '', --replace(pldesc,'TT ',''), -- [PM]  
   pu.PUID,   
   1, --[OrderID]  
   vardesc, --dbo.fnLocal_GlblParseInfo(v.extendedinfo,'GlblDesc='), -- [VarDesc]  
   units, --[Units],  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 7  
   then value  
   else  0  
   end), --[Jul]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 8  
   then value  
   else  0  
   end), --[Aug]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 9  
   then value  
   else  0  
   end), --[Sep]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 10  
   then value  
   else  0  
   end), --[Oct]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 11  
   then value  
   else  0  
   end), --[Nov]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 12  
   then value  
   else  0  
   end), --[Dec]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 1  
   then value  
   else  0  
   end), --[Jan]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 2  
   then value  
   else  0  
   end), --[Feb]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 3  
   then value  
   else  0  
   end), --[Mar]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 4  
   then value  
   else  0  
   end), --[Apr]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 5  
   then value  
   else  0  
   end), --[May]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 6  
   then value  
   else  0  
   end) --[Jun]  
  FROM @variables v  
  join dbo.#tests t  
  on v.varid = t.varid  
  join @produnits pu  
  on v.puid = pu.puid  
  join @prodlines pl  
  on pu.plid = pl.plid   
  where t.vartype = 'COGENTURBINEAIRVENTEDDAY'  
  GROUP BY vartype,vardesc,units,pu.puid  
  ORDER BY vartype,vardesc,units,pu.puid  
  option (keep plan)  
  
  
  if (SELECT count(*) FROM @Results) > 65000   
   begin  
   select @TooMuchDataMsg [User Notification Msg]  
   end  
  else  
   begin   
   if (SELECT count(*) FROM @Results) = 0   
    begin  
    select @NoDataMsg [User Notification Msg]  
    end  
   else    
    begin  
    select *   
    from @Results  
    order by [PM], [OrderID]  
    end  
   end  
  
 delete @Results  
  
  
  -------------------------------------------------------------------------------------------  
  -- Section 16: Results Set #6 - Return the result set for H2O_W  
  -------------------------------------------------------------------------------------------  
  
   
  insert @Results  
  select  
   ltrim(rtrim(right(pldesc,len(pldesc) -5))), -- [PM]  
   pu.PUID,   
   case  
    when vartype = 'PMWATERTOTALDAY'  
    then 1  
    when vartype = 'WWDISCHARGESOLIDSDAY'  
    then 2  
    when vartype = 'PMTAYTOTALDAY'  
    then 3  
    else 0  
   end, --[OrderID]  
   vardesc, -- [VarDesc]  
   units, --[Units],  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 7  
   then value  
   else  0  
   end), --[Jul]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 8  
   then value  
   else  0  
   end), --[Aug]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 9  
   then value  
   else  0  
   end), --[Sep]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 10  
   then value  
   else  0  
   end), --[Oct]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 11  
   then value  
   else  0  
   end), --[Nov]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 12  
   then value  
   else  0  
   end), --[Dec]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 1  
   then value  
   else  0  
   end), --[Jan]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 2  
   then value  
   else  0  
   end), --[Feb]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 3  
   then value  
   else  0  
   end), --[Mar]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 4  
   then value  
   else  0  
   end), --[Apr]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 5  
   then value  
   else  0  
   end), --[May]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 6  
   then value  
   else  0  
   end) --[Jun]  
  FROM @variables v  
  join dbo.#tests t  
  on v.varid = t.varid  
  join @produnits pu  
  on v.puid = pu.puid  
  join @prodlines pl  
  on pu.plid = pl.plid   
  where t.vartype = 'PMWATERTOTALDAY'  
  or t.vartype = 'WWDISCHARGESOLIDSDAY'  
  or t.vartype = 'PMTAYTOTALDAY'  
  GROUP BY pldesc,vartype,vardesc,units,pu.puid  
  ORDER BY pldesc,vartype,vardesc,units,pu.puid  
  option (keep plan)  
  
  -- divide Total Water by Total TAY  
  update r1 set  
   [Jul] =  (  
      select  case  
         when r2.[Jul] > 0   
         then r1.[Jul] / r2.[Jul]   
         else 0  
         end  
      from @Results r2   
      where r1.pm = r2.pm   
      and r2.[OrderID] = 3  
      ),  
   [Aug] =  (  
      select  case  
         when r2.[Aug] > 0   
         then r1.[Aug] / r2.[Aug]   
         else 0  
         end  
      from @Results r2   
      where r1.pm = r2.pm   
      and r2.[OrderID] = 3  
      ),  
   [Sep] = (  
      select  case  
         when r2.[Sep] > 0   
         then r1.[Sep] / r2.[Sep]   
         else 0  
         end  
      from @Results r2   
      where r1.pm = r2.pm   
      and r2.[OrderID] = 3  
      ),  
   [Oct] = (  
      select  case  
         when r2.[Oct] > 0   
         then r1.[Oct] / r2.[Oct]   
         else 0  
         end  
      from @Results r2   
      where r1.pm = r2.pm   
      and r2.[OrderID] = 3  
      ),  
   [Nov] = (  
      select  case  
         when r2.[Nov] > 0   
         then r1.[Nov] / r2.[Nov]   
         else 0  
         end  
      from @Results r2   
      where r1.pm = r2.pm   
      and r2.[OrderID] = 3  
      ),  
   [Dec] = (  
      select  case  
         when r2.[Dec] > 0   
         then r1.[Dec] / r2.[Dec]   
         else 0  
         end  
      from @Results r2   
      where r1.pm = r2.pm   
      and r2.[OrderID] = 3  
      ),  
   [Jan] = (  
      select  case  
         when r2.[Jan] > 0   
         then r1.[Jan] / r2.[Jan]   
         else 0  
         end  
      from @Results r2   
      where r1.pm = r2.pm   
      and r2.[OrderID] = 3  
      ),  
   [Feb] = (  
      select  case  
         when r2.[Feb] > 0   
         then r1.[Feb] / r2.[Feb]   
         else 0  
         end  
      from @Results r2   
      where r1.pm = r2.pm   
      and r2.[OrderID] = 3  
      ),  
   [Mar] = (  
      select  case  
         when r2.[Mar] > 0   
         then r1.[Mar] / r2.[Mar]   
         else 0  
         end  
      from @Results r2   
      where r1.pm = r2.pm   
      and r2.[OrderID] = 3  
      ),  
   [Apr] = (  
      select  case  
         when r2.[Apr] > 0   
         then r1.[Apr] / r2.[Apr]   
         else 0  
         end  
      from @Results r2   
      where r1.pm = r2.pm   
      and r2.[OrderID] = 3  
      ),  
   [May] = (  
      select  case  
         when r2.[May] > 0   
         then r1.[May] / r2.[May]   
         else 0  
         end  
      from @Results r2   
      where r1.pm = r2.pm   
      and r2.[OrderID] = 3  
      ),  
   [Jun] = (  
      select  case  
         when r2.[Jun] > 0   
         then r1.[Jun] / r2.[Jun]   
         else 0  
         end  
      from @Results r2   
      where r1.pm = r2.pm   
      and r2.[OrderID] = 3  
      ),  
   [Units] =  (  
       select r1.units + '/' + r2.units  
       from @Results r2  
       where r1.pm=r2.pm  
       and r2.[OrderID] = 3   
       )  
  from @Results r1  
  where r1.[OrderID] = 1  
  
  
  if (SELECT count(*) FROM @Results where [OrderID] < 3) > 65000   
   begin  
   select @TooMuchDataMsg [User Notification Msg]  
   end  
  else  
   begin   
   if (SELECT count(*) FROM @Results) = 0   
    begin  
    select @NoDataMsg [User Notification Msg]  
    end  
   else    
    begin  
    select *   
    from @Results  
    where [OrderID] < 3  
    order by [OrderID], [PM]  
    end  
   end  
  
 delete @Results  
  
  
  -------------------------------------------------------------------------------------------  
  -- Section 17: Results Set #7 - Return the result set for Chill H20  
  -------------------------------------------------------------------------------------------  
  
   
  insert @Results  
  select  
   '', --replace(pldesc,'TT ',''), -- [PM]  
   pu.PUID,   
   case  
    when vartype = 'CWGENNRGDAY'  
    then 1  
    when vartype = 'CWCOOLINGTOWERDELTATDAY'  
    then 2  
    else 0  
   end, --[OrderID]  
   vardesc, --dbo.fnLocal_GlblParseInfo(v.extendedinfo,'GlblDesc='), -- [VarDesc]  
   units, --[Units],  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 7  
   then value  
   else  0  
   end), --[Jul]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 8  
   then value  
   else  0  
   end), --[Aug]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 9  
   then value  
   else  0  
   end), --[Sep]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 10  
   then value  
   else  0  
   end), --[Oct]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 11  
   then value  
   else  0  
   end), --[Nov]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 12  
   then value  
   else  0  
   end), --[Dec]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 1  
   then value  
   else  0  
   end), --[Jan]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 2  
   then value  
   else  0  
   end), --[Feb]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 3  
   then value  
   else  0  
   end), --[Mar]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 4  
   then value  
   else  0  
   end), --[Apr]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 5  
   then value  
   else  0  
   end), --[May]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 6  
   then value  
   else  0  
   end) --[Jun]  
  FROM @variables v  
  join dbo.#tests t  
  on v.varid = t.varid  
  join @produnits pu  
  on v.puid = pu.puid  
  join @prodlines pl  
  on pu.plid = pl.plid   
  where t.vartype = 'CWGENNRGDAY'  
  or t.vartype = 'CWCOOLINGTOWERDELTATDAY'  
  GROUP BY vartype,vardesc,units,pu.puid  
  ORDER BY vartype,vardesc,units,pu.puid  
  option (keep plan)  
  
  
  if (SELECT count(*) FROM @Results) > 65000   
   begin  
   select @TooMuchDataMsg [User Notification Msg]  
   end  
  else  
   begin   
   if (SELECT count(*) FROM @Results) = 0   
    begin  
    select @NoDataMsg [User Notification Msg]  
    end  
   else    
    begin  
    select *   
    from @Results  
    order by [PM], [OrderID]  
    end  
   end  
  
 delete @Results  
  
  
  -------------------------------------------------------------------------------------------  
  -- Section 18: Results Set #8 - Return the result set for Comp. Air  
  -------------------------------------------------------------------------------------------  
  
   
  insert @Results  
  select  
   '', --replace(pldesc,'TT ',''), -- [PM]  
   pu.PUID,   
   case  
    when vartype = 'CAAIRNRGDAY'  
    then 1  
    when vartype = 'CAAIRUSAGEDAY'  
    then 2  
    else 0  
   end, --[OrderID]  
   vardesc, --dbo.fnLocal_GlblParseInfo(v.extendedinfo,'GlblDesc='), -- [VarDesc]  
   units, --[Units],  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 7  
   then value  
   else  0  
   end), --[Jul]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 8  
   then value  
   else  0  
   end), --[Aug]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 9  
   then value  
   else  0  
   end), --[Sep]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 10  
   then value  
   else  0  
   end), --[Oct]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 11  
   then value  
   else  0  
   end), --[Nov]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 12  
   then value  
   else  0  
   end), --[Dec]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 1  
   then value  
   else  0  
   end), --[Jan]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 2  
   then value  
   else  0  
   end), --[Feb]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 3  
   then value  
   else  0  
   end), --[Mar]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 4  
   then value  
   else  0  
   end), --[Apr]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 5  
   then value  
   else  0  
   end), --[May]  
   sum(case  
   when datepart(m,dateadd(ss,-1,ResultOn)) = 6  
   then value  
   else  0  
   end) --[Jun]  
  FROM @variables v  
  join dbo.#tests t  
  on v.varid = t.varid  
  join @produnits pu  
  on v.puid = pu.puid  
  join @prodlines pl  
  on pu.plid = pl.plid   
  where t.vartype = 'CAAIRNRGDAY'  
  or t.vartype = 'CAAIRUSAGEDAY'  
  GROUP BY vartype,vardesc,units,pu.puid  
  ORDER BY vartype,vardesc,units,pu.puid  
  option (keep plan)  
  
  
  if (SELECT count(*) FROM @Results) > 65000   
   begin  
   select @TooMuchDataMsg [User Notification Msg]  
   end  
  else  
   begin   
   if (SELECT count(*) FROM @Results) = 0   
    begin  
    select @NoDataMsg [User Notification Msg]  
    end  
   else    
    begin  
    select *   
    from @Results  
    order by [PM], [OrderID]  
    end  
   end  
  
  
 delete @Results  
  
 end  
  
  
-------------------------------------------------------------------------------------------  
-- Section 19: Drop temp tables  
-------------------------------------------------------------------------------------------  
  
Finished:  
  
drop table dbo.#tests  
  
  
RETURN  
  
