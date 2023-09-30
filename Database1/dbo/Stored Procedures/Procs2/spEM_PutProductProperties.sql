CREATE PROCEDURE dbo.spEM_PutProductProperties
  @Prod_Id       int,
  @EventLevel  	  Int,
  @ProductLevel  Int,
  @User_Id       int,
  @Serialized    int
 AS
  --
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_PutProductProperties',
                Convert(nVarChar(10),@Prod_Id) + ','  + 
 	  	  	  	 Convert(nVarChar(10),@EventLevel) + ','  + 
 	  	  	  	 Convert(nVarChar(10),@ProductLevel) + ','  + 
 	  	  	  	 Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  Update Products set Event_Esignature_Level = case when @EventLevel = 0 then Null Else @EventLevel End,
 	   Product_Change_Esignature_Level = case when @ProductLevel = 0 then Null Else @ProductLevel End
 	  where Prod_Id = @Prod_Id
  IF @Serialized = 1
  BEGIN
     DECLARE @Serialize Int
     SELECT @Serialize = isSerialized from Product_Serialized where product_id = @Prod_Id 	  
     If @Serialize is null
        INSERT INTO Product_Serialized(product_id,isSerialized) VALUES(@Prod_Id,@Serialized) 	  	      
 	  else
 	  	 Update Product_Serialized set isSerialized = 1 where product_id = @Prod_Id
  END
  ELSE
  BEGIN
 	 DECLARE @Serialize1 Int
 	 SELECT @Serialize1 = isSerialized from Product_Serialized where product_id = @Prod_Id 	  
     If @Serialize1 is not null
 	  	 Update Product_Serialized set isSerialized = 0 where product_id = @Prod_Id  
  END
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
