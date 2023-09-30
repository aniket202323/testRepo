CREATE PROCEDURE dbo.spEM_RenameProductFamily
  @Product_Family_Id   int,
  @Product_Desc nvarchar(50),
  @User_Id int
  AS
  DECLARE @Insert_Id integer
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_RenameProductFamily',Convert(nVarChar(10),@Product_Family_Id) + ','  + 
                @Product_Desc + ','  + Convert(nVarChar(10),@User_Id),dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Return Code: 0 = Success. 
  --
 	 If (@@Options & 512) = 0
 	  	 Update Product_Family Set Product_Family_Desc_Global = @Product_Desc Where Product_Family_Id = @Product_Family_Id
 	 Else
 	  	 Update Product_Family Set Product_Family_Desc_Local = @Product_Desc Where Product_Family_Id = @Product_Family_Id
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
