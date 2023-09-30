Create Procedure dbo.spEM_AppTransExpandVS
 	 @Trans_Id 	 Int
 AS
Declare @PUG_Id 	 Int,
 	 @Prod_Id 	 Int
Create Table #TransVar (Var_Id 	  	 Int,
 	  	  	 Prod_Id 	  	 Int,
 	  	  	 Char_Id 	  	 Int,
 	  	  	 Spec_Id 	 Int,
 	  	  	 U_Entry 	  	 nVarChar(25),
 	  	  	 U_Reject 	 nVarChar(25),
 	  	  	 U_Warning 	 nVarChar(25),
 	  	  	 U_User 	  	 nVarChar(25),
 	  	  	 Target 	  	 nVarChar(25),
 	  	  	 L_User 	  	 nVarChar(25),
 	  	  	 L_Warning 	 nVarChar(25),
 	  	  	 L_Reject 	 nVarChar(25),
 	  	  	 L_Entry 	  	 nVarChar(25),
 	  	  	 L_Control 	 nVarChar(25),
 	  	  	 T_Control 	 nVarChar(25),
 	  	  	 U_Control 	 nVarChar(25),
 	  	  	 Test_Freq 	 int, 
 	  	  	 Esignature_Level 	 Int,
 	  	  	 Comment_Id 	 Int,
 	  	  	 Expiration_Date DateTime,
 	  	  	 Not_Defined  	 Int,
 	  	  	 Is_Defined 	  	  	 Int)
-- Process updates
Declare T2_Cursor Cursor
  For Select Distinct v.Pug_Id,t.Prod_Id
  From Trans_Variables t
  Join Variables v on v.Var_Id = t.Var_Id and v.spec_id is not null
  Where Trans_Id = @Trans_Id 
Open T2_Cursor
NextTC1:
 Fetch Next From T2_Cursor Into @PUG_Id,@Prod_Id
 If @@Fetch_Status = 0
    Begin
        Insert into #TransVar  Execute spEM_TransVSExpand @Trans_Id,@PUG_Id,@Prod_Id,0
        Goto NextTC1
    End
Close T2_Cursor
Deallocate T2_Cursor
Delete from Trans_Variables 
 	 From Trans_Variables tv
 	 Join #TransVar v on v.var_Id = tv.var_Id and v.prod_Id = tv.prod_Id
 	 Where tv.trans_Id = @Trans_Id
Insert into Trans_Variables (Var_Id,Prod_Id,U_Entry,U_Reject,U_Warning,U_User,Target,L_User,L_Warning,
 	  	  	 L_Reject,L_Entry,L_Control,T_Control,U_Control,Test_Freq, Esignature_Level, Comment_Id,Not_Defined,Is_Defined,Trans_Id) 
 	 Select Var_Id,Prod_Id,U_Entry,U_Reject,U_Warning,U_User,Target,L_User,L_Warning,
 	  	  	 L_Reject,L_Entry,L_Control,T_Control,U_Control,Test_Freq, Esignature_Level, Comment_Id,Not_Defined,Is_Defined,@Trans_Id
 	  	  from #TransVar
Drop Table #TransVar
