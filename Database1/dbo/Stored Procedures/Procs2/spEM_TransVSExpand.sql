Create Procedure dbo.spEM_TransVSExpand
  @Trans_Id 	 Int,
  @PUG_Id        Int,
  @Prod_Id        Int,
  @IsForClient 	 Int
  AS
 --
  -- Insert new record into the active specifications table and determine the
  -- identity of the newly inserted record.
  --
  DECLARE 	 @Var_Id 	  	 int,
 	  	 @Prod1_Id 	 int,
 	  	 @Spec_Id 	 Int,
 	  	 @Char_Id 	 Int,
 	  	 @FChar_Id 	 Int,
 	  	 @L_Entry 	 nvarchar(25),
 	  	 @L_Reject 	 nvarchar(25),
 	  	 @L_Warning 	 nvarchar(25),
 	  	 @L_User 	 nvarchar(25),
 	  	 @Target 	 nvarchar(25),
 	  	 @U_User 	 nvarchar(25),
 	  	 @U_Warning 	 nvarchar(25),
 	  	 @U_Reject 	 nvarchar(25),
 	  	 @U_Entry 	 nvarchar(25),
 	  	 @L_Control 	 nvarchar(25),
 	  	 @U_Control 	 nvarchar(25),
 	  	 @T_Control 	 nvarchar(25),
 	  	 @Test_Freq 	 int,
 	  	 @Sig 	  	 int,
 	  	 @Limit 	  	 int,
 	  	 @IsDefined 	 int,
 	  	 @Not_Defined   int,
 	  	 @Is_Defined 	  int,
 	  	 @Id 	  	 Int,
 	  	 @Now 	  	 DateTime,
 	  	 @Master_Pu 	 Int,
 	  	 @IsTrans 	 TinyInt
 Select @Master_Pu = Pu_Id From Pu_Groups Where PUG_Id = @PUG_Id
 Select @Master_Pu = Coalesce(Master_Unit,@Master_Pu) From Prod_Units Where PU_Id = @Master_Pu
 Select @Now = dbo.fnServer_CmnGetDate(getUTCdate())
Create Table #TransV (Var_Id 	  	 Int,
 	  	  	 Prod_Id 	  	 Int,
 	  	  	 Char_Id 	  	 Int,
 	  	  	 Spec_Id 	 Int,
 	  	  	 U_Entry 	  	 nvarchar(25),
 	  	  	 U_Reject 	 nvarchar(25),
 	  	  	 U_Warning 	 nvarchar(25),
 	  	  	 U_User 	  	 nvarchar(25),
 	  	  	 Target 	  	 nvarchar(25),
 	  	  	 L_User 	  	 nvarchar(25),
 	  	  	 L_Warning 	 nvarchar(25),
 	  	  	 L_Reject 	 nvarchar(25),
 	  	  	 L_Entry 	  	 nvarchar(25),
 	  	  	 L_Control 	 nvarchar(25),
 	  	  	 T_Control 	 nvarchar(25),
 	  	  	 U_Control 	 nvarchar(25),
 	  	  	 Test_Freq 	 int,
 	  	  	 Esignature_Level 	 Int, 
 	  	  	 Comment_Id 	 Int,
 	  	  	 Expiration_Date DateTime,
 	  	  	 Not_Defined  	 Int,
 	  	  	 Is_Defined 	  	  	 Int)
  Insert into #TransV(Var_Id,Prod_Id,Char_Id,Spec_Id,U_Entry,U_Reject,U_Warning,U_User,Target,L_User,L_Warning,L_Reject,L_Entry,L_Control,T_Control,U_Control,Test_Freq,Esignature_Level,Comment_Id,Expiration_Date,Not_Defined,Is_Defined)
     SELECT  t.Var_Id, t.Prod_Id,pu.Char_Id,v.Spec_Id,t.U_Entry, t.U_Reject, t.U_Warning, t.U_User, t.Target, t.L_User, t.L_Warning, t.L_Reject, t.L_Entry,t.L_Control,t.T_Control,t.U_Control, t.Test_Freq,t.Esignature_Level,  t.Comment_Id,  Expiration_Date = NULL, t.Not_Defined,t.Is_Defined
      FROM trans_variables  t
      INNER JOIN Variables v ON (v.Var_Id = t.Var_Id) AND (v.PUG_Id = @PUG_Id) AND (v.PVar_Id IS NULL)
      Left Join Specifications  s on s.Spec_Id = v.Spec_Id
      Left Join Pu_Characteristics pu on pu.Prop_Id = s.Prop_Id And pu.Prod_Id = t.Prod_Id  and pu.PU_Id = @Master_PU
      WHERE (t.Trans_Id = @Trans_Id) AND (t.Prod_Id = @Prod_Id)
  Declare Trans_Cursor Insensitive Cursor
    For Select t.Var_Id,t.Prod_Id,v.Spec_Id,pu.Char_Id,L_Entry,L_Reject,L_Warning,L_User,Target,U_User,U_Warning,U_Reject,U_Entry,L_Control,T_Control,U_Control,Test_Freq,t.Esignature_Level,Not_Defined,Is_Defined
      From Trans_Variables t
      INNER JOIN Variables v ON (v.Var_Id = t.Var_Id) AND (v.PUG_Id = @PUG_Id) AND (v.PVar_Id IS NULL)
      Join Specifications  s on s.Spec_Id = v.Spec_Id
      Join Pu_Characteristics pu on pu.Prop_Id = s.Prop_Id And pu.Prod_Id = t.Prod_Id  and pu.PU_Id = @Master_PU
      WHERE (t.Trans_Id = @Trans_Id) AND (t.Prod_Id = @Prod_Id)
    For Read Only
    Open Trans_Cursor
