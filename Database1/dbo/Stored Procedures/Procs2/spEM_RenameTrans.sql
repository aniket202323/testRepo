CREATE PROCEDURE dbo.spEM_RenameTrans
  @Trans_Id   int,
  @Trans_Desc nvarchar(50),
  @User_Id int
  AS
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_RenameTrans',
                Convert(nVarChar(10),@Trans_Id) + ','  + 
                @Trans_Desc + ','  + 
                Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Return Codes:
  --
  --   0 = Success
  --
  UPDATE Transactions SET Trans_Desc = @Trans_Desc WHERE Trans_Id = @Trans_Id
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
