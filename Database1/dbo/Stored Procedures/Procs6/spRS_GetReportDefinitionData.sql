CREATE PROCEDURE [dbo].[spRS_GetReportDefinitionData]
@Report_Id int,
@Force int
 AS
Declare @SPName varchar(255)
Declare @SQLString varchar(265)
Declare @Count int
Declare @Schedule_id int  
Declare @Last_Run_Time dateTime
Declare @Next_Run_Time dateTime
Declare @Interval int
Declare @Run_Id int
-- MESSAGE FLAGS --
Declare @NoDataFlag int
Declare @Now DateTime
Set @Now = dbo.fnServer_CmnGetDate(GetUtcDate())
----------------------------
-- Initialize
----------------------------
Select @NoDataFlag = 0
Select @Run_Id = 0
Select @Schedule_Id = 0
Select @SPName = ''
-----------------------------
-- Is This Report Scheduled?
-----------------------------
Select 	 @Schedule_id = Schedule_Id,
 	  	 @Last_Run_Time = Last_Run_Time,
 	  	 @Interval = Interval,
 	  	 @Next_Run_Time = Next_Run_Time
From 	 Report_Schedule
Where 	 Report_Id = @Report_Id
If @Schedule_id Is Null
 	 Select @Schedule_id = 0
------------------------------
-- Is This A Scheduled Report?
------------------------------
If @Schedule_id <> 0
 	 Begin 	 
 	  	 If @Next_Run_Time < @Now
 	  	  	 Begin
 	  	  	  	 -- Force The Report To Run Now
 	  	  	  	 Select @Force = 1
 	  	  	  	 Select @NoDataFlag = 1 	  	  	  	 
 	  	  	 End
 	  	 Else
 	  	  	 Begin
 	  	  	  	 -- Use The Existing Data
 	  	  	  	 Select @Force = 0
 	  	  	  	 Select @NoDataFlag = 1 	  	  	  	 
 	  	  	 End
 	 End
-----------------------------------------
-- Does Any Data Exist For This Report?
-----------------------------------------
Select @Count = Count(Report_Id) from report_definition_data Where Report_Id = @Report_Id
If @Count = 0
  Begin
 	 --There is no existing data for this report, the stored procedure will have to be called
 	 Select @NoDataFlag = 1
 	 Select @Force = 1
  End
----------------------------
-- Report SP Will Be Called
----------------------------
If @Force = 1
  Begin
 	 -- Assign A New Report Run Id
 	 Insert Into Report_Runs(Start_Time, Report_Id, Schedule_id)
 	  	  	  	 Values 	    (@Now, @Report_Id, @Schedule_id)
 	 
 	 Select @Run_Id = Scope_Identity()
 	 if @NoDataFlag = 1
 	  	 exec spRS_AddEngineActivity 'Get Definition Data', 0, 'No Current Data Exists.  New Report Run Will Be Forced', 4, @Report_Id, @Run_Id
  End
---------------------------------------------
-- First Result Set Contains Run Information
---------------------------------------------
select @Report_Id 'Report_Id', @Schedule_Id 'Schedule_Id', @Run_Id 'Run_Id', @Force 'Force'
-------------------------------
-- Get The Report_Type SPName
-------------------------------
SELECT 	 @SPName = SPName 
FROM 	 Report_Types rt
JOIN 	 Report_Definitions rd on rd.Report_Type_Id = rt.Report_Type_Id and rd.Report_Id = @Report_Id
---------------------------------------------------
-- Does This Report Have A Valid Stored Procedure?
---------------------------------------------------
if @SPName Is Null
  Begin
 	 exec spRS_AddEngineActivity 'Get Definition Data', 0, 'Stored Procedure Name Is Not Defined. Report Will Not Be Run', 3, @Report_Id, @Run_Id
  End
Else
  Begin
 	 Select @SQLString = @SPName + ' ' + convert(varchar(10), @Report_Id) + ', ' + convert(varchar(10), @Run_Id)
 	 -----------------------------------------------------
 	 -- Rerun The Stored Procedure Now And Get Fresh Data
 	 -----------------------------------------------------
 	 if @Force = 1
 	   Begin
 	     exec (@SQLString)
 	     If @@Error <> 0 
 	       Begin
 	         -- Log message here
 	      	 exec spRS_AddEngineActivity 'Get Definition Data', 0, 'An Error Occured While Calling Stored Procedure ', 3, @Report_Id, @Run_Id
 	         raiserror('Error In Stored Procedure', 16, 1)
 	 
 	       End    
 	   End
 	 
 	 -----------------------------------------------------
 	 -- Get Existing Data From Report_Definition_Data
 	 -----------------------------------------------------
 	 Else
 	   Begin
 	         Select 	 Data
 	         From 	 Report_Definition_Data
 	         Where 	 Report_Id = @Report_Id
 	         Order By PageNum asc
 	   End
  End
---------------------------------------------
-- Update Report Schedule Table If Necessary
---------------------------------------------
If @Schedule_id <> 0
 	 begin
 	  	 exec spRS_CompleteAspTask @Schedule_id
 	 End
-----------------------------------------
-- Update Report Runs Table If Necessary
-----------------------------------------
If @Force <> 0
  Begin
 	 ----------------------------
 	 -- Update Report Runs Table
 	 ---------------------------- 	  	 
 	 Update Report_Runs
 	 Set End_Time = @Now
 	 Where Run_Id = @Run_Id 	  	 
  End
