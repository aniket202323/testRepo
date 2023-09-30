 /*  
Stored Procedure: spLocal_RptPmkgSBsSummary  
Author:   Matt Wells (MSI)  
Date Created:  04/23/02  
  
Description:  
=========  
This procedure summarizes sheetbreak detail data for a given start time, end time and product..  
  
INPUTS: Start Time  
 End Time  
 Production Line Name (without the TT prefix)  
 Data Category  (not used now)  
 Product ID for Report -1:  Returns SB summary data grouped by Product for all Products run in time period specified  
     0:  Returns SB summary data across all Products run in time period specified  
 Product ID: Returns SB summary data for this Product ID in time period specified  
  
CALLED BY:  RptPmkgSBsSummaryVAL.xlt (Excel/VBA Template)  
  
CALLS: None  
  
Rev # Change Date Who  What  
===== =========== ====  =====  
0.0 04/23/02 MW  Original Creation  
0.1 05/01/02 CE  Numerous enhancements for SB Summary Rpt  
0.2 08/07/02 CE  Remove refs to Local_Timed_Event_Detail_Categories table  
0.3 07/07/03 Eduardo B Put No Reason Assigned text when the reason code is blank  
1.0 2004-FEB-12 Langdon Davis Changed name to spLocal_RptPmkgSheetBreaksSummary standard.  
1.1 2004-02-12 Jeff Jaeger - added #Error messages and parameter error checks.  
     - updated the sp, so that test values for 'Sheet Reel Time' and 'Tons Repulper'  
       are now pulled according to the GlblDesc in Extended_Info, instead of   
       the var_desc.  
1.2 2004-02-20 Jeff Jaeger - added #Sheetbreaks and related code to allow event data to be split to   
       account for the report window boundaries.  
       fields with a prefix of 'Rpt_' are modifed if the event spands beyond the   
       report window.  
       Rpt_StartTime is set to the start of the report window if the event starts   
      prior to the report window.  
       Rpt_EndTime is set to the end of the report window if the event ends outside   
      of the report window.  
       Rpt_Failure_Mode_Count is zero if the event started prior to the report window.  
       Rpt_Downtime is the length of the event within the report window.  
       Rpt_Primary_Time is the length of the Primary_Time within the report window.  
       Rpt_Extended_Time is the length of the Extended_Time within the report window.  
       Rpt_Primary_Tons is the ratio of Primary_Tons within the report window.  
       Rpt_Extended_Tons is the ratio of Extended_Tons within the report window.  
       Rpt_Repulper_Tons is the ratio of Repulper_Tons within the report window.  
       Rpt_Primary_Stops is set to zero if the event started prior to the report   
       window.    
       Rpt_Extended_Stops is set to zero if the event started prior to the report   
       window.    
       Rpt_Stops is set to zero if the event started prior to the report   
       window.  
       Rpt_UPLTRx is set to zero if the event started prior to the report   
       window.   
       Rpt_Minor_Stops is set to zero if the event started prior to the report   
       window.       
     - converted 'real' data types to 'float'.  
     - When returning values, I set the timed event details end_time =   
       @Report_End_time when the timed event detail value is null.   
2.0 2004-AUG-15 Langdon Davis Changed name from spLocal_PmkgSheetBreaksSummary to spLocal_PmkgSBsSummary to  
      align with the convention used on the Detail report.        
  
2.1 2004-12-15  Jeff Jaeger  - converted #ErrorMessages to a table variable.  
  
2.2 2009-01-05 Jeff Jaeger    
-  converted #SheetBreaks to a table variable.  
- changed "Failure_Mode" related labels to "Failure_Mode_Cause".   
- added "MD Location" related fields to @SheetBreaks.  
- added a new result set to summarize data by Reason Level 4.  
  
  
*/  
  
CREATE PROCEDURE dbo.spLocal_RptPmkgSBsSummary  
--Declare  
  
@Report_Start_Time datetime,  
@Report_End_Time datetime,  
@Line_Name   varchar(50),  
@Data_Category  varchar(15),  
@Report_Prod_Id  int  
  
AS  
  
-- these are not used anywhere....  
--Declare @Time1 datetime, @Time2 datetime, @Time3 datetime, @Time4 datetime, @Time5 datetime  
  
