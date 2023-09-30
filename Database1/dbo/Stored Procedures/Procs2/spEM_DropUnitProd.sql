Create Procedure dbo.spEM_DropUnitProd
  @PU_Id   int,
  @Prod_Id int,
  @User_Id   int
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
DECLARE @DateNow  DateTime,
 	     @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_DropUnitProd',
                 convert(nVarChar(10),@PU_Id) + ','  + Convert(nVarChar(10), @Prod_Id) + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Begin a transaction.
  --
  SELECT @DateNow = dbo.fnServer_CmnGetDate(getUTCdate())
  --
  -- Get all Slave Units
  --
  SELECT PU_Id INTO #TempUnits  FROM Prod_Units WHERE Master_Unit = @PU_Id or PU_Id = @PU_Id
 --
  -- Expire current specs 
  --
  DELETE FROM var_specs 
 	 WHERE Var_Id IN(SELECT Var_id FROM Variables WHERE PU_Id IN (SELECT PU_Id FROM #TempUnits))
          AND Prod_Id = @Prod_Id
          AND Effective_Date > @DateNow
  UPDATE Var_Specs set Expiration_Date = @DateNow,AS_Id = Null
 	 WHERE Var_Id IN(SELECT Var_id FROM Variables WHERE PU_Id IN (SELECT PU_Id FROM #TempUnits))
         AND Prod_Id = @Prod_Id
         AND (Expiration_Date is NULL OR Expiration_Date > @DateNow)
  --
  -- Drop all characteristics associated with this production unit and product.
  --
  DELETE FROM PU_Characteristics WHERE PU_Id = @PU_Id AND Prod_Id = @Prod_Id
  --
  -- Drop this product as a valid Path for this production unit.
  --
DECLARE @Paths Table(PathId Int)
Insert Into @Paths(PathId)
 	 SELECT Path_Id
   	  	 FROM PrdExec_Path_Units
 	  	 WHERE PU_Id = @PU_Id and Is_Schedule_Point = 1
DELETE FROM  PrdExec_Path_Products
 	 WHERE Prod_Id = @Prod_Id and Path_Id In (SELECT PathId FROM @Paths)
  --
  -- Drop this product as a valid product for this production unit.
  --
  DELETE FROM PU_Products WHERE PU_Id = @PU_Id AND Prod_Id = @Prod_Id
  --
  -- Commit the transaction and return success.
  --
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
