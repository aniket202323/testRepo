--  spEM_BuildCorporateTransaction 'D14jrk31','','',1,'testing',124,0
Create Procedure dbo.spEM_BuildCorporateTransaction --spEM_CorporateSpecCreater
@InServerName nVarChar(100),
@TestNames 	 VarChar(7000),
@ProdIds 	 Varchar(7000),
@UserId 	  	 Int,
@TransDesc 	 nvarchar(50),
@CorpTransId Int,
@TransId 	 Int 	 Output
as
Declare @ServerId 	 Int,
 	  	 @IsLinkedServer Bit,
 	  	 @Is_OverRidable Int,
 	  	 @ServerName nvarchar(1000),
 	  	 @Sql VarChar(7000),
 	  	 @Now DateTime,
 	  	 @SaveTestNames VarChar(7000),
 	  	 @SaveProdIds 	 Varchar(7000)
Select @SaveProdIds 	 = @ProdIds
Select @SaveTestNames = @TestNames
Select @Now = dbo.fnServer_CmnGetDate(getUTCdate())
--Insert into local_debug (time,msg) values(@Now,coalesce(convert(nVarChar(10),@CorpTransId),'Null'))
Update Transactions set Trans_Type_Id = 2,Transaction_Grp_Id = 1 where Trans_Id = @CorpTransId
Select @ServerId = Linked_Server_Id,@IsLinkedServer = Linked_Server_IsLinked
  From Linkable_Remote_Servers Where Linked_Server_Desc = @InServerName
