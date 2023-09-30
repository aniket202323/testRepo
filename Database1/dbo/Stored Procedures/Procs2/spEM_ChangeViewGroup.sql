CREATE PROCEDURE dbo.spEM_ChangeViewGroup
  @View_Id int,
  @View_Group_Id int,
  @User_Id int
  AS
DECLARE @Insert_Id integer 
  --
  -- Return Codes:
  --
  --   0 = Success
  --
 Insert into Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_ChangeViewGroup',  convert(nVarChar(10),@View_Id) + ','  +  convert(nVarChar(10),@View_Group_Id) + ','  +  convert(nVarChar(10),@User_Id) ,dbo.fnServer_CmnGetDate(getUTCdate()))
 Select @Insert_Id = Scope_Identity()
 Update Views SET View_Group_Id = @View_Group_Id  WHERE View_Id = @View_Id
 Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0 where Audit_Trail_Id = @Insert_Id
RETURN(0)