/* Testing...   
  
Select    
@Report_Start_Time  = '2009-01-05 05:00:00',  
@Report_End_Time    = '2009-01-06 05:00:00',  
@Line_Name    = 'PC1X', -- 'AY3A',  
@Data_Category   = 'SheetBreaks', --'Quality', --   
@Report_Prod_Id  = 0   --Null  
  
 --select @PL_Id,@Report_Start_Time,@Report_End_Time,@Data_Category  
 --execute spLocal_RptPmkgSBsSummary '2002-08-01 00:00:00', '2002-08-07 00:00:00', 'GP06','SheetBreaks',-1  
*/  
  
/************************************************************************************************  
*                                                                                               *  
*                                 Global execution switches                                     *  
*                                                                                               *  
************************************************************************************************/  
SET NOCOUNT ON  
SET ANSI_WARNINGS OFF  
  
  
-------------------------------------------------------------------------------------------------  
--  Create  temp tables  
-------------------------------------------------------------------------------------------------  
  
--CREATE TABLE #Sheetbreaks (  
declare @Sheetbreaks table  
 (  
 StartTime  datetime,  
 EndTime   datetime,  
 Rpt_StartTime  datetime,  
 Rpt_EndTime  datetime,  
 Product   varchar(100),  
 Failure_Mode_Cause  varchar(100),  
-- Failure_Mode_Cause_Count integer,  
-- Rpt_Failure_Mode_Cause_Count integer,   
 MD_Location  varchar(100),  
 SheetBreak_Count integer,  
 Rpt_SheetBreak_Count integer,   
 Downtime  float,  
 Rpt_Downtime  float,  
 Uptime   float,  
 Primary_Time  float,  
 Extended_Time  float,  
 Rpt_Primary_Time float,  
 Rpt_Extended_Time float,  
 Primary_Tons  float,  
 Extended_Tons  float,  
 Repulper_Tons  float,  
 Rpt_Primary_Tons float,  
 Rpt_Extended_Tons float,  
 Rpt_Repulper_Tons float,  
 Primary_Stops  integer,  
 Extended_Stops  integer,  
 Stops   integer,  
 UPLTRx   integer,  
 Minor_Stop  integer,  
 Rpt_Primary_Stops integer,  
 Rpt_Extended_Stops integer,  
 Rpt_Stops  integer,  
 Rpt_UPLTRx  integer,  
 Rpt_Minor_Stop  integer  
)  
  
  
declare @ErrorMessages table  
(  
 ErrMsg  nVarChar(255)   
)  
  
  
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
  
if (select count(*) from prod_lines where pl_desc = 'TT ' + ltrim(rtrim(@Line_Name))) = 0   
BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@Line_Name is not valid.')  
 GOTO ReturnResultSets  
END  
  
--if  @Data_Category not in ('Production','SheetBreaks','QUALITY')  
--BEGIN  
-- INSERT @ErrorMessages (ErrMsg)  
--  VALUES ('@Data_Category is not valid.')  
-- GOTO ReturnResultSets  
--END  
  
if (select count(*) from products where prod_id = @Report_Prod_ID or @Report_Prod_ID = 0) = 0   
BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@Report_Prod_ID is not valid.')  
 GOTO ReturnResultSets  
END  
  
  
/************************************************************************************************  
*                                                                                               *  
*                                        Declarations                                           *  
*                                                                                               *  
************************************************************************************************/  
  
Declare @PL_Id    int,  
 @Sheetbreak_PU_Id  int,  
 @Mechanical_Desc  varchar(50),  
 @Electrical_Desc  varchar(50),  
 @Process_Failure_Desc  varchar(50),  
 @Blocked_Starved_Desc  varchar(50),  
 @Mechanical_Id   int,  
 @Electrical_Id   int,  
 @Process_Failure_Id  int,  
 @Blocked_Starved_Id  int,  
 @Uptime_Var_Id   int,  
 @Repulper_Tons_Var_Id  int,  
 @Invalid_Status_Desc  varchar(50),  
 @Invalid_Status_Id  int  
  
-- this is never used  
--Select @Time1 = getdate()  
  
