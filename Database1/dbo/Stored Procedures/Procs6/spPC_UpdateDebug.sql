Create Procedure dbo.spPC_UpdateDebug
 	 @Id Int,
 	 @DebugValue 	 Int,
 	 @DebugType 	 Int = 0
  AS
Declare @Exists Int
If @DebugType = 0
  Begin
 	 Select @Exists = Null
 	 Select @Exists = Parm_Id from User_Parameters where parm_Id = 112 and User_Id = @Id
 	 If @Exists Is null
 	  	 Insert INto User_Parameters (User_Id,Parm_Id,HostName,Value) Values (@Id,112,'',convert(nVarChar(10),@DebugValue))
 	 else
 	  	 Update User_Parameters Set Value = convert(nVarChar(10),@DebugValue) Where  User_Id = @Id and parm_Id = 112
 	 
  End
Else If @DebugType = 1
 Begin
 	 Update Event_Configuration set Debug = @DebugValue Where EC_Id = @Id
 End
Else If @DebugType = 2
 Begin
 	 Update Variables_Base set Debug = @DebugValue Where Var_Id = @Id
 End
 	 
