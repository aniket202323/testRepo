CREATE PROCEDURE dbo.spServer_DBMgrDeleteEventData 
@UnitID int,
@ResultOn datetime,
@EventType int = 1,
@ReturnResultSet int = 0, -- 0 = Don't Return Result sets, caller will do it, 1 = Return Result Sets, 2 = Defer Result Sets to Pending Result Sets Table
@Pei_Id 	  	  	 Int = Null,
@EventSubtypeId 	 Int = Null,
@UserId int = 14
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
      Values(@ID, 'in DBMgrDeleteEventData /UnitID: ' + Coalesce(convert(nVarChar(4),@UnitID),'Null') + ' /ResultOn: ' + Coalesce(convert(nVarChar(25),@ResultOn),'Null') + 
 	 ' /EventType: ' + Coalesce(convert(nVarChar(4),@EventType),'Null') + ' /ReturnResultSet: ' + Coalesce(convert(nVarChar(4),@ReturnResultSet),'Null') + 
 	 ' /Pei_Id: ' + Coalesce(convert(nVarChar(4),@Pei_Id),'Null') + ' /EventSubtypeId: ' + Coalesce(convert(nVarChar(4),@EventSubtypeId),'Null'))
  End
Declare
  @TestId BigInt,
  @VarId int,
  @EventId int
Create Table #spServerVariableUpdates(RSetType int, VarId int, PUId int, UserId int, Canceled int, Result nVarChar(25), ResultOn datetime, TransType int,EventId Int,Locked TinyInt)
Create Table #Vars(Var_Id Int)
If @Pei_Id is null and @EventSubtypeId is null
 	 Insert Into #Vars (Var_Id)
 	   Select v.Var_Id 
 	  	 From Variables_Base v
 	  	 JOIN Prod_Units_base p On p.PU_Id = v.PU_Id
 	  	 Where (v.PU_Id = p.PU_Id) And ((p.PU_Id = @UnitID) Or (p.Master_Unit = @UnitID)) And (v.Event_Type = @EventType)
Else If @EventSubtypeId is null
 	 Insert Into #Vars (Var_Id)
 	   Select v.Var_Id 
 	   From Variables_Base v
 	  	 JOIN Prod_Units_base p On p.PU_Id = v.PU_Id
 	   Where (v.PU_Id = p.PU_Id) And ((p.PU_Id = @UnitID) Or (p.Master_Unit = @UnitID)) And (v.Event_Type = @EventType) and (v.Pei_Id = @Pei_Id)
Else
 	 Insert Into #Vars (Var_Id)
 	   Select v.Var_Id 
 	   From Variables_Base v
 	  	 JOIN Prod_Units_base p On p.PU_Id = v.PU_Id
 	   Where (v.PU_Id = p.PU_Id) And ((p.PU_Id = @UnitID) Or (p.Master_Unit = @UnitID)) And (v.Event_Type = @EventType) and (v.Event_Subtype_Id = @EventSubtypeId)
Select t.Test_Id,v.Var_Id,t.Result,t.Event_Id 
  Into #TestData
  From Tests t
  Join #Vars v on (v.Var_Id = t.Var_Id) And (t.Result_On = @ResultOn)
Drop Table #Vars
Execute('Declare TestData_Cursor CURSOR Global STATIC ' + 
  'For (Select Test_Id,Var_Id,Event_Id From #TestData)' + 
  'For Read Only')
  Open TestData_Cursor  
Fetch_Loop:
  Fetch Next From TestData_Cursor Into @TestId,@VarId,@EventId
  If (@@Fetch_Status = 0)
    Begin
      If (@ReturnResultSet in (1,2)) 
        Begin
          Insert Into #spServerVariableUpdates(RSetType,VarId,PUId,UserId,Canceled,Result,ResultOn,TransType,EventId)
            Values (2,@VarId,0,0,1,'',@ResultOn,3,@EventId)
        End
 	   SET @originalContextInfo = Context_Info()
 	   SET @ContextInfo = CAST(@UserId AS varbinary(128))
 	   SET Context_Info @ContextInfo 
      Delete From Tests Where Test_Id = @TestId
 	   IF @originalContextInfo Is NULL SET Context_Info 0x ELSE SET Context_Info @originalContextInfo
      Goto Fetch_Loop
    End
Close TestData_Cursor
Deallocate TestData_Cursor
Drop Table #TestData
if (@ReturnResultSet = 1) -- Send out the Result Set
Begin
 	 Select RSetType,VarId,PUId,UserId,Canceled,Result,ResultOn,TransType,1,null,null,EventId From #spServerVariableUpdates
 	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'ReturnResultSet')
End
Else if (@ReturnResultSet = 2) -- Put the Result Set into the Pending Result Sets table for DBMgr to pickup later
Begin
 	 INSERT INTO Pending_ResultSets(Processed,RS_Value,User_Id,Entry_On)
 	 SELECT 0, (
 	  	 Select 	 RSType = RSetType, VarId = VarId, PUId = PUId, UserId = UserId, Canceled = Canceled,
 	  	  	  	 Result = Result, ResultOn = ResultOn, TransType = TransType, PostDB = 1,
 	  	  	  	 SecondUserId = null, TransNum = null, EventId = EventId From #spServerVariableUpdates
 	  	  	  	 d WHERE d.VarId = T.VarId and  d.TransType = T.TransType and  d.EventId = T.EventId
 	  	 for xml path ('row'), ROOT('rows'), ELEMENTS XSINIL), @UserId, dbo.fnServer_CmnGetDate(GetUtcDate())
 	  	 From #spServerVariableUpdates T
End
Drop Table #spServerVariableUpdates
If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
