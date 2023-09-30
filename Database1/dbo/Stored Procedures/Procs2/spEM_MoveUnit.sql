CREATE PROCEDURE dbo.spEM_MoveUnit
  @PU_Id int,
  @PL_Id int,
  @User_Id int
  AS
  --
  -- Begin a transaction.
  --
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_MoveUnit',
                 convert(nVarChar(10),@PU_Id) + ','  + Convert(nVarChar(10), @PL_Id) + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  BEGIN TRANSACTION
  --
  -- Determine the units that will be moved.
  --
  SELECT PU_Id FROM Prod_Units WHERE PU_Id = @PU_Id OR Master_Unit = @PU_Id
  --
  -- MOve the production units to the specified production line.
  --
  UPDATE Prod_Units SET PL_Id = @PL_Id WHERE PU_Id = @PU_Id OR Master_Unit = @PU_Id
  --
  -- Commit the transaction.
  --
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  COMMIT TRANSACTION
