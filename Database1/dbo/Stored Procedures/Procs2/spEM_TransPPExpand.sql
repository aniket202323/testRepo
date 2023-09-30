Create Procedure dbo.spEM_TransPPExpand 
  @Trans_Id 	 Int,
  @Characteristic int,
  @IsForClient 	  Int
  AS
  --
  -- Insert new record into the active specifications table and determine the
  -- identity of the newly inserted record.
  --
  DECLARE 	 @Spec_Id 	 int,
 	  	 @Char_Id 	 int,
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
 	  	 @T_Control 	 nvarchar(25),
 	  	 @U_Control 	 nvarchar(25),
 	  	 @Test_Freq 	 int,
 	  	 @Sig 	  	 int,
 	  	 @Limit 	  	 int,
 	  	 @Ch_Id 	  	 int,
 	  	 @IsDefined 	 int,
 	  	 @Not_Defined   int,
 	  	 @Not_Defined2 int,
 	  	 @Id 	  	 Int,
 	  	 @Now 	  	 DateTime,
 	  	 @ToId 	  	 Int,
 	  	 @FromId 	 Int,
 	  	 @Prev_Char_Id Int,
 	  	 @NextChar 	 Int,
 	  	 @CharOrder 	 Int,
 	  	 @CommentId 	 Int,
 	  	 @IsTrans 	 Tinyint
 	  	 
   If (select count(*) From Trans_Char_links Where trans_id = @Trans_Id) = 0 and (select count(*) From Trans_Properties Where trans_id = @Trans_Id) = 0 
 	 Return
 Select @Now = dbo.fnServer_CmnGetDate(getUTCdate())
 DECLARE @CharId1 Table (Char_Id integer)
 DECLARE @CharId2 Table (Char_Id integer)
 DECLARE  @TransLinks Table(To_Char_Id Integer,From_Char_Id Integer)
 Create Table #TransPPExpand(   Spec_Id 	 int 	  	 Not Null,
 	  	  	 Char_Id 	  	 int 	  	 Not Null,
 	  	  	 L_Entry 	  	 nVarChar(25) 	 Null,
 	  	  	 L_Reject 	 nVarChar(25) 	 Null,
 	  	  	 L_Warning 	 nVarChar(25) 	 Null,
 	  	  	 L_User 	  	 nVarChar(25) 	 Null,
 	  	  	 Target 	  	 nVarChar(25) 	 Null,
 	  	  	 U_User 	  	 nVarChar(25) 	 Null,
 	  	  	 U_Warning 	 nVarChar(25) 	 Null,
 	  	  	 U_Reject 	 nVarChar(25) 	 Null,
 	  	  	 U_Entry 	  	 nVarChar(25) 	 Null,
 	  	  	 L_Control 	 nVarChar(25) 	 Null,
 	  	  	 T_Control 	 nVarChar(25) 	 Null,
 	  	  	 U_Control 	 nVarChar(25) 	 Null,
 	  	  	 Test_Freq 	 int 	  	 Null,
 	  	  	 Esignature_Level 	 int 	  	 Null,
 	  	  	 Comment_Id 	 int  	  	 Null,
 	  	  	 Expiration_date  DateTime  	 Null,
 	  	  	 Is_Defined 	 Int 	  	 Null,
 	  	  	 Not_Defined 	 Int 	  	 Null,
 	  	  	 Updated 	 Int 	  	 Null)
  Create Table #TransPPExpand1( Spec_Id 	 int,
 	  	  	 From_Char_Id     int,
 	  	  	 Char_Id 	  	 int)
DECLARE @TopChar Int
DECLARE @StartChar Int
SELECT @StartChar = NULL
SELECT @StartChar = To_Char_Id,@TopChar = From_Char_Id
 	 FROM Trans_Char_Links
 	 WHERE Trans_Id = @Trans_Id and From_Char_Id = @Characteristic
SELECT @NextChar = @StartChar
/* Loop thru transactions*/
WHILE @NextChar Is Not Null
BEGIN
 	 SELECT @NextChar = NULL
 	 SELECT @NextChar = To_Char_Id
 	  	 FROM Trans_Char_Links
 	  	 WHERE Trans_Id = @Trans_Id and From_Char_Id = @TopChar 
 	 IF @NextChar IS NOT NULL
 	 BEGIN 	 
 	  	 SELECT @TopChar = @NextChar
 	 END
END
IF @TopChar Is Not NULL
 	 INSERT INTO @TransLinks(To_Char_Id,From_Char_Id)
 	  	 SELECT @TopChar,@Characteristic
  Insert into #TransPPExpand1(Spec_Id,From_Char_Id,Char_Id)
       Select Distinct s.Spec_Id,t.From_Char_Id,t.To_Char_Id
 	  From  @TransLinks t
 	  Join Characteristics c on c.Char_Id = t.To_Char_Id
 	  Join Specifications s on s.Prop_Id  = c.Prop_Id
Execute ('Declare Link_Cursor Cursor Global for ' +
 	   'Select Spec_Id,From_Char_Id, Char_Id ' +
 	   ' From #TransPPExpand1 For Read Only')
 	 Open Link_Cursor
FetchNextLink:
 	 Fetch Next From Link_Cursor InTo @Spec_Id,@FChar_Id,@Ch_Id
   If @@Fetch_Status = 0 
 	 Begin
 	   Select @IsDefined = Is_Defined,
 	  	 @L_Entry  	 = L_Entry,
 	  	 @L_Reject 	 = L_Reject,
 	  	 @L_Warning 	 = L_Warning,
 	  	 @L_User 	 = L_User,
 	  	 @Target 	 = Target,
 	  	 @U_User 	 = U_User,
 	  	 @U_Warning 	 = U_Warning,
 	  	 @U_Reject 	 = U_Reject,
 	  	 @U_Entry 	 = U_Entry,
 	  	 @L_Control 	 = L_Control,
 	  	 @T_Control 	 = T_Control,
 	  	 @U_Control 	 = U_Control,
 	  	 @Test_Freq 	 = Test_Freq,
 	  	 @Sig        = Esignature_Level,
 	  	 @CommentId     = Comment_Id
  	  	 From Active_Specs
 	  	 Where Spec_Id = @Spec_Id And Char_Id = @FChar_Id  And
 	  	     Effective_Date <= @Now And  ((Expiration_Date IS NULL) Or
             	  	    ((Expiration_Date IS NOT NULL) And  (Expiration_Date > @Now)))
 	   Insert into #TransPPExpand (Spec_Id,Char_Id,L_Entry,L_Reject,L_Warning,L_User,Target,U_User,U_Warning,U_Reject,U_Entry,L_Control,T_Control,U_Control,Test_Freq,Esignature_Level,Not_Defined,Updated)
 	   Select Spec_Id,
 	  	 @FChar_Id,
 	  	 L_Entry = Case  
 	  	  	  	 When L_Entry is null and  @L_Entry is not null Then ''
 	  	  	     	 Else L_Entry 
 	  	  	 End,
 	  	 L_Reject = Case 
 	  	  	               When L_Reject is null and  @L_Reject is not null Then ''
 	  	  	       	 Else L_Reject
 	  	  	 End,
 	  	 L_Warning = Case 
 	  	  	          	     When L_Warning is null and  @L_Warning is not null Then ''
 	  	  	  	      Else L_Warning 
 	  	  	    End,
 	  	 L_User = Case 
 	  	  	    	 When L_User is null and  @L_User is not null Then ''
 	  	  	    	 Else L_User 
 	  	  	 End,
 	  	 Target = Case 
 	  	  	   	 When Target is null and  @Target is not null Then ''
 	  	  	   	 Else Target 
 	  	  	 End,
 	  	 U_User = Case
 	  	  	     	 When U_User is null and  @U_User is not null Then ''
 	  	  	     	 Else U_User 
 	  	  	 End,
 	  	 U_Warning = Case
 	  	  	          	 When U_Warning is null and  @U_Warning is not null Then ''
 	  	  	          	 Else U_Warning 
 	  	  	    End,
 	  	 U_Reject = Case 
 	  	  	        	 When U_Reject is null and  @U_Reject is not null Then ''
 	  	  	        	 Else U_Reject 
 	  	  	 End,
 	  	 U_Entry = Case 
 	  	  	     	 When U_Entry is null and  @U_Entry is not null Then ''
 	  	  	     	 Else U_Entry 
 	  	  	 End,
 	  	 L_Control = Case
 	  	  	     	 When L_Control is null and  @L_Control is not null Then ''
 	  	  	     	 Else L_Control 
 	  	  	 End,
 	  	 T_Control = Case
 	  	  	     	 When T_Control is null and  @T_Control is not null Then ''
 	  	  	     	 Else T_Control 
 	  	  	 End,
 	  	 U_Control = Case
 	  	  	     	 When U_Control is null and  @U_Control is not null Then ''
 	  	  	     	 Else U_Control 
 	  	  	 End,
 	  	 Test_Freq = Case
 	  	  	        	   When Test_Freq is null and  @Test_Freq is not null Then -1
 	  	  	        	 Else Test_Freq 
 	  	  	  End,
 	  	 Esignature_Level = Case 
 	  	  	        	   When Esignature_Level is null and  @Sig is not null Then -1
 	  	  	        	 Else Esignature_Level 
 	  	  	  End,
 	  	 Not_Defined = @IsDefined,1
 	  	 From Active_Specs
 	  	 Where Spec_Id = @Spec_Id And Char_Id = @Ch_Id  And
 	  	     Effective_Date <= @Now And  ((Expiration_Date IS NULL) Or
             	  	    ((Expiration_Date IS NOT NULL) And  (Expiration_Date > @Now)))
 	  	 If @@rowcount = 0 
 	  	    Begin
 	  	      Select @Id = Null
 	  	      Select @Id = Spec_Id from #TransPPExpand Where  Spec_Id = @Spec_Id and Char_Id = @Ch_Id
 	  	      IF @Id is null
 	  	        Insert into #TransPPExpand (Spec_Id,Char_Id,L_Entry,L_Reject,L_Warning,L_User,Target,U_User,U_Warning,U_Reject,U_Entry,L_Control,T_Control,U_Control,Test_Freq,Esignature_Level,Is_Defined,not_defined,Updated)
 	  	          SELECT @Spec_Id,@FChar_Id,
 	  	  	  	  	  	  	 L_Entry = Case  When  @L_Entry is not null Then '' 	  	 Else Null  	 End,
 	  	  	  	  	  	  	 L_Reject = Case When @L_Reject is not null Then '' 	  	 Else Null 	 End,
 	  	  	  	  	  	  	 L_Warning = Case  When @L_Warning is not null Then ''   Else Null   End,
 	  	  	  	  	  	  	 L_User = Case  When @L_User is not null Then '' 	  	  	 Else Null 	 End,
 	  	  	  	  	  	  	 Target = Case  When @Target is not null Then '' 	  	  	 Else Null 	 End,
 	  	  	  	  	  	  	 U_User = Case When  @U_User is not null Then '' 	  	  	 Else Null 	 End,
 	  	  	  	  	  	  	 U_Warning = Case When  @U_Warning is not null Then '' 	 Else Null   End,
 	  	  	  	  	  	  	 U_Reject = Case When  @U_Reject is not null Then '' 	  	 Else Null 	 End,
 	  	  	  	  	  	  	 U_Entry = Case When  @U_Entry is not null Then '' 	  	 Else Null 	 End,
 	  	  	  	  	  	  	 L_Control = Case WHEN @L_Control is not null Then '' 	 Else Null 	 End,
 	  	  	  	  	  	  	 T_Control = Case When   @T_Control is not null Then '' 	 Else Null 	 End,
 	  	  	  	  	  	  	 U_Control = Case When   @U_Control is not null Then '' 	 Else Null 	 End,
 	  	  	  	  	  	  	 Test_Freq = Case When   @Test_Freq is not null Then -1 	 Else Null   End,
 	  	  	  	  	  	  	 Esignature_Level = Case When  @Sig is not null Then -1 	 Else Null   End,
 	  	  	  	  	  	  	 Null,
 	  	  	  	  	  	    Null,
 	  	  	  	  	  	    1
 	  	    End
 	   GoTo FetchNextLink
     	 End
    Close Link_Cursor
    Deallocate Link_Cursor
Drop Table #TransPPExpand1
IF  (select count(*) From Trans_Properties Where trans_id = @Trans_Id) = 0 
 	 GOTO Done
update #TransPPExpand set Not_Defined = 65535
-- Add Trans Properties
 Declare Trans_Cursor Insensitive Cursor
     For Select Spec_Id,Char_Id,L_Entry,L_Reject,L_Warning,L_User,Target,U_User,U_Warning,U_Reject,U_Entry,L_Control,T_Control,U_Control,Test_Freq,Esignature_Level,Is_Defined,Not_Defined,Comment_Id
     From Trans_Properties Where Trans_Id = @Trans_Id and Char_Id = @Characteristic 
     For Read Only
   Open Trans_Cursor
 Next_Trans1:
    Fetch Next From Trans_Cursor InTo  @Spec_Id,@Char_Id,@L_Entry,@L_Reject,@L_Warning,@L_User,@Target,@U_User,@U_Warning,@U_Reject,@U_Entry,@L_Control,@T_Control,@U_Control,@Test_Freq,@Sig,@IsDefined,@Not_Defined,@CommentId
    If @@Fetch_Status = 0 
        Begin
 	 If (Select Count(*) From #TransPPExpand Where Char_Id  = @Char_Id and Spec_Id = @Spec_Id) = 0 
 	  	 Insert into #TransPPExpand (Spec_Id,Char_Id,L_Entry,L_Reject,L_Warning,L_User,Target,U_User,U_Warning,U_Reject,U_Entry,L_Control,T_Control,U_Control,Test_Freq,Esignature_Level,Is_Defined,not_defined,updated,Comment_Id)
 	  	     Values (@Spec_Id,@Char_Id,@L_Entry,@L_Reject,@L_Warning,@L_User,@Target,@U_User,@U_Warning,@U_Reject,@U_Entry,@L_Control,@T_Control,@U_Control,@Test_Freq,@Sig,@IsDefined,@Not_Defined,1,@CommentId)
 	 Else
 	   Begin
 	  	 Select @Not_Defined2 = not_defined  From #TransPPExpand Where Spec_Id = @Spec_Id and Char_Id = @Char_Id
 	  	 Delete From #TransPPExpand Where Spec_Id = @Spec_Id and Char_Id = @Char_Id
 	  	 Insert into #TransPPExpand (Spec_Id,Char_Id,L_Entry,L_Reject,L_Warning,L_User,Target,U_User,U_Warning,U_Reject,U_Entry,L_Control,T_Control,U_Control,Test_Freq,Esignature_Level,Is_Defined,not_defined,Updated,Comment_Id)
 	  	     Values (@Spec_Id,@Char_Id,@L_Entry,@L_Reject,@L_Warning,@L_User,@Target,@U_User,@U_Warning,@U_Reject,@U_Entry,@L_Control,@T_Control,@U_Control,@Test_Freq,@Sig,@IsDefined,@Not_Defined2 - @IsDefined,1,@CommentId)
 	   End
 	 Goto Next_Trans1
        End
Close Trans_Cursor
Deallocate Trans_Cursor
Update #TransPPExpand SET Not_Defined = 65535 - Is_Defined
Insert into #TransPPExpand  (Spec_Id,Char_Id,Is_Defined,not_defined,Updated)
 	 Select Distinct s.Spec_Id,c.Char_Id,a.Is_Defined,
 	  	 Case When a.Is_Defined is null then 65535
 	  	    Else 65535 - a.Is_Defined
   	  	 End,0
 	 From Characteristics c 
 	 Join Specifications s On s.Prop_Id = c.Prop_Id
 	 Join Trans_properties t on t.spec_Id = s.spec_Id and t.trans_Id = @Trans_Id
 	 Left Join Active_specs a on a.Spec_Id = s.spec_id   and a.Char_Id = c.Char_Id and
 	     a.Effective_Date <= @Now And  ((a.Expiration_Date IS NULL) Or
           	  	    ((a.Expiration_Date IS NOT NULL) And  (a.Expiration_Date > @Now)))
 	  Where  c.Char_Id  = @Characteristic and s.Spec_Id not in (select distinct spec_Id from #TransPPExpand)
Select @Not_Defined2 = 0
Execute(' Declare Trans_Cursor Cursor Global ' +
    'For Select Spec_Id,Char_Id,L_Entry,L_Reject,L_Warning,L_User,Target,U_User,U_Warning,U_Reject,U_Entry,L_Control,T_Control,U_Control,Test_Freq,Esignature_Level,Not_Defined ' +
     'From #TransPPExpand ' +
    'For Read Only')
    Open Trans_Cursor
Next_Trans:
    Fetch Next From Trans_Cursor InTo  @Spec_Id,@Char_Id,@L_Entry,@L_Reject,@L_Warning,@L_User,@Target,@U_User,@U_Warning,@U_Reject,@U_Entry,@L_Control,@T_Control,@U_Control,@Test_Freq,@Sig,@Not_Defined
    If @@Fetch_Status = 0 
        Begin
 	    IF @Not_Defined & 1 = 1 
 	      Begin
 	         Execute spEM_TransGetLimitDef @Char_Id,@Spec_Id,1,0,@Now,@Trans_Id,@L_Entry  Output,@IsTrans OutPut
                If @IsTrans = 1
 	             Update #TransPPExpand Set L_Entry = @L_Entry,Updated = 1,@Not_Defined2 = @Not_Defined2 + 1 Where Char_Id = @Char_Id and Spec_Id = @Spec_Id
 	  	 Else
 	             Update #TransPPExpand Set L_Entry = Null Where Char_Id = @Char_Id and Spec_Id = @Spec_Id
 	      End
 	    IF @Not_Defined & 2 = 2
 	      Begin
 	         Execute spEM_TransGetLimitDef @Char_Id,@Spec_Id,2,0,@Now,@Trans_Id,@L_Reject  Output,@IsTrans OutPut
                If @IsTrans = 1
 	          	 Update #TransPPExpand Set L_Reject = @L_Reject,Updated = 1,@Not_Defined2 = @Not_Defined2 + 2 Where Char_Id = @Char_Id and Spec_Id = @Spec_Id
 	  	 Else
 	          	 Update #TransPPExpand Set L_Reject = Null Where Char_Id = @Char_Id and Spec_Id = @Spec_Id
 	      End
 	    IF @Not_Defined & 4 = 4
 	      Begin
 	         Execute spEM_TransGetLimitDef @Char_Id,@Spec_Id,4,0,@Now,@Trans_Id,@L_Warning  Output,@IsTrans OutPut
                If @IsTrans = 1
 	          	 Update #TransPPExpand Set L_Warning = @L_Warning,Updated = 1,@Not_Defined2 = @Not_Defined2 + 4 Where Char_Id = @Char_Id and Spec_Id = @Spec_Id
 	  	 Else
 	          	 Update #TransPPExpand Set L_Warning = Null Where Char_Id = @Char_Id and Spec_Id = @Spec_Id
 	      End
 	    IF @Not_Defined & 8 = 8
 	      Begin
 	         Execute spEM_TransGetLimitDef @Char_Id,@Spec_Id,8,0,@Now,@Trans_Id,@L_User  Output,@IsTrans OutPut
                If @IsTrans = 1
 	          	 Update #TransPPExpand Set L_User = @L_User,Updated = 1,@Not_Defined2 = @Not_Defined2 + 8 Where Char_Id = @Char_Id and Spec_Id = @Spec_Id
 	  	 Else
 	          	 Update #TransPPExpand Set L_User = Null Where Char_Id = @Char_Id and Spec_Id = @Spec_Id
 	      End
 	    IF @Not_Defined & 16 = 16
 	      Begin
 	         Execute spEM_TransGetLimitDef @Char_Id,@Spec_Id,16,0,@Now,@Trans_Id,@Target  Output,@IsTrans OutPut
                If @IsTrans = 1
 	  	         Update #TransPPExpand Set Target  = @Target,Updated = 1,@Not_Defined2 = @Not_Defined2 + 16  Where Char_Id = @Char_Id and Spec_Id = @Spec_Id
 	  	 Else
 	  	         Update #TransPPExpand Set Target  = Null  Where Char_Id = @Char_Id and Spec_Id = @Spec_Id
 	      End
 	    IF @Not_Defined & 32 = 32 
 	      Begin
 	         Execute spEM_TransGetLimitDef @Char_Id,@Spec_Id,32,0,@Now,@Trans_Id,@U_User  Output,@IsTrans OutPut
                If @IsTrans = 1
 	          	 Update #TransPPExpand Set U_User = @U_User,Updated = 1,@Not_Defined2 = @Not_Defined2 + 32 Where Char_Id = @Char_Id and Spec_Id = @Spec_Id
 	  	 Else
 	          	 Update #TransPPExpand Set U_User = Null Where Char_Id = @Char_Id and Spec_Id = @Spec_Id
 	      End
 	    IF @Not_Defined & 64 = 64
 	      Begin
 	         Execute spEM_TransGetLimitDef @Char_Id,@Spec_Id,64,0,@Now,@Trans_Id,@U_Warning  Output,@IsTrans OutPut
                If @IsTrans = 1
 	          	 Update #TransPPExpand Set U_Warning = @U_Warning,Updated = 1,@Not_Defined2 = @Not_Defined2 + 64 Where Char_Id = @Char_Id and Spec_Id = @Spec_Id
 	  	 Else
 	          	 Update #TransPPExpand Set U_Warning = Null Where Char_Id = @Char_Id and Spec_Id = @Spec_Id
 	      End
 	    IF @Not_Defined & 128 = 128 
 	      Begin
 	         Execute spEM_TransGetLimitDef @Char_Id,@Spec_Id,128,0,@Now,@Trans_Id,@U_Reject  Output,@IsTrans OutPut
                If @IsTrans = 1
 	          	 Update #TransPPExpand Set U_Reject = @U_Reject,Updated = 1,@Not_Defined2 = @Not_Defined2 + 128 Where Char_Id = @Char_Id and Spec_Id = @Spec_Id
 	  	 Else
 	          	 Update #TransPPExpand Set U_Reject = Null Where Char_Id = @Char_Id and Spec_Id = @Spec_Id
 	      End
 	    IF @Not_Defined & 256 = 256 
 	      Begin
 	         Execute spEM_TransGetLimitDef @Char_Id,@Spec_Id,256,0,@Now,@Trans_Id,@U_Entry  Output,@IsTrans OutPut
                If @IsTrans = 1
 	          	 Update #TransPPExpand Set U_Entry = @U_Entry,Updated = 1,@Not_Defined2 = @Not_Defined2 + 256 Where Char_Id = @Char_Id and Spec_Id = @Spec_Id
 	  	 Else
 	          	 Update #TransPPExpand Set U_Entry = Null Where Char_Id = @Char_Id and Spec_Id = @Spec_Id
 	      End
 	    IF @Not_Defined & 512 = 512 
 	      Begin
 	         Execute spEM_TransGetLimitDef @Char_Id,@Spec_Id,512,0,@Now,@Trans_Id,@Test_Freq  Output,@IsTrans OutPut
                If @IsTrans = 1
 	  	  	 Update #TransPPExpand Set Test_Freq = @Test_Freq,Updated = 1,@Not_Defined2 = @Not_Defined2 + 512 Where Char_Id = @Char_Id and Spec_Id = @Spec_Id
 	  	 Else
 	  	  	 Update #TransPPExpand Set Test_Freq = Null Where Char_Id = @Char_Id and Spec_Id = @Spec_Id
 	      End
 	    IF @Not_Defined & 1024 = 1024 
 	      Begin
 	         Execute spEM_TransGetLimitDef @Char_Id,@Spec_Id,1024,0,@Now,@Trans_Id,@Sig  Output,@IsTrans OutPut
                If @IsTrans = 1
 	  	  	 Update #TransPPExpand Set Esignature_Level = @Sig,Updated = 1,@Not_Defined2 = @Not_Defined2 + 1024 Where Char_Id = @Char_Id and Spec_Id = @Spec_Id
 	  	 Else
 	  	  	 Update #TransPPExpand Set Esignature_Level = Null Where Char_Id = @Char_Id and Spec_Id = @Spec_Id
 	      End
 	    IF @Not_Defined & 8192 = 8192 
 	      Begin
 	         Execute spEM_TransGetLimitDef @Char_Id,@Spec_Id,8192,0,@Now,@Trans_Id,@L_Control  Output,@IsTrans OutPut
                If @IsTrans = 1
 	  	  	 Update #TransPPExpand Set L_Control = @L_Control,Updated = 1,@Not_Defined2 = @Not_Defined2 + 8192 Where Char_Id = @Char_Id and Spec_Id = @Spec_Id
 	  	 Else
 	  	  	 Update #TransPPExpand Set L_Control = Null Where Char_Id = @Char_Id and Spec_Id = @Spec_Id
 	      End
 	    IF @Not_Defined & 16384 = 16384 
 	      Begin
 	         Execute spEM_TransGetLimitDef @Char_Id,@Spec_Id,16384,0,@Now,@Trans_Id,@T_Control  Output,@IsTrans OutPut
                If @IsTrans = 1
 	  	  	 Update #TransPPExpand Set T_Control = @T_Control,Updated = 1,@Not_Defined2 = @Not_Defined2 + 16384 Where Char_Id = @Char_Id and Spec_Id = @Spec_Id
 	  	 Else
 	  	  	 Update #TransPPExpand Set T_Control = Null Where Char_Id = @Char_Id and Spec_Id = @Spec_Id
 	      End
 	    IF @Not_Defined & 32768 = 32768 
 	      Begin
 	         Execute spEM_TransGetLimitDef @Char_Id,@Spec_Id,32768,0,@Now,@Trans_Id,@U_Control  Output,@IsTrans OutPut
                If @IsTrans = 1
 	  	  	 Update #TransPPExpand Set U_Control = @U_Control,Updated = 1,@Not_Defined2 = @Not_Defined2 + 32768 Where Char_Id = @Char_Id and Spec_Id = @Spec_Id
 	  	 Else
 	  	  	 Update #TransPPExpand Set U_Control = Null Where Char_Id = @Char_Id and Spec_Id = @Spec_Id
 	      End
 	 GoTo Next_Trans
        End
  Close Trans_Cursor
  Deallocate Trans_Cursor
  If @IsForClient = 0
 	 BEGIN
 	  	 update #TransPPExpand set Not_Defined = t.Not_Defined
 	  	  	 From Trans_Properties t 
 	  	  	 Where t.Trans_Id = @Trans_Id and t.Spec_Id = #TransPPExpand.Spec_Id and  t.Char_Id = #TransPPExpand.Char_Id 
 	  	 update #TransPPExpand set Not_Defined = NULL
 	  	  	 Where Not_Defined + Is_Defined = 65535
 	 END
  If @IsForClient = 1
  BEGIN
    update #TransPPExpand set Not_Defined = Null
    update #TransPPExpand set Not_Defined = t.Not_Defined
 	 From Trans_Properties t 
 	 Where t.Trans_Id = @Trans_Id and t.Spec_Id = #TransPPExpand.Spec_Id and  t.Char_Id = #TransPPExpand.Char_Id 
  END
Done:
update #TransPPExpand set Is_Defined = Null where Is_Defined = 0
Delete From #TransPPExpand Where L_Entry Is Null And L_Reject Is Null And L_Warning Is Null And L_User Is Null And Target Is Null And U_User Is Null And U_Warning Is Null And U_Reject Is Null And 
 	  	 U_Entry Is Null And L_Control Is Null And T_Control Is Null And U_Control Is Null And Test_Freq Is Null and Esignature_Level is null And Is_Defined Is Null And  Not_Defined  Is Null and comment_Id is Null
Select    Spec_Id,Char_Id,L_Entry,L_Reject,L_Warning,L_User,Target,U_User,U_Warning,U_Reject,U_Entry,L_Control,T_Control,U_Control,Test_Freq,Esignature_Level,Comment_Id,Expiration_date,Is_Defined,Not_Defined
 From #TransPPExpand
Where Updated = 1
order by Spec_Id, Char_Id
Drop Table #TransPPExpand
