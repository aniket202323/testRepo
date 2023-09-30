CREATE PROCEDURE dbo.spEM_DropPHN
  @PHN_Id int,
  @User_Id int
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_DropPHN',
                 convert(nVarChar(10),@PHN_Id) + ','  +  Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --Can not delete Proficy historian (For base variables)
  If @PHN_Id = -1 
 	 return (0)
  Delete From Historian_Option_Data where Hist_Id = @PHN_Id
  DELETE FROM Historians WHERE Hist_Id = @PHN_Id
  --
  -- Return success.
  --
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
