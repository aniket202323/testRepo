CREATE PROCEDURE dbo.spEM_DropProductFamily
  @Product_Family_Id int,
  @User_Id int
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --
  -- Delete the product group data.
  --
  DECLARE @Insert_Id integer 
  If @Product_Family_Id = 1 Return(1)
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_DropProductFamily',
                 convert(nVarChar(10),@Product_Family_Id)  + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  BEGIN TRANSACTION
  Update Products Set Product_Family_Id = 1 Where Product_Family_Id = @Product_Family_Id
  DELETE FROM Product_Family WHERE Product_Family_Id = @Product_Family_Id
  COMMIT TRANSACTION
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