If @IsLinkedServer = 0 
  Begin
     Select @ServerName = 'OPENDATASOURCE(''' 
     Select @ServerName = @ServerName + 'SQLOLEDB''' + ',''' + 'Data Source=' + @InServerName + ';User ID=Comxclient;Password=comxclient'
     Select @ServerName = @ServerName + ''')'
  End
Else
  Select @ServerName = @InServerName
Create Table #TestNames(Test_Name nvarchar(50))
Create Table #ProdCodes(Prod_Code nVarChar(25))
Declare @Id  	 nVarChar(10),
 	 @VarFound 	 Bit,
 	 @ProdFound 	 Bit
Select @VarFound = 0,@ProdFound = 0
While (Datalength(LTRIM(RTRIM(@TestNames))) > 1) 
  Begin
 	 Select @Id = SubString(@TestNames,1,CharIndex(Char(3),@TestNames)-1)
 	 Insert Into #TestNames (Test_Name) Select Test_Name From Variables Where Var_Id =  (Convert(Int,@Id))
 	 Select @VarFound = 1
 	 Select @TestNames = SubString(@TestNames,CharIndex(Char(3),@TestNames),Datalength(@TestNames))
 	 Select @TestNames = Right(@TestNames,Datalength(@TestNames)-1)
  End
While (Datalength(LTRIM(RTRIM(@ProdIds))) > 1) 
  Begin
 	 Select @Id = SubString(@ProdIds,1,CharIndex(Char(3),@ProdIds)-1)
 	 Insert Into #ProdCodes (Prod_Code) Select Prod_Code From Products where Prod_Id =  (Convert(Int,@Id))
 	 Select @ProdFound = 1
 	 Select @ProdIds = SubString(@ProdIds,CharIndex(Char(3),@ProdIds),Datalength(@ProdIds))
 	 Select @ProdIds = Right(@ProdIds,Datalength(@ProdIds)-1)
  End
Create Table #RemoteVarSpecs(Test_Freq 	  	 Int,
 	  	  	  	 Esignature_Level Int,
 	  	  	     Comment_Id 	  	 Int,
 	  	  	     L_Warning 	  	 nVarChar(25),
 	  	  	     L_Reject 	  	 nVarChar(25),
 	  	  	     L_Entry 	  	 nVarChar(25),
 	  	  	     U_User 	  	 nVarChar(25),
 	  	  	     Target 	  	 nVarChar(25),
 	  	  	     L_User 	  	 nVarChar(25),
 	  	  	     U_Entry             nVarChar(25),
 	  	  	     U_Reject 	  	 nVarChar(25),
 	  	  	     U_Warning 	  	 nVarChar(25),
 	  	  	     L_Control 	  	 nVarChar(25),
 	  	  	     T_Control 	  	 nVarChar(25),
 	  	  	     U_Control 	  	 nVarChar(25),
 	  	  	     Prod_Code 	  	 nVarChar(25),
 	  	  	     Test_Name 	  	 nvarchar(50),
 	  	  	     Is_OverRidable 	 Int)
Create Table #RemoteVarSpecsUpdates(Test_Freq 	 Int Null,
 	  	  	  	 Esignature_Level Int Null,
 	  	  	     Comment_Id 	  	 Int Null,
 	  	  	     L_Warning 	  	 nVarChar(25) Null,
 	  	  	     L_Reject 	  	 nVarChar(25) Null,
 	  	  	     L_Entry 	  	 nVarChar(25) Null,
 	  	  	     U_User 	  	 nVarChar(25) Null,
 	  	  	     Target 	  	 nVarChar(25) Null,
 	  	  	     L_User 	  	 nVarChar(25) Null,
 	  	  	     U_Entry             nVarChar(25) Null,
 	  	  	     U_Reject 	  	 nVarChar(25) Null,
 	  	  	     U_Warning 	  	 nVarChar(25) Null,
 	  	  	     L_Control 	  	 nVarChar(25) Null,
 	  	  	     T_Control 	  	 nVarChar(25) Null,
 	  	  	     U_Control 	  	 nVarChar(25) Null,
 	  	  	     Prod_Code 	  	 nVarChar(25),
 	  	  	     Test_Name 	  	 nvarchar(50),
 	  	  	     Is_OverRidable 	 Int 	 Null)
Select @Sql = 'Insert Into #RemoteVarSpecs(Test_Freq,Esignature_Level,Comment_Id,L_Warning,L_Reject,L_Entry,U_User,Target,L_User,U_Entry,U_Reject,U_Warning,L_Control,T_Control,U_Control,Prod_Code,Test_Name,Is_OverRidable) '
Select @Sql =  @Sql + 'SELECT  Distinct vs.Test_Freq,vs.Esignature_Level,vs.Comment_Id,vs.L_Warning,vs.L_Reject,vs.L_Entry,vs.U_User,vs.Target,vs.L_User,vs.U_Entry,vs.U_Reject,vs.U_Warning,vs.L_Control,vs.T_Control,vs.U_Control,p.Prod_Code,v.Test_Name,vs.Is_OverRidable '
Select @Sql = @Sql + ' From ' + @ServerName + '.gbdb.dbo.Variables v '
Select @Sql = @Sql + ' Join ' + @ServerName + '.gbdb.dbo.Prod_Units pu on v.pu_Id = pu.Pu_Id '
Select @Sql = @Sql + ' Join ' + @ServerName + '.gbdb.dbo.Pu_Products pp on pp.pu_Id = pu.pu_Id or pp.pu_Id = pu.master_Unit'
Select @Sql = @Sql + ' left Join ' + @ServerName + '.gbdb.dbo.Products p on p.Prod_Id = pp.Prod_Id '
Select @Sql = @Sql + ' Left Join ' + @ServerName + '.gbdb.dbo.Var_Specs vs on vs.var_id = v.var_Id and vs.prod_Id = p.Prod_Id and vs.Effective_Date < dbo.fnServer_CmnGetDate(getUTCdate()) and (vs.Expiration_Date > dbo.fnServer_CmnGetDate(getUTCdate()) Or vs.Expiration_Date is null) '
Select  @Sql = @Sql + ' Where v.test_Name is not null '
If @VarFound = 0
 	 Select  @Sql = @Sql + 'And  v.test_Name In (Select Distinct Test_Name From Variables) ' 
Else
 	 Select  @Sql = @Sql + 'And  v.test_Name In (Select Distinct Test_Name From #TestNames) ' 
If @ProdFound = 0
 	 Select  @Sql = @Sql + 'And  p.Prod_Code In (Select Distinct Prod_Code From Products) ' 
Else
 	 Select  @Sql = @Sql + 'And  p.Prod_Code In (Select Distinct Prod_Code From #ProdCodes) ' 
Execute (@SQL)
Create Table #Dups (MyCount Int,Prod_Code nVarChar(100),Test_Name nVarChar(100))
Insert Into #Dups (MyCount,Prod_Code,Test_Name) Select Count(*),Prod_Code,Test_Name From #RemoteVarSpecs Group By Prod_Code,Test_Name Having Count(*) > 1
Delete From #RemoteVarSpecs
 	 From #RemoteVarSpecs r
 	 Join #Dups d On d.Prod_Code = r.Prod_Code and r.Test_Name = d.Test_Name
INsert Into #RemoteVarSpecsUpdates (Prod_Code,Test_Name) 
   Select Prod_Code,Test_Name From #RemoteVarSpecs
Declare @Test_Freq 	 Int,
 	 @Esignature_Level 	 Int,
 	 @Comment_Id 	 Int,
 	 @L_Warning 	 nVarChar(25),
 	 @L_Reject 	 nVarChar(25),
 	 @L_Entry 	 nVarChar(25),
 	 @U_User 	  	 nVarChar(25),
 	 @Target 	  	 nVarChar(25),
 	 @L_User 	  	 nVarChar(25),
 	 @U_Entry 	 nVarChar(25),
 	 @U_Reject 	 nVarChar(25),
 	 @U_Warning 	 nVarChar(25),
 	 @L_Control 	 nVarChar(25),
 	 @T_Control 	 nVarChar(25),
 	 @U_Control 	 nVarChar(25),
 	 @Prod_Code 	 nVarChar(25),
 	 @Test_Name 	 nvarchar(50)
Declare  Var_Spec Cursor
  For Select vs.Test_Freq,
 	 vs.Esignature_Level,
 	 vs.Comment_Id,
 	 v.Test_Name,
 	 p.Prod_Code,
 	 vs.L_Warning,
 	 vs.L_Reject,
 	 vs.L_Entry,
 	 vs.U_User,
 	 vs.Target,
 	 vs.L_User,
 	 vs.U_Entry,
 	 vs.U_Reject,
 	 vs.U_Warning,
 	 vs.L_Control,
 	 vs.T_Control,
 	 vs.U_Control
FROM  Var_Specs vs
Join  Variables v on vs.var_Id = v.Var_Id
Join Products p On p.prod_Id = vs.Prod_Id
Where Expiration_Date is null and v.test_Name is not null
Open Var_Spec
Var_SpecLoop:
Fetch Next From Var_Spec Into   @Test_Freq,@Esignature_Level,@Comment_Id,@Test_Name,@Prod_Code,@L_Warning,@L_Reject,
 	  	  	  	 @L_Entry,@U_User,@Target,@L_User,@U_Entry,@U_Reject,@U_Warning,@L_Control,@T_Control,@U_Control
IF @@Fetch_Status = 0
  Begin
 	 Select @Is_OverRidable  = 0
    If @L_Entry Is Not Null
 	 Begin 
 	     If  (((Select L_Entry From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) <> @L_Entry) or
 	  	 ((Select Is_OverRidable & 1 From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code)<> 1) or
 	  	 ((Select Is_OverRidable  From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) Is NUll) or
 	  	 ((Select L_Entry From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) Is Null))
 	  	    Begin
 	  	  	 Update #RemoteVarSpecsUpdates Set L_Entry = @L_Entry 
  	  	  	   Where Test_Name = @Test_Name and Prod_Code = @Prod_Code
 	  	  	 Select @Is_OverRidable  = @Is_OverRidable + 1
 	  	    End
 	 End
    If @L_Reject Is Not Null
 	 Begin 
 	     If  (((Select L_Reject From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) <> @L_Reject) or
 	  	 ((Select Is_OverRidable & 2 From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) <> 2) or
 	  	 ((Select Is_OverRidable  From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) Is NUll) or
 	  	 ((Select L_Reject From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) Is Null)) 
 	  	    Begin
 	  	  	 Update #RemoteVarSpecsUpdates Set L_Reject = @L_Reject
  	  	  	   Where Test_Name = @Test_Name and Prod_Code = @Prod_Code
 	  	  	 Select @Is_OverRidable  = @Is_OverRidable + 2
 	  	    End
 	 End
    If @L_Warning Is Not Null
 	 Begin 
 	     If  (((Select L_Warning From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) <> @L_Warning) or
 	  	 ((Select Is_OverRidable & 4 From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) <> 4) or
 	  	 ((Select Is_OverRidable  From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) Is NUll) or
 	  	 ((Select L_Warning From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) Is Null)) 
 	  	    Begin
 	  	  	 Update #RemoteVarSpecsUpdates Set L_Warning = @L_Warning 
 	  	    	   Where Test_Name = @Test_Name and Prod_Code = @Prod_Code
 	  	  	 Select @Is_OverRidable  = @Is_OverRidable + 4
 	  	    End
 	 End
    If @L_User Is Not Null
 	 Begin 
 	     If  (((Select L_User From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) <> @L_User) or
 	  	 ((Select Is_OverRidable & 8 From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) <> 8) or
 	  	 ((Select Is_OverRidable  From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) Is NUll) or
 	  	 ((Select L_User From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) Is Null)) 
 	  	    Begin
 	  	  	 Update #RemoteVarSpecsUpdates Set L_User = @L_User
  	  	  	   Where Test_Name = @Test_Name and Prod_Code = @Prod_Code
 	  	  	 Select @Is_OverRidable  = @Is_OverRidable + 8
 	  	    End
 	 End
    If @Target Is Not Null
 	 Begin
 	     If  (((Select Target From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) <> @Target) or
 	  	 ((Select Is_OverRidable  From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) Is NUll) or
 	  	 ((Select Is_OverRidable & 16 From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) <> 16) or
 	  	 ((Select Target From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) Is Null)) 
 	  	    Begin
 	  	  	 Update #RemoteVarSpecsUpdates Set Target = @Target
  	  	  	   Where Test_Name = @Test_Name and Prod_Code = @Prod_Code
 	  	  	 Select @Is_OverRidable  = @Is_OverRidable + 16
 	  	    End
 	 End
    If @U_User Is Not Null
 	 Begin 
 	     If  (((Select U_User From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) <> @U_User) or
 	  	 ((Select Is_OverRidable & 32 From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) <> 32) or
 	  	 ((Select Is_OverRidable  From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) Is NUll) or
 	  	 ((Select U_User From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) Is Null)) 
 	  	    Begin
 	  	  	 Update #RemoteVarSpecsUpdates Set U_User = @U_User
  	  	  	   Where Test_Name = @Test_Name and Prod_Code = @Prod_Code
 	  	  	 Select @Is_OverRidable  = @Is_OverRidable + 32
 	  	    End
 	 End
    If @U_Warning Is Not Null
 	 Begin
 	     If  (((Select U_Warning From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) <> @U_Warning) or
 	  	 ((Select Is_OverRidable & 64 From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) <> 64) or
 	  	 ((Select Is_OverRidable  From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) Is NUll) or
 	  	 ((Select U_Warning From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) Is Null)) 
 	  	    Begin
 	  	  	 Update #RemoteVarSpecsUpdates Set U_Warning = @U_Warning
  	  	  	   Where Test_Name = @Test_Name and Prod_Code = @Prod_Code
 	  	  	 Select @Is_OverRidable  = @Is_OverRidable + 64
 	  	    End
 	 End
    If @U_Reject Is Not Null
 	 Begin 
 	     If  (((Select U_Reject From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) <> @U_Reject) or
 	  	 ((Select Is_OverRidable & 128 From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) <> 128) or
 	  	 ((Select Is_OverRidable  From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) Is NUll) or
 	  	 ((Select U_Reject From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) Is Null)) 
 	  	    Begin
 	  	  	 Update #RemoteVarSpecsUpdates Set U_Reject = @U_Reject
  	  	  	   Where Test_Name = @Test_Name and Prod_Code = @Prod_Code
 	  	  	 Select @Is_OverRidable  = @Is_OverRidable + 128
 	  	    End
 	 End
   If @U_Entry Is Not Null
 	 Begin 
 	     If  (((Select U_Entry From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) <> @U_Entry) or
 	  	 ((Select Is_OverRidable & 256 From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) <> 256) or
 	  	 ((Select Is_OverRidable  From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) Is NUll) or
 	  	 ((Select U_Entry From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) Is Null)) 
 	  	    Begin
 	  	  	 Update #RemoteVarSpecsUpdates Set U_Entry = @U_Entry
  	  	  	   Where Test_Name = @Test_Name and Prod_Code = @Prod_Code
 	  	  	 Select @Is_OverRidable  = @Is_OverRidable + 256
 	  	    End
 	 End
    If @Test_Freq Is Not Null
 	 Begin 
 	     If  (((Select Test_Freq From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) <> @Test_Freq) or
 	  	 ((Select Is_OverRidable & 512 From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) <> 512) or
 	  	 ((Select Is_OverRidable  From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) Is NUll) or
 	  	 ((Select Test_Freq From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) Is Null))
 	  	    Begin
 	  	  	 Update #RemoteVarSpecsUpdates Set Test_Freq = @Test_Freq 
 	   	  	   Where Test_Name = @Test_Name and Prod_Code = @Prod_Code
 	  	  	 Select @Is_OverRidable  = @Is_OverRidable + 512
 	  	    End
 	 End
    If @Esignature_Level Is Not Null
 	 Begin 
 	     If  (((Select Esignature_Level From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) <> @Esignature_Level) or
 	  	 ((Select Is_OverRidable & 1024 From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) <> 1024) or
 	  	 ((Select Is_OverRidable  From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) Is NUll) or
 	  	 ((Select Esignature_Level From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) Is Null))
 	  	    Begin
 	  	  	 Update #RemoteVarSpecsUpdates Set Esignature_Level = @Esignature_Level 
 	   	  	   Where Test_Name = @Test_Name and Prod_Code = @Prod_Code
 	  	  	 Select @Is_OverRidable  = @Is_OverRidable + 1024
 	  	    End
 	 End
   If @L_Control Is Not Null
 	 Begin 
 	     If  (((Select L_Control From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) <> @L_Control) or
 	  	 ((Select Is_OverRidable & 8192 From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) <> 8192) or
 	  	 ((Select Is_OverRidable  From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) Is NUll) or
 	  	 ((Select L_Control From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) Is Null)) 
 	  	    Begin
 	  	  	 Update #RemoteVarSpecsUpdates Set L_Control = @L_Control
  	  	  	   Where Test_Name = @Test_Name and Prod_Code = @Prod_Code
 	  	  	 Select @Is_OverRidable  = @Is_OverRidable + 8192
 	  	    End
 	 End
   If @T_Control Is Not Null
 	 Begin 
 	     If  (((Select T_Control From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) <> @T_Control) or
 	  	 ((Select Is_OverRidable & 16384 From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) <> 16384) or
 	  	 ((Select Is_OverRidable  From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) Is NUll) or
 	  	 ((Select T_Control From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) Is Null)) 
 	  	    Begin
 	  	  	 Update #RemoteVarSpecsUpdates Set T_Control = @T_Control
  	  	  	   Where Test_Name = @Test_Name and Prod_Code = @Prod_Code
 	  	  	 Select @Is_OverRidable  = @Is_OverRidable + 16384
 	  	    End
 	 End
   If @U_Control Is Not Null
 	 Begin 
 	     If  (((Select U_Control From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) <> @U_Control) or
 	  	 ((Select Is_OverRidable & 32768 From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) <> 32768) or
 	  	 ((Select Is_OverRidable  From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) Is NUll) or
 	  	 ((Select U_Control From #RemoteVarSpecs Where Test_Name = @Test_Name and Prod_Code = @Prod_Code) Is Null)) 
 	  	    Begin
 	  	  	 Update #RemoteVarSpecsUpdates Set U_Control = @U_Control
  	  	  	   Where Test_Name = @Test_Name and Prod_Code = @Prod_Code
 	  	  	 Select @Is_OverRidable  = @Is_OverRidable + 32768
 	  	    End
 	 End
 	 Update #RemoteVarSpecsUpdates Set Is_OverRidable = @Is_OverRidable 
 	  	  	   Where Test_Name = @Test_Name and Prod_Code = @Prod_Code
    Goto Var_SpecLoop
  End
close Var_Spec
Deallocate Var_Spec
Delete From #RemoteVarSpecsUpdates Where 
 	  	 Test_Freq Is Null And
 	  	 Esignature_Level is Null And
 	  	 L_Warning Is Null And
 	  	 L_Reject Is Null And
 	  	 L_Entry Is Null And
 	  	 U_User Is Null And
 	  	 Target Is Null And
 	  	 L_User Is Null And
 	  	 U_Entry Is Null And
 	  	 U_Reject Is Null And
 	  	 U_Warning Is Null And
 	  	 L_Control Is Null  And
 	  	 T_Control Is Null  And
 	  	 U_Control Is Null
Declare @Id1 Int,
 	  	 @Id2 Int
Select @Id1 = Null,@Id2 = Null
If @SaveProdIds <> ''
  Begin
    Insert Into Transaction_Filter_Values(Value) Values(@SaveProdIds)
    Select @Id1 = Scope_Identity()
  End
If @SaveTestNames <> ''
  Begin
    Insert Into Transaction_Filter_Values(Value) Values(@SaveTestNames)
    Select @Id2 = Scope_Identity()
  End
Insert InTo Transactions(Effective_Date,Approved_On,Trans_Create_Date,Approved_By,Trans_Type_Id,Transaction_Grp_Id,Trans_Desc,Linked_Server_Id,Prod_Id_Filter_Id,Var_Id_Filter_Id,Corp_Trans_Id) 
 	 Values (Null,Null,@Now,Null,2,1,@TransDesc,@ServerId,@Id1,@Id2,@CorpTransId)
Select @TransId = Scope_Identity()
Insert Into Trans_Variables(Force_Delete,Trans_Id,Test_Freq,Esignature_Level,Var_Id,Prod_Id,
 	 L_Warning,L_Reject,L_Entry,U_User,Target,L_User,U_Entry,U_Reject,U_Warning,L_Control,T_Control,U_Control,Is_OverRidable)
  Select 0,@TransId,vs.Test_Freq,vs.Esignature_Level,vs.Var_Id,vs.Prod_Id,
 	 vs.L_Warning,vs.L_Reject,vs.L_Entry,vs.U_User,vs.Target,
 	 vs.L_User,vs.U_Entry,vs.U_Reject,vs.U_Warning,vs.L_Control,vs.T_Control,vs.U_Control,r.Is_OverRidable
  From #RemoteVarSpecsUpdates r
 	 Join Products p on p.Prod_Code = r.prod_Code
 	 Join Variables v on v.Test_Name = r.Test_Name
 	 Join Var_Specs vs On vs.Var_Id = v.var_Id and vs.prod_Id = p.prod_Id and
 	   vs.effective_Date < @Now and (vs.Expiration_Date > @Now or vs.Expiration_Date is null)
Drop Table #RemoteVarSpecs
drop table #RemoteVarSpecsUpdates
