CREATE PROCEDURE dbo.spEM_ChangeUserAccess
  @Security_Id  int,
  @Access_Level tinyint,
  @User_Id int
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --
 DECLARE @Insert_Id integer 
Insert into Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_ChangeUserAccess',
                convert(nVarChar(10),@Security_Id) + ','  + Convert(nVarChar(10), @Access_Level) + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
select @Insert_Id = Scope_Identity()
 UPDATE User_Security SET Access_Level = @Access_Level WHERE Security_Id = @Security_Id
Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0 where Audit_Trail_Id = @Insert_Id
 RETURN(0)
