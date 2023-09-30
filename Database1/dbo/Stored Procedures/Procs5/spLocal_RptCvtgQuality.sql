 --------------------------------------------------------------------------------------------------------------------------------------------------------------  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
-- Revision 4.4  Last Update: 2004-Nov-08 Jeff Jaeger  
  
--  This SP works with the template RptCvtgQuality.xlt. The SP provides 6  
-- different result sets.  Configuration report parameters are:  
-- @StartTime   DateTime,  -- Beginning period for the data.  
-- @EndTime   DateTime,  -- Ending period for the data.  
-- @DisplayId   Varchar(8000),  -- String of the displays ID ex. "70|71|73"  
-- @PUIdList   Varchar(8000),  -- String of Audits Prod_Units (production unit where  
--        -- quality variables reside) ex. "96|98|94"  
-- @FailDesc   Varchar(50),  -- attribute reject value, ex. Fail  
-- @BySummary   int   -- determines whether or not to include the Raw Data set  
  
-- This SP will gather data for the specified date/time range and return all the statistic of  
-- the display selected.  
--  
-- All data reported will be static and will be written to the xlt template,   
-- then formatted.  
  
--  
-- 2002-06-06   Clement Morin  
--  - Original procedure.  
--  
-- 2002-08-12 Vince King  
--  - Modified the result sets to return data in the correct order  
--    for the template.  
--  - Changed LowerUser (L_Warning) to LowerWarning (L_Warning) and  
--  - UpperWarning (U_Warning) to UpperWarning (U_Warning).  
--  
-- 2002-08-13 Vince King  
--  - Modified selection of product to allow a NULL End_Time.  
--  - Added PU_Id to the temp tables in order to include Prod Line  
--    in results sets.  This allows multiple lines to be selected.  
--  
-- 2002-09-09 Jeff Jaeger  
--  - Replaced cursors with correlated subqueries to increase speed  
--  - Replaced #request_q temp table with select statements to increase speed  
--  - Added a nonclustered index to #test_q to increase speed  
--  
-- 2002-10-30 Jeff Jaeger  
--  - added results sets for new sheets in report template  
--  - modified fields in results sets according to new requirements  
--  
--  
-- 2003-02-04 Jeff Jaeger  
--  - altered Variables Out result sets to refect the columns in Raw Data  
--  - changes in Variables Out will cause individual records to be displayed instead of counts  
--  - verified that out of limits comparisons are using the expanded definition  
--  - updated Attributes out to include all attributes, with count of fails and total count of N  
--  
--2003-02-06 Jeff Jaeger  
--  - updated Attributes result sets to test for data_type = "Global Pass/Fail"   
--  - added "DataType" column to the #test_q table to store variable datatype  
--  - updated the insert to #test_q so that it will not join with var_specs  
--  - changed several result column names according to Langdon and Vince's requests  
--  - corrected the way that OOL is being determined  
--  - dealt with a divide by zero error in PPM, so that I can see other results.  I'll need to  
--    review this issue more closely tomorrow.  
--  
--2003-02-07 Jeff Jaeger  
--  - updated the way that [N] and [Fails] are determined in the result sets  
--  - fixed divide by zero error in PPM  
--  - removed the use of "where specstart is not null" restriction in result sets that should include  
--    attributes data  
--  - added Product Code to each result set.  This provides additional information, and allows the template   
--    a consistent field with which to check for valid data.  
--  - rearranged the order of Attributes Out columns according to Langdon's email of 02/07/03.  
  
-- 2003-02-17 Jeff Jaeger  
--  - added use of @BySummary back into the sp  
  
-- 2003-02-18 Jeff Jaeger  
--  - updated names according to standards  
  
-- 2003-02-19 Jeff Jaeger  
--  - added header information similar to spLocal_CvtgDDSStops on MP  
--  - put processing of By Summary in sp instead of in template  
  
-- 2003-02-20 Jeff Jaeger  
--  - updated the insert to #test_q to restrict the dataset to those records with a data type  
--    of Global Pass/Fail, Integer, or Float  
  
-- 2003-02-21 Jeff Jaeger  
--  - created burn copy of sp, per request of Vince King  
  
-- 2003-02-25 Jeff Jaeger  
--  - added setting of permissions to the burn script  
  
-- 2003-02-28 Jeff Jaeger  
--  - corrected the update of product info in #test_q  
  
