CREATE PROCEDURE dbo.spEM_DropColorScheme
  @CS_Id int,
  @User_Id int
 AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --
  -- Delete the color scheme.
  --
 DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_DropColorScheme',
                 convert(nVarChar(10),@CS_Id)  + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
 DELETE FROM Color_Scheme_Data WHERE CS_Id = @CS_Id
 DELETE FROM Color_Scheme WHERE CS_Id = @CS_Id
  --
  -- Return success.
  --
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
