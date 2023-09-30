/*
7-7-2003 MSI/DS
This Stored Procedure Loops Through The Report_Schedule Table
Looking For Reports That Are Not Assigned And Not In Failed Status
The Stored Procedure 'spRS_UpdateAdvancedReportQue' Will Determine If 
The Report Needs To Run.  If It Does, This SP Will Update The Report_Schedule
and Report_Que Tables So That The Report Can Be Bid On By The Engines. 
 	 Scheduled Report Criteria:
 	 -Must Be In The Schedule
 	 -Must Not Already Be In The Que
 	 -Last Result <> 2 (Failed Status)
 	 -Computer_Name and Process_ID must be null (Not Already Assigned To Another Engine)
*/
CREATE PROCEDURE dbo.spRS_UpdateReportQue
 AS
Declare @Now DateTime
Set @Now = dbo.fnServer_CmnGetDate(GetUtcDate())
Declare @Ids Table(ID int)
-- Get Reports That Need To Run
Insert Into @Ids
 	 select Schedule_Id from report_schedule where
 	 (Computer_Name Is NULL AND Process_Id Is Null) AND
 	 ((Last_Result Is NULL) or (Last_Result <> 2)) AND
 	 ((Next_Run_Time) IS Null or (Next_Run_Time < @Now)) AND
 	 Schedule_Id Not In (Select RQ.Schedule_Id From Report_Que RQ)
-- Set To Pending Status
Update Report_Schedule Set Status = 2 Where Schedule_Id in (Select ID From @Ids)
-- Insert Into Queue For Engine Bidding
Insert Into Report_Que(Schedule_Id) Select Id From @Ids
-- Tell Scheduler What Reports Were Updated
Select Schedule_Id = Id from @Ids
