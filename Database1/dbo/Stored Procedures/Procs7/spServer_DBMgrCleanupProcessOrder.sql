Create Procedure dbo.spServer_DBMgrCleanupProcessOrder
@PPSId int,
@NewTime Datetime,
@ReturnResultSet int 	 -- 0 = Don't Return Result sets, caller will do it, 1 = Return Result Sets, 2 = Defer Result Sets to Pending Result Sets Table
AS
Declare
  @MasterPUId int,
  @TimeStamp datetime,
  @SheetId int,
  @UserId int = 14
Select @MasterPUId = NULL
Select @MasterPUId = PU_Id, @TimeStamp = End_Time
From Production_Plan_Starts 
  Where PP_Start_Id = @PPSId
If (@MasterPUId Is NULL)
  Return
If (@NewTime Is NULL)
 Begin
   Execute spServer_DBMgrDeleteEventData @MasterPUId,@TimeStamp, 19,@ReturnResultSet
   Execute spServer_DBMgrDeleteEventData @MasterPUId,@TimeStamp, 28,@ReturnResultSet
 End
Else 
  Begin
    Execute spServer_DBMgrMoveEventData @MasterPUId,@TimeStamp,@NewTime,19,@ReturnResultSet
    Execute spServer_DBMgrMoveEventData @MasterPUId,@TimeStamp,@NewTime,28,@ReturnResultSet
  End
Declare ProcessOrder_Sheet_Cursor INSENSITIVE CURSOR
  For (Select Sheet_Id From Sheets Where (Event_Type = 0) And (Master_Unit = @MasterPUId) And ((Sheet_Type = 21) or (Sheet_Type = 22)))
  Open ProcessOrder_Sheet_Cursor  
Fetch_Loop:
  Fetch Next From ProcessOrder_Sheet_Cursor Into @SheetId
  If (@@Fetch_Status = 0)
    Begin
      Delete From Sheet_Columns Where (Sheet_Id = @SheetId) And (Result_On = @TimeStamp)
 	   Declare @pu_Id Int,@Activity_Type_Id Int 
 	 Select @pu_Id = Master_Unit ,@Activity_Type_Id = CASE WHEN Sheet_Type =21 Then 5 ELSE 0 END  from sheets where sheet_Id = @SheetId
 	    IF @Activity_Type_Id = 5
 	  Begin
 	    	    	  EXECUTE spServer_DBMgrUpdActivities  Null,Null,Null,Null,Null,
  	    	    	    	    	    	    	    	    	    	    	  @SheetId,null,Null,@Activity_Type_Id,@SheetId,
  	    	    	    	    	    	    	    	    	    	    	  /*@Result_On = @OldTime*/ @TimeStamp,  	  Null,Null,Null,Null,
  	    	    	    	    	    	    	    	    	    	    	  3,0,@UserId, @pu_Id,Null,
  	    	    	    	    	    	    	    	    	    	    	  Null,Null,Null,Null,Null,
  	    	    	    	    	    	    	    	    	    	    	  Null,Null,Null,2 /*@ReturnResultSet*/
 	 End
 	   
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
Close ProcessOrder_Sheet_Cursor
Deallocate ProcessOrder_Sheet_Cursor
