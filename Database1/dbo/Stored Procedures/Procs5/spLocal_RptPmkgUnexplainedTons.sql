  /*  
Stored Procedure: spLocal_RptPmkgUnexplainedTons  
Author:   Matt Wells (MSI)  
Date Created:  02/03/03  
  
Description:  
=========  
This procedure attempts to identify causes of unexplained tons.  
  
  
INPUTS: Report Start Time  
  Report End Time  
  Production Line Name (without 'TT' prefix)  
  Data Category  
  
CALLED BY:  RptPmkgUnexplainedTons.xlt (Excel/VBA Template)  
  
CALLS: None  
  
Revision Change Date Who What  
======== =========== ==== =====  
1.0  02/03/03 MKW Created  
  
2.0  05/10/04 JSJ - Saved this sp as "Val".  
     - Added the ErrMsg table variable.  
     - Moved the table create statements to top of script.  
     - Moved the table drop statements to the bottom of the script.  
     - Added parameter validation checks.  
     - Added temporary tables for result sets.  This was done to   
       better manage the control flow around the result sets.  
       These will also be used in language translation.  
     - Added flow control around the result sets.  
     - Added translation variables and related code.  
     - Updated the method of getting var_id from var_desc to use the   
       global language description instead of the variable description.  
     - Moved the assignment of @Product_End_Time outside of the nested IF statement.  
       This is because the variable was still null when executing the second nested   
       IF statement.  
     - Converted #Downtime and #Downtime_Turnover temporary tables into table   
       variables.  
     - Added Proficy Wgt Units and QCS Wgt Units to result sets.  
     - Set the decimal precision in result sets to two places instead of three.  
     - A future opportunity:  since the template displays all 3 result sets, it   
       might be better to return all results in one call to the stored procedure.  
2.1  2004-SEP-14 FLD Moved Roll Delta Limit from the 'General' results set to the 'Individual' since  
     it is the Individual results set where it is used, not the General.  
  
2.2  2004-SEP-15 FLD Added a parameter for the Weight Comparison Limit [Roll Delta Limit] instead of  
     the previous hard-coding.  
  
2.21  2005-JAN-18 FLD Put fields/headers in mixed case.  
  
2.22  2005-MAR-23 NHK Changed 'SET ANSI_NULLS OFF' to 'SET ANSI_NULLS ON'  
*/  
  
CREATE PROCEDURE spLocal_RptPmkgUnexplainedTons  
--declare  
@Report_Start_Time  datetime,  
@Report_End_Time  datetime,  
@PL_Desc   varchar(50),  
@Data_Category   varchar(15),  
@UserName   varchar(30),  
@CompLimit   float  
  
AS  
  
/* Testing values:  
  
Select  @Report_Start_Time = '2003-02-25 00:00:00',  
 @Report_End_Time = '2003-02-27 00:00:00',  
 @PL_Desc  = 'MP3M',  
 --@Data_Category  = 'General',  
 @Data_Category  = 'Individual',  
 --@Data_Category  = 'Sheetbreaks',  
 @UserName  = 'ComXClient'  
  
*/  
  
  
----------------------------------------------------------------  
-- Create temporary tables  
----------------------------------------------------------------  
  
  
 DECLARE @ErrorMessages TABLE   
  (   
  ErrMsg varchar(255)   
  )  
  
  
     Declare @Downtime table   
 (   
 TEDet_Id int,  
 PU_Desc varchar(50),  
 Start_Time datetime,  
 End_Time datetime  
 )  
  
  
     Declare @Downtime_Turnovers table   
 (   
 TEDet_Id int,  
 TimeStamp datetime,  
 Event_Num varchar(50)  
 )  
  
  
 Create Table #GeneralResults   
  (   
  [Total Proficy Wgt] varchar(25),  
  [Proficy Wgt Units] varchar(25),  
  [Total QCS Wgt]  varchar(25),  
  [QCS Wgt Units]  varchar(25),  
  [Total Delta]  varchar(25)  
  )  
  
  
 Create Table #IndividualResults   
  (   
  [Timestamp]  datetime,  
  [TID]   varchar(50),  
  [Proficy Weight] varchar(25),  
  [Proficy Wgt Units] varchar(25),  
  [QCS Weight]  varchar(25),  
  [QCS Wgt Units]  varchar(25),  
  [Delta]   varchar(25)  
  )  
  
  
 Create Table #SheetbreakResults   
  (   
  [Unit]   varchar(50),  
  [Start Time]  datetime,  
  [End Time]  datetime,  
  [TO Timestamp]  datetime,  
  [TID]   varchar(50)  
  )  
  
  
