CREATE PROCEDURE dbo.spEM_DropProdGroupData
  @PGD_Id int,
  @User_Id int
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_DropProdGroupData',
                 convert(nVarChar(10),@PGD_Id)  + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Delete the product group data.
  --
  DELETE FROM Product_Group_Data WHERE PGD_Id = @PGD_Id
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
