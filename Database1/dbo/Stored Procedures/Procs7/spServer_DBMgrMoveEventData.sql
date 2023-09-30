CREATE PROCEDURE dbo.spServer_DBMgrMoveEventData 
@UnitID int,
@OldResultOn datetime,
@NewResultOn datetime,
@EventType int = 1,
@ReturnResultSet int = 0, 	 -- 0 = Don't Return Result sets, caller will do it, 1 = Return Result Sets, 2 = Defer Result Sets to Pending Result Sets Table
@Pei_Id Int = Null,
@EventSubtypeId 	 Int = Null,
@ProcessResultsInCallingSP Int = 0,
@UserId Int = 14
 AS
Declare @DebugFlag tinyint,
       	 @ID int
DECLARE @originalContextInfo VARBINARY(128)
DECLARE @ContextInfo varbinary(128)
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
      Values(@ID, 'in DBMgrMoveEventData /UnitID: ' + Coalesce(convert(nvarchar(10),@UnitID),'Null') + ' /OldResultOn: ' + Coalesce(convert(nvarchar(25),@OldResultOn,120),'Null') + 
 	 ' /NewResultOn: ' + Coalesce(convert(nvarchar(25),@NewResultOn,120),'Null') + ' /EventType: ' + Coalesce(convert(nvarchar(10),@EventType),'Null') + 
 	 ' /ReturnResultSet: ' + Coalesce(convert(nvarchar(4),@ReturnResultSet),'Null') + ' /Pei_Id: ' + Coalesce(convert(nvarchar(10),@Pei_Id),'Null') + 
 	 ' /EventSubtypeId: ' + Coalesce(convert(nvarchar(10),@EventSubtypeId),'Null'))
  End
Declare
  @TestId BigInt,
  @VarId int,
  @EventId int,
  @ExistingTestId BigInt,
  @Result nVarChar(25),
  @SecondUserId int,
  @ArrayId int,
  @CommentId int,
  @SignatureId int,
  @EntryOn datetime,
  @Locked TinyInt
If (@OldResultOn = @NewResultOn)
 	 Begin
 	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '(@OldResultOn = @NewResultOn)')
 	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
 	   Return
 	 End
Declare @spServerVariableUpdates Table (RSetType int, VarId int, PUId int, UserId int, Canceled int, Result nvarchar(25), ResultOn datetime, TransType int,EventId Int,TranNum Int,
 	  	  	  	  	  	  	  	  	  	 SecondUserId int, ArrayId int, CommentId int, SignatureId int, EntryOn datetime, TestId bigint, Locked TinyInt)
Declare @Vars Table (Var_Id Int)
Declare @BaseVars Table (Var_Id Int)
Declare @TestData Table (Test_Id BigInt, Var_Id int, Result nvarchar(25) NULL,EventId int Null, SecondUserId int Null, ArrayId int Null, CommentId int Null, SignatureId int Null,
 	  	  	  	  	  	 EntryOn datetime not null, Locked TinyInt null) 
If @Pei_Id is null and @EventSubtypeId is null
 	 Insert Into @Vars (Var_Id)
 	   Select v.Var_Id 
 	  	 From Variables_base v
 	  	 JOIN Prod_Units_base p On p.PU_Id = v.PU_Id
  	  	 Where (v.PU_Id = p.PU_Id) And ((p.PU_Id = @UnitID) Or (p.Master_Unit = @UnitID)) And (v.Event_Type = @EventType)
Else If @EventSubtypeId is null
 	 Insert Into @Vars (Var_Id)
 	   Select v.Var_Id 
 	   From Variables_Base v
 	   JOIN Prod_Units_base p On p.PU_Id = v.PU_Id
 	   Where (v.PU_Id = p.PU_Id) And ((p.PU_Id = @UnitID) Or (p.Master_Unit = @UnitID)) And (v.Event_Type = @EventType) and (v.Pei_Id = @Pei_Id)
Else
 	 Insert Into @Vars (Var_Id)
 	   Select v.Var_Id 
 	   From Variables_Base v
 	  	 JOIN Prod_Units_base p On p.PU_Id = v.PU_Id
 	   Where (v.PU_Id = p.PU_Id) And ((p.PU_Id = @UnitID) Or (p.Master_Unit = @UnitID)) And (v.Event_Type = @EventType) and (v.Event_Subtype_Id = @EventSubtypeId)
/* No Resultsets for Base Variables  Event TimeStamp */
INSERT INTO @BaseVars(Var_Id)
 	 SELECT v.Var_Id 
 	 FROM @Vars v 
 	 JOIN  Variables_Base v1  ON v.Var_Id = v1.Var_Id and v1.Sampling_Type = 19
 	 
Insert Into @TestData (Test_Id, Var_Id, Result,EventId,SecondUserId,ArrayId,CommentId,SignatureId,EntryOn,Locked )
 	 Select t.Test_Id,v.Var_Id,t.Result,t.Event_Id,t.Second_User_Id,t.Array_Id,t.Comment_Id,t.Signature_Id,t.Entry_On,t.Locked 
 	   From Tests t
 	   Join @Vars v on v.Var_Id = t.Var_Id
 	   where t.Result_On = @OldResultOn
 	 
