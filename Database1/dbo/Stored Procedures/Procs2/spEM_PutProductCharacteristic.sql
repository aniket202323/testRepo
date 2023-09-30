CREATE PROCEDURE dbo.spEM_PutProductCharacteristic
  @Prod_Id       int,
  @Char_Id       int,
  @Prop_Id 	  int,
  @User_Id       int
 AS
  --
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_PutProductCharacteristic',
                Convert(nVarChar(10),@Prod_Id) + ','  + 
 	  	 Convert(nVarChar(10),@Char_Id) + ','  + 
 	  	 Convert(nVarChar(10),@Prop_Id) + ','  + 
 	  	 Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  Delete From Product_Characteristic_Defaults Where Prop_Id = @Prop_Id and Prod_Id = @Prod_Id
  If @Char_Id > 0
    Insert Into  Product_Characteristic_Defaults (Prod_Id,Prop_Id,Char_Id) Values (@Prod_Id,@Prop_Id,@Char_Id)
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