------------------------------------------------------------  
-- Validate the input parameters  
------------------------------------------------------------  
  
  
IF IsDate(@Report_Start_Time) <> 1  
BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@Report_Start_Time is not a Date.')  
 GOTO ReturnResultSets  
END  
  
  
IF IsDate(@Report_End_Time) <> 1  
BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@Report_End_Time is not a Date.')  
 GOTO ReturnResultSets  
END  
  
  
IF 'TT ' + @PL_Desc not in (select pl_desc from prod_lines)  
BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('PL_Desc is not valid.')  
 GOTO ReturnResultSets  
END  
  
  
IF @Data_Category not in ('General','Individual','Sheetbreaks')  
BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@Data_Category is not valid.')  
 GOTO ReturnResultSets  
END  
  
  
----------------------------------------------------------------  
-- Declare the program variables  
----------------------------------------------------------------  
  
  
Declare @PL_Id    int,  
 @Production_PU_Id  int,  
 @Sheetbreak_PU_Id  int,  
 @Downtime_PU_Id   int,  
 @Proficy_Weight_Var_Id  int,  
 @QCS_Weight_Var_Id  int,  
 @Weight_Delta_Limit  float,  
 @Production_End_Time  datetime,  
 @Sheetbreak_PU_Desc  varchar(50),  
 @Downtime_PU_Desc  varchar(50),  
 @Invalid_Sheetbreak_Name varchar(50),  
 @Invalid_Downtime_Name  varchar(50),  
 @Invalid_Sheetbreak_Id  int,  
 @Invalid_Downtime_Id  int,  
 @TEDet_Id   int,  
 @TEDet_Start_Time  datetime,  
 @TEDet_End_Time   datetime,  
 @LanguageId   integer,  
 @UserId    integer,  
 @LanguageParmId   integer,  
 @NoDataMsg    varchar(50),  
 @TooMuchDataMsg   varchar(50),  
 @SQL     varchar(8000)  
  
  
  
/*************************************************************************************  
*                                  Initialization                                    *  
*************************************************************************************/  
Select  @Weight_Delta_Limit  = @CompLimit,  
 @Invalid_Sheetbreak_Name = 'Invalid',  
 @Invalid_Downtime_Name  = 'Invalid'  
  
  
-------------------------------------------------------------------------------------  
-- get local language information  
-------------------------------------------------------------------------------------  
  
select   @LanguageParmID  = 8,  
  @LanguageId   = NULL  
  
SELECT @UserId = User_Id  
FROM Users  
WHERE UserName = @UserName  
  
SELECT @LanguageId = CASE WHEN isnumeric(ltrim(rtrim(Value))) = 1 THEN convert(float, ltrim(rtrim(Value)))  
    ELSE NULL  
    END  
FROM User_Parameters  
WHERE User_Id = @UserId  
 AND Parm_Id = @LanguageParmId  
  
IF @LanguageId IS NULL  
 BEGIN  
 SELECT @LanguageId = CASE   
WHEN isnumeric(ltrim(rtrim(Value))) = 1   
THEN convert(float, ltrim(rtrim(Value)))  
     ELSE NULL  
     END  
 FROM Site_Parameters  
 WHERE Parm_Id = @LanguageParmId  
  
 IF @LanguageId IS NULL  
  BEGIN  
  SELECT @LanguageId = 0  
  END  
 END  
  
select @NoDataMsg = GBDB.dbo.fnLocal_GlblTranslation('NO DATA meets the given criteria', @LanguageId)  
select @TooMuchDataMsg = GBDB.dbo.fnLocal_GlblTranslation('There are more results than can be displayed', @LanguageId)  
  
  
/*************************************************************************************  
*                                 Get Configuraton                                   *  
*************************************************************************************/  
Select @PL_Id = PL_Id  
From Prod_Lines  
Where PL_Desc = 'TT ' + @PL_Desc  
  
Select @Production_PU_Id = PU_Id  
From Prod_Units  
Where PL_Id = @PL_Id And PU_Desc = @PL_Desc + ' Production'  
  
Select @Sheetbreak_PU_Desc = @PL_Desc + ' Sheetbreak'  
Select @Sheetbreak_PU_Id = PU_Id  
From Prod_Units  
Where PL_Id = @PL_Id And PU_Desc = @PL_Desc + ' Sheetbreak'  
  
Select @Downtime_PU_Desc = @PL_Desc + ' Reliability'  
Select @Downtime_PU_Id = PU_Id  
From Prod_Units  
Where PL_Id = @PL_Id And PU_Desc = @Downtime_PU_Desc  
  
