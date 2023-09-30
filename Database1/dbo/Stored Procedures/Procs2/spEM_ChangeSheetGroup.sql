CREATE PROCEDURE dbo.spEM_ChangeSheetGroup
  @Sheet_Id int,
  @Sheet_Grp_Id int,
  @User_Id int
  AS
DECLARE @Insert_Id integer 
  --
  -- Return Codes:
  --
  --   0 = Success
  --
Insert into Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_ChangeSheetGroup',  convert(nVarChar(10),@Sheet_Id) + ','  +  convert(nVarChar(10),@Sheet_Grp_Id) + ','  +  convert(nVarChar(10),@User_Id) ,dbo.fnServer_CmnGetDate(getUTCdate()))
select @Insert_Id = Scope_Identity()
  UPDATE Sheets SET Sheet_Group_Id = @Sheet_Grp_Id WHERE Sheet_Id = @Sheet_Id
  Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0 where Audit_Trail_Id = @Insert_Id
RETURN(0)
