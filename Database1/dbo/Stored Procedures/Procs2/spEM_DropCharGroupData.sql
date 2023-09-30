CREATE PROCEDURE dbo.spEM_DropCharGroupData
  @CGD_Id int,
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
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_DropCharGroupData',
                 convert(nVarChar(10),@CGD_Id) + ','   + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  DELETE FROM Characteristic_Group_Data WHERE CGD_Id = @CGD_Id
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
