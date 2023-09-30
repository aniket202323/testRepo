/*
Febuary 23, 2004 MSI/DS
Removed reference to table Report Server Settings
These values are now stored as site parameters
August 6, 2003 MSI/DS
Modified Order By clause when stored procedure is selecting a report
from the que.  Reports with the earliest Next_Run_Time at the top of the
result set.
June 30, 2003 MSI/DS
Removed transaction code to avoid blocking.
SP will guarantee that one and only one engine will be assigned to a report
by checking the @@RowCount:
    Delete From Report_Que Where Schedule_Id = @Schedule_Id
    If @@RowCount = 0
    Begin
 	   Close MyCursor
 	   Deallocate MyCursor
      Select * From Report_Schedule  Where 1 = 2
      Return
    End
December 2, 2002 MSI/DS
Modified report selection when an engine dies while running a report.
Rather than giving the requesting engine the same report back immediately,
its name will be removed from the report in question and no result set 
will be sent back.  This will give the engine time to signal the service control
panel that it is running.
August 12, 2002 MSI/DS
Modified selection criteria to avoid getting report types of 'Active Server Page'
This type of scheduled report will be handled by another sp
*/
CREATE PROCEDURE dbo.spRS_AssignScheduleTask
@Computer_Name varchar(20),
@Process_Id  Int
 AS
------------------------
-- LOCAL VARIABLES 
------------------------
Declare @Schedule_Id int
Declare @t int
Declare @Restrict varchar(20)
Declare @ReportDefId int
Declare @Ok int
Declare @Run_Id int
Declare @MyError int
Declare @E_Id int
Declare @User_Id int
Declare @User_Name varchar(20)
Declare @ReportTimeout varchar(255)
Declare @MyReport int
Declare @MaxReportFails int
Declare @Run_Attempts int
Declare @Class int
Declare @Now DateTime
Set @Now = dbo.fnServer_CmnGetDate(GetUtcDate())
------------------------
-- INITIALIZE VARAIBLES
------------------------
Select @MyReport = 0
Select @Schedule_Id = Null
Select @MaxReportFails = convert(int, Value) From Site_Parameters Where Parm_Id = 306
If @MaxReportFails Is Null 
  Select @MaxReportFails = 4
---------------------------------------------------
-- IS THE ENGINE THAT IS MAKING THIS REQUEST
-- ALREADY SUPPOSED TO BE RUNNING ANOTHER REPORT?
---------------------------------------------------
Select @Schedule_Id = Schedule_Id, @Run_Attempts = Run_Attempts, @ReportDefId = Report_Id 
From Report_Schedule 
where Computer_Name = @Computer_Name and Process_Id = @Process_Id
---------------------------------------------------------------
-- IF THE ENGINE IS ALREADY SUPPOSED TO BE WORKING ON A REPORT
-- AND THE REPORT IS NOT A "SCHEDULED" REPORT (CLASS <> 2)
-- REPORT THEN REMOVE IT FROM THE SCHEDULE
-- THIS WILL ENSURE THAT ONLY "SCHEDULED" REPORTS STAY IN 
-- THE SCHEDULE
-- SELECT * FROM RETURN_ERROR_CODES WHERE GROUP_ID = 2
---------------------------------------------------------------
If @Schedule_Id Is Not Null
  Begin
    Select @Class = Class From Report_Definitions Where Report_Id = @ReportDefId
    If @Class <> 2
      Begin
        -- REMOVE FROM SCHEDULE
        Exec spRS_DeleteReportSchedule @Schedule_Id
        -- CLEAR SCHEDULE_ID SO ENGINE CAN PICK FROM QUE
        Select @Schedule_Id = Null
      End
  End
