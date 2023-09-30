 /*  
Stored Procedure: spLocal_GetCLDetailData  
Author:    M. Wells (MSI)  
Date Created:  05/21/02  
  
Description:  
===========  
This procedure returns detailed centerline data for a given start time, end time and product..  
  
INPUTS: Start Time  
   End Time  
   Production Line Id  
  
CALLED BY:  RptPmkgCL.xlt (Excel/VBA Template)  
  
CALLS: None  
  
Revision Change Date Who What  
======== =========== ==== =====  
1.00  5/24/02  CE  Added alarm end_time to columns returned  
2.00  6/11/02  CE  Changed time criteria in final Where clause to also return Alarms that went active   
         before the Report period, and are still active or went inactive during the Report period.  
  
2.10  2/24/04  JSJ - Changed file name to spLocal_RptPmkgCL  
         - Added the #ErrMessages temporary table  
         - Added validation checks for the input parameters  
  
2.20  12/02/04  JSJ - brought this sp up to date with Checklist 110804.  
         - removed some unused code.  
         - Converted the temp table to a table variable.  
  
2.21  2005-APR-12 FLD Modified to provide flexibility to run for converting CL's.  
  
2.22  2005-APR-19 FLD Added 'dbo.' prefix to all object references to minimize recompiling.  
  
2.23  2006-FEB-27 FLD -  Eliminated @AlarmVars table variable.  It's primary key was causing an issue  
          in GB [for no discernable reason].  Since it was basically a table of one  
          record, used only once, I simply moved the logic that was populating it  
          down into the results set selection.  
         - Added the 'Control Setting' section.  
         - Cleaned up/simplified the comparisons between the alarm time and report  
          window in the results set selection.  Also added an '=' to the time  
          comparison between alarm start time and production starts.  
  
2.24 2009-05-19 JSJ   
- modified the restriction on a.End_Time in the final result set.  
 this will allow results that were still out at the end of the report window  
 to be included in the results.  
  
  
*/  
  
CREATE PROCEDURE dbo.spLocal_RptPmkgCL  
  
--DECLARE  
  
 @Report_Start_Time datetime,  
 @Report_End_Time  datetime,  
 @Line      varchar(25)  
  
AS  
  
/* Testing  
Select    
@Line     = 'PC1X', --'AY1A',    
@Report_Start_Time = '2008-05-18 00:00:00',  
@Report_End_Time = '2008-05-19 00:00:00'  
*/  
  
-------------------------------------------------------------------------------  
-- Control settings  
-------------------------------------------------------------------------------  
SET ANSI_WARNINGS OFF  
SET NOCOUNT ON  
  
-------------------------------------------------------------------------------------  
-- Create temporary tables  
------------------------------------------------------------------------------------  
  
declare @ErrorMessages  table(  
        ErrMsg  nVarChar(255))  
  
-------------------------------------------------------------------------------------  
-- Validate the input parameters  
-------------------------------------------------------------------------------------  
  
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
  
if (select count(*) from prod_lines where pl_desc = 'TT ' + ltrim(rtrim(@Line))) = 0   
BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@Line is not valid.')  
 GOTO ReturnResultSets  
END  
  
-------------------------------------------------------------------------------  
-- Declare program variables  
-------------------------------------------------------------------------------  
  
Declare @AT_Id    int,  
   @PL_Id    int,  
   @Production_PU_Id int,  
   @Schedule_PU_Id int,  
   @Extended_Info  varchar(255),   
   @Start_Position int,  
   @End_Position  int,  
   @Schedule_PU_Str varchar(255)  
  
----------------------------------------------------------------------------------  
-- Get values  
---------------------------------------------------------------------------------  
  
Select  @PL_Id = PL_Id  
From   dbo.Prod_Lines  
Where  PL_Desc = 'TT ' + @Line  
  
Select  @Production_PU_Id = PU_Id  
From   dbo.Prod_Units  
Where  (PL_Id = @PL_Id And PU_Desc = @Line + ' Production')     --Pmkg  
OR   (PL_Id = @PL_Id And PU_Desc = @Line + ' Converter Production') --Cvtg  
  
Select  @Extended_Info = Extended_Info  
From   dbo.Prod_Units  
Where  PU_Id = @Production_PU_Id  
  
Select @Start_Position  = charindex('ScheduleUnit=', @Extended_Info, 0) + 13  
Select @End_Position  = charindex(';', @Extended_Info, @Start_Position)  
  
If @End_Position = 0  
 Select @End_Position = @Start_Position + 10  
  
Select @Schedule_PU_Str = substring(@Extended_Info, @Start_Position, @End_Position-@Start_Position)  
If IsNumeric(@Schedule_PU_Str) = 1  
 Select @Schedule_PU_Id = convert(int, @Schedule_PU_Str)  
  
-------------------------------------------------------------------------------------  
ReturnResultSets:  
------------------------------------------------------------------------------------  
  
if (select count(*) from @ErrorMessages) > 0   
 select * from @ErrorMessages  
 else  
 begin  
  select * from @ErrorMessages  
  Select a.Start_Time,   
    a.End_Time,  
    cs.Crew_Desc,  
    a.Alarm_Desc,  
    a.Start_Result,  
    a.End_Result,  
    a.Source_PU_Id,  
    v.PU_Id,  
    ps.Prod_Id,  
    vs.Target,  
    vs.U_Warning,  
    vs.L_Warning,  
    c.Comment_Text  
  From  dbo.Alarms a  
       Inner Join dbo.Alarm_Template_Var_Data atd  On a.ATD_Id = atd.ATD_Id  
   INNER JOIN dbo.Alarm_Templates atp     ON atp.AT_Id = atd.AT_Id   
   Inner Join dbo.Variables v       On atd.Var_Id = v.Var_Id   
   Inner Join dbo.Prod_Units pu       On v.PU_Id = pu.PU_Id  
       Inner Join dbo.Production_Starts ps On ps.PU_Id = coalesce(pu.Master_Unit, pu.PU_Id)   
     And ps.Start_Time   <= a.Start_Time   
     And (ps.End_Time    >  a.Start_Time Or ps.End_Time Is Null)  
       Inner Join dbo.Var_Specs vs On v.Var_Id = vs.Var_Id   
     And vs.Prod_Id = ps.Prod_Id   
     And vs.Effective_Date  <= a.Start_Time   
     And (vs.Expiration_Date > a.Start_Time Or vs.Expiration_Date Is Null)  
      Left  Join dbo.Comments c On a.Action_Comment_Id = c.Comment_Id  
      Left  Join dbo.Crew_Schedule cs On cs.PU_Id = @Schedule_PU_Id   
     And cs.Start_time   <= a.Start_Time   
     And cs.End_Time    >  a.Start_Time  
-- Rev2.24  
-- WHERE  ((a.End_Time >= @Report_Start_Time AND a.End_Time < @Report_End_Time) OR a.End_Time is Null)  
-- AND  a.Start_Time < @Report_End_Time  
 WHERE  (a.End_Time > @Report_Start_Time OR a.End_Time is Null)  
 AND  a.Start_Time < @Report_End_Time  
 AND   (atp.AT_Desc = @Line + ' Centerline Alarms'   
    OR atp.AT_Desc LIKE 'Cvtg ' + @Line + ' CL%')    
 Order By a.Start_Time Asc,   
    a.End_Time Asc  
  
 END  
  
