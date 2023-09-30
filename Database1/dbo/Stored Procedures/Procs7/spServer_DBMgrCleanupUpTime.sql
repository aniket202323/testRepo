Create Procedure dbo.spServer_DBMgrCleanupUpTime
@DowntimeId int,
@NewTime Datetime,
@ReturnResultSet int, 	 -- 0 = Don't Return Result sets, caller will do it, 1 = Return Result Sets, 2 = Defer Result Sets to Pending Result Sets Table
@UserId int = 14
AS
Declare
  @MasterPUId int,
  @TimeStamp datetime,
  @SheetId int
Select @MasterPUId = NULL
Select @MasterPUId = PU_Id, @TimeStamp = Start_Time
From Timed_Event_Details 
  Where TEDet_Id = @DowntimeId
If (@MasterPUId Is NULL)
  Return
If (@NewTime Is NULL)
  Execute spServer_DBMgrDeleteEventData @MasterPUId,@TimeStamp, 22,@ReturnResultSet, null, null, @UserId
Else 
  Begin
    Execute spServer_DBMgrMoveEventData @MasterPUId,@TimeStamp,@NewTime,22,@ReturnResultSet, null, null, 0, @UserId
  End
Declare Downtime_Sheet_Cursor INSENSITIVE CURSOR
  For (Select Sheet_Id From Sheets Where (Event_Type = 0) And (Sheet_Type = 24) And (Master_Unit = @MasterPUId))
  Open Downtime_Sheet_Cursor  
Fetch_Loop:
  Fetch Next From Downtime_Sheet_Cursor Into @SheetId
  If (@@Fetch_Status = 0)
    Begin
      Delete From Sheet_Columns Where (Sheet_Id = @SheetId) And (Result_On = @TimeStamp)
 	   if (@ReturnResultSet = 1) -- Send out the Result Set
 	   Begin
 	  	 Select 7,@SheetId,0,3,Convert(nVarChar(30),@TimeStamp,120),1
 	   End
 	   Else if (@ReturnResultSet = 2) -- Put the Result Set into the Pending Result Sets table for DBMgr to pickup later
 	   Begin
 	  	 INSERT INTO Pending_ResultSets(Processed,RS_Value,User_Id,Entry_On)
 	  	 SELECT 0, (
 	  	  	 Select RSTId = 7, SheetId = @SheetId, UserId = 0, TransType = 3, TimeStampCol = Convert(nVarChar(30),@TimeStamp,120), PostDB = 1
 	  	  	 for xml path ('row'), ROOT('rows'), ELEMENTS XSINIL), @UserId, dbo.fnServer_CmnGetDate(GetUtcDate())
 	   End
      Goto Fetch_Loop
    End
Close Downtime_Sheet_Cursor
Deallocate Downtime_Sheet_Cursor
