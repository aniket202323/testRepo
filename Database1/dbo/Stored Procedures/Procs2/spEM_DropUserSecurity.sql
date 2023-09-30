CREATE PROCEDURE dbo.spEM_DropUserSecurity
  @Security_Id int,
  @User_Id   int
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
 	 VALUES (1,@User_Id,'spEM_DropUserSecurity',
                 convert(nVarChar(10),@Security_Id) + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  DELETE FROM User_Security WHERE Security_Id = @Security_Id
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