/************************************************************************************************  
*                                                                                               *  
*                                     Initialization                                            *  
*                                                                                               *  
************************************************************************************************/  
Select @Invalid_Status_Desc = 'Invalid',  
 @Mechanical_Desc = 'Category:Mechanical Equipment',  
 @Electrical_Desc = 'Category:Electrical Equipment',  
 @Process_Failure_Desc = 'Category:Process/Operational',  
 @Blocked_Starved_Desc = 'Category:Blocked/Starved'  
  
  
  
/************************************************************************************************  
*                                                                                               *  
*                                     Get Configuration                                         *  
*                                                                                               *  
************************************************************************************************/  
/* Get the line id */  
Select @PL_Id = PL_Id  
From Prod_Lines  
Where PL_Desc = 'TT ' + @Line_Name  
  
/* Get Different PU Ids */  
Select @Sheetbreak_PU_Id = PU_Id  
From Prod_Units  
Where PL_Id = @PL_Id And PU_Desc = @Line_Name + ' Sheetbreak'  
  
/* Get variables */  
Select @Uptime_Var_Id = Var_Id  
From Variables  
Where charindex(lower('GlblDesc=Sheet Reel Time;'),lower(coalesce(extended_info,''))) > 0   
And PU_Id = @Sheetbreak_PU_Id  
  
Select @Repulper_Tons_Var_Id = Var_Id  
From Variables  
Where charindex(lower('GlblDesc=Tons Repulper;'),lower(coalesce(extended_info,''))) > 0   
And PU_Id = @Sheetbreak_PU_Id  
  
Select @Mechanical_Id = ERC_Id  
From Event_Reason_Catagories  
Where ERC_Desc = @Mechanical_Desc  
  
Select @Electrical_Id = ERC_Id  
From Event_Reason_Catagories  
Where ERC_Desc = @Electrical_Desc  
  
Select @Process_Failure_Id = ERC_Id  
From Event_Reason_Catagories  
Where ERC_Desc = @Process_Failure_Desc  
  
Select @Blocked_Starved_Id = ERC_Id  
From Event_Reason_Catagories  
Where ERC_Desc = @Blocked_Starved_Desc  
  
Select @Invalid_Status_Id = TEStatus_Id  
From Timed_Event_Status  
Where PU_Id = @Sheetbreak_PU_Id And TEStatus_Name = @Invalid_Status_Desc  
  
  
/************************************************************************************************  
*                                                                                               *  
*                                     Get actual event data                                 *  
*                                                                                               *  
************************************************************************************************/  
  
If @Report_Prod_Id = -1  
insert into @Sheetbreaks   
 (  
 StartTime,  
 EndTime,  
 Product,   
 Failure_Mode_Cause,  
-- Failure_Mode_Cause_Count,  
 MD_Location,  
 SheetBreak_Count,  
 Uptime,  
 Downtime,  
 Repulper_Tons,  
 Stops,  
 UPLTRx,  
 Minor_Stop  
 )  
     Select  ted.Start_Time,  
  ted.End_Time,  
  p.Prod_Desc        ,--As Product,  
  case WHEN r1.Event_Reason_Name = '' or r1.Event_Reason_Name is Null  
   THEN 'No Reason Assigned'  
   ELSE r1.Event_Reason_Name   
   END        ,--As Failure_Mode_Cause,  
--  count(ted.TEDet_Id)        ,--As Failure_Mode_Cause_Count,   
  case WHEN r2.Event_Reason_Name = '' or r2.Event_Reason_Name is Null  
   THEN 'No Reason Assigned'  
   ELSE r2.Event_Reason_Name   
   END        ,--As MD_Location,  
  count(ted.TEDet_Id)        ,--As MD_Location_Count,   
  sum(convert(float, ut.Result))      ,--As Uptime,  
  sum(convert(float, datediff(s, ted.Start_Time, coalesce(ted.End_Time,@Report_End_Time)))/60) ,--As Downtime,  
  sum(convert(float, rt.Result))      ,--As Repulper_Tons,  
  sum(Case When convert(float, ut.Result) > 0 Then 1   
    Else 0   
    End)         ,--As Stops,  
  sum(Case When convert(float, ut.Result) > 2*convert(float, datediff(s, ted.Start_Time, coalesce(ted.End_Time,@Report_End_Time)))/60 And convert(float, ut.Result) > 0 Then 1  
    Else 0  
    End)        ,--As UPLTRx,  
  sum(Case When convert(float, datediff(s, ted.Start_Time, coalesce(ted.End_Time,@Report_End_Time)))/60 < 2 Then 1  
    Else 0  
    End)        --As Minor_Stop  
     From Timed_Event_Details ted  
          Inner Join Production_Starts ps On ps.PU_Id = @Sheetbreak_PU_Id And ted.Start_Time >= ps.Start_Time And (ted.End_Time < ps.End_Time or ps.End_Time is null)  
          Inner Join Products p On ps.Prod_Id = p.Prod_Id  
