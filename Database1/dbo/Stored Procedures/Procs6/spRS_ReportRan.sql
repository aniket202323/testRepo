CREATE PROCEDURE dbo.spRS_ReportRan
@Schedule_Id int,
@Next_Run_Time datetime = Null,
@Last_Run_Time datetime = Null,
@Status int = Null,
@Last_Result int = Null,
@Run_Attempts int = Null,
@Error_Code int = Null,
@Error_String varChar(255) = Null,
@Run_Id int = Null,
@File_Name varchar(255) = Null,
@Error_Id int = Null,
@User_Name varchar(20) = Null
 AS
Declare @MyError int
-- Local Variables used for the spy table
Declare @MinRunTime int
Declare @MaxRunTime int
Declare @TotalRuns int
Declare @TotalTime int  -- in minutes
Declare @StartTime DateTime
Declare @EndTime DateTime
Declare @RunTime int -- in minutes
Declare @Report_Id int
Declare @RP_Id int 
Declare @RDP_Id_MinRunTime int 
Declare @RDP_Id_MaxRunTime int 
Declare @RDP_Id_TotalRuns int 
Declare @RDP_Id_TotalTime int 
Declare @User_Id int
Declare @Now DateTime
Set @Now = dbo.fnServer_CmnGetDate(GetUtcDate())
Select @Report_Id = Report_Id
From Report_Schedule
Where Schedule_Id = @Schedule_Id
Select @MyError = 0
--Capture this information to do the updates later (inside the transaction)
If @Report_Id Is Not Null
  Begin
 	 -- These should be standard at every site (31,32,33,34) but JIC: 
    -- NOTE: Leave the Where clause on, its faster - JG
    Select @RP_Id = RP_Id 
 	   From Report_Parameters
      Where RP_Name = 'MinRunTime'
    Select @RDP_Id_MinRunTime = dp.RDP_Id
    From Report_Definitions d
    Join Report_Types t on t.Report_Type_Id = d.Report_Type_Id
    Join Report_Type_Parameters tp on tp.Report_Type_Id = t.Report_Type_Id and tp.rp_id = @RP_Id
    Join Report_Definition_Parameters dp on dp.RTP_Id = tp.RTP_Id and dp.Report_Id = @Report_Id  
    Where d.Report_Id = @Report_Id
    Select @RP_Id = RP_Id 
 	   From Report_Parameters
      Where RP_Name = 'MaxRunTime'
    Select @RDP_Id_MaxRunTime = dp.RDP_Id
    From Report_Definitions d
    Join Report_Types t on t.Report_Type_Id = d.Report_Type_Id
    Join Report_Type_Parameters tp on tp.Report_Type_Id = t.Report_Type_Id and tp.rp_id = @RP_Id
    Join Report_Definition_Parameters dp on dp.RTP_Id = tp.RTP_Id and dp.Report_Id = @Report_Id  
    Where d.Report_Id = @Report_Id
    Select @RP_Id = RP_Id 
 	   From Report_Parameters
      Where RP_Name = 'TotalRuns'
    Select @RDP_Id_TotalRuns = dp.RDP_Id
    From Report_Definitions d
    Join Report_Types t on t.Report_Type_Id = d.Report_Type_Id
    Join Report_Type_Parameters tp on tp.Report_Type_Id = t.Report_Type_Id and tp.rp_id = @RP_Id
    Join Report_Definition_Parameters dp on dp.RTP_Id = tp.RTP_Id and dp.Report_Id = @Report_Id  
    Where d.Report_Id = @Report_Id
    Select @RP_Id = RP_Id 
 	   From Report_Parameters
      Where RP_Name = 'TotalTime'
    Select @RDP_Id_TotalTime = dp.RDP_Id
    From Report_Definitions d
    Join Report_Types t on t.Report_Type_Id = d.Report_Type_Id
    Join Report_Type_Parameters tp on tp.Report_Type_Id = t.Report_Type_Id and tp.rp_id = @RP_Id
    Join Report_Definition_Parameters dp on dp.RTP_Id = tp.RTP_Id and dp.Report_Id = @Report_Id  
    Where d.Report_Id = @Report_Id
  End
Select 
  @Next_Run_Time = COALESCE(@Next_Run_Time,Next_Run_Time)
 ,@Last_Run_Time = COALESCE(@Last_Run_Time,Last_Run_Time)
 ,@Status = COALESCE(@Status,Status)
 ,@Last_Result = COALESCE(@Last_Result,Last_Result)
 ,@Run_Attempts = COALESCE(@Run_Attempts,Run_Attempts)
 ,@Error_Code = COALESCE(@Error_Code,Error_Code)
 ,@Error_String = COALESCE(@Error_String,Error_String)
  From Report_Schedule
  Where Schedule_Id = @Schedule_Id
Select @User_Id = User_Id
  From Users
  Where username = @User_Name
