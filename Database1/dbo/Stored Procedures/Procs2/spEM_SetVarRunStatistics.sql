CREATE PROCEDURE dbo.spEM_SetVarRunStatistics
  @Var_Id      int,
  @Var_Reject  bit,
  @Unit_Reject bit,
  @Rank        Smallint_Pct,
  @User_Id int
  AS
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_SetVarRunStatistics',
                Convert(nVarChar(10),@Var_Id) + ','  + 
                Convert(nVarChar(10),@Var_Reject) + ','  + 
                Convert(nVarChar(10),@Unit_Reject) + ','  + 
                Convert(nVarChar(10),@Rank) + ','  + 
                Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  UPDATE Variables_Base
    SET Var_Reject  = @Var_Reject,
        Unit_Reject = @Unit_Reject,
        Rank        = @Rank
    WHERE Var_Id = @Var_Id
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
