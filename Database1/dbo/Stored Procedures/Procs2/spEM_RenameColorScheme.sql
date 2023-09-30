CREATE PROCEDURE dbo.spEM_RenameColorScheme
  @CS_Id   int,
  @CS_Desc nvarchar(50),
  @User_Id int
  AS
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_RenameColorScheme',
                Convert(nVarChar(10),@CS_Id) + ','  + 
                @CS_Desc + ','  + 
 	  	 Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Return Code: 0 = Success. 
  --
  UPDATE Color_Scheme SET CS_Desc = @CS_Desc WHERE CS_Id = @CS_Id
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