Declare TestData_Cursor CURSOR LOCAL STATIC READ_ONLY
  For Select Test_Id,Var_Id,Result,EventId,SecondUserId,ArrayId,CommentId,SignatureId,EntryOn,Locked  From @TestData
  Open TestData_Cursor  
Fetch_Loop:
  Fetch Next From TestData_Cursor Into @TestId,@VarId,@Result,@EventId,@SecondUserId,@ArrayId,@CommentId,@SignatureId,@EntryOn,@locked
  If (@@Fetch_Status = 0)
    Begin
      If (@ReturnResultSet in (1,2)) 
        Begin
          Insert Into @spServerVariableUpdates(RSetType,VarId,PUId,UserId,Canceled,Result,ResultOn,TransType,EventId,SecondUserId,ArrayId,CommentId,SignatureId,EntryOn,TestId,Locked)
            Values (2,@VarId,0,0,1,'',@OldResultOn,3,@EventId,@SecondUserId,@ArrayId,@CommentId,@SignatureId,@EntryOn,@TestId,@locked)
          Insert Into @spServerVariableUpdates(RSetType,VarId,PUId,UserId,Canceled,Result,ResultOn,TransType,EventId,SecondUserId,ArrayId,CommentId,SignatureId,EntryOn,TestId,Locked)
            Values (2,@VarId,0,0,0,@Result,@NewResultOn,1,@EventId,@SecondUserId,@ArrayId,@CommentId,@SignatureId,@EntryOn,@TestId,@locked)
 	  	  	  	 End
      Select @ExistingTestId = NULL
      Select @ExistingTestId = Test_Id From Tests Where (Var_Id = @VarId) And (Result_On = @NewResultOn)
      If (@ExistingTestId Is NULL)
        Begin
          Update Tests Set Result_On = @NewResultOn Where Test_Id = @TestId
 	  	  	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Update Tests')
        End
      Else
        Begin
 	   SET @originalContextInfo = Context_Info()
 	   SET @ContextInfo = CAST(@UserId AS varbinary(128))
 	   SET Context_Info @ContextInfo 
          Delete From Tests Where Test_Id = @TestId
 	   IF @originalContextInfo Is NULL SET Context_Info 0x ELSE SET Context_Info @originalContextInfo
 	  	  	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Delete Tests')
          Update Tests Set Result = @Result Where Test_Id = @ExistingTestId
 	  	  	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Update Tests')
        End
      Goto Fetch_Loop
    End
Close TestData_Cursor
Deallocate TestData_Cursor
Update  @spServerVariableUpdates SET TranNum = 2 WHERE VARId in (SELECT Var_Id FROM @BaseVars)
If (exists(select 1 from @spServerVariableUpdates))
Begin
 	 if (@ReturnResultSet = 1) -- Send out the Result Set
 	 Begin
 	  	 Select 	 RSType = RSetType, VarId = VarId, PUId = PUId, UserId = UserId, Canceled = Canceled,
 	  	  	  	 Result = Result, ResultOn = ResultOn, TransType = TransType, PostDB = 1,
 	  	  	  	 SecondUserId = SecondUserId, TransNum = TranNum, EventId = EventId, ArrayId = ArrayId,
 	  	  	  	 CommentId = CommentId, ESigId = SignatureId, EntryOn = EntryOn, TestId = TestId, ShouldArchive = 1,
 	  	  	  	 HasHistory = null, IsLocked = Locked
 	  	   From 	 @spServerVariableUpdates
 	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'ReturnResultSet')
 	 End
 	 Else if (@ReturnResultSet = 2) -- Put the Result Set into the Pending Result Sets table for DBMgr to pickup later
 	 Begin
 	  	 INSERT INTO Pending_ResultSets(Processed,RS_Value,User_Id,Entry_On)
 	  	 SELECT 0, (
 	  	  	 Select 	 RSType = RSetType, VarId = VarId, PUId = PUId, UserId = UserId, Canceled = Canceled,
 	  	  	  	  	 Result = Result, ResultOn = ResultOn, TransType = TransType, PostDB = 1,
 	  	  	  	  	 SecondUserId = SecondUserId, TransNum = TranNum, EventId = EventId, ArrayId = ArrayId,
 	  	  	  	  	 CommentId = CommentId, ESigId = SignatureId, EntryOn = EntryOn, TestId = TestId, ShouldArchive = 1,
 	  	  	  	  	 HasHistory = null, IsLocked = Locked
 	  	  	   From 	 @spServerVariableUpdates d WHERE d.VarId = T.VarId and  d.TransType = T.TransType and  d.EventId = T.EventId
 	  	  	 for xml path ('row'), ROOT('rows'), ELEMENTS XSINIL), @UserId, dbo.fnServer_CmnGetDate(GetUtcDate())
 	  	  	 From @spServerVariableUpdates T
 	 End
End
If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