--          Left Join Local_Timed_Event_Detail_Categories tedc On ted.TEDet_Id = tedc.TEDet_Id  
          Left Join Event_Reasons r1 On ted.Reason_Level3 = r1.Event_Reason_Id  
          Left Join Event_Reasons r2 On ted.Reason_Level4 = r2.Event_Reason_Id  
          Left Join tests ut On ut.Var_Id = @Uptime_Var_Id And ut.Result_On = ted.Start_Time-- And isnumeric(result) = 1 -- Uptime  
          Left Join tests rt On rt.Var_Id = @Repulper_Tons_Var_Id And rt.Result_On = ted.Start_Time-- And isnumeric(result) = 1 -- Uptime  
     Where ted.PU_Id = @Sheetbreak_PU_Id And (ted.TEStatus_Id <> @Invalid_Status_Id Or ted.TEStatus_Id Is Null) And  
                (  
   ted.Start_Time < @Report_End_Time  
   and (ted.End_Time > @Report_Start_Time or ted.End_Time is null)  
  )   
     Group By p.Prod_Desc, r1.Event_Reason_Name, r2.Event_Reason_Name, ted.start_time, ted.end_time  
Else If @Report_Prod_Id = 0  
insert into @Sheetbreaks  
 (  
 StartTime,  
 EndTime,  
 Failure_Mode_Cause,  
-- Failure_Mode_Cause_Count,  
 MD_Location,  
 SheetBreak_Count,  
 Downtime,  
 Uptime,  
 Repulper_Tons,  
 Primary_Stops,  
 Extended_Stops,  
 Primary_Tons,  
 Extended_Tons,  
 Primary_Time,  
 Extended_Time,  
 UPLTRx,  
 Minor_Stop  
 )  
     Select  ted.Start_Time,  
  ted.End_Time,  
  case WHEN r1.Event_Reason_Name = '' or r1.Event_Reason_Name is Null  
   THEN 'No Reason Assigned'  
   ELSE r1.Event_Reason_Name   
   END        ,--As Failure_Mode_Cause,  
