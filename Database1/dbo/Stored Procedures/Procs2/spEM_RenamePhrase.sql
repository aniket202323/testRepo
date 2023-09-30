CREATE PROCEDURE dbo.spEM_RenamePhrase
  @Phrase_Id        int,
  @New_Phrase_Value nvarchar(50),
  @HistoryRename bit,
  @User_Id int
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Error: Can't find phrase.
  --
  -- Declare local variables.
  --
  DECLARE @Old_Phrase_Value nvarchar(25),
          @Data_Type_Id     int
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_RenamePhrase',
                Convert(nVarChar(10),@Phrase_Id) + ','  + 
                @New_Phrase_Value + ','  + 
                Convert(nVarChar(10),@HistoryRename) + ','  + 
 	  	 Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Begin a transaction. All these changes must happen atomically.
  --
  BEGIN TRANSACTION
  --
  -- Initialize local variables.
  --
  SELECT @Old_Phrase_Value = Phrase_Value, @Data_Type_Id = Data_Type_Id
    FROM Phrase WHERE Phrase_Id = @Phrase_Id
  IF @Data_Type_Id IS NULL
  BEGIN
      ROLLBACK TRANSACTION
      UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 WHERE Audit_Trail_Id = @Insert_Id
      RETURN(1)
  END
  --
  -- Change any instances of the phrase in the test or test history tables.
  --
    --
    -- Change any instances of the phrase in the active specifications table.
    --
Declare @SpecId Int
 	 Create Table #Specs (Spec_Id Int)
 	 Insert Into #Specs
 	  	 Select Spec_Id From Specifications
 	  	 Where Data_Type_Id = @Data_Type_Id
Declare SpecCursor Cursor For 
 	 Select Spec_Id From #Specs
 	 For Read Only
Open SpecCursor
SpecCursorLoop:
Fetch next from SpecCursor INto @SpecId
  If @@Fetch_Status = 0
 	 Begin
      Declare @AsID Int,@L_Entry nVarChar(25),@L_Reject nVarChar(25),@L_Warning nVarChar(25),@L_User nVarChar(25),@Target nvarchar(25),
 	      @U_User nVarChar(25),@U_Warning nVarChar(25),@U_Reject nVarChar(25),@U_Entry nVarChar(25),@L_Control nVarChar(25),@T_Control nVarChar(25),@U_Control nVarChar(25)
 	  	 Declare ASCursor Cursor For 
 	  	  	 Select AS_Id,L_Entry,L_Reject,L_Warning,L_User,Target,U_User,U_Warning,U_Reject,U_Entry,L_Control,T_Control,U_Control
 	  	  	  From Active_Specs
 	  	  	  Where Spec_Id = @SpecId
 	  	  	 For Read Only
 	  	 Open ASCursor
 	  	 ASCursorLoop:
 	  	 Fetch next from ASCursor INto  @AsID,@L_Entry,@L_Reject ,@L_Warning ,@L_User ,@Target , @U_User,@U_Warning,@U_Reject,@U_Entry,@L_Control,@T_Control,@U_Control
 	  	   If @@Fetch_Status = 0
 	  	  	 Begin
 	  	  	    If (@L_Entry = @Old_Phrase_Value)
      	  	  	  	 UPDATE Active_Specs SET L_Entry = @New_Phrase_Value WHERE AS_Id =@AsID
 	  	  	    If (@L_Reject = @Old_Phrase_Value)
      	  	  	  	 UPDATE Active_Specs SET L_Reject = @New_Phrase_Value WHERE AS_Id =@AsID
 	  	  	    If (@L_Warning = @Old_Phrase_Value)
      	  	  	  	 UPDATE Active_Specs SET L_Warning = @New_Phrase_Value WHERE AS_Id =@AsID
 	  	  	    If (@L_User = @Old_Phrase_Value)
      	  	  	  	 UPDATE Active_Specs SET L_User = @New_Phrase_Value WHERE AS_Id =@AsID
 	  	  	    If (@Target = @Old_Phrase_Value)
      	  	  	  	 UPDATE Active_Specs SET Target = @New_Phrase_Value WHERE AS_Id =@AsID
 	  	  	    If (@U_User = @Old_Phrase_Value)
      	  	  	  	 UPDATE Active_Specs SET U_User = @New_Phrase_Value WHERE AS_Id =@AsID
 	  	  	    If (@U_Warning = @Old_Phrase_Value)
      	  	  	  	 UPDATE Active_Specs SET U_Warning = @New_Phrase_Value WHERE AS_Id =@AsID
 	  	  	    If (@U_Reject = @Old_Phrase_Value)
      	  	  	  	 UPDATE Active_Specs SET U_Reject = @New_Phrase_Value WHERE AS_Id =@AsID
 	  	  	    If (@U_Entry = @Old_Phrase_Value)
      	  	  	  	 UPDATE Active_Specs SET U_Entry = @New_Phrase_Value WHERE AS_Id =@AsID
 	  	  	    If (@U_Entry = @Old_Phrase_Value)
      	  	  	  	 UPDATE Active_Specs SET U_Entry = @New_Phrase_Value WHERE AS_Id =@AsID
 	  	  	    If (@L_Control = @Old_Phrase_Value)
      	  	  	  	 UPDATE Active_Specs SET L_Control = @New_Phrase_Value WHERE AS_Id =@AsID
 	  	  	    If (@T_Control = @Old_Phrase_Value)
      	  	  	  	 UPDATE Active_Specs SET T_Control = @New_Phrase_Value WHERE AS_Id =@AsID
 	  	  	    If (@U_Control = @Old_Phrase_Value)
      	  	  	  	 UPDATE Active_Specs SET U_Control = @New_Phrase_Value WHERE AS_Id =@AsID
 	    	  	 Goto ASCursorLoop
 	  	   End
 	  	   Close ASCursor
 	  	   Deallocate ASCursor
 	   Goto SpecCursorLoop
 	 End
 	 close SpecCursor
 	 Deallocate SpecCursor
