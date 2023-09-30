  /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-02  
Version  : 1.0.3  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Replace temp table for table variable   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_GetSBSummaryData  
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
  
CALLED BY:  RptPmkgSheetBreaksSummary.xlt (Excel/VBA Template)  
  
CALLS: None  
  
Revision Change Date Who What  
======== =========== ==== =====  
0.0  4/23/02  MW Original Creation  
0.1  5/1/02  CE Numerous enhancements for SB Summary Rpt  
0.2  8/7/02  CE Remove refs to Local_Timed_Event_Detail_Categories table  
  
*/  
CREATE PROCEDURE dbo.spLocal_GetSBSummaryData  
--Declare  
  
@Report_Start_Time datetime,  
@Report_End_Time datetime,  
@Line_Name   varchar(50),  
@Data_Category varchar(15),  
@Report_Prod_Id int  
  
AS  
  
Declare @Time1 datetime, @Time2 datetime, @Time3 datetime, @Time4 datetime, @Time5 datetime  
/* Testing...   
  
Select  @Report_Start_Time  = '2002-07-01 00:00:00',  
 @Report_End_Time    = '2002-07-07 00:00:00',  
 @Line_Name  = 'GP06',  
  @Data_Category  = 'SheetBreaks', --'Quality', --   
 @Report_Prod_Id  = 0   --Null  
  
--select @PL_Id,@Report_Start_Time,@Report_End_Time,@Data_Category  
  
--execute spLocal_GetSBSummaryData '2002-08-01 00:00:00', '2002-08-07 00:00:00', 'GP06','SheetBreaks',-1  
*/  
  
/************************************************************************************************  
*                                                                                               *  
*                                 Global execution switches                                     *  
*                                                                                               *  
************************************************************************************************/  
SET NOCOUNT ON  
SET ANSI_WARNINGS OFF  
  
  
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
 @Blocked_Starved_Desc varchar(50),  
 @Mechanical_Id  int,  
 @Electrical_Id   int,  
 @Process_Failure_Id  int,  
 @Blocked_Starved_Id  int,  
 @Uptime_Var_Id  int,  
 @Repulper_Tons_Var_Id int,  
 @Invalid_Status_Desc  varchar(50),  
 @Invalid_Status_Id  int  
  
Select @Time1 = getdate()  
  
/************************************************************************************************  
*                                                                                                                               *  
*                                     Initialization                                                      *  
*                                                                                                                               *  
************************************************************************************************/  
Select @Invalid_Status_Desc  = 'Invalid',  
 @Mechanical_Desc  = 'Category:Mechanical Equipment',  
 @Electrical_Desc  = 'Category:Electrical Equipment',  
 @Process_Failure_Desc  = 'Category:Process/Operational',  
 @Blocked_Starved_Desc = 'Category:Blocked/Starved'  
  
  
  
/************************************************************************************************  
*                                                                                                                               *  
*                                     Get Configuration                                                               *  
*                                                                                                                               *  
************************************************************************************************/  
/* Get the line id */  
Select @PL_Id = PL_Id  
From [dbo].Prod_Lines  
Where PL_Desc = 'TT ' + @Line_Name  
  
/* Get Different PU Ids */  
Select @Sheetbreak_PU_Id = PU_Id  
From [dbo].Prod_Units  
Where PL_Id = @PL_Id And PU_Desc = @Line_Name + ' Sheetbreak'  
  
/* Get variables */  
Select @Uptime_Var_Id = Var_Id  
From [dbo].Variables  
Where Var_Desc = 'Sheet Reel Time' And PU_Id = @Sheetbreak_PU_Id  
  
Select @Repulper_Tons_Var_Id = Var_Id  
From [dbo].Variables  
Where Var_Desc = 'Tons Repulper' And PU_Id = @Sheetbreak_PU_Id  
  
Select @Mechanical_Id = ERC_Id  
From [dbo].Event_Reason_Catagories  
Where ERC_Desc = @Mechanical_Desc  
  