--  count(ted.TEDet_Id)        ,--As Failure_Mode_Cause_Count,   
  case WHEN r2.Event_Reason_Name = '' or r2.Event_Reason_Name is Null  
   THEN 'No Reason Assigned'  
   ELSE r2.Event_Reason_Name   
   END        ,--As MD_Location,  
  count(ted.TEDet_Id)        ,--As MD_Location_Count,   
  sum(convert(float, datediff(s, ted.Start_Time, coalesce(ted.End_Time,@Report_End_Time)))/60) ,--As Downtime,  
  sum(convert(float, ut.Result))      ,--As Uptime,  
  sum(convert(float, rt.Result))      ,--As Repulper_Tons,  
  sum(Case When convert(float, ut.Result) > 0 Then 1   
    Else 0   
    End)         ,--As Primary_Stops,  
  sum(Case When convert(float, ut.Result) = 0 Then 1   
    Else 0   
    End)         ,--As Extended_Stops,  
  sum(Case When convert(float, ut.Result) > 0 Then rt.Result   
    Else cast(0.0 as float)   
    End)         ,--As Primary_Tons,  
  sum(Case When convert(float, ut.Result) = 0 Then rt.Result   
    Else cast(0.0 as float)   
    End)         ,--As Extended_Tons,  
  sum(Case When convert(float, ut.Result) > 0 Then convert(float,datediff(s, ted.Start_Time, coalesce(ted.End_Time,@Report_End_Time)))/60  
    Else cast(0.0 as float)   
    End)         ,--As Primary_Time,  
  sum(Case When convert(float, ut.Result) = 0 Then convert(float,datediff(s, ted.Start_Time, coalesce(ted.End_Time,@Report_End_Time)))/60  
    Else cast(0.0 as float)   
    End)         ,--As Extended_Time,  
  sum(Case When convert(float, ut.Result) > 2*convert(float, datediff(s, ted.Start_Time, coalesce(ted.End_Time,@Report_End_Time)))/60 And convert(float, ut.Result) > 0 Then 1  
    Else 0  
    End)        ,--As UPLTRx,  
  sum(Case When convert(float, datediff(s, ted.Start_Time, coalesce(ted.End_Time,@Report_End_Time)))/60 < 2 Then 1  
    Else 0  
    End)        --As Minor_Stop  
     From Timed_Event_Details ted  
          Left Join Event_Reasons r1 On ted.Reason_Level3 = r1.Event_Reason_Id  
          Left Join Event_Reasons r2 On ted.Reason_Level4 = r2.Event_Reason_Id  
          Left Join tests ut On ut.Var_Id = @Uptime_Var_Id And ut.Result_On = ted.Start_Time-- And isnumeric(result) = 1 -- Uptime  
          Left Join tests rt On rt.Var_Id = @Repulper_Tons_Var_Id And rt.Result_On = ted.Start_Time-- And isnumeric(result) = 1 -- Uptime  
     Where ted.PU_Id = @Sheetbreak_PU_Id And (ted.TEStatus_Id <> @Invalid_Status_Id Or ted.TEStatus_Id Is Null) And  
                (  
   ted.Start_Time < @Report_End_Time  
   and (ted.End_Time > @Report_Start_Time or ted.End_Time is null)  
  )   
     Group By r1.Event_Reason_Name, r2.Event_Reason_Name, ted.start_time, ted.end_time  
Else  
insert into @Sheetbreaks  
 (  
 StartTime,  
 EndTime,  
 Product,  
 Failure_Mode_Cause,  
-- Failure_Mode_Cause_Count,  
 MD_Location,  
 SheetBreak_Count,  
 Uptime,  
 Downtime,  
 Repulper_Tons,  
 Stops,  
 UPLTRx,  
 Minor_Stop  
 )  
     Select  ted.Start_Time,  
  ted.End_Time,  
  p.Prod_Desc        ,--As Product,  
  case WHEN r1.Event_Reason_Name = '' or r1.Event_Reason_Name is Null  
   THEN 'No Reason Assigned'  
   ELSE r1.Event_Reason_Name   
   END        ,--As Failure_Mode_Cause,  
--  count(ted.TEDet_Id)        ,--As Failure_Mode_Cause_Count,   
  case WHEN r2.Event_Reason_Name = '' or r2.Event_Reason_Name is Null  
   THEN 'No Reason Assigned'  
   ELSE r2.Event_Reason_Name   
   END        ,--As Failure_Mode_Cause,  
  count(ted.TEDet_Id)        ,--As Failure_Mode_Cause_Count,   
  sum(convert(float, ut.Result))      ,--As Uptime,  
  sum(convert(float, datediff(s, ted.Start_Time, coalesce(ted.End_Time,@Report_End_Time)))/60) ,--As Downtime,  
  sum(convert(float, rt.Result))      ,--As Repulper_Tons,  
  sum(Case When convert(float, ut.Result) > 0 Then 1   
    Else 0   
    End)         ,--As Stops,  
  sum(Case When convert(float, ut.Result) > 2*convert(float, datediff(s, ted.Start_Time, coalesce(ted.End_Time,@Report_End_Time)))/60 And convert(float, ut.Result) > 0 Then 1  
    Else 0  
    End)        ,--As UPLTRx,  
  sum(Case When convert(float, datediff(s, ted.Start_Time, coalesce(ted.End_Time,@Report_End_Time)))/60 < 2 Then 1  
    Else 0  
    End)        --As Minor_Stop  
     From Timed_Event_Details ted  
          Inner Join Production_Starts ps On ps.PU_Id = @Sheetbreak_PU_Id And ted.Start_Time >= ps.Start_Time And (ted.End_Time < ps.End_Time or ted.end_time is null or ps.end_time is null)  
          Inner Join Products p On ps.Prod_Id = p.Prod_Id  
          Left Join Event_Reasons r1 On ted.Reason_Level3 = r1.Event_Reason_Id  
          Left Join Event_Reasons r2 On ted.Reason_Level4 = r2.Event_Reason_Id  
          Left Join tests ut On ut.Var_Id = @Uptime_Var_Id And ut.Result_On = ted.Start_Time-- And isnumeric(result) = 1 -- Uptime  
          Left Join tests rt On rt.Var_Id = @Repulper_Tons_Var_Id And rt.Result_On = ted.Start_Time-- And isnumeric(result) = 1 -- Uptime  
     Where ted.PU_Id = @Sheetbreak_PU_Id And (ted.TEStatus_Id <> @Invalid_Status_Id Or ted.TEStatus_Id Is Null) And ps.Prod_Id = @Report_Prod_Id And  
                (  
   ted.Start_Time < @Report_End_Time  
   and (ted.End_Time > @Report_Start_Time or ted.End_Time is null)  
  )   
     Group By p.Prod_Desc, r1.Event_Reason_Name, r2.Event_Reason_Name, ted.start_time, ted.end_time  
  
  