Next_Trans:
    Fetch Next From Trans_Cursor InTo  @Var_Id,@Prod1_Id,@Spec_Id,@Char_Id,@L_Entry,@L_Reject,@L_Warning,@L_User,@Target,@U_User,@U_Warning,@U_Reject,@U_Entry,@L_Control,@T_Control,@U_Control,@Test_Freq,@Sig,@Not_Defined,@Is_Defined
    If @@Fetch_Status = 0
        Begin
 	       Update #TransV Set Is_Defined = @Is_Defined Where Char_Id = @Char_Id and Spec_Id = @Spec_Id
 	  	  	    IF @Not_Defined & 1 = 1 
 	  	  	      Begin
 	  	  	         Execute spEM_TransGetLimitDef @Char_Id,@Spec_Id,1,1,@Now,@Trans_Id,@L_Entry  Output,@IsTrans OutPut
 	  	  	         Update #TransV Set L_Entry = case when @L_Entry is null then '' else @L_Entry End Where Char_Id = @Char_Id and Spec_Id = @Spec_Id
 	  	  	      End
 	  	  	    IF @Not_Defined & 2 = 2
 	  	  	      Begin
 	  	  	         Execute spEM_TransGetLimitDef @Char_Id,@Spec_Id,2,1,@Now,@Trans_Id,@L_Reject  Output,@IsTrans OutPut
 	  	  	         Update #TransV Set L_Reject = case when @L_Reject is null then '' else @L_Reject End Where Char_Id = @Char_Id and Spec_Id = @Spec_Id
 	  	  	      End
 	  	  	    IF @Not_Defined & 4 = 4
 	  	  	      Begin
 	  	  	         Execute spEM_TransGetLimitDef @Char_Id,@Spec_Id,4,1,@Now,@Trans_Id,@L_Warning  Output,@IsTrans OutPut
 	  	  	         Update #TransV Set L_Warning = case when @L_Warning is null then '' else @L_Warning End Where Char_Id = @Char_Id and Spec_Id = @Spec_Id
 	  	  	      End
 	  	  	    IF @Not_Defined & 8 = 8
 	  	  	      Begin
 	  	  	         Execute spEM_TransGetLimitDef @Char_Id,@Spec_Id,8,1,@Now,@Trans_Id,@L_User  Output,@IsTrans OutPut
 	  	  	         Update #TransV Set L_User = case when @L_User is null then '' else @L_User End Where Char_Id = @Char_Id and Spec_Id = @Spec_Id
 	  	  	      End
 	  	  	    IF @Not_Defined & 16 = 16
 	  	  	      Begin
 	  	  	         Execute spEM_TransGetLimitDef @Char_Id,@Spec_Id,16,1,@Now,@Trans_Id,@Target  Output,@IsTrans OutPut
 	  	  	         Update #TransV Set Target  = case when @Target is null then '' else @Target End  Where Char_Id = @Char_Id and Spec_Id = @Spec_Id
 	  	  	      End
 	  	  	    IF @Not_Defined & 32 = 32 
 	  	  	      Begin
 	  	  	         Execute spEM_TransGetLimitDef @Char_Id,@Spec_Id,32,1,@Now,@Trans_Id,@U_User  Output,@IsTrans OutPut
 	  	  	         Update #TransV Set U_User = case when @U_User is null then '' else @U_User End Where Char_Id = @Char_Id and Spec_Id = @Spec_Id
 	  	  	      End
 	  	  	    IF @Not_Defined & 64 = 64
 	  	  	      Begin
 	  	  	         Execute spEM_TransGetLimitDef @Char_Id,@Spec_Id,64,1,@Now,@Trans_Id,@U_Warning  Output,@IsTrans OutPut
 	  	  	         Update #TransV Set U_Warning = case when @U_Warning is null then '' else @U_Warning End Where Char_Id = @Char_Id and Spec_Id = @Spec_Id
 	  	  	      End
 	  	  	    IF @Not_Defined & 128 = 128 
 	  	  	      Begin
 	  	  	         Execute spEM_TransGetLimitDef @Char_Id,@Spec_Id,128,1,@Now,@Trans_Id,@U_Reject  Output,@IsTrans OutPut
 	  	  	         Update #TransV Set U_Reject = case when @U_Reject is null then '' else @U_Reject End Where Char_Id = @Char_Id and Spec_Id = @Spec_Id
 	  	  	      End
 	  	  	    IF @Not_Defined & 256 = 256 
 	  	  	      Begin
 	  	  	         Execute spEM_TransGetLimitDef @Char_Id,@Spec_Id,256,1,@Now,@Trans_Id,@U_Entry  Output,@IsTrans OutPut
 	  	  	         Update #TransV Set U_Entry = case when @U_Entry is null then '' else @U_Entry End Where Char_Id = @Char_Id and Spec_Id = @Spec_Id
 	  	  	      End
 	  	  	    IF @Not_Defined & 512 = 512 
 	  	  	      Begin
 	  	  	         Execute spEM_TransGetLimitDef @Char_Id,@Spec_Id,512,1,@Now,@Trans_Id,@Test_Freq  Output,@IsTrans OutPut
 	  	  	  	  	 If @IsForClient = 1
 	  	  	  	      	 Update #TransV Set Test_Freq = case when @Test_Freq is null then '' else @Test_Freq End Where Char_Id = @Char_Id and Spec_Id = @Spec_Id
 	  	  	  	  	 Else
 	  	  	  	      	 Update #TransV Set Test_Freq = case when @Test_Freq is null then -1 else @Test_Freq End Where Char_Id = @Char_Id and Spec_Id = @Spec_Id
 	  	  	      End
 	  	  	    IF @Not_Defined & 1024 = 1024 
 	  	  	      Begin
 	  	  	         Execute spEM_TransGetLimitDef @Char_Id,@Spec_Id,1024,1,@Now,@Trans_Id,@Sig  Output,@IsTrans OutPut
 	  	  	  	  	 If @IsForClient = 1
 	  	  	          	 Update #TransV Set Esignature_Level = case when @Sig is null then '' else @Sig End Where Char_Id = @Char_Id and Spec_Id = @Spec_Id
 	  	  	  	  	 Else
 	  	  	          	 Update #TransV Set Esignature_Level = case when @Sig is null then -1 else @Sig End Where Char_Id = @Char_Id and Spec_Id = @Spec_Id 	  	  	 
 	  	  	      End
 	  	  	    IF @Not_Defined & 8192 = 8192 
 	  	  	      Begin
 	  	  	         Execute spEM_TransGetLimitDef @Char_Id,@Spec_Id,8192,1,@Now,@Trans_Id,@L_Control  Output,@IsTrans OutPut
 	  	  	         Update #TransV Set L_Control = case when @L_Control is null then '' else @L_Control End Where Char_Id = @Char_Id and Spec_Id = @Spec_Id
 	  	  	      End
 	  	  	    IF @Not_Defined & 16384 = 16384 
 	  	  	      Begin
 	  	  	         Execute spEM_TransGetLimitDef @Char_Id,@Spec_Id,16384,1,@Now,@Trans_Id,@T_Control  Output,@IsTrans OutPut
 	  	  	         Update #TransV Set T_Control = case when @T_Control is null then '' else @T_Control End Where Char_Id = @Char_Id and Spec_Id = @Spec_Id
 	  	  	      End
 	  	  	    IF @Not_Defined & 32768 = 32768 
 	  	  	      Begin
 	  	  	         Execute spEM_TransGetLimitDef @Char_Id,@Spec_Id,32768,1,@Now,@Trans_Id,@U_Control  Output,@IsTrans OutPut
 	  	  	         Update #TransV Set U_Control = case when @U_Control is null then '' else @U_Control End Where Char_Id = @Char_Id and Spec_Id = @Spec_Id
 	  	  	      End
 	  	  	 GoTo Next_Trans
        End
  Close Trans_Cursor
  Deallocate Trans_Cursor
select * From #TransV
Drop Table #TransV