SELECT @Proficy_Weight_Var_Id = GBDB.dbo.fnLocal_GlblGetVarId(@Production_PU_Id, 'Proficy Turnover Weight')  
SELECT @QCS_Weight_Var_Id = GBDB.dbo.fnLocal_GlblGetVarId(@Production_PU_Id, 'QCS Turnover Weight')  
  
Select @Invalid_Sheetbreak_Id = TEStatus_Id  
From Timed_Event_Status  
Where PU_Id = @Sheetbreak_PU_Id And TEStatus_Name = @Invalid_Sheetbreak_Name  
  
Select @Invalid_Downtime_Id = TEStatus_Id  
From Timed_Event_Status  
Where PU_Id = @Downtime_PU_Id And TEStatus_Name = @Invalid_Downtime_Name  
  
/*************************************************************************************  
*                        Compare Proficy Weights With QCS Weights                    *  
*************************************************************************************/  
  
-- moved this block of code from within the IF statement for 'General' because @Production_End_Time was still   
-- null when running the IF statement for 'Individual'    
     -- Adjust end time to account for weight divided over ending midnight  
     Select TOP 1 @Production_End_Time = coalesce(TimeStamp, @Report_End_Time)  
     From Events  
     Where PU_Id = @Production_PU_Id And TimeStamp > @Report_End_Time  
     Order By TimeStamp Asc  
  
  
If @Data_Category = 'General'  
     Begin  
     -- Get total difference for the time period  
insert into #GeneralResults  
     Select  ltrim(str(sum(convert(float, pwt.Result)), 25, 2)),    --As 'Total Proficy Wgt',  
  null,  
  ltrim(str(sum(convert(float, qwt.Result)), 25, 2)),    --As 'Total QCS Wgt',  
  null,  
  ltrim(str(sum(isnull(convert(float, pwt.Result), 0.0)) -   
  --sum(isnull(convert(float, coalesce(qwt.Result, pwt.Result)), 0.0)), 25, 2)), --As 'Total Delta',  
  --ltrim(str(@Weight_Delta_Limit, 25, 2))      --As 'Roll Delta Limit'  
  sum(isnull(convert(float, coalesce(qwt.Result, pwt.Result)), 0.0)), 25, 2))  
     From Events e  
          Left Join tests pwt On pwt.Result_On = e.TimeSTamp And pwt.Var_Id = @Proficy_Weight_Var_Id  
          Left Join tests qwt On qwt.Result_On = e.TimeSTamp And qwt.Var_Id = @QCS_Weight_Var_Id  
     Where  e.PU_Id = @Production_PU_Id And   
  e.TimeStamp > @Report_Start_Time And e.TimeStamp <= @Production_End_Time  
     update #GeneralResults set  
 [PROFICY WGT UNITS] = upper ((select eng_units from variables where var_id = @Proficy_Weight_Var_ID)),  
 [QCS WGT UNITS] = upper  ((select eng_units from variables where var_id = @QCS_Weight_Var_ID))  
     End  
Else If @Data_Category = 'Individual'  
     Begin  
     -- Look for large individual divergence  
insert into #IndividualResults  
     Select  e.TimeStamp,    --As 'TimeStamp',  
 e.Event_Num,     --As 'TID',  
 ltrim(str(convert(float,pwt.Result), 25, 2)),     --As 'Proficy',  
 null,  
 ltrim(str(convert(float,qwt.Result), 25, 2)),      --As 'QCS',  
 null,  
 ltrim(str(convert(float, pwt.Result) -   
 convert(float, qwt.Result), 25, 2))  --As 'Delta'  
 From Events e  
          Left Join tests pwt On pwt.Result_On = e.TimeSTamp And pwt.Var_Id = @Proficy_Weight_Var_Id  
          Left Join tests qwt On qwt.Result_On = e.TimeSTamp And qwt.Var_Id = @QCS_Weight_Var_Id  
     Where  e.PU_Id = @Production_PU_Id And   
  e.TimeStamp > @Report_Start_Time And e.TimeStamp <= @Production_End_Time And  
  abs(convert(float, pwt.Result) - convert(float, qwt.Result)) > @Weight_Delta_Limit  
     Order By e.TimeStamp Asc  
     update #IndividualResults set  
 [PROFICY WGT UNITS] = upper((select eng_units from variables where var_id = @Proficy_Weight_Var_ID)),  
 [QCS WGT UNITS] = upper((select eng_units from variables where var_id = @QCS_Weight_Var_ID))  
     End  
