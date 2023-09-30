CREATE PROCEDURE dbo.spEM_ChangeApprovedGroup
  @Trans_Id int,
  @Trans_Grp_Id int,
  @User_Id int
  AS
DECLARE @Insert_Id integer 
  --
  -- Return Codes:
  --
  --   0 = Success
  --
Insert into Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_ChangeApprovedGroup',  convert(nVarChar(10),@Trans_Id) + ','  +  convert(nVarChar(10),@Trans_Grp_Id) + ','  +  convert(nVarChar(10),@User_Id) ,dbo.fnServer_CmnGetDate(getUTCdate()))
select @Insert_Id = Scope_Identity()
  UPDATE Transactions SET Transaction_Grp_Id = @Trans_Grp_Id WHERE Trans_Id = @Trans_Id
  Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0 where Audit_Trail_Id = @Insert_Id
RETURN(0)