--------------------------------------------------------------------------------  
-- Update data to reflect boundaries of the report window  
--------------------------------------------------------------------------------  
  
update @Sheetbreaks set  
 Rpt_StartTime = StartTime,  
 Rpt_EndTime = EndTime,  
-- Rpt_Failure_Mode_Cause_Count = SheetBreak_Count,  
 Rpt_SheetBreak_Count = SheetBreak_Count,  
 Rpt_Primary_Stops = Primary_Stops,  
 Rpt_Extended_Stops = Extended_Stops,  
 Rpt_Stops = Stops,  
 Rpt_UPLTRx = UPLTRx,  
 Rpt_Minor_Stop = Minor_Stop  
  
  
update @Sheetbreaks set  
 Rpt_StartTime = @Report_Start_Time,  
-- Rpt_Failure_Mode_Cause_Count = 0,  
 Rpt_SheetBreak_Count = 0,  
 Rpt_Primary_Stops = 0,  
 Rpt_Extended_Stops = 0,  
 Rpt_Stops = 0,  
 Rpt_UPLTRx = 0,  
 Rpt_Minor_Stop = 0  
where Rpt_StartTime < @Report_Start_Time  
  
update @Sheetbreaks set  
 Rpt_EndTime = @Report_End_Time  
where Rpt_EndTime > @Report_End_Time  
  
  
update @Sheetbreaks set  
 Rpt_Downtime = convert(float, datediff(s, Rpt_StartTime, Rpt_EndTime))/60,  
 Rpt_Primary_Time = Case  When Primary_Time = 0.0  
     Then 0.0   
     When Primary_Time is null   
     Then null      
      Else convert(float,datediff(s, Rpt_StartTime, Rpt_EndTime))/60  
      End,  
 Rpt_Extended_Time = Case  When Extended_Time = 0.0  
     Then 0.0  
     When Extended_Time is null  
     Then null       
      Else convert(float,datediff(s, Rpt_StartTime, Rpt_EndTime))/60  
      End  
  
update @Sheetbreaks set   
 Rpt_Repulper_Tons = Repulper_Tons * (convert(float,Rpt_Downtime) / convert(float,Downtime)),  
 Rpt_Primary_Tons = Primary_Tons * (convert(float,Rpt_Downtime) / convert(float,Downtime)),  
 Rpt_Extended_Tons = Extended_Tons * (convert(float,Rpt_Downtime) / convert(float,Downtime))  
  
  
  
-------------------------------------------------------------------------------------  
  
ReturnResultSets:  
  
--select * from @Sheetbreaks  
  
------------------------------------------------------------------------------------  
  
  
if (select count(*) from @ErrorMessages) > 0   
  
 select * from @ErrorMessages  
  
else  
  
begin  
  
 select * from @ErrorMessages  
  
-- Failure Mode Cause  
If @Report_Prod_Id = -1  
     Select  Product,  
  Failure_Mode_Cause,  
  sum(Rpt_SheetBreak_Count) Failure_Mode_Cause_Count,   
  sum(Uptime) Uptime,  
  sum(Rpt_Downtime) Downtime,  
  sum(Rpt_Repulper_Tons) Repulper_Tons,  
  sum(Rpt_Stops)Stops,  
  sum(Rpt_UPLTRx) UPLTRx,  
  sum(Rpt_Minor_Stop) Minor_Stop  
     From @Sheetbreaks  
     Group By Product, Failure_Mode_Cause  
     Order By Product, sum(Rpt_Downtime) Desc  
  