-- 2003-03-03 Jeff Jaeger  
--  - converted the syntax of this sp to use joins  
  
-- 2003-10-10 Jeff Jaeger  
--  - Moved the input validations to before any temp tables are created.  
--    This prevents tables from being created before the parameters are validated.  
--    If an error occurs, no tables need to be dropped.  
  
-- 2003-10-14 Jeff Jaeger  
--  - updated the parameter validations to display better error messages.  
  
-- 2003-10-20 Jeff Jaeger  
--  - Added a variable to store the local language, and the query to get that value.  
--  - Added addition flow control to the result sets.  If the local language is German,   
--    results will have German headers.  Else, the results will have English headers.  
--    This format can be expanded for other languages, but the header values will be   
--    determined on the fly, once the language translation table is put into place.  
--  - Modified the varchar lengths of names for displays, products, variables, and units to be  
--    100 instead of 50, because some of the German names are pretty long, and end up truncated.  
  
-- 2003-10-23 Jeff Jaeger  
--  - Moved all create table statements to the top of the script.    
--  - Placed the parameter validation checks after that.  
--  - Made sure all tables are dropped at the end of the script.  Took the drop statements out of the IF.  
--  - These changes were made to conform to the approach that Matt Wells has discussed using.  
  
-- 2004-MAR-26 Langdon Davis  Rev3.5  
--  - Added check for exceeding 65000 records on the raw data results set.  
  
-- 2004-APR-15 Langdon Davis Rev3.6  
--   - Modified results set selection to use English headers for local language = US English, Spanish,  
--    French, or Italian.  Previously, if the local language was other than US English or German,  
--    nothing was returned.  
  
-- 2004-May-06 Jeff Jaeger  Rev3.7  
--  - Extended the @FailDesc parameter so that it is now a delimited list of text values.  
--  - Added the parameter @strDataTypeDesc, along with the code to populate it.  This is a delimited list  
--    of data type descriptions, created by using the @FailDesc parameter.  
--  - Where the value 'global pass/fail' was hardcoded in a where clause, I replaced the check with a   
--    charindex check against @strDataTypeDesc.  
--  - where test result are being compared with the @FailDesc, I changed the check to a charindex.  
--  
-- 2004-JUL-06 Langdon Davis  Rev3.8  
--  - Constrained 'COUNT' selections in the German results set to be restricted to WHERE tq1.varpuid =   
--    tq2.varpuid so that distinctions between sample sizes et al on individual lines within the report  
--    were made.  Same thing still needs to be done for the other languages results sets.  
  
-- 2004-JUL-19 Langdon Davis  Rev3.9  
--  - Made the same restriction as above in the non-German results sets.  
  
