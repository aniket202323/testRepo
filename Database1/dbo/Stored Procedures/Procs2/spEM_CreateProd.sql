/* This sp is called by dbo.spBatch_ProcessMaterialMovement parameters need to stay in sync*/
/* This sp is called by dbo.spBatch_ProcessProcedureReport parameters need to stay in sync*/
CREATE PROCEDURE dbo.spEM_CreateProd
  @Prod_Desc      nvarchar(50),
  @Prod_Code      nvarchar(25),
  @Prod_Family_Id int,
  @User_Id        int,  
  @Prod_Id        int OUTPUT,
  @Serialized 	   int=0 OUTPUT
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Can't create product.
  --
  BEGIN TRANSACTION
DECLARE @Insert_Id integer,@Sql nvarchar(1000)
  Insert into Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_CreateProd',
                 @Prod_Desc  + ','  + Convert(nVarChar(25), @Prod_Code) + ','  + 
 	      Convert(nVarChar(10), @Prod_Family_Id)  + ','  + 
 	      Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  select @Insert_Id = Scope_Identity()
  INSERT INTO Products(Prod_Desc, Prod_Code,Product_Family_Id)
 	 VALUES(@Prod_Desc,@Prod_Code,@Prod_Family_Id)
  SELECT @Prod_Id = Prod_Id FROM Products WHERE Prod_Code = @Prod_Code
  IF @Prod_Id IS NULL
    BEGIN
      ROLLBACK TRANSACTION
     Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 where Audit_Trail_Id = @Insert_Id
     RETURN(1)
    END
  COMMIT TRANSACTION
  Declare @PropId Int,@Char_Id Int
  Declare ProductCursor Cursor
   	 for Select Prop_Id From Product_Properties where Product_Family_Id = @Prod_Family_Id and Auto_Sync_Chars = 1
  Open ProductCursor
ProductCursorLoop:
  Fetch next from ProductCursor Into @PropId
  If @@Fetch_Status = 0
 	 Begin
 	   Select @Char_Id = Null
 	   Select @Char_Id = Char_Id from Characteristics where Char_Desc = @Prod_Code and Prop_Id = @PropId
 	   If @Char_Id is null
 	  	 Begin
 	  	   execute spEM_CreateChar  @Prod_Code,@PropId, @User_Id,@Char_Id  OUTPUT
 	  	 End
 	   GoTo ProductCursorLoop
 	 End
  Close ProductCursor
  Deallocate ProductCursor
  IF @Serialized = 1
  BEGIN
 	 INSERT INTO Product_Serialized(product_id,isSerialized) VALUES(@Prod_Id,@Serialized) 	  	      
  END
  Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0,Output_Parameters = convert(nVarChar(10),@Prod_Id) where Audit_Trail_Id = @Insert_Id
  RETURN(0)
