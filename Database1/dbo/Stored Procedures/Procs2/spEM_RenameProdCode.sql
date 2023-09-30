CREATE PROCEDURE dbo.spEM_RenameProdCode
  @Prod_Id   int,
  @Prod_Code nvarchar(25),
  @User_Id int
  AS
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_RenameProdCode',
                Convert(nVarChar(10),@Prod_Id) + ','  + 
                @Prod_Code + ','  + 
 	  	 Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Return Codes:
  --
  --   0 = Success
  --
  Declare @OldProdCode nVarChar(25)
  Select @OldProdCode = Prod_Code From Products WHERE Prod_Id = @Prod_Id
  UPDATE Products SET Prod_Code = @Prod_Code WHERE Prod_Id = @Prod_Id
  Declare @PropId Int,@Char_Id Int,@Prod_Family_Id Int,@NewCharId Int
  Select @Prod_Family_Id = Product_Family_Id From Products where prod_Id = @Prod_Id
  Declare ProductCursor Cursor
   	 for Select Prop_Id From Product_Properties where Product_Family_Id = @Prod_Family_Id and Auto_Sync_Chars = 1
  Open ProductCursor
ProductCursorLoop:
  Fetch next from ProductCursor Into @PropId
  If @@Fetch_Status = 0
 	 Begin
 	   Select @Char_Id = Null
 	   Select @Char_Id = Char_Id from Characteristics where Char_Desc  = @OldProdCode and Prop_Id = @PropId
 	   If @Char_Id is Not null
 	  	 Begin
 	  	   Select @NewCharId = Null
 	    	   Select @NewCharId = Char_Id from Characteristics where Char_Desc = @Prod_Code and Prop_Id = @PropId
 	  	   If @NewCharId is null
 	  	    	 execute spEM_RenameChar  @Char_Id,@Prod_Code, @User_Id
 	  	 End
 	   GoTo ProductCursorLoop
 	 End
  Close ProductCursor
  Deallocate ProductCursor
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