Select @Electrical_Id = ERC_Id  
From [dbo].Event_Reason_Catagories  
Where ERC_Desc = @Electrical_Desc  
  
Select @Process_Failure_Id = ERC_Id  
From [dbo].Event_Reason_Catagories  
Where ERC_Desc = @Process_Failure_Desc  
  
Select @Blocked_Starved_Id = ERC_Id  
From [dbo].Event_Reason_Catagories  
Where ERC_Desc = @Blocked_Starved_Desc  
  
Select @Invalid_Status_Id = TEStatus_Id  
From [dbo].Timed_Event_Status  
Where PU_Id = @Sheetbreak_PU_Id And TEStatus_Name = @Invalid_Status_Desc  
  
/************************************************************************************************  
*                                                                                                                               *  
*                                     Get Production Statistics                                                   *  
*                                                                                                                               *  
************************************************************************************************/  
If @Report_Prod_Id = -1  
     Select  p.Prod_Desc        As Product,  
  r1.Event_Reason_Name       As Failure_Mode,  
  count(ted.TEDet_Id)        As Failure_Mode_Count,   
  sum(convert(real, ut.Result))      As Uptime,  
  sum(convert(real, datediff(s, ted.Start_Time, ted.End_Time))/60) As Downtime,  
  sum(convert(real, rt.Result))      As Repulper_Tons,  
  sum(Case When convert(real, ut.Result) > 0 Then 1   
    Else 0   
    End)         As Stops,  
  sum(Case When convert(real, ut.Result) > 2*convert(real, datediff(s, ted.Start_Time, ted.End_Time))/60 And convert(real, ut.Result) > 0 Then 1  
    Else 0  
    End)        As UPLTRx,  
  sum(Case When convert(real, datediff(s, ted.Start_Time, ted.End_Time))/60 < 2 Then 1  
    Else 0  
    End)        As Minor_Stop  
/*  sum(Case When (Category_Id = @Mechanical_Id Or Category_Id = @Electrical_Id) And  
         convert(real, datediff(s, ted.Start_Time, ted.End_Time))/60 > 2 Then 1  
    Else 0  
    End)        As Breakdown,  
  sum(Case When Category_Id = @Process_Failure_Id And  
         convert(real, datediff(s, ted.Start_Time, ted.End_Time))/60 > 2 Then 1  
    Else 0  
    End)        As Process_Failure,  
  sum(Case When Category_Id = @Blocked_Starved_Id Then 1  
    Else 0  
    End)        As Blocked_Starved  
*/  
     From [dbo].Timed_Event_Details ted  
          Inner Join [dbo].Production_Starts ps On ps.PU_Id = @Sheetbreak_PU_Id And ted.Start_Time >= ps.Start_Time And ted.End_Time < ps.End_Time  
          Inner Join [dbo].Products p On ps.Prod_Id = p.Prod_Id  
--          Left Join Local_Timed_Event_Detail_Categories tedc On ted.TEDet_Id = tedc.TEDet_Id  
          Left Join [dbo].Event_Reasons r1 On ted.Reason_Level3 = r1.Event_Reason_Id  
          Left Join [dbo].tests ut On ut.Var_Id = @Uptime_Var_Id And ut.Result_On = ted.Start_Time-- And isnumeric(result) = 1 -- Uptime  
          Left Join [dbo].tests rt On rt.Var_Id = @Repulper_Tons_Var_Id And rt.Result_On = ted.Start_Time-- And isnumeric(result) = 1 -- Uptime  
     Where ted.PU_Id = @Sheetbreak_PU_Id And (ted.TEStatus_Id <> @Invalid_Status_Id Or ted.TEStatus_Id Is Null) And  
                ((ted.Start_Time >= @Report_Start_Time And ted.Start_Time < @Report_End_Time) Or  
                 (ted.Start_Time < @Report_Start_Time And (ted.End_Time > @Report_Start_Time Or ted.End_Time Is Null)) Or  
                 (ted.Start_Time > @Report_Start_Time And ted.Start_Time < @Report_End_Time And (ted.End_Time >= @Report_End_Time Or ted.End_Time Is Null)))   
     Group By p.Prod_Desc, Event_Reason_Name  
     Order By p.Prod_Desc, Downtime Desc  
