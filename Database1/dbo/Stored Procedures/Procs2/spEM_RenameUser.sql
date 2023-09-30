﻿CREATE PROCEDURE dbo.spEM_RenameUser
  @User_Id  int,
  @Username nvarchar(30),
  @User2_Id int
  AS
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User2_Id,'spEM_RenameUser',
                Convert(nVarChar(10),@User_Id) + ','  + 
                @Username + ','  + 
                Convert(nVarChar(10),@User2_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Return Code: 0 = Success. 
  --
  UPDATE Users_Base SET Username = @Username WHERE User_Id = @User_Id
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)