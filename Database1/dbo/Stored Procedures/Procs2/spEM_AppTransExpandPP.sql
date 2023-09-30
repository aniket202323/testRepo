Create Procedure dbo.spEM_AppTransExpandPP
  @Trans_Id 	 Int,
  @User_Id 	 Int
  AS
  --
  -- Insert new record into the active specifications table and determine the
  -- identity of the newly inserted record.
  --
  DECLARE 	 @Insert_Id 	 Int ,
 	  	 @Char_Id 	 int,
 	  	 @ToId 	  	 Int,
 	  	 @FromId 	  	 Int
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'AppTransExpandPP',
 	  Convert(nVarChar(10),@Trans_Id) + ','  + 
 	  Convert(nVarChar(10), @User_Id),
              dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  Create Table #TProp( Spec_Id 	  	 int 	  	 Not Null,
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
 	  	  	 Esignature_Level INt Null,
 	  	  	 Comment_Id 	 int 	  	 Null,
 	  	  	 Expiration_Date 	 DateTime 	 Null,
 	  	  	 Is_Defined 	 Int 	  	 Null,
 	  	  	 Not_Defined  	 Int 	  	 Null)
 Create Table #CharId1(Char_Id integer)
 Create Table #CharId2(Char_Id integer)
 Create Table #TransLinks(To_Char_Id Integer,From_Char_Id Integer)
 Create Table #TransP1( Char_Id 	 int)
   Declare  Trans_Char Cursor 
     For  Select To_Char_Id,From_Char_Id
      From Trans_Char_Links
      Where Trans_Id = @Trans_Id
      Order by TransOrder
      For Read only
Open Trans_Char 
FetchNextTransLink:
Fetch Next From Trans_Char InTo @ToId,@FromId
If @@Fetch_status = 0
  Begin
 	 Delete From #CharId1
 	 Insert InTo  #TransLinks(To_Char_Id,From_Char_Id) Values (@ToId, @FromId)
 	 Insert into #CharId1 (Char_Id) Values (@FromId)
  	 Loop1:
 	 Delete From #CharId2
 	 Insert Into #CharId2  Select Char_Id From Characteristics Where Derived_From_Parent in(Select Char_Id from #CharId1)
   	  If @@RowCount > 0
 	     Begin
 	  	 Delete From #CharId1
 	  	 Insert Into #CharId1 Select * From #CharId2
 	  	 Insert InTo  #TransLinks(To_Char_Id,From_Char_Id)  Select @ToId,  Char_Id From #CharId1
 	  	 Goto Loop1
 	     End
 	 goto FetchNextTransLink
   End
close Trans_Char
deallocate Trans_Char
 Insert into #TransP1(Char_Id) Select Distinct From_Char_Id From  #TransLinks
 Drop Table #TransLinks
 Drop table #CharId2
 Insert into #TransP1
 	 Select Distinct Char_Id
 	     From Trans_Properties
 	     Where  Trans_Id  = @Trans_Id
-- Expand to cover all lower branches
Delete From #CharId1
Execute('Declare AllChar_Cursor Cursor Global ' +
    'For Select Char_Id ' +
     'From #TransP1 ' +
    'For Read Only')
    Open AllChar_Cursor
Next_Char1:
    Fetch Next From AllChar_Cursor InTo  @Char_Id
    If @@Fetch_Status = 0 
        Begin
 	 Insert InTo #CharId1
 	    Execute spEM_CharExpand @Char_Id
 	 Goto Next_Char1
        End
  Close AllChar_Cursor
  Deallocate AllChar_Cursor
Insert Into #TransP1 Select Distinct Char_Id From #CharId1
Drop table #CharId1
Execute('Declare AllChar_Cursor Cursor Global ' +
    'For Select Distinct Char_Id ' +
     'From #TransP1 ' +
    'For Read Only')
    Open AllChar_Cursor
Next_Char:
    Fetch Next From AllChar_Cursor InTo  @Char_Id
    If @@Fetch_Status = 0 
        Begin
 	 Insert InTo #TProp
 	    Execute spEm_TransPPExpand @Trans_Id,@Char_Id,0
 	 Goto Next_Char
        End
  Close AllChar_Cursor
  Deallocate AllChar_Cursor
--Select * from #TProp
Begin Transaction
    Delete From Trans_Properties where Trans_Id = @Trans_Id
    Insert Into Trans_Properties (Trans_Id,Spec_Id,Char_Id,U_Entry, U_Reject,  U_Warning , U_User ,Target, L_User ,L_Warning, L_Reject, L_Entry,L_Control,T_Control,U_Control, Test_Freq,Esignature_Level, Comment_Id, Is_Defined ,Not_Defined)  
 	 Select Distinct @Trans_Id, Spec_Id,Char_Id,U_Entry, U_Reject,  U_Warning , U_User ,Target, L_User ,L_Warning, L_Reject, L_Entry,L_Control,T_Control,U_Control, Test_Freq,Esignature_Level,Comment_Id, Is_Defined ,Not_Defined
 	    From #TProp
Commit Transaction
Drop Table #TProp
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
Return (0)