Else If @Report_Prod_Id = 0  
     Select  r1.Event_Reason_Name       As Failure_Mode,  
  count(ted.TEDet_Id)        As Failure_Mode_Count,   
  sum(convert(real, datediff(s, ted.Start_Time, ted.End_Time))/60)  As Downtime,  
  sum(convert(real, ut.Result))      As Uptime,  
  sum(convert(real, rt.Result))      As Repulper_Tons,  
  sum(Case When convert(real, ut.Result) > 0 Then 1   
    Else 0   
    End)         As Primary_Stops,  
  sum(Case When convert(real, ut.Result) = 0 Then 1   
    Else 0   
    End)         As Extended_Stops,  
  sum(Case When convert(real, ut.Result) > 0 Then rt.Result   
    Else cast(0.0 as real)   
    End)         As Primary_Tons,  
  sum(Case When convert(real, ut.Result) = 0 Then rt.Result   
    Else cast(0.0 as real)   
    End)         As Extended_Tons,  
  sum(Case When convert(real, ut.Result) > 0 Then convert(real,datediff(s, ted.Start_Time, ted.End_Time))/60  
    Else cast(0.0 as real)   
    End)         As Primary_Time,  
  sum(Case When convert(real, ut.Result) = 0 Then convert(real,datediff(s, ted.Start_Time, ted.End_Time))/60  
    Else cast(0.0 as real)   
    End)         As Extended_Time,  
  sum(Case When convert(real, ut.Result) > 2*convert(real, datediff(s, ted.Start_Time, ted.End_Time))/60 And convert(real, ut.Result) > 0 Then 1  
    Else 0  
    End)        As UPLTRx,  
  sum(Case When convert(real, datediff(s, ted.Start_Time, ted.End_Time))/60 < 2 Then 1  
    Else 0  
    End)        As Minor_Stop  
/*  sum(Case When (Category_Id = @Mechanical_Id Or Category_Id = @Electrical_Id) And  
         convert(real, datediff(s, ted.Start_Time, ted.End_Time))/60 > 2 Then 1  
    Else 0  
    End)        As Breakdown,  
  sum(Case When Category_Id = @Process_Failure_Id And  
         convert(real, datediff(s, ted.Start_Time, ted.End_Time))/60 > 2 Then 1  
    Else 0  
    End)        As Process_Failure,  
  sum(Case When Category_Id = @Blocked_Starved_Id Then 1  
    Else 0  
    End)        As Blocked_Starved  
*/  
     From [dbo].Timed_Event_Details ted  
--          Left Join Local_Timed_Event_Detail_Categories tedc On ted.TEDet_Id = tedc.TEDet_Id  
          Left Join [dbo].Event_Reasons r1 On ted.Reason_Level3 = r1.Event_Reason_Id  
          Left Join [dbo].tests ut On ut.Var_Id = @Uptime_Var_Id And ut.Result_On = ted.Start_Time-- And isnumeric(result) = 1 -- Uptime  
          Left Join [dbo].tests rt On rt.Var_Id = @Repulper_Tons_Var_Id And rt.Result_On = ted.Start_Time-- And isnumeric(result) = 1 -- Uptime  
     Where ted.PU_Id = @Sheetbreak_PU_Id And (ted.TEStatus_Id <> @Invalid_Status_Id Or ted.TEStatus_Id Is Null) And  
      ((ted.Start_Time >= @Report_Start_Time And ted.Start_Time < @Report_End_Time) Or  
                 (ted.Start_Time < @Report_Start_Time And (ted.End_Time > @Report_Start_Time Or ted.End_Time Is Null)) Or  
                 (ted.Start_Time > @Report_Start_Time And ted.Start_Time < @Report_End_Time And (ted.End_Time >= @Report_End_Time Or ted.End_Time Is Null)))   
     Group By Event_Reason_Name--, Type  
     Order By Downtime Desc  
