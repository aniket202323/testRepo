Create Procedure dbo.spEM_AppTransCharacteristics
  @Trans_Id 	 Int,
  @User_Id 	 Int
  AS
  --
  -- Insert new record into the active specifications table and determine the
  -- identity of the newly inserted record.
  --
  DECLARE @Insert_Id 	 Int ,
 	       @RetCode 	 Int,
 	       @PU_Id 	 Int,
 	       @Prod_Id 	 Int,
 	       @Prop_Id     Int,
                   @Char_Id     Int
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_AppTransCharacteristics',
 	  Convert(nVarChar(10),@Trans_Id) + ','  + 
 	  Convert(nVarChar(10), @User_Id),
              dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  Declare Trans_Cursor Cursor
    For Select PU_Id, Prod_Id,Prop_Id,Char_Id  From Trans_Characteristics Where  Trans_Id  = @Trans_Id
    For Read Only
    Open Trans_Cursor
Next_Trans:
    Fetch Next From Trans_Cursor InTo @PU_Id, @Prod_Id,@Prop_Id,@Char_Id
    If @@Fetch_Status = 0 
        Begin
 	 Execute @RetCode = spEM_PutUnitCharacteristic  @PU_Id,  @Prod_Id,  @Prop_Id,  @Char_Id,@User_Id
 	 If @RetCode <> 0 
 	     Begin
 	  	 Update  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 1
 	  	    Where Audit_Trail_Id = @Insert_Id
 	  	 Return(1)
 	     End
 	 GoTo Next_Trans
        End
  Close Trans_Cursor
  Deallocate Trans_Cursor
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
Return (0)
