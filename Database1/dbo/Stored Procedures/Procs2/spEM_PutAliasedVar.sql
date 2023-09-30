CREATE PROCEDURE dbo.spEM_PutAliasedVar
  @Dst_Var_Id  int,
  @Var_Id       int,
  @Is_Dependant bit,
  @User_Id int
  AS
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_PutAliasedVar',
                Convert(nVarChar(10),@Dst_Var_Id) + ','  + 
                Convert(nVarChar(10),@Var_Id) + ','  + 
                Convert(nVarChar(10),@Is_Dependant) + ','  + 
 	    Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
--
-- This Put SP is also used to delete via the dependant bit.
   DELETE FROM Variable_Alias WHERE (Src_Var_Id = @Var_Id) AND (Dst_Var_Id = @Dst_Var_Id)
--
   IF @Is_Dependant = 1  INSERT Variable_Alias(Src_Var_Id,Dst_Var_Id) VALUES (@Var_Id,@Dst_Var_Id)
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
RETURN(0)
