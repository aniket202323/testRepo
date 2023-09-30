CREATE PROCEDURE dbo.spEM_CreateProductFamily
  @ProductFamily_Desc      nvarchar(50),
  @User_Id int,
  @Prod_Family_Id        int OUTPUT
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Can't create characteristic.
  --
 	 DECLARE @Insert_Id integer,@Sql nvarchar(1000)
 	 Insert into Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_CreateProductLine',
 	  	  	  	  convert(nVarChar(10),@ProductFamily_Desc) + ','  +  Convert(nVarChar(10), @User_Id),
 	  	  	  	 dbo.fnServer_CmnGetDate(getUTCdate()))
 	 select @Insert_Id = Scope_Identity()
 	 BEGIN TRANSACTION
 	  	 INSERT INTO Product_Family(Product_Family_Desc_Local) VALUES(@ProductFamily_Desc)
 	  	   SELECT @Prod_Family_Id = Product_Family_Id From Product_Family Where Product_Family_Desc_Local = @ProductFamily_Desc
 	  	 IF @Prod_Family_Id IS NULL
 	  	 BEGIN
 	  	  	 ROLLBACK TRANSACTION
 	  	  	 Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 where Audit_Trail_Id = @Insert_Id
 	  	  	 RETURN(1)
 	  	 END
 	  	 If (@@Options & 512) = 0
 	  	 BEGIN
 	  	  	 Update Product_Family set Product_Family_Desc_Global = Product_Family_Desc_Local where Product_Family_Id = @Prod_Family_Id
 	  	 END
 	 COMMIT TRANSACTION
 	 Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0,Output_Parameters = convert(nVarChar(10),@Prod_Family_Id) where Audit_Trail_Id = @Insert_Id
 RETURN(0)