Select 
  @File_Name=COALESCE(@File_Name,File_Name)
 ,@Error_Id=COALESCE(@Error_Id,Error_Id)
 ,@Last_Result=COALESCE(@Last_Result,@Last_Result) 
 ,@User_Id=COALESCE(@User_Id, User_Id)
  From Report_Runs 
  Where Run_Id = @Run_Id
--Begin Transaction
--------------------------------------
-- UPDATE THE REPORT SCHEDULE TABLE
-- @Next_Run_Time should always be null
-- AND
-- RELEASE ENGINE GRIP 
--------------------------------------
Update Report_Schedule Set
    Last_Run_Time = @Now,
    Status = @Status,
    Last_Result = @Last_Result,
    Run_Attempts = 
       CASE WHEN (@Status = 4 and @Last_Result = 1) THEN 0
            ELSE @Run_Attempts
       END,
    Error_Code = @Error_Code,
    Error_String = @Error_String,
    Computer_Name = Null,
    Process_Id = Null
    Where Schedule_Id = @Schedule_Id
--Reset The Start_Date_Time and Next_Run_Time
Exec spRS_UpdateAdvancedReportQue @Schedule_Id
Delete from Report_Que Where Schedule_Id = @Schedule_Id
Update Report_Runs Set
 	 File_Name = @File_Name,
 	 End_Time = @Now,
 	 Error_Id = @Error_Id,
 	 Status = 4,
 	 Last_Result = @Last_Result,
 	 User_Id = @User_Id
 	 Where Run_Id = @Run_Id
------------------------------------------
-- RECALCULATE SPY TABLE RUN TIME VALUES
------------------------------------------
If @Report_Id Is Not Null
  Begin
    Select @RunTime = DateDiff(Second, Start_Time, End_Time) From Report_Runs Where Run_Id = @Run_Id
 	 Update Report_Definition_Parameters 
      Set Value = @RunTime
      Where RDP_Id = @RDP_Id_MinRunTime and CAST(Value AS int) > @RunTime
 	 Update Report_Definition_Parameters 
      Set Value = @RunTime
      Where RDP_Id = @RDP_Id_MaxRunTime and CAST(Value AS int) < @RunTime
 	 Update Report_Definition_Parameters 
      Set Value = CAST(Value AS int) + 1
      Where RDP_Id = @RDP_Id_TotalRuns 
 	 Update Report_Definition_Parameters 
      Set Value = CAST(Value AS int) + @RunTime
      Where RDP_Id = @RDP_Id_TotalTime 
  End
/*
Update Report_Schedule 
    Set Next_Run_Time = @Next_Run_Time
    ,Last_Run_Time = @Last_Run_Time
    ,Status = @Status
    ,Last_Result = @Last_Result
    ,Run_Attempts = 
       CASE WHEN (@Status = 4 and @Last_Result = 1) THEN 0
            ELSE @Run_Attempts
       END
    ,Error_Code = @Error_Code
    ,Error_String = @Error_String
    ,Computer_Name = Null       --<Release Engine
    ,Process_Id = Null          -- grip>
    Where Schedule_Id = @Schedule_Id
If @@ERROR <> 0 
  Begin 
    ROLLBACK TRANSACTION 
    RETURN(1)
  End
Delete from Report_Que Where Schedule_Id = @Schedule_Id
If @@ERROR <> 0 
  Begin 
    ROLLBACK TRANSACTION 
    RETURN(1)
  End
----------------------------------
-- UPDATE THE SPY TABLE
----------------------------------
If Not(@Run_Id Is Null)
  Begin
    Update Report_Runs
      Set File_Name = @File_Name
      ,End_Time = @Now
      ,Error_Id = @Error_Id
      ,Status = 4
      ,Last_Result = @Last_Result
      ,User_Id = @User_Id
      Where Run_Id = @Run_Id
    If @@ERROR <> 0 
      Begin 
        ROLLBACK TRANSACTION 
        RETURN(1)
      End
  End
------------------------------------------
-- RECALCULATE SPY TABLE RUN TIME VALUES
------------------------------------------
If @Report_Id Is Not Null
  Begin
    Select @RunTime = DateDiff(Second, Start_Time, End_Time)
    From Report_Runs
    Where Run_Id = @Run_Id
 	 Update Report_Definition_Parameters 
      Set Value = @RunTime
      Where RDP_Id = @RDP_Id_MinRunTime and CAST(Value AS int) > @RunTime
 	 Update Report_Definition_Parameters 
      Set Value = @RunTime
      Where RDP_Id = @RDP_Id_MaxRunTime and CAST(Value AS int) < @RunTime
 	 Update Report_Definition_Parameters 
      Set Value = CAST(Value AS int) + 1
      Where RDP_Id = @RDP_Id_TotalRuns 
 	 Update Report_Definition_Parameters 
      Set Value = CAST(Value AS int) + @RunTime
      Where RDP_Id = @RDP_Id_TotalTime 
    If @@ERROR <> 0 
      Begin 
        ROLLBACK TRANSACTION 
        RETURN(1)
      End
  End
COMMIT TRANSACTION
RETURN(0)
*/
