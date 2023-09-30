CREATE PROCEDURE dbo.[spServer_DBMgrDeleteEvent_Bak_177]
@EventId int,
@ReturnResultSet int = 0, 
@UserId int = 14 
 AS
-- Need to Finish Triggers for Comments
Declare
  @Pass int,
  @Num int,
  @DelEventId int,
  @NextEventId int,
  @ThePUId int,
  @TheTimeStamp datetime,
  @NextTimeStamp datetime,
  @PrevTimestamp datetime,
  @NextStartTime datetime,
  @PUId int,
  @TimeStamp datetime,
  @OrderingId int,
  @ErrMsg nVarChar(255),
  @UsesStartTime tinyint,
  @SelectStmt nVarChar(255),
  @DoChildDelete  Int
DECLARE @originalContextInfo VARBINARY(128)
DECLARE @ContextInfo varbinary(128)
Select @ErrMsg = 'DeleteEvent: SPID - [' + Convert(nvarchar(10),@@SPID) + ']  EventId - [' + Convert(nVarChar(5),@EventId) + '] Start'
-- Execute spServer_CmnSendEmail 1,@ErrMsg,''
Select @ThePUId = NULL
Select @ThePUId = PU_Id, @TheTimeStamp = TimeStamp From Events Where Event_Id = @EventId
If (@ThePUId Is NULL)
  Return
Select @DoChildDelete = Delete_Child_Events From Prod_Units_Base where PU_Id = @ThePUId
Create Table #SvrEventUpdates (RSetType int, OrderingId int, TransType int, EventId int, EventNum nVarChar(50), PUId int, TimeStamp datetime, AppProdId int, SourceEvent int, EventStatus int, Confirmed int, UserId int, Post int, Conformance tinyint, TestPrctComplete tinyint, StartTime datetime, TransNum int, TestingStatus int, CommentId int, EventSubTypeId int, EntryOn datetime, ApproverUserId int, SecondUserId int, ApprovedReasonId int, UserReasonId int, UserSignoffId int)
Create Table #SvrEventIds (EventId int, PUId int, UsesStartTime tinyint, TimeStamp datetime, Pass int)
/* Added By Dave H to remove Input Events */
Create Table #InputEventUpdates (
  Pre  	  	  	 Int Null,
  User_Id  	  	 int Null, 
  Transaction_Type  	 int,
  Trans_Num 	  	 Int,
  TimeStamp 	  	 DateTime,
  Entry_On 	  	 DateTime,
  Comment_Id 	  	 Int Null,
  PEI_Id 	  	  	 Int,
  PEIP_Id 	  	 Int,
  Event_Id  	  	 int NULL, 
  Dim_X  	  	 nVarChar(25) Null, 
  Dim_Y  	  	 nVarChar(25) Null, 
  Dim_Z  	  	 nVarChar(25) Null,
  Dim_A  	  	 nVarChar(25) Null,
  Unloaded 	  	 int)
/* End of add */
Select @Pass = 1
Select @OrderingId = 1
-- Only adjust starttime for parent event. 
Insert Into #SvrEventIds (EventId,PUId,UsesStartTime,TimeStamp,Pass) 
  Select @EventId,@ThePUId,COALESCE(Uses_Start_Time, 0),@TheTimeStamp,@Pass From Prod_Units_Base Where PU_Id = @ThePUId
