CREATE PROCEDURE dbo.spEM_ChangeVariableGroup
  @Var_Id int,
  @PUG_Id int,
  @User_Id int
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --
  DECLARE @Insert_Id integer 
Insert into Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_ChangeVariableGroup',
                convert(nVarChar(10),@Var_Id) + ','  + Convert(nVarChar(10), @PUG_Id) + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
select @Insert_Id = Scope_Identity()
UPDATE Variables_Base SET PUG_Id = @PUG_Id WHERE Var_Id = @Var_Id
Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0 where Audit_Trail_Id = @Insert_Id
  RETURN(0)
