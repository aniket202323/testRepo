CREATE PROCEDURE dbo.spServer_PurgeDatabase
@StartTime datetime,
@EndTime datetime
AS
--*****************************************************
-- TODO:
--
-- Delete from the following tables
-- 	 Events
-- 	 Event_History
-- 	 Event_Details
-- 	 Event_Components
-- 	 Timed_Event_Details
-- 	 Waste_Event_Details
--
--*****************************************************
Set Nocount On
Declare
  @Status int,
  @@VarId int,
  @Cmd nVarChar(1000),
  @NumTestsDeleted int,
  @NumTestHistoryDeleted int,
  @NumCommentsDeleted int,
  @NumArraysDeleted int,
  @TotalTestsDeleted int,
  @TotalTestHistoryDeleted int,
  @TotalArraysDeleted int ,
  @TotalCommentsDeleted int ,
  @ClockStart datetime,
  @ClockEnd datetime,
  @Duration nVarChar(20),
  @NumProficyProcesses int
Select @NumProficyProcesses = NULL
Select @NumProficyProcesses = Count(Program_Name) From master..sysprocesses where (Program_Name like '%Proficy%')
If (@NumProficyProcesses Is NULL)
  Select @NumProficyProcesses = 0
If (@NumProficyProcesses > 0)
  Begin
    Print 'Error: Proficy is still running'
    return
  End
If (IsDate(@StartTime) <> 1) Or (IsDate(@EndTime) <> 1) Or (@StartTime >= @EndTime)
  Begin
    Print 'Error: Invalid Parameters'
    return
  End
Select @ClockStart = dbo.fnServer_CmnGetDate(GetUTCDate())
Select @TotalArraysDeleted = 0
Select @TotalCommentsDeleted = 0
Select @TotalTestsDeleted = 0
Select @TotalTestHistoryDeleted = 0
Execute SpServer_PurgeForeignKeys
Execute @Status = SpServer_PurgeToggleTriggers 'EverythingIsShutdown-ForSure!!!',0
If (@Status <> 1)
  Begin
    Print 'Error: Disabling Triggers'
    return
  End
Declare VarIds_Cursor INSENSITIVE CURSOR 
  For (Select Var_Id From Variables_Base Where Var_Id > 0)
  For Read Only
  Open VarIds_Cursor  
VarIds_Loop:
  Fetch Next From VarIds_Cursor Into @@VarId
  If (@@Fetch_Status = 0)
    Begin
      Execute spServer_PurgeTestData @@VarId,@StartTime,@EndTime,@NumTestsDeleted OUTPUT, @NumTestHistoryDeleted OUTPUT, @NumCommentsDeleted OUTPUT, @NumArraysDeleted OUTPUT
      Select @TotalCommentsDeleted = @TotalCommentsDeleted + @NumCommentsDeleted
      Select @TotalArraysDeleted = @TotalArraysDeleted + @NumArraysDeleted
      Select @TotalTestsDeleted = @TotalTestsDeleted + @NumTestsDeleted
      Select @TotalTestHistoryDeleted = @TotalTestHistoryDeleted + @NumTestHistoryDeleted
      If (@NumTestsDeleted > 0)
        Begin
          Select @Cmd = 'Dump Transaction ' + db_name() + ' With No_Log'
          Execute(@Cmd)
        End
      Goto VarIds_Loop
    End
Close VarIds_Cursor 
Deallocate VarIds_Cursor
Execute SpServer_PurgeToggleTriggers 'EverythingIsShutdown-ForSure!!!',1
Execute @NumCommentsDeleted = SpServer_PurgeComments
Select @TotalCommentsDeleted = @TotalCommentsDeleted + @NumCommentsDeleted
Select @Cmd = 'Dump Transaction ' + db_name() + ' With No_Log'
Execute(@Cmd)
Execute @NumArraysDeleted = SpServer_PurgeArrayData
Select @TotalArraysDeleted = @TotalArraysDeleted + @NumArraysDeleted
Select @Cmd = 'Dump Transaction ' + db_name() + ' With No_Log'
Execute(@Cmd)
Select @ClockEnd = dbo.fnServer_CmnGetDate(GetUTCDate())
If DateDiff(Minute,@ClockStart,@ClockEnd) < 1
  Select @Duration = '[' + Convert(nVarChar(100),DateDiff(Second,@ClockStart,@ClockEnd)) + '] Seconds'
Else
  Select @Duration = '[' + Convert(nVarChar(100),DateDiff(Minute,@ClockStart,@ClockEnd)) + '] Minutes'
Select Duration 	  	 = @Duration,
       Tests  	  	 = @TotalTestsDeleted,
       TestHistory  	 = @TotalTestHistoryDeleted,
       Arrays  	  	 = @TotalArraysDeleted,
       Comments  	 = @TotalCommentsDeleted