Else If @Data_Category = 'Sheetbreaks'  
     Begin  
  
     /*************************************************************************************  
     *                       Check for any false sheetbreaks/downtime                     *  
     *************************************************************************************/  
     Insert Into @Downtime ( TEDet_Id,  
    PU_Desc,  
    Start_Time,  
    End_Time)  
     Select  TEDet_Id,  
  @Sheetbreak_PU_Desc,  
  Start_Time,  
  End_time  
     From Timed_Event_Details ted  
     Where Start_Time < @Report_End_Time And (End_Time > @Report_Start_Time Or End_Time Is Null) And  
                 PU_Id = @Sheetbreak_PU_Id And TEStatus_Id = @Invalid_Sheetbreak_Id  
  
     Insert Into @Downtime ( TEDet_Id,  
    PU_Desc,  
    Start_Time,  
    End_Time)  
     Select  TEDet_Id,  
  @Downtime_PU_Desc,  
  Start_Time,  
  End_time  
     From Timed_Event_Details ted  
     Where Start_Time < @Report_End_Time And (End_Time > @Report_Start_Time Or End_Time Is Null) And  
           PU_Id = @Downtime_PU_Id And TEStatus_Id = @Invalid_Downtime_Id  
  
     Declare Downtime Insensitive Cursor For  
     Select  TEDet_Id,  
  Start_Time,  
  End_Time  
     From @Downtime  
     For Read Only  
  
     Open Downtime  
     Fetch Next From Downtime Into @TEDet_Id, @TEDet_Start_Time, @TEDet_End_Time  
     While @@FETCH_STATUS = 0  
          Begin  
          Insert Into @Downtime_Turnovers ( TEDet_Id,  
     TimeStamp,  
     Event_Num)  
          Select @TEDet_Id,  
  TimeStamp,  
  Event_Num  
          From Events  
          Where PU_Id = @Production_PU_Id And TimeStamp > @TEDet_Start_Time And TimeStamp < @TEDet_End_Time  
  
          Insert Into @Downtime_Turnovers ( TEDet_Id,  
     TimeStamp,  
     Event_Num)  
          Select TOP 1 @TEDet_Id,  
   TimeStamp,  
   Event_Num  
          From Events  
          Where PU_Id = @Production_PU_Id And TimeStamp >= @TEDet_End_Time  
          Order By TimeStamp Asc  
  
          Fetch Next From Downtime Into @TEDet_Id, @TEDet_Start_Time, @TEDet_End_Time  
          End  
     Close Downtime  
     Deallocate Downtime  
  
insert into #SheetbreakResults  
 Select PU_Desc,  --[Unit],   
 Start_Time,   --[Start Time],   
 End_Time,   --[End Time],   
 TimeStamp,   --[TO TimeStamp],   
 Event_Num   --[TID]  
      from @Downtime d  
        Left Join @Downtime_Turnovers dt   
 On d.TEDet_Id = dt.TEDet_Id  
  
  
     End  
  
  
ReturnResultSets:  
  
  
 if (select count(*) from @ErrorMessages) > 0  
  
 begin  
  
  SELECT ErrMsg  
  FROM @ErrorMessages  
    
 end  
  
 else  
  
 begin  
  
  -- errors  index 1  
  
  SELECT ErrMsg  
  FROM @ErrorMessages  
  
  --additional result sets  index 2  
  
  if @Data_Category = 'General'  
  select @SQL =   
  case  
  when (select count(*) from #GeneralResults) > 65000 then   
  'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
  when (select count(*) from #GeneralResults) = 0 then   
  'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
  else GBDB.dbo.fnLocal_RptTableTranslation('#GeneralResults', @LanguageId)  
  end  
  
  
  if @Data_Category = 'Individual'  
  select @SQL =   
  case  
  when (select count(*) from #IndividualResults) > 65000 then   
  'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
  when (select count(*) from #IndividualResults) = 0 then   
  'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
  else GBDB.dbo.fnLocal_RptTableTranslation('#IndividualResults', @LanguageId)  
  end  
  
  
  if @Data_Category = 'Sheetbreaks'  
  select @SQL =   
  case  
  when (select count(*) from #SheetbreakResults) > 65000 then   
  'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
  when (select count(*) from #SheetbreakResults) = 0 then   
  'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
  else GBDB.dbo.fnLocal_RptTableTranslation('#SheetbreakResults', @LanguageId)  
  end  
  
  Exec (@SQL)   
  
  
 end  
  
  
 -----------------------------  
 -- Drop temporary tables  
 -----------------------------  
  
 drop table #GeneralResults  
 drop table #IndividualResults  
 drop table #SheetbreakResults  
  
  
