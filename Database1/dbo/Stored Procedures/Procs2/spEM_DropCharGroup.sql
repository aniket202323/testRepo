CREATE PROCEDURE dbo.spEM_DropCharGroup
  @Char_Grp_Id int,
  @User_Id int
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --
  -- Delete the Characteristic group data.
  --
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_DropCharGroup',
                 convert(nVarChar(10),@Char_Grp_Id) + ','   + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  BEGIN TRANSACTION
  DELETE FROM Characteristic_Group_Data WHERE Characteristic_Grp_Id = @Char_Grp_Id
  DELETE FROM Characteristic_Groups WHERE Characteristic_Grp_Id = @Char_Grp_Id
  COMMIT TRANSACTION
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
