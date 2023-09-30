CREATE PROCEDURE dbo.spPDB_DBMgrMoveEventData 
@UnitID int,
@OldResultOn datetime,
@NewResultOn datetime,
@EventType int = 1,
@ReturnResultSet int = 0,
@Pei_Id Int = Null,
@EventSubtypeId 	 Int = Null
 AS
Declare
  @@TestId BigInt,
  @@VarId int,
  @ExistingTestId Bigint,
  @@Result nvarchar(25)
If (@OldResultOn = @NewResultOn)
  Return
Create Table #VariableUpdates(RSetType int, VarId int, PUId int, UserId int, Canceled int, Result nvarchar(25), ResultOn datetime, TransType int)
Create Table #Vars(Var_Id Int)
If @Pei_Id is null and @EventSubtypeId is null
 	 Insert Into #Vars (Var_Id)
 	   Select v.Var_Id 
 	  	 From Variables v, Prod_Units p 
 	  	 Where (v.PU_Id = p.PU_Id) And ((p.PU_Id = @UnitID) Or (p.Master_Unit = @UnitID)) And (v.Event_Type = @EventType)
Else If @EventSubtypeId is null
 	 Insert Into #Vars (Var_Id)
 	   Select v.Var_Id 
 	   From Variables v, Prod_Units p 
 	   Where (v.PU_Id = p.PU_Id) And ((p.PU_Id = @UnitID) Or (p.Master_Unit = @UnitID)) And (v.Event_Type = @EventType) and (v.Pei_Id = @Pei_Id)
Else
 	 Insert Into #Vars (Var_Id)
 	   Select v.Var_Id 
 	   From Variables v, Prod_Units p 
 	   Where (v.PU_Id = p.PU_Id) And ((p.PU_Id = @UnitID) Or (p.Master_Unit = @UnitID)) And (v.Event_Type = @EventType) and (v.Event_Subtype_Id = @EventSubtypeId)
Select t.Test_Id,v.Var_Id,t.Result 
  Into #TestData
  From Tests t
  Join #Vars v on (v.Var_Id = t.Var_Id) And (t.Result_On = @OldResultOn)
Drop Table #Vars
Execute('Declare PDBTestDataMove_Cursor CURSOR Global STATIC ' + 
  'For (Select Test_Id,Var_Id,Result From #TestData) ' + 
  'For Read Only ')
  Open PDBTestDataMove_Cursor  
Fetch_Loop:
  Fetch Next From PDBTestDataMove_Cursor Into @@TestId,@@VarId,@@Result
  If (@@Fetch_Status = 0)
    Begin
      If (@ReturnResultSet = 1) 
        Begin
          Insert Into #VariableUpdates(RSetType,VarId,PUId,UserId,Canceled,Result,ResultOn,TransType)
            Values (2,@@VarId,0,0,1,'',@OldResultOn,3)
          Insert Into #VariableUpdates(RSetType,VarId,PUId,UserId,Canceled,Result,ResultOn,TransType)
            Values (2,@@VarId,0,0,0,@@Result,@NewResultOn,1)
        End
      Select @ExistingTestId = NULL
      Select @ExistingTestId = Test_Id From Tests Where (Var_Id = @@VarId) And (Result_On = @NewResultOn)
      If (@ExistingTestId Is NULL)
        Begin
          Update Tests Set Result_On = @NewResultOn Where Test_Id = @@TestId
        End
      Else
        Begin
          Delete From Tests Where Test_Id = @@TestId
          Update Tests Set Result = @@Result Where Test_Id = @ExistingTestId
        End
      Goto Fetch_Loop
    End
Close PDBTestDataMove_Cursor
Deallocate PDBTestDataMove_Cursor
Drop Table #TestData
If (@ReturnResultSet = 1)
  Select RSetType,VarId,PUId,UserId,Canceled,Result,ResultOn,TransType,1 From #VariableUpdates
Drop Table #VariableUpdates
