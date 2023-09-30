Create Procedure dbo.spServer_DBMgrCleanupUserDefined
@UDEId int,
@NewTime Datetime,
@ReturnResultSet int, 	 -- 0 = Don't Return Result sets, caller will do it, 1 = Return Result Sets, 2 = Defer Result Sets to Pending Result Sets Table
@EventSubTypeId 	  Int,
@OldTime 	 Datetime,
@MasterPUId Int,
@UserId int = 14
AS
Declare @Id Int,@DebugFlag Int
Select @DebugFlag = CONVERT(tinyint, COALESCE(Value, '0')) From User_Parameters Where User_Id = 6 and Parm_Id = 100
If @DebugFlag = 1 
  Begin 
    Insert into Message_Log_Header (Timestamp) Select dbo.fnServer_CmnGetDate(getUTCdate()) Select @ID = Scope_Identity() 
    Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'START')
    Insert into Message_Log_Detail (Message_Log_Id, Message)
      Values(@ID, 'in spServer_DBMgrCleanupUserDefined /UDEId: ' + Coalesce(convert(nvarchar(10),@UDEId),'Null') + ' /NewTime: ' + Coalesce(convert(nVarChar(25),@NewTime,120),'Null') + 
+ ' /OldTime: ' + Coalesce(convert(nVarChar(25),@OldTime,120),'Null') +
 	 ' /ReturnResultSet: ' + Coalesce(convert(nVarChar(4),@ReturnResultSet),'Null') + 	 ' /EventSubtypeId: ' + Coalesce(convert(nVarChar(4),@EventSubtypeId),'Null') + 
 	 ' /MasterPUId: ' + Coalesce(convert(nVarChar(4),@MasterPUId),'Null'))
  End
Declare
  @SheetId int
If (@MasterPUId Is NULL)
  Return
If (@NewTime Is NULL)
  Execute spServer_DBMgrDeleteEventData @MasterPUId,@OldTime, 14,@ReturnResultSet,Null,@EventSubTypeId,@UserId
Else 
  Begin
    Execute spServer_DBMgrMoveEventData @MasterPUId,@OldTime,@NewTime,14,@ReturnResultSet,Null,@EventSubTypeId,0,@UserId
  End
Declare UDE_Sheet_Cursor INSENSITIVE CURSOR
  For (Select Sheet_Id From Sheets Where (Event_Type = 0) And (Sheet_Type = 25) And (Master_Unit = @MasterPUId) and Event_Subtype_Id = @EventSubTypeId)
  Open UDE_Sheet_Cursor  
Fetch_Loop:
  Fetch Next From UDE_Sheet_Cursor Into @SheetId
  If (@@Fetch_Status = 0)
    Begin
      Delete From Sheet_Columns Where (Sheet_Id = @SheetId) And (Result_On = @OldTime)
 	   if (@ReturnResultSet = 1) -- Send out the Result Set
 	   Begin
 	  	 Select 7,@SheetId,0,3,@OldTime,1
 	   End
 	   Else if (@ReturnResultSet = 2) -- Put the Result Set into the Pending Result Sets table for DBMgr to pickup later
 	   Begin
 	  	 INSERT INTO Pending_ResultSets(Processed,RS_Value,User_Id,Entry_On)
 	  	 SELECT 0, (
 	  	  	 Select RSTId = 7, SheetId = @SheetId, UserId = 0, TransType = 3, TimeStampCol = @OldTime, PostDB = 1
 	  	  	 for xml path ('row'), ROOT('rows'), ELEMENTS XSINIL), @UserId, dbo.fnServer_CmnGetDate(GetUtcDate())
 	   End
      Goto Fetch_Loop
    End
Close UDE_Sheet_Cursor
Deallocate UDE_Sheet_Cursor
If @DebugFlag = 1     Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END (spServer_DBMgrCleanupUserDefined')
