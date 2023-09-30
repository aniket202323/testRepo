CREATE PROCEDURE dbo.spEM_DropTransaction
  @Trans_Id int,
  @User_Id   int
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_DropTransaction',
                 convert(nVarChar(10),@Trans_Id)  + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  -- Begin a transaction.
  --
  BEGIN TRANSACTION
  --
  -- Delete the transaction and its associated items.
  --
  -- Delete the comments. (Changed 04/22/98 - Deletes Causing to much bottle necking)
  --
  UPDATE Comments SET Comment = '',ShouldDelete = 1 
    WHERE Comment_Id IN (SELECT Comment_Id FROM Trans_Properties WHERE Trans_Id = @Trans_Id)
  UPDATE Comments SET Comment = '',ShouldDelete = 1 
    WHERE Comment_Id IN (SELECT Comment_Id FROM Trans_Variables WHERE Trans_Id = @Trans_Id)
  UPDATE Comments SET Comment = '',ShouldDelete = 1 
    WHERE Comment_Id IN (SELECT Comment_Id FROM Transactions WHERE Trans_Id = @Trans_Id)
  DELETE FROM Trans_Properties WHERE Trans_Id = @Trans_Id
  DELETE FROM Trans_Metric_Properties WHERE Trans_Id = @Trans_Id
  DELETE FROM Trans_Variables WHERE Trans_Id = @Trans_Id
  DELETE FROM Trans_Characteristics WHERE Trans_Id = @Trans_Id
  DELETE FROM Trans_Char_Links WHERE Trans_Id = @Trans_Id
  DELETE FROM Trans_Products WHERE Trans_Id = @Trans_Id
  DELETE FROM Transactions WHERE Trans_Id = @Trans_Id
  --
  -- Commit our transaction and return success.
  --
  COMMIT TRANSACTION
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
