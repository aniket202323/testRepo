CREATE PROCEDURE dbo.spEM_RenameTransactionGroup
  @TransGroup_Id   int,
  @Trans_Desc nvarchar(50),
  @User_Id int
  AS
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_RenameTransactionGroup',
                Convert(nVarChar(10),@TransGroup_Id) + ','  + 
                @Trans_Desc + ','  + 
                Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Return Code: 0 = Success. 
  --
  UPDATE Transaction_Groups SET Transaction_Grp_Desc  = @Trans_Desc WHERE Transaction_Grp_Id = @TransGroup_Id
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
