CREATE PROCEDURE dbo.spEM_PutPropertyData
  @Prop_Id       int,
  @ProdFamId  	  Int,
  @PropagateChars Int,
  @User_Id       int
 AS
  --
  DECLARE @Insert_Id integer,@OldProdFamId Int
  Select @OldProdFamId = Product_Family_Id From Product_Properties Where Prop_Id = @Prop_Id
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_PutPropertyData',
                Convert(nVarChar(10),@Prop_Id) + ','  + 
 	  	  	  	 Convert(nVarChar(10),@ProdFamId) + ','  + 
 	  	  	  	 Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  Update Product_Properties set Product_Family_Id = @ProdFamId,Auto_Sync_Chars = @PropagateChars
 	  where Prop_Id = @Prop_Id
  If  @PropagateChars = 1
 	 Begin
 	   Declare @Desc nvarchar(50),@Char_Id Int,@Prod_Id Int
 	   Declare PropCursor cursor For 
 	  	 Select Prod_Code,Prod_Id From Products where Product_Family_Id = @ProdFamId and Prod_Id > 1
 	   Open PropCursor
 	 FetchLoop:
 	   Fetch Next From PropCursor Into @Desc,@Prod_Id
 	   If @@Fetch_Status = 0
 	  	 Begin
 	  	   Select @Char_Id = Null
 	  	   Select @Char_Id = Char_Id from Characteristics where Char_Desc = @Desc and Prop_Id = @Prop_Id
 	  	   If @Char_Id is null
 	  	  	 Begin
 	  	  	   execute spEM_CreateChar  @Desc,@Prop_Id, @User_Id,@Char_Id  OUTPUT
 	  	  	 End
 	  	   GoTo FetchLoop
 	  	 End
 	   Close PropCursor
 	   Deallocate PropCursor
 	 End
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
