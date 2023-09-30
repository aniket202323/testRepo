/* This sp is called by dbo.spBatch_CreateEvents parameters need to stay in sync*/
CREATE PROCEDURE dbo.spEM_CreateUnitProd
  @PU_Id   int,
  @Prod_Id int,
  @User_Id int
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --
  -- Setup the product as a valid product for this prodcution unit.
  --
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_CreateUnitProd',
                 convert(nVarChar(10),@PU_Id) + ','  + Convert(nVarChar(10), @Prod_Id) + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  INSERT INTO PU_Products(PU_Id, Prod_Id) VALUES(@PU_Id, @Prod_Id)
  --
  -- Return success.
  --
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