Drop Table #Specs
Declare @VarId Int
 	 Create Table #Vars (Var_Id Int)
 	 Insert Into #Vars
 	  	 Select Var_Id From Variables
 	  	 Where Data_Type_Id = @Data_Type_Id
Declare VarCursor Cursor For 
 	 Select Var_Id From #Vars
 	 For Read Only
Open VarCursor
VarCursorLoop:
Fetch next from VarCursor INto @VarId
  If @@Fetch_Status = 0
 	 Begin
      Declare @VSID Int
 	   Declare VSCursor Cursor For 
 	  	  	 Select VS_Id,L_Entry,L_Reject,L_Warning,L_User,Target,U_User,U_Warning,U_Reject,U_Entry,L_Control,T_Control,U_Control
 	  	  	  From Var_Specs
 	  	  	  Where Var_Id = @VarId
 	  	  	 For Read Only
 	  	 Open VSCursor
 	  	 VSCursorLoop:
 	  	 Fetch next from VSCursor INto  @VSID,@L_Entry,@L_Reject ,@L_Warning ,@L_User ,@Target , @U_User,@U_Warning,@U_Reject,@U_Entry,@L_Control,@T_Control,@U_Control
 	  	   If @@Fetch_Status = 0
 	  	  	 Begin
 	  	  	    If (@L_Entry = @Old_Phrase_Value)
      	  	  	  	 UPDATE Var_Specs SET L_Entry = @New_Phrase_Value WHERE VS_Id = @VSID
 	  	  	    If (@L_Reject = @Old_Phrase_Value)
      	  	  	  	 UPDATE Var_Specs SET L_Reject = @New_Phrase_Value WHERE VS_Id =@VSID
 	  	  	    If (@L_Warning = @Old_Phrase_Value)
      	  	  	  	 UPDATE Var_Specs SET L_Warning = @New_Phrase_Value WHERE VS_Id =@VSID
 	  	  	    If (@L_User = @Old_Phrase_Value)
      	  	  	  	 UPDATE Var_Specs SET L_User = @New_Phrase_Value WHERE VS_Id =@VSID
 	  	  	    If (@Target = @Old_Phrase_Value)
      	  	  	  	 UPDATE Var_Specs SET Target = @New_Phrase_Value WHERE VS_Id =@VSID
 	  	  	    If (@U_User = @Old_Phrase_Value)
      	  	  	  	 UPDATE Var_Specs SET U_User = @New_Phrase_Value WHERE VS_Id =@VSID
 	  	  	    If (@U_Warning = @Old_Phrase_Value)
      	  	  	  	 UPDATE Var_Specs SET U_Warning = @New_Phrase_Value WHERE VS_Id =@VSID
 	  	  	    If (@U_Reject = @Old_Phrase_Value)
      	  	  	  	 UPDATE Var_Specs SET U_Reject = @New_Phrase_Value WHERE VS_Id =@VSID
 	  	  	    If (@U_Entry = @Old_Phrase_Value)
      	  	  	  	 UPDATE Var_Specs SET U_Entry = @New_Phrase_Value WHERE VS_Id =@VSID
 	  	  	    If (@L_Control = @Old_Phrase_Value)
      	  	  	  	 UPDATE Var_Specs SET L_Control = @New_Phrase_Value WHERE VS_Id =@VSID
 	  	  	    If (@T_Control = @Old_Phrase_Value)
      	  	  	  	 UPDATE Var_Specs SET T_Control = @New_Phrase_Value WHERE VS_Id =@VSID
 	  	  	    If (@U_Control = @Old_Phrase_Value)
      	  	  	  	 UPDATE Var_Specs SET U_Control = @New_Phrase_Value WHERE VS_Id =@VSID
 	    	  	 Goto VSCursorLoop
 	  	   End
 	   Close VSCursor
 	   Deallocate VSCursor
 	   GoTo VarCursorLoop
 	 End
    Close VarCursor
    Deallocate VarCursor
  --
  -- Rename the phrase.
  --
  UPDATE Phrase SET Old_Phrase   = @Old_Phrase_Value, Changed_Date = dbo.fnServer_CmnGetDate(getUTCdate()) 
    WHERE Phrase_Id = @Phrase_Id
  UPDATE Phrase SET Phrase_Value = @New_Phrase_Value
    WHERE Phrase_Id = @Phrase_Id
  --
  -- Commit the transaction and return success.
  --
  COMMIT TRANSACTION
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
