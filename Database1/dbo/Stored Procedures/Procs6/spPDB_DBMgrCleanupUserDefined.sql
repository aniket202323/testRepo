Create Procedure dbo.spPDB_DBMgrCleanupUserDefined
@UDEId int,
@NewTime Datetime,
@ReturnResultSet int,
@EventSubTypeId 	  Int,
@DurationReq 	 Int
AS
Declare
  @MasterPUId int,
  @TimeStamp datetime,
  @SheetId int
Select @MasterPUId = NULL
IF @DurationReq = 1
 	 Select @MasterPUId = PU_Id, @TimeStamp = End_Time
 	 From user_Defined_events 
   	 Where UDE_Id = @UDEId
Else
 	 Select @MasterPUId = PU_Id, @TimeStamp = Start_Time
 	 From user_Defined_events 
   	 Where UDE_Id = @UDEId
If (@MasterPUId Is NULL)
  Return
If (@NewTime Is NULL)
  Execute spPDB_DBMgrDeleteEventData @MasterPUId,@TimeStamp, 14,@ReturnResultSet,Null,@EventSubTypeId
Else 
  Begin
    Execute spPDB_DBMgrMoveEventData @MasterPUId,@TimeStamp,@NewTime,14,@ReturnResultSet,Null,@EventSubTypeId
  End
Declare UDE_Sheet_Cursor INSENSITIVE CURSOR
  For (Select Sheet_Id From Sheets Where (Event_Type = 0) And (Sheet_Type = 25) And (Master_Unit = @MasterPUId) and Event_Subtype_Id = @EventSubTypeId)
  Open UDE_Sheet_Cursor  
Fetch_Loop:
  Fetch Next From UDE_Sheet_Cursor Into @SheetId
  If (@@Fetch_Status = 0)
    Begin
      Delete From Sheet_Columns Where (Sheet_Id = @SheetId) And (Result_On = @TimeStamp)
 	   If (@ReturnResultSet = 1)
        Select 7,@SheetId,0,3,Convert(nvarchar(30),@TimeStamp,120),1
      Goto Fetch_Loop
    End
Close UDE_Sheet_Cursor
Deallocate UDE_Sheet_Cursor