Else  
     Select  p.Prod_Desc        As Product,  
  r1.Event_Reason_Name       As Failure_Mode,  
  count(ted.TEDet_Id)        As Failure_Mode_Count,   
  sum(convert(real, ut.Result))      As Uptime,  
  sum(convert(real, datediff(s, ted.Start_Time, ted.End_Time))/60) As Downtime,  
  sum(convert(real, rt.Result))      As Repulper_Tons,  
  sum(Case When convert(real, ut.Result) > 0 Then 1   
    Else 0   
    End)         As Stops,  
  sum(Case When convert(real, ut.Result) > 2*convert(real, datediff(s, ted.Start_Time, ted.End_Time))/60 And convert(real, ut.Result) > 0 Then 1  
    Else 0  
    End)        As UPLTRx,  
  sum(Case When convert(real, datediff(s, ted.Start_Time, ted.End_Time))/60 < 2 Then 1  
    Else 0  
    End)        As Minor_Stop  
/*  sum(Case When (Category_Id = @Mechanical_Id Or Category_Id = @Electrical_Id) And  
         convert(real, datediff(s, ted.Start_Time, ted.End_Time))/60 > 2 Then 1  
    Else 0  
    End)        As Breakdown,  
  sum(Case When Category_Id = @Process_Failure_Id And  
         convert(real, datediff(s, ted.Start_Time, ted.End_Time))/60 > 2 Then 1  
    Else 0  
    End)        As Process_Failure,  
  sum(Case When Category_Id = @Blocked_Starved_Id Then 1  
    Else 0  
    End)        As Blocked_Starved  
*/  
     From [dbo].Timed_Event_Details ted  
          Inner Join [dbo].Production_Starts ps On ps.PU_Id = @Sheetbreak_PU_Id And ted.Start_Time >= ps.Start_Time And ted.End_Time < ps.End_Time  
          Inner Join [dbo].Products p On ps.Prod_Id = p.Prod_Id  
--          Left Join Local_Timed_Event_Detail_Categories tedc On ted.TEDet_Id = tedc.TEDet_Id  
          Left Join [dbo].Event_Reasons r1 On ted.Reason_Level3 = r1.Event_Reason_Id  
          Left Join [dbo].tests ut On ut.Var_Id = @Uptime_Var_Id And ut.Result_On = ted.Start_Time-- And isnumeric(result) = 1 -- Uptime  
          Left Join [dbo].tests rt On rt.Var_Id = @Repulper_Tons_Var_Id And rt.Result_On = ted.Start_Time-- And isnumeric(result) = 1 -- Uptime  
     Where ted.PU_Id = @Sheetbreak_PU_Id And (ted.TEStatus_Id <> @Invalid_Status_Id Or ted.TEStatus_Id Is Null) And ps.Prod_Id = @Report_Prod_Id And  
                ((ted.Start_Time >= @Report_Start_Time And ted.Start_Time < @Report_End_Time) Or  
                 (ted.Start_Time < @Report_Start_Time And (ted.End_Time > @Report_Start_Time Or ted.End_Time Is Null)) Or  
                 (ted.Start_Time > @Report_Start_Time And ted.Start_Time < @Report_End_Time And (ted.End_Time >= @Report_End_Time Or ted.End_Time Is Null)))   
     Group By p.Prod_Desc, Event_Reason_Name  
     Order By p.Prod_Desc, Downtime Desc  
  
/************************************************************************************************  
*                                     Cleanup                                                   *  
************************************************************************************************/  
  
/* Testing....  
Select @Time5 = getdate()  
Select Datediff(ms, @Time1, @Time5), Datediff(ms, @Time1, @Time2), Datediff(ms, @Time2, @Time3), Datediff(ms, @Time3, @Time4), Datediff(ms, @Time4, @Time5)  
*/  
  
SET NOCOUNT OFF  
  
  