GetChildren:
Update Events Set Source_Event = NULL Where Event_Id In (Select EventId From #SvrEventIds Where Pass = @Pass)
Select @Pass = @Pass + 1
If @DoChildDelete = 1 
  Begin
 	 Insert Into #SvrEventIds(EventId,PUId,UsesStartTime,TimeStamp,Pass)
 	   Select ec.Event_Id,e.PU_Id,0,e.TimeStamp,@Pass 
 	  	 From Event_Components ec
        Join Events e on e.event_Id = ec.event_Id
 	     Where ec.Source_Event_Id In (Select EventId From #SvrEventIds Where Pass = (@Pass - 1))
 	 Delete From #SvrEventIds
 	   Where Pass = @Pass and EventId in (Select EventId From #SvrEventIds Where Pass < @Pass )
 	 Select @Num = NULL
 	 Select @Num = Count(EventId) From #SvrEventIds Where Pass = @Pass
 	 If (@Num Is NULL) Or (@Num = 0)
 	  	 Goto DoneWithChildren
 	 Goto GetChildren
  End
DoneWithChildren:
Select @Pass = @Pass - 1
RemoveEvents:
Select @SelectStmt = 'Declare EventDel_Cursor CURSOR Global STATIC For (Select EventId,PUId,UsesStartTime,TimeStamp From #SvrEventIds Where Pass = ' + Convert(nvarchar(10),@Pass) + ') For Read Only'
  Execute(@SelectStmt)
    Open EventDel_Cursor  
  Fetch_Loop:
    Fetch Next From EventDel_Cursor Into @DelEventId,@PUId,@UsesStartTime,@TimeStamp
    If (@@Fetch_Status = 0)
      Begin
 	 EXECUTE spServer_DBMgrDeleteEventData @PUId,@TimeStamp,1,@ReturnResultSet,null,null,@UserId
/* Added By Dave H to remove Input Events */
    Insert Into #InputEventUpdates(Pre,User_Id,Transaction_Type,Trans_Num, TimeStamp, Entry_On, 
 	  	  	  	   Comment_Id, PEI_Id, PEIP_Id,Event_Id, Dim_X, Dim_Y,  Dim_Z, Dim_A, Unloaded)
 	  	 Select 0,@UserId,3,0,dbo.fnServer_CmnGetDate(getUTCdate()),dbo.fnServer_CmnGetDate(getUTCdate()),Event_Id,PEI_Id,PEIP_Id,Null,Null,null,Null,Null,1
 	     	  	 From PrdExec_Input_Event Where Event_Id = @DelEventId
 	 UPdate PrdExec_Input_Event Set Event_Id = Null,Timestamp = dbo.fnServer_CmnGetDate(getUTCdate()),Entry_On = dbo.fnServer_CmnGetDate(getUTCdate()),User_Id = @UserId,
 	  	  	 Comment_Id = Null,Dimension_X = Null,Dimension_Y = Null,Dimension_Z = Null,Dimension_A = Null,Unloaded = 1
 	   where Event_Id = @DelEventId
/* End of add */
 	 SET @originalContextInfo = Context_Info()
 	 SET @ContextInfo = CAST(@UserId AS varbinary(128))
 	 SET Context_Info @ContextInfo
 	 DELETE FROM Waste_Event_Details WHERE Event_Id = @DelEventId
 	 IF @originalContextInfo Is NULL SET Context_Info 0x ELSE SET Context_Info @originalContextInfo
 	 Execute spServer_CmnRemoveScheduledTask @DelEventId,1
 	 SET Context_Info @ContextInfo
 	 DELETE FROM Event_Components Where Event_Id = @DelEventId
 	 DELETE FROM Event_Components Where Source_Event_Id = @DelEventId
 	 DELETE FROM Event_Details Where Event_Id = @DelEventId
 	 DELETE FROM Event_PU_Transitions Where Event_Id = @DelEventId
 	 IF @originalContextInfo Is NULL SET Context_Info 0x ELSE SET Context_Info @originalContextInfo
 	 UPDATE User_Defined_Events SET Event_Id = Null  WHERE Event_Id = @DelEventId
        If @UsesStartTime > 0 
          Begin
            -- If this timestamp = next events start time, adjust next events start time 
            Select @NextTimestamp = MIN(Timestamp) FROM Events WHERE PU_Id = @PUId AND TimeStamp > @TimeStamp
            Select @NextStartTime = Start_Time, @NextEventId = Event_Id FROM Events WHERE PU_Id = @PUId AND TimeStamp = @NextTimeStamp
            If @TimeStamp = @NextStartTime 
              Begin
                Select @PrevTimestamp = COALESCE(MAX(TimeStamp), DATEADD(minute, -1, @TimeStamp)) FROM Events WHERE PU_Id = @PUId AND TimeStamp < @TimeStamp
                UPDATE Events Set Start_Time = @PrevTimestamp, Entry_On = dbo.fnServer_CmnGetDate(getUTCdate()), User_Id = @UserId Where Event_Id = @NextEventId
                If (@ReturnResultSet in (1,2))
                  Begin
                    Insert Into #SvrEventUpdates (RSetType,OrderingId,TransType,EventId,EventNum,PUId,TimeStamp,AppProdId,SourceEvent,EventStatus,Confirmed,UserId,Post,Conformance,TestPrctComplete,StartTime,TransNum,TestingStatus,CommentId,EventSubTypeId,EntryOn,ApproverUserId,SecondUserId,ApprovedReasonId,UserReasonId,UserSignoffId)
                      SELECT 1,@OrderingId,2,Event_Id, Event_Num, PU_Id, Timestamp, Applied_Product, Source_Event, Event_Status,Confirmed, User_Id, 1, Conformance,Testing_Prct_Complete,Start_Time, 0, Testing_Status,Comment_Id,Event_Subtype_Id, Entry_On, Approver_User_Id, Second_User_Id, Approver_Reason_Id, User_Reason_Id, User_Signoff_Id
                         FROM Events
                         WHERE Event_Id = @NextEventId
                  End
                Select @OrderingId = @OrderingId + 1
              End
          End
 	 SET Context_Info @ContextInfo
 	 DELETE FROM Events WHERE Event_Id = @DelEventId
 	 IF @originalContextInfo Is NULL SET Context_Info 0x ELSE SET Context_Info @originalContextInfo
        If (@ReturnResultSet in (1,2))
          Begin
            Insert Into #SvrEventUpdates (RSetType,OrderingId,TransType,EventId,EventNum,PUId,TimeStamp,AppProdId,SourceEvent,EventStatus,Confirmed,UserId,Post,Conformance,TestPrctComplete,StartTime,TransNum,TestingStatus,CommentId,EventSubTypeId,EntryOn,ApproverUserId,SecondUserId,ApprovedReasonId,UserReasonId,UserSignoffId)
              Values(1,@OrderingId,3,@DelEventId,'',@PUId,@TimeStamp,0,0,0,0,0,1,0,0,NULL,0,0,0,0,dbo.fnServer_CmnGetDate(getUTCdate()),null,null,null,null,null)
          End
        Select @OrderingId = @OrderingId + 1
        Goto Fetch_Loop
      End
  Close EventDel_Cursor
  Deallocate EventDel_Cursor
Select @Pass = @Pass - 1
If (@Pass > 0)
  Goto RemoveEvents
Drop Table #SvrEventIds
if (@ReturnResultSet = 1) -- Send out the Result Set
Begin
 	 Select RSetType,OrderingId,TransType,EventId,EventNum,PUId,TimeStamp,AppProdId,SourceEvent,EventStatus,Confirmed,UserId,Post,Conformance,TestPrctComplete,StartTime,TransNum,TestingStatus,CommentId,EventSubTypeId,EntryOn,ApproverUserId,SecondUserId,ApprovedReasonId,UserReasonId,UserSignoffId From #SvrEventUpdates Order By OrderingId
 	 If (Select Count(*) From #InputEventUpdates) > 0
 	  	 Select 12,* From #InputEventUpdates
End
Else if (@ReturnResultSet = 2) -- Put the Result Set into the Pending Result Sets table for DBMgr to pickup later
Begin
 	 INSERT INTO Pending_ResultSets(Processed,RS_Value,User_Id,Entry_On)
 	 SELECT 0, (
 	  	 Select RSetType,OrderingId,TransType,EventId,EventNum,PUId,TimeStamp,AppProdId,SourceEvent,EventStatus,Confirmed,UserId,Post,Conformance,TestPrctComplete,StartTime,TransNum,TestingStatus,CommentId,EventSubTypeId,EntryOn,ApproverUserId,SecondUserId,ApprovedReasonId,UserReasonId,UserSignoffId From #SvrEventUpdates Order By OrderingId
 	  	 for xml path ('row'), ROOT('rows'), ELEMENTS XSINIL), @UserId, dbo.fnServer_CmnGetDate(GetUtcDate())
 	 If (Select Count(*) From #InputEventUpdates) > 0
 	 Begin
 	  	 INSERT INTO Pending_ResultSets(Processed,RS_Value,User_Id,Entry_On)
 	  	 SELECT 0, (
 	  	  	 Select RSetType=12,* From #InputEventUpdates
 	  	  	 for xml path ('row'), ROOT('rows'), ELEMENTS XSINIL), @UserId, dbo.fnServer_CmnGetDate(GetUtcDate())
 	 End
End
Drop Table #SvrEventUpdates
Drop Table #InputEventUpdates
Select @ErrMsg = 'DeleteEvent: SPID - [' + Convert(nvarchar(10),@@SPID) + ']  EventId - [' + Convert(nVarChar(5),@EventId) + '] Success'
-- Execute spServer_CmnSendEmail 1,@ErrMsg,''