Else If @Report_Prod_Id = 0  
     Select  Failure_Mode_Cause,  
  sum(Rpt_SheetBreak_Count) Failure_Mode_Cause_Count,   
  sum(Rpt_Downtime) Downtime,  
  sum(Uptime) Uptime,  
  sum(Rpt_Repulper_Tons) Repulper_Tons,  
  sum(Rpt_Primary_Stops) Primary_Stops,  
  sum(Rpt_Extended_Stops) Extended_Stops,  
  sum(Rpt_Primary_Tons) Primary_Tons,  
  sum(Rpt_Extended_Tons) Extended_Tons,  
  sum(Rpt_Primary_Time) Primary_Time,  
  sum(Rpt_Extended_Time) Extended_Time,  
  sum(Rpt_UPLTRx) UPLTRx,  
  sum(Rpt_Minor_Stop) Minor_Stop  
     From @Sheetbreaks  
     Group By Failure_Mode_Cause  
     Order By sum(Rpt_Downtime) Desc  
  
Else  
     Select  Product,  
  Failure_Mode_Cause,  
  sum(Rpt_SheetBreak_Count) Failure_Mode_Cause_Count,   
  sum(Uptime) Uptime,  
  sum(Rpt_Downtime) Downtime,  
  sum(Rpt_Repulper_Tons) Repulper_Tons,  
  sum(Rpt_Stops) Stops,  
  sum(Rpt_UPLTRx) UPLTRx,  
  sum(Rpt_Minor_Stop) Minor_Stop  
     From @Sheetbreaks  
     Group By Product, Failure_Mode_Cause  
     Order By Product, sum(Rpt_Downtime) Desc  
  
  
-- MD Location  
If @Report_Prod_Id = -1  
     Select  Product,  
  MD_Location,  
  sum(Rpt_SheetBreak_Count) MD_Location_Count,   
  sum(Uptime) Uptime,  
  sum(Rpt_Downtime) Downtime,  
  sum(Rpt_Repulper_Tons) Repulper_Tons,  
  sum(Rpt_Stops)Stops,  
  sum(Rpt_UPLTRx) UPLTRx,  
  sum(Rpt_Minor_Stop) Minor_Stop  
     From @Sheetbreaks  
     Group By Product, MD_Location  
     Order By Product, sum(Rpt_Downtime) Desc  
  
Else If @Report_Prod_Id = 0  
     Select  MD_Location,  
  sum(Rpt_SheetBreak_Count) MD_Location_Count,   
  sum(Rpt_Downtime) Downtime,  
  sum(Uptime) Uptime,  
  sum(Rpt_Repulper_Tons) Repulper_Tons,  
  sum(Rpt_Primary_Stops) Primary_Stops,  
  sum(Rpt_Extended_Stops) Extended_Stops,  
  sum(Rpt_Primary_Tons) Primary_Tons,  
  sum(Rpt_Extended_Tons) Extended_Tons,  
  sum(Rpt_Primary_Time) Primary_Time,  
  sum(Rpt_Extended_Time) Extended_Time,  
  sum(Rpt_UPLTRx) UPLTRx,  
  sum(Rpt_Minor_Stop) Minor_Stop  
     From @Sheetbreaks  
     Group By MD_Location  
     Order By sum(Rpt_Downtime) Desc  
  
Else  
     Select  Product,  
  MD_Location,  
  sum(Rpt_SheetBreak_Count) MD_Location_Count,   
  sum(Uptime) Uptime,  
  sum(Rpt_Downtime) Downtime,  
  sum(Rpt_Repulper_Tons) Repulper_Tons,  
  sum(Rpt_Stops) Stops,  
  sum(Rpt_UPLTRx) UPLTRx,  
  sum(Rpt_Minor_Stop) Minor_Stop  
     From @Sheetbreaks  
     Group By Product, MD_Location  
     Order By Product, sum(Rpt_Downtime) Desc  
  
  
end  
  
  