Select @ReportDefId = Null
------------------------------------------------
-- THE ENGINE IS ALREADY SUPPOSED TO BE WORKING
-- ON A REPORT.  THIS SITUATION MIGHT OCCUR IF
-- THE ENGINE WAS KILLED WHILE RUNNING A REPORT
------------------------------------------------
If @Schedule_Id Is Not Null
  Begin
 	 --print 'you are already running a report'
    ----------------------------------------------------------------
    -- KEEP ASSIGNING THIS REPORT UNTIL IT REACHES MAX REPORT FAILS
    ----------------------------------------------------------------
    If @Run_Attempts >= @MaxReportFails
      Begin
        --------------------------------------------
        -- Set Report To Failed Status
        -- Clear Engine Fields
        --------------------------------------------
        Update Report_Schedule Set
           	   Status = 4, 
 	  	  	   Last_Result = 2, 
              Computer_Name = Null, 
              Process_Id = Null, 
              Error_String = 'Report Run By Same Engine Multiple Times But Was Unable To Complete'
          Where Schedule_Id = @Schedule_Id
        -- CLEAR SCHEDULE_ID SO ENGINE CAN PICK FROM QUE
        Select @Schedule_Id = Null
 	  	 
 	  	 --December 2, 2002 MSI/DS
 	  	 Return(0)
 	  	 --End December 2, 2002 MSI/DS
      End
    Else
      Begin
        -----------------------------------------------------------------------
        -- Clear my name from all reports in the schedule
 	  	 -- Increment Run Attempts
        -----------------------------------------------------------------------
 	  	 Update Report_Schedule Set
 	  	  	 Status = 4,
 	  	  	 Run_Attempts = Run_Attempts + 1,
 	  	  	 Computer_Name = Null,
 	  	  	 Process_Id = Null
 	  	  	 Where Computer_Name = @Computer_Name
 	  	  	 AND Process_Id = @Process_Id
 	  	  	 Return (0)
 	  	 --End December 2, 2002 MSI/DS
      End
  End
--------------------------------------------------
-- ENGINE IS NOT CURRENTLY ASSIGNED TO ANY REPORT
-- LET IT PICK FROM THE QUE
--------------------------------------------------
If @Schedule_Id Is Null
  Begin
    Declare MyCursor INSENSITIVE CURSOR
      For 
 	 Select RD.Report_Id
 	 from report_definitions RD
 	 Left Join Report_Types RT on RT.Report_Type_Id = RD.Report_Type_Id and rt.Class_Name <> 'Active Server Page'
 	 Left Join Report_Type_Parameters RTP on RTP.Report_Type_Id = RT.Report_Type_Id
 	 Left Join Report_Definition_Parameters RDP on RDP.Report_Id = RD.Report_Id
 	 Join Report_Schedule RS on RS.Report_Id = RD.Report_Id
 	 Where RD.Report_Id in(
 	  	 Select RS.Report_Id
 	  	 From Report_Schedule RS
 	  	 Where RS.Schedule_Id in (
 	  	  	 Select RQ.Schedule_Id
 	  	  	 From Report_Que RQ
 	  	 )
 	  	 And Computer_Name Is Null
 	  	 And Process_Id Is Null
 	 )
 	 And RTP.RP_Id = 30
 	 And RDP.RTP_Id = RTP.RTP_Id
 	 order by RD.Priority Desc,rd.class asc,RS.Next_Run_Time ASC,  Value Desc 
 	 -- ECR #34144
 	 -- AdHoc Reports Get Priority
    For Read Only
    Open MyCursor 
  End
Else
  Begin
    --------------------------------------------------------------
    -- Get the report_id that is already assigned to this engine
    -- Set the @MyReport Flag
    --------------------------------------------------------------
    Select @MyReport = 1
    Declare MyCursor INSENSITIVE CURSOR
      For 
 	 Select RD.Report_Id
 	 from report_definitions RD
 	 Left Join Report_Types RT on RT.Report_Type_Id = RD.Report_Type_Id and rt.Class_Name <> 'Active Server Page'
 	 Left Join Report_Type_Parameters RTP on RTP.Report_Type_Id = RT.Report_Type_Id
 	 Left Join Report_Definition_Parameters RDP on RDP.Report_Id = RD.Report_Id
 	 Where RD.Report_Id in(
 	  	 Select RS.Report_Id
 	  	 From Report_Schedule RS
 	  	 Where Computer_Name = @Computer_Name
 	  	 And Process_Id = @Process_Id
 	 )
 	 And RTP.RP_Id = 30
 	 And RDP.RTP_Id = RTP.RTP_Id
 	 order by Value Desc, RD.Priority Desc
    For Read Only
    Open MyCursor 
  End 
