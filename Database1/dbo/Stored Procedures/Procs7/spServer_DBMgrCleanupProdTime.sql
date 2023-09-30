Create Procedure dbo.spServer_DBMgrCleanupProdTime
@OldTime DateTime,
@NewTime Datetime,
@ReturnResultSet int, 	 -- 0 = Don't Return Result sets, caller will do it, 1 = Return Result Sets, 2 = Defer Result Sets to Pending Result Sets Table
@MasterPUId int,
@UserId int = 14
AS
Declare  @SheetId int
Declare @Id Int,@DebugFlag Int
Select @DebugFlag = 0
If @DebugFlag = 1 
  Begin 
    Insert into Message_Log_Header (Timestamp) Select dbo.fnServer_CmnGetDate(getUTCdate()) Select @ID = Scope_Identity() 
    Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'START')
    Insert into Message_Log_Detail (Message_Log_Id, Message)
      Values(@ID, 'in spServer_DBMgrCleanupProdTime /OldTime: ' + Isnull(convert(nVarChar(25),@OldTime,120),'Null') + 
 	 ' /@NewTime: ' + Isnull(convert(nVarChar(25),@NewTime,120),'Null') + 
 	 ' /ReturnResultSet: ' + Coalesce(convert(nvarchar(10),@ReturnResultSet),'Null') + 
 	 ' /MasterPUId: ' + Coalesce(convert(nvarchar(10),@MasterPUId),'Null')
 	 ) 
  End
If (@MasterPUId Is NULL)
  Return
Select @OldTime = DateAdd(Second,-1,@OldTime)
Select @NewTime = DateAdd(Second,-1,@NewTime)
IF @OldTime = @NewTime
 	 RETURN
If (@NewTime Is NULL)
 Begin
  Execute spServer_DBMgrDeleteEventData @MasterPUId,@OldTime,5,@ReturnResultSet,null,null,@UserId
  Execute spServer_DBMgrDeleteEventData @MasterPUId,@OldTime,4,@ReturnResultSet,null,null,@UserId --product change sheet
 End
Else 
  Begin
    Execute spServer_DBMgrMoveEventData @MasterPUId,@OldTime,@NewTime,5,@ReturnResultSet ,null,null,null,@UserId
    Execute spServer_DBMgrMoveEventData @MasterPUId,@OldTime,@NewTime,4,@ReturnResultSet,null,null,null,@UserId
  End
Declare Sheet_Cursor INSENSITIVE CURSOR
  For (Select Sheet_Id From Sheets Where (Event_Type = 0) And (Master_Unit = @MasterPUId) And (Sheet_Type = 16) or  (Sheet_Type = 23))
  Open Sheet_Cursor  
Fetch_Loop:
  Fetch Next From Sheet_Cursor Into @SheetId
  If (@@Fetch_Status = 0)
  Begin
 	 Declare @pu_Id Int,@Activity_Type_Id Int 
 	 Select @pu_Id = Master_Unit ,@Activity_Type_Id = CASE WHEN Sheet_Type =23 Then 4 ELSE 0 END  from sheets where sheet_Id = @SheetId
    Delete From Sheet_Columns Where (Sheet_Id = @SheetId) And (Result_On = @OldTime)
 	  IF @Activity_Type_Id = 4
 	  Begin
 	    	    	  EXECUTE spServer_DBMgrUpdActivities  Null,Null,Null,Null,Null,
  	    	    	    	    	    	    	    	    	    	    	  @SheetId,null,Null,@Activity_Type_Id,@SheetId,
  	    	    	    	    	    	    	    	    	    	    	  /*@Result_On = @OldTime*/ @OldTime,  	  Null,Null,Null,Null,
  	    	    	    	    	    	    	    	    	    	    	  3,0,@UserId, @pu_Id,Null,
  	    	    	    	    	    	    	    	    	    	    	  Null,Null,Null,Null,Null,
  	    	    	    	    	    	    	    	    	    	    	  Null,Null,Null,2 /*@ReturnResultSet*/
 	 End
    if (@ReturnResultSet = 1) -- Send out the Result Set
    Begin
      If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Sheet Resultset' )
      Select 7,@SheetId,14,3,@OldTime,1
    End
    Else if (@ReturnResultSet = 2) -- Put the Result Set into the Pending Result Sets table for DBMgr to pickup later
    Begin
      INSERT INTO Pending_ResultSets(Processed,RS_Value,User_Id,Entry_On)
      SELECT 0, (
 	  	 Select RSTId = 7, SheetId = @SheetId, UserId = 14, TransType = 3, TimeStampCol = @OldTime, PostDB = 1
        for xml path ('row'), ROOT('rows'), ELEMENTS XSINIL), @UserId, dbo.fnServer_CmnGetDate(GetUtcDate())
    End
    Goto Fetch_Loop
  End
Close Sheet_Cursor
Deallocate Sheet_Cursor
If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END spServer_DBMgrCleanupProdTime' )