-- 2004-JUL-28 Langdon Davis  Rev4.0 [Incident Ticket # 7088614]  
--  - Modified the code that pulls in the spec to sort by Effective_Date DESC instead of Var_ID  
--    DESC so that the right spec gets associated.   
--  - Modified the aliases for the limts to better match terminolgy used within Proficy.  
   
-- 2004-AUG-09 Langdon Davis Rev4.1 [Problem Ticket #11250]  
--  - Modified code to include a Prod_Id constraint between #Test_Q and Var_Specs when selecting  
--    the limits values.  Without this, limits for products other than the one to which the test  
--    was done were sometimes getting applied.  
  
-- 2004-AUG-10 Langdon Davis Rev4.2  
--  - Modified the Group By's and Order By's for all the results sets in order to...  
--   * Achive correct summary calc's by line, product and variable.  
--   * Provide a more logical ordering for the user.  
--  - Updated aliases for the limits to spell out the words 'Lower' and 'Upper'.  
  
-- 2004-AUG-12  Langdon Davis   Rev4.3  
--              - Modified the SELECT statements for results sets 4 and 5 to put 'Product_Code' back as the  
--                first item in the ORDER BY statement.  Without this, if the report is configured to run on   
--                multiple lines and there is one or more brand codes run on both lines, the VBA fails as it  
--                attempts to name two worksheets with the same brand code.  
  
-- 2004-11-08 Jeff Jaeger Rev4.4  
--  - brought the sp up to spec with Checklist 110804.  
--  - removed some unused code  
--  - added parameters @UserName  
--  - added language transation code and related variables.  
--  - converted #PU_ID_Q, #Display_Q, and #ErrorMessages to table variables.  
--  - added the temp tables #Attribues, #VAriables, #AttributesOut, #VariablesOut, and #RawData.  
  
----------------------------------------------------------------------------------------------------------------------  
  
CREATE  PROCEDURE dbo.spLocal_RptCvtgQuality  
--declare  
 @StartTime   DateTime,  -- Beginning period for the data.  
 @EndTime   DateTime,  -- Ending period for the data.  
 @DisplayId   Varchar(8000),  -- String of the displays ID ex. "70|71|73"  
 @PUIdList   Varchar(8000),  -- String of Audits Prod_Units (production unit where  
        -- quality variables reside) ex. "96|98|94"  
 @FailDesc   Varchar(50),  -- attribute reject value, ex. Fail  
 @BySummary   int,  
 @UserName   varchar(30)  
as  
  
-------------------------------------------------------------------------------  
-- Assign Report Parameters for SP testing locally.  
-------------------------------------------------------------------------------  
/*  
-- MP  
  
Select  @StartTime = '2004-02-19 07:30:00',    
  @EndTime = '2004-02-20 07:30:00',    
 --@DisplayId = '231|229|230|272',    
 @DisplayId = '724|730|736|780|741|796|562|569|578|776|589|800',  -- MP  
 --@PUIdList = '950|984',    
 @PUIdList = '1136|1137|1138|852|853|864', --  MP  
    @FailDesc='Fail|No',  
 @BySummary = 1  
*/  
  
/*  
-- GB  
  
Select  @StartTime = '2004-05-05 00:00:00',    
  @EndTime = '2004-05-06 00:00:00',    
 @DisplayId = '673|666|660|662|677|658',  
 @PUIdList = '851|852|853|854|855|856',  
    @FailDesc='Fail|No',  
 @BySummary = 1  
*/  
  
/*  
--  AY  
  
select  @StartTime = '2003-02-01 07:30:00',       
 @EndTime = '2003-02-06 07:30:00',      
 @DisplayId = '231|265', --'231|229|230|265|272',      
 @PUIdList = '950',      
 @FailDesc = 'Fail|No',  
 @BySummary = 1,  
 @UserName = 'ComXClient'  
*/  
  
  
-------------------------------------------------------------------------------  
-- Create temporary Error Messages and ResultSet tables.  
-------------------------------------------------------------------------------  
  
declare @Display_Q table  
(  
 Dis_id    Int,  
 Dis_name   Varchar(100)   
)  
  
  
declare @PU_ID_Q table  
(  
 PU_Id    Int,  
 pu_name    Varchar(100)   
)  
  
CREATE TABLE #Test_Q (    
 Var_id    Int,  
 Display_Name   VarChar(100),  
 Result_on   Datetime,  
 Product    varchar(100),  
 Product_code   varchar(50),  
 Product_ID   Int,  
 Variable_name   varchar(100),  
 Unit    varchar(100),  
 Result    varchar(50),  
 Target    Varchar(50),  
 UpperReject   varchar(50),  
 LowerReject   varchar(50),  
 UpperUser   varchar(50),  
 LowerUser   varchar(50),  
 SpecStart   Datetime,  
 SpecEnd    Datetime,  
 VarPUId    Int,  
 DataType   int)  
  
  
create table #AttributesOut  
 (  
 [Line]    varchar(50),  
 [Diplay]   varchar(50),  
 [Product_Code]   varchar(25),  
 [Product]   varchar(50),  
 [Test Timestamp]  datetime,  
 [Attribute]   varchar(50),  
 [Result]   varchar(25)  
)  
  
  
create table #VariablesOut  
(  
 [Line]   varchar(50),  
 [Display]  varchar(50),  
 [Product Code]  varchar(25),  
 [Product]  varchar(50),  
 [Test Timestamp]  datetime,  
 [Spec Start Date] datetime,  
 [Spec End Date]  datetime,  
 [Variable]  varchar(50),  
 [Units]   varchar(50),  
 [Result]  varchar(25),  
 [Lower Reject]  varchar(25),  
 [Lower User]  varchar(30),  
 [Target]  varchar(25),  
 [Upper User]  varchar(30),  
 [Upper Reject]  varchar(25)  
)  
  
  
create table #Variables  
(  
 [Line]    varchar(50),  
 [Spec Start Date] datetime,    
 [Spec End Date]  datetime,   
 [Variable]  varchar(50),   
 [Units]   varchar(50),   
 [N]   int,    
 [AVG]   float,   
 [STD DEV]  float,   
 [Observed OOL]  int,  
 [Min]   float,    
 [Max]   float,   
 [Lower Reject]  varchar(25),   
 [Lower User]  varchar(30),   
 [Target]  varchar(25),   
 [Upper User]  varchar(30),   
 [Upper Reject]  varchar(25),  
 [Product Code]  varchar(25)   
)  
  
  
create table #Attributes  
(  
 [Line]    varchar(50),  
 [Display]  varchar(50),  
 [Product]  varchar(50),   
 [Attribute]  varchar(50),   
 [Fails]   int,     
 [N]   int,   
 [Defect PPM]  int,  
 [Product Code]  varchar(25)  
)  
  
  
create table #RawData  
(  
 [Line]    varchar(50),  
 [Display]  varchar(50),  
 [Product Code]  varchar(25),  
 [Product]  varchar(50),  
 [Test Timestamp] datetime,  
 [Spec Start Date] datetime,  
 [Spec End Date]  datetime,  
 [Variable]  varchar(50),  
 [Units]   varchar(50),  
 [Result]  varchar(25),  
 [Lower Reject]  varchar(25),  
 [Lower User]  varchar(30),  
 [Target]  varchar(25),  
 [Upper User]  varchar(30),  
 [Upper Reject]  varchar(25)  
)  
  
  
DECLARE @ErrorMessages TABLE  
  (  
 ErrMsg varchar(255)   
 )  
  
  
-------------------------------------------------------------------------------  
-- Check Input Parameters.  
-------------------------------------------------------------------------------  
  
  
IF IsDate(@StartTime) <> 1  
BEGIN  
 INSERT #ErrorMessages (ErrMsg)  
  VALUES ('@StartTime is not a Date.')  
 GOTO ReturnResultSets  
END  
IF IsDate(@EndTime) <> 1  
BEGIN  
 INSERT #ErrorMessages (ErrMsg)  
  VALUES ('@EndTime is not a Date.')  
 GOTO ReturnResultSets  
END  
IF @DisplayId IS NULL  
BEGIN  
 INSERT #ErrorMessages (ErrMsg)  
  VALUES ('@DisplayId is not valid.')  
 GOTO ReturnResultSets  
END  
IF @PUIdList IS NULL  
BEGIN  
 INSERT #ErrorMessages (ErrMsg)  
  VALUES ('@PUIdList is not valid.')  
 GOTO ReturnResultSets  
END  
IF @FailDesc IS NULL  
BEGIN  
 INSERT #ErrorMessages (ErrMsg)  
  VALUES ('@FailDesc is not valid.')  
 GOTO ReturnResultSets  
END  
  
  
-------------------------------------------------------------------------------  
-- Variable Declarations  
-------------------------------------------------------------------------------  
  
declare  
@strDataTypeDesc  varchar(100),    
@LocalLanguageDesc  nVarChar(50),  
@LanguageId   integer,  
@UserId    integer,  
@LanguageParmId   integer,  
@NoDataMsg    varchar(50),  
@TooMuchDataMsg   varchar(50),  
@SQL     varchar(8000)  
  
  
select @NoDataMsg = GBDB.dbo.fnLocal_GlblTranslation('NO DATA meets the given criteria', @LanguageId)  
select @TooMuchDataMsg = GBDB.dbo.fnLocal_GlblTranslation('There are more results than can be displayed', @LanguageId)  
  
-- get variables values related to language translation  
  
select   @LanguageParmID  = 8,  
@LanguageId  = NULL  
  
SELECT @UserId = User_Id  
FROM Users  
WHERE UserName = @UserName  
  
SELECT @LanguageId = CASE   
WHEN isnumeric(ltrim(rtrim(Value))) = 1   
THEN convert(float, ltrim(rtrim(Value)))  
    ELSE NULL  
    END  
FROM User_Parameters  
WHERE User_Id = @UserId  
 AND Parm_Id = @LanguageParmId  
  
  
IF @LanguageId IS NULL  
  
  SELECT @LanguageId = CASE   
WHEN isnumeric(ltrim(rtrim(Value))) = 1   
THEN convert(float, ltrim(rtrim(Value)))  
     ELSE NULL  
     END  
  FROM Site_Parameters  
  WHERE Parm_Id = @LanguageParmId  
  
IF @LanguageId IS NULL  
  
  SELECT @LanguageId = 0  
  
  
-------------------------------------------------------------------------------  
-- Fill the temporary tables #Pu_id_Q and #Display_Q  
-------------------------------------------------------------------------------  
  
  
  insert @pu_id_q (pu_id)  
  select pu_id   
  from prod_units   
  where charindex('|' + convert(varchar, pu_id) + '|', '|' + @puidlist + '|') > 0  
  
  
 insert @display_q (dis_id, dis_name)  
  select distinct sh.sheet_id, sheet_desc  
  from sheets sh   
  join sheet_variables sv on sh.sheet_id = sv.sheet_id  
  join variables v on v.var_id = sv.var_id  
  where charindex('|' + convert(varchar,sh.sheet_id) + '|', '|' + @displayid + '|') > 0  
  AND EXISTS(SELECT PU_Id from @PU_ID_Q where PU_ID = v.pu_id  )   
  group by SH.Sheet_id,sheet_desc  
  
  
-------------------------------------------------------------------------------  
-- Get @strFailDesc  
-------------------------------------------------------------------------------  
  
select @strDataTypeDesc = @FailDesc  
  
select @strDataTypeDesc = replace(@strDataTypeDesc,p.phrase_value,dt.data_type_desc)  
from phrase p  
join data_type dt on p.data_type_id = dt.data_type_id  
where charindex('|' + p.phrase_value + '|','|' + @strDataTypeDesc + '|') > 0  
and dt.data_type_desc IN ('Global Pass/Fail', 'Global Yes/No')  
  
  
---------------------------------------------------------------------------------  
-- Fill the temporary table Test With all the result done in the selected displays  
---------------------------------------------------------------------------------  
  
  
INSERT #Test_Q (Var_id, Display_Name, Result_on,Result, variable_name, unit, VarPUId, DataType)  
  SELECT  distinct sv.Var_id, Dis_name, t.Result_on, t.Result, v.Var_desc, v.Eng_units,   
   v.PU_Id, v.data_type_id  
   FROM Variables v  
   join sheet_variables SV on v.var_id = sv.var_id   
   join @Display_Q d on d.dis_id = sv.sheet_id  
   join   
    (  
    select var_id, result_on, result  
    from tests  
    where result_on >= @StartTime  
    AND result_on < @EndTime  
    ) t  
   on t.var_id = v.var_id   
   WHERE  EXISTS(SELECT PU_Id from @PU_ID_Q where PU_ID = v.pu_id  )   
    and charindex(  
     '|' + lower((  
     select lower(data_type_desc)   
     from  data_type   
     where  data_type_id = v.data_type_id  
     )) + '|',   
     '|' + lower(@strDataTypeDesc) + '|integer|float|'  
     ) > 0      
    
  
create nonclustered index temp_ind on #test_q(result_on, var_id)   
  
  
 UPDATE #Test_Q SET  Product_Id = sel.prod_id, Product = sel.prod_Desc, product_code = sel.prod_code  
  from   (  
   select distinct ps.prod_id, p.prod_Desc,p.prod_code, tq.var_id tqv, tq.result_on tqr   
   from  Production_starts ps  
   join products p on ps.prod_id = p.prod_id  
   join  (  
    select var_id, result_on, varpuid  
    from #test_q  
    ) tq  
   on ps.Start_time <= tq.result_on   
   AND   (ps.End_time > tq.result_on OR ps.End_time IS NULL)  
   and ps.pu_id = tq.varpuid   
   Where  lower(prod_desc) <> 'no grade'  
   ) sel  
  where Var_id = sel.tqv and Result_on = sel.tqr   
  
  
 UPDATE #Test_Q SET   
  
   UpperReject = (  
   select  top 1 u_reject  
   from  var_specs vs  
   where  #test_q.var_id = vs.var_id  
   AND #test_q.product_id = vs.prod_id   --FLD Rev4.1  
   and vs.effective_date <= #test_q.result_on  
   AND  (vs.expiration_date > #test_q.result_on or vs.expiration_date is NULL)  
   order by effective_date desc  --FLD Rev4.0  
   ),  
  
   LowerReject = (  
   select  top 1 l_reject  
   from  var_specs vs  
   where  #test_q.var_id = vs.var_id  
   AND #test_q.product_id = vs.prod_id   --FLD Rev4.1  
   and vs.effective_date <= #test_q.result_on  
   AND  (vs.expiration_date > #test_q.result_on or vs.expiration_date is NULL)  
   order by effective_date desc  --FLD Rev4.0  
   ),  
  
   Target= (  
   select  top 1 vs.target  
   from  var_specs vs  
   where  #test_q.var_id = vs.var_id  
   AND #test_q.product_id = vs.prod_id   --FLD Rev4.1  
   and vs.effective_date <= #test_q.result_on  
   AND  (vs.expiration_date > #test_q.result_on or vs.expiration_date is NULL)  
   order by effective_date desc  --FLD Rev4.0  
   ),   
  
   SpecStart = (  
   select  top 1 effective_date  
   from  var_specs vs  
   where  #test_q.var_id = vs.var_id  
   AND #test_q.product_id = vs.prod_id   --FLD Rev4.1  
   and vs.effective_date <= #test_q.result_on  
   AND  (vs.expiration_date > #test_q.result_on or vs.expiration_date is NULL)  
   order by effective_date desc  --FLD Rev4.0  
   ),  
  
   SpecEnd = (  
   select  top 1 expiration_date  
   from  var_specs vs  
   where  #test_q.var_id = vs.var_id  
   AND #test_q.product_id = vs.prod_id   --FLD Rev4.1  
   and vs.effective_date <= #test_q.result_on  
   AND  (vs.expiration_date > #test_q.result_on or vs.expiration_date is NULL)  
   order by effective_date desc  --FLD Rev4.0  
   ),  
  
   LowerUser = (  
   select  top 1 l_user  
   from  var_specs vs  
   where  #test_q.var_id = vs.var_id  
   AND #test_q.product_id = vs.prod_id   --FLD Rev4.1  
   and vs.effective_date <= #test_q.result_on  
   AND  (vs.expiration_date > #test_q.result_on or vs.expiration_date is NULL)  
   order by effective_date desc  --FLD Rev4.0  
   ),  
  
   UpperUser = (  
   select  top 1 u_user  
   from  var_specs vs  
   where  #test_q.var_id = vs.var_id  
   AND #test_q.product_id = vs.prod_id   --FLD Rev4.1  
   and vs.effective_date <= #test_q.result_on  
   AND  (vs.expiration_date > #test_q.result_on or vs.expiration_date is NULL)  
   order by effective_date desc  --FLD Rev4.0  
   )  
  
  
  
ReturnResultSets:  
  
---------------------------------------------------------------------------------  
-- Select all the information we need to return from the SP  
---------------------------------------------------------------------------------  
  
  
 ----------------------------------------------------------------------------------------------------  
 -- Error Messages.  
 ----------------------------------------------------------------------------------------------------  
  
 if (select count(*) from @ErrorMessages) > 0  
  
 begin  
  
  SELECT ErrMsg  
  FROM @ErrorMessages  
    
 end  
  
 else  
  
 begin  
  
  
 ---------------------------------------------------------------------------------  
 -- Return ErrorMessages result set.  
 ---------------------------------------------------------------------------------  
  
--  errors  index 1  
  
 SELECT ErrMsg  
  FROM @ErrorMessages  
  
  
-- Attributes out of spec  index 2  
  
insert #AttributesOut  
select  Line =  (  
   select  pl_desc   
   from  prod_units pu   
   join prod_lines pl on pu.pl_id = pl.pl_id    
   where  pu_id = VarPUId  
   ),  
  display_name Display,  
  product_code [Product Code],  
  product Product,  
  Result_on [Test Timestamp],  
  variable_name Attribute,  
  result Result  
from  #test_q tq  
WHERE   isnumeric(Result)<>1   
and  charindex('|' + lower(result) + '|', '|' + lower(@FailDesc) + '|')>0  
ORDER BY line, product_code, Variable_name, result_on --FLD Rev4.2  
  
  
select @SQL =   
 case  
 when (select count(*) from #AttributesOut) > 65000 then   
 'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
 when (select count(*) from #AttributesOut) = 0 then   
 'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
 else GBDB.dbo.fnLocal_RptTableTranslation('#AttributesOut', @LanguageId)  
 end  
  
Exec (@SQL)   
  
  
--  variables out of spec   index 3  
  
insert #VariablesOut  
select  distinct   
  Line =  (  
   select  pl_desc   
   from  prod_units pu   
   join prod_lines pl on pu.pl_id = pl.pl_id    
   where  pu_id = VarPUId  
   ),  
  display_name Display,  
  product_code [Product Code],  
  product Product,  
  result_on [Test Timestamp],  
  specstart [Spec Start Date],  
  specend [Spec End Date],  
  variable_name Variable,  
  unit Units,  
  result Result,  
  lowerreject [Lower Reject],  
  loweruser [Lower User],  
  target [Target],  
  upperuser [Upper User],  
  upperreject [Upper Reject]  
FROM   #test_Q tq  
WHERE   isnumeric(Result)=1 and  
   SpecStart is not null  
and  (  --  expanded definition of Out of Spec  
  convert(float,tq.result) < convert(float,tq.lowerreject) or   
  convert(float,tq.result) > convert(float,tq.upperreject) or  
   (  
   convert(float,tq.result) <> convert(float,tq.target) and  
   tq.lowerreject is null and  
   tq.upperreject is null and  
   tq.target is not null  
   )   
  )  
ORDER BY Line, product_code, Variable_name, result_on --FLD Rev4.2  
  
  
select @SQL =   
 case  
 when (select count(*) from #VariablesOut) > 65000 then   
 'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
 when (select count(*) from #VariablesOut) = 0 then   
 'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
 else GBDB.dbo.fnLocal_RptTableTranslation('#VariablesOut', @LanguageId)  
 end  
  
Exec (@SQL)   
  
  
--  variables   index 4  
  
insert #Variables  
SELECT distinct  
  Line =  (  
   select  pl_desc   
   from  prod_units pu   
   join prod_lines pl on pu.pl_id = pl.pl_id    
   where  pu_id = VarPUId  
   ),  
  specstart [Spec Start Date],   
  specend [Spec End Date],   
  Variable_name Variable,   
  Unit Units,   
  (  
   select  Count(*)   
   from  #test_q tq1   
   where  tq.product_code = tq1.product_code  
   and tq.variable_name = tq1.variable_name  
   AND  tq.varpuid = tq1.varpuid  --FLD Rev3.9  
   and isnumeric(Result)=1   
   and SpecStart is not null  
  ) [N],    
  avg(Convert(Float,Result)) [AVG],   
  Stdev(Convert(Float,Result)) [STD DEV],   
  (   
  select  count (tq1.result)   
  from  #test_q tq1   
  where  tq.SpecStart = tq1.SpecStart  
   and isnumeric(tq1.result) = 1  
   -- expanded definition of "out of spec"  
   and (  
     convert(float,tq1.result) < convert(float,tq1.lowerreject) or   
     convert(float,tq1.result) > convert(float,tq1.upperreject) or  
     (  
      convert(float,tq1.result) <> convert(float,tq1.target) and  
      tq1.lowerreject is null and  
      tq1.upperreject is null and  
      tq1.target is not null  
     )   
    )  
   AND tq.Variable_name = tq1.Variable_name  
   AND tq.Product = tq1.product  
   AND tq.varpuid = tq1.varpuid  --FLD Rev3.9  
  ) [Observed OOL],  
  Min(Convert(Float,Result)) [Min],    
  Max(Convert(Float,result)) [Max],   
  LowerReject [Lower Reject],   
  LowerUser [Lower User],   
  Target,   
  UpperUser [Upper User],   
  UpperReject [Upper Reject],  
  product_code [Product Code]   
FROM   #test_Q tq  
WHERE   isnumeric(Result)=1 and  
   SpecStart is not null  
GROUP BY  VarPUId, product_code, product, Variable_name, specstart, specend, Unit,   --FLD Rev4.2  
  LowerReject, LowerUser, Target, UpperUser, UpperReject  --FLD Rev4.2  
ORDER BY  product_code, Line, Variable_name, specstart, specend  --FLD Rev4.2 then 4.3  
  
  
select @SQL =   
 case  
 when (select count(*) from #Variables) > 65000 then   
 'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
 when (select count(*) from #Variables) = 0 then   
 'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
 else GBDB.dbo.fnLocal_RptTableTranslation('#Variables', @LanguageId)  
 end  
  
Exec (@SQL)   
  
  
--  attributes  index 5  
  
insert #Attributes  
SELECT  distinct   
 Line =  (  
  select  pl_desc   
  from  prod_units pu   
  join prod_lines pl on pu.pl_id = pl.pl_id    
  where  pu_id = VarPUId  
  ),  
 Display_Name [Display],  
 Product  [Product],   
 Variable_name [Attribute],   
 (  
  select  Count(*)  
  from  #test_q tq2   
  where  tq1.[product_code] = tq2.[product_code]  
  and tq1.variable_name = tq2.variable_name  
  AND  tq1.varpuid = tq2.varpuid  --FLD Rev3.9  
  and  isnumeric(tq2.result) <> 1  
  and charindex('|' + lower(tq2.result) + '|', '|' + lower(@FailDesc) + '|')>0  
   
 )    [Fails],     
 (  
  select  Count(*)  
  from  #test_q tq2   
  where  tq1.[product_code] = tq2.[product_code]  
  and tq1.variable_name = tq2.variable_name  
  AND  tq1.varpuid = tq2.varpuid  --FLD Rev3.9  
  and  tq2.datatype in (  
     select data_type_id   
     from data_type   
     where charindex(lower(data_type_desc),lower(@strDataTypeDesc))>0  
     )    
 )    [N],   
    
   convert(integer,   
   convert(decimal,(  
   select  Count(*)  
   from  #test_q tq2   
   where  tq1.[product_code] = tq2.[product_code]  
   and tq1.variable_name = tq2.variable_name  
   and  tq1.varpuid = tq2.varpuid  --FLD Rev3.9  
   and  isnumeric(tq2.result) <> 1  
   and charindex('|' + lower(tq2.result) + '|', '|' + lower(@FailDesc) + '|')>0  
   ))   
   /       
   convert(decimal,(  
   select  Count(*)  
   from  #test_q tq2   
   where  tq1.[product_code] = tq2.[product_code]  
   and tq1.variable_name = tq2.variable_name  
   AND  tq1.varpuid = tq2.varpuid  --FLD Rev3.9  
   and  tq2.datatype in  (  
      select data_type_id   
      from data_type   
      where charindex(lower(data_type_desc),lower(@strDataTypeDesc))>0  
      )   
   ))  * 1000000) [Defect PPM],  
 Product_Code    [Product Code]  
FROM  #test_Q tq1  
WHERE  tq1.datatype in (  
   select data_type_id   
   from data_type   
   where charindex(lower(data_type_desc),lower(@strDataTypeDesc))>0  
   )   
GROUP BY VarPUId, display_name, product_code, product, Variable_name  --FLD Rev4.2  
ORDER BY product_code, Line, Variable_name --FLD Rev4.2 then 4.3  
  
  
 select @SQL =   
 case  
 when (select count(*) from #Attributes) > 65000 then   
 'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
 when (select count(*) from #Attributes) = 0 then   
 'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
 else GBDB.dbo.fnLocal_RptTableTranslation('#Attributes', @LanguageId)  
 end  
  
Exec (@SQL)   
  
  
-- Raw data  index 6  
  
 if @BySummary = 1   
  
 -------------------------------------------------------------------------------  
 -- If the dataset has more than 65000 records, then send an error message and  
 -- suspend processing.  This is because Excel can not handle more than 65536 rows  
 -- in a spreadsheet.  
 -------------------------------------------------------------------------------  
 begin  
  
 insert #RawData  
 select  distinct   
   Line =  (  
    select  pl_desc   
    from  prod_units pu   
    join prod_lines pl on pu.pl_id = pl.pl_id    
    where  pu_id = VarPUId  
    ),  
   display_name Display,  
   product_code [Product Code],  
   product Product,  
   result_on [Test Timestamp],  
   specstart [Spec Start Date],  
   specend [Spec End Date],  
   variable_name Variable,  
   unit Units,  
   result Result,  
   lowerreject [Lower Reject],  
   loweruser [Lower User],  
   target Target,  
   upperuser [Upper User],  
   upperreject [Upper Reject]  
 from  #test_q tq  
 ORDER BY Line, product_code, Variable_name, result_on  --FLD Rev4.2  
  
  
 select @SQL =   
 case  
 when (select count(*) from #RawData) > 65000 then   
 'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
 when (select count(*) from #RawData) = 0 then   
 'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
 else GBDB.dbo.fnLocal_RptTableTranslation('#RawData', @LanguageId)  
 end  
  
 Exec (@SQL)   
  
 end  
 end   
  
  
---------------------------------------------------------------------------------  
-- Drop the temporary table  
---------------------------------------------------------------------------------  
  
DROP TABLE   #Test_Q  
drop table #Attributes  
drop table #Variables  
drop table #AttributesOut  
drop table #VariablesOut  
drop table #RawData  
  
  
RETURN  
  
