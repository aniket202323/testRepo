CREATE PROCEDURE dbo.spEM_DropTransactionGroup
  @TransGrp_Id int,
  @User_Id   int
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_DropTransactionGroup',
                 convert(nVarChar(10),@TransGrp_Id)  + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Begin a transaction.
  --
  BEGIN TRANSACTION
  --
  -- Delete the transaction group
   UPDATE Transactions SET Transaction_Grp_Id = 1 WHERE Transaction_Grp_Id = @TransGrp_Id 
   DELETE FROM Transaction_Groups WHERE Transaction_Grp_Id = @TransGrp_Id
  --
  -- Commit our transaction and return success.
  --
  COMMIT TRANSACTION
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