------------------------------
-- Go through the Result set 
------------------------------
MyLoop1:
  Fetch Next From MyCursor Into @ReportDefId 
  If (@@Fetch_Status = 0)
    Begin
      ------------------------------------------------------------------
      -- Check to see if this computer is authorized to run this report
      ------------------------------------------------------------------
      Exec @Ok = spRS_GetEngineRestriction @ReportDefId, @Computer_Name     
      If @Ok = 0 
        Begin
          ------------------------------------------------
          -- Assign this task to the requesting engine
          ------------------------------------------------
          --------------------------------------------------------
 	   	   -- Make sure a valid engine is calling for this report
          --------------------------------------------------------
          Select @E_Id = Engine_Id From Report_Engines Where Engine_Id = @Process_Id
          -- If @E_Id is not a valid engine_Id
          If @E_Id Is Null
            Begin
 	       -- Return Empty Result Set
              Select * From Report_Schedule Where 1 = 2
 	       goto myend
            End
 	   Else -- If @E_Id is a valid engine
            Begin
 	  	  	   Execute sprs_GetReportParamValue 'ReportTimeout', @ReportDefId, @ReportTimeout Output
              Execute sprs_GetReportParamValue 'Owner', @ReportDefId, @User_Name Output
              Select @User_Id = User_Id
              From Users
              Where UserName = @User_Name
              Select @Schedule_Id = Schedule_Id
              From Report_Schedule
              Where Report_Id = @ReportDefId
 	  	       ----------------------
 	  	       -- Begin Transaction
 	  	       ---------------------- 
 	  	       --Begin Transaction
 	  	       Select @MyError = 0
              ------------------------------------
              -- If this report was not previously
              -- assigned to me then remove it
              -- from the que
              ------------------------------------
              If @MyReport = 0
              Begin
                Delete From Report_Que Where Schedule_Id = @Schedule_Id
                If @@RowCount = 0
                Begin
                  -- Someone else took this report from under my feet
 	  	  	  	   Close MyCursor
 	  	  	  	   Deallocate MyCursor
                  --Rollback Transaction
                  Select * From Report_Schedule  Where 1 = 2
                  Return
                End
              End
 	  	       If @@Error <> 0
 	  	  	  	 Select @MyError = 1
              -----------------------------
              -- Update Report_Runs Table
              -----------------------------
              Insert Into Report_Runs(Report_Id, Start_Time, Engine_Id, User_Id, Schedule_Id)
              Values(@ReportDefId, @Now, @Process_Id, @User_Id, @Schedule_Id)
              Select @Run_Id = Scope_Identity()
 	  	       If @@Error <> 0
 	  	  	  	 Select @MyError = 2
              ---------------------------------
              -- Update Report_Schedule Table
              ---------------------------------
              Update Report_Schedule
                Set Status = 3,
                Computer_Name = @Computer_Name,
                Process_Id = @Process_Id,
 	  	  	  Last_Result = 0
                Where Report_Id = @ReportDefId
 	  	       If @@Error <> 0
 	  	  	  	 Select @MyError = 3
              ----------------------
              -- Select Result Set
              ----------------------
              Select RS.Schedule_Id, RS.Report_Id, RD.Report_Type_Id, RT.Date_Saved, RS.Start_Date_Time, RS.Interval, Next_Run_Time = @Now, RS.Last_Run_Time,
                     RS.Status, RS.Last_Result, RS.Run_Attempts, RS.Computer_Name, RS.Process_Id, RS.Error_Code,  RS.Error_String, 
                     Report_Name, File_Name, @User_Name 'Owner', @ReportTimeout 'ReportTimeout' , Class ,RT.Description, Template_Path, Class_Name, Run_Id = @Run_Id
              From Report_Schedule RS
              Left join Report_Definitions RD on RS.Report_Id = RD.Report_Id
              Left Join Report_Types RT on RD.Report_Type_Id = RT.Report_Type_Id
              Where RS.Report_Id = @ReportDefId
 	  	       If @@Error <> 0
 	  	  	  	 Select @MyError = 4
 	       
 	           If @MyError = 0 
 	  	  	  	 Begin
 	  	  	  	   Close MyCursor
 	  	  	  	   Deallocate MyCursor
 	  	  	  	   --Commit Transaction
 	  	  	  	 End
 	  	       Else -- Error occured during Transaction
 	  	  	  	 Begin
 	  	  	  	   Close MyCursor
 	  	  	  	   Deallocate MyCursor
 	  	  	  	   --Rollback Transaction
 	  	  	  	   Select * From Report_Schedule Where 1 = 2
 	  	  	  	 End
 	  	       ---------------------
 	  	       -- End Transaction  
 	  	       --------------------
              Return
            End -- If @E_Id is null
          End -- If @Ok = 0
        Else -- @Ok is not 0 
          Begin
            Goto MyLoop1
          End
    End -- If @@Fetch_Status = 0
  Else -- @@Fetch_Status is not 0
    Begin
      goto myEnd
    End
myEnd:
Close MyCursor
Deallocate MyCursor
