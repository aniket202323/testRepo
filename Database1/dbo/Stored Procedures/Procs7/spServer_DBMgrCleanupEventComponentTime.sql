Create Procedure dbo.spServer_DBMgrCleanupEventComponentTime
@ComponentId int,
@NewTime Datetime,
@ReturnResultSet int,   	 -- 0 = Don't Return Result sets, caller will do it, 1 = Return Result Sets, 2 = Defer Result Sets to Pending Result Sets Table
@UserId int = 14
AS
Declare @DebugFlag tinyint,
       	 @ID int
/*
Insert Into User_Parameters (Parm_Id, User_Id, Value, HostName) Values(100, 6, 1, '')
update User_Parameters set value = 0 where Parm_Id = 100 and User_Id = 6
*/
Select @DebugFlag = CONVERT(tinyint, COALESCE(Value, '0')) From User_Parameters Where User_Id = 6 and Parm_Id = 100
If @DebugFlag = 1 
  Begin 
    Insert into Message_Log_Header (Timestamp) Select dbo.fnServer_CmnGetDate(getUTCdate()) Select @ID = Scope_Identity() 
    Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'START')
    Insert into Message_Log_Detail (Message_Log_Id, Message)
      Values(@ID, 'in DBMgrCleanupEventComponentTime /ComponentId: ' + Coalesce(convert(nVarChar(4),@ComponentId),'Null') + ' /NewTime: ' + Coalesce(convert(nVarChar(25),@NewTime),'Null') + 
 	 ' /ReturnResultSet: ' + Coalesce(convert(nVarChar(4),@ReturnResultSet),'Null'))
  End
Declare
  @MasterPUId int,
  @TimeStamp datetime,
  @StartTime datetime,
  @SheetId int,
  @PEI_Id Int
Select @MasterPUId = NULL
Exec spServer_CmnGetInputGenealogyInfo @ComponentId, @MasterPUId OUTPUT, @StartTime OUTPUT, @TimeStamp OUTPUT, @PEI_Id OUTPUT
If (@MasterPUId Is NULL)
 	 Begin
 	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '(@MasterPUId Is NULL)')
 	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
 	   Return
 	 End
If (@NewTime Is NULL)
 	 Begin
 	   Execute spServer_DBMgrDeleteEventData @MasterPUId,@TimeStamp, 17,@ReturnResultSet,@PEI_Id, null, @UserId
 	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'spServer_DBMgrDeleteEventData')
 	 End
Else 
  Begin
    Execute spServer_DBMgrMoveEventData @MasterPUId,@TimeStamp,@NewTime,17,@ReturnResultSet,@PEI_Id, null, 0, @UserId
 	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'spServer_DBMgrMoveEventData')
  End
Declare EC_Sheet_Cursor INSENSITIVE CURSOR
  For (Select Sheet_Id From Sheets Where (Event_Type = 0) And (Sheet_Type = 19) And (PEI_Id = @PEI_Id) And (Master_Unit = @MasterPUId))
  Open EC_Sheet_Cursor  
Fetch_Loop:
  Fetch Next From EC_Sheet_Cursor Into @SheetId
  If (@@Fetch_Status = 0)
    Begin
      Delete From Sheet_Columns Where (Sheet_Id = @SheetId) And (Result_On = @TimeStamp)
 	   if (@ReturnResultSet = 1) -- Send out the Result Set
 	   Begin
 	  	 Select 7,@SheetId,0,3,Convert(nVarChar(30),@TimeStamp,120),1
 	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'ReturnResultSet')
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
Close EC_Sheet_Cursor
Deallocate EC_Sheet_Cursor
If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
