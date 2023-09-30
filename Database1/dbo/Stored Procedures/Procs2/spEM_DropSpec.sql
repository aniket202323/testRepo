CREATE PROCEDURE dbo.spEM_DropSpec
  @Spec_Id int,
  @User_Id int
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --
  -- Begin a transaction.
  --
  DECLARE @Old_Order int,
                    @Prop_Id    int,
                    @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_DropSpec',
                 convert(nVarChar(10),@Spec_Id)  + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  BEGIN TRANSACTION
  --
  -- Drop all active specifications and transaction properties
  -- involving the specification. Retire All Var Specs
  --
  Declare @AS_Id int
  SELECT AS_Id INTO #DS_VS FROM Active_Specs WHERE Spec_Id = @Spec_Id
  DECLARE AS_Cursor CURSOR FOR SELECT AS_Id FROM #DS_VS
  FOR READ ONLY
  OPEN AS_Cursor
  Fetch_Next_Active_Spec:
  FETCH NEXT FROM AS_Cursor INTO @AS_Id
  IF @@FETCH_STATUS = 0
    BEGIN
      UPDATE Var_Specs SET AS_Id = Null WHERE AS_Id = @AS_Id
      GOTO Fetch_Next_Active_Spec
    END
  ELSE IF @@FETCH_STATUS <> -1
    BEGIN
      RAISERROR('Fetch error for AS_Cursor (@@FETCH_STATUS = %d).', 11, -1,
       @@FETCH_STATUS)
      DEALLOCATE AS_Cursor
      DROP TABLE #DS_VS
      UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1
 	  WHERE Audit_Trail_Id = @Insert_Id
     RETURN(1)
    END
  DEALLOCATE AS_Cursor
  DROP TABLE #DS_VS
  --
  --
  DELETE FROM Active_Specs WHERE Spec_Id = @Spec_Id
  DELETE FROM Trans_Properties WHERE Spec_Id = @Spec_Id
  DELETE FROM Trans_Metric_Properties WHERE Spec_Id = @Spec_Id
  --
  -- Remove this specification from and variables that reference
  -- it.
  --
  UPDATE Variables_Base SET Spec_Id = NULL WHERE Spec_Id = @Spec_Id
  UPDATE PrdExec_Inputs SET Alternate_Spec_Id = NULL WHERE Alternate_Spec_Id = @Spec_Id
  UPDATE PrdExec_Inputs SET Primary_Spec_Id = NULL WHERE Primary_Spec_Id = @Spec_Id
  UPDATE PrdExec_Path_Inputs SET Alternate_Spec_Id = NULL WHERE Alternate_Spec_Id = @Spec_Id
  UPDATE PrdExec_Path_Inputs SET Primary_Spec_Id = NULL WHERE Primary_Spec_Id = @Spec_Id
  UPDATE Prod_Units SET Downtime_Percent_Specification = NULL WHERE Downtime_Percent_Specification = @Spec_Id
  UPDATE Prod_Units SET Efficiency_Percent_Specification = NULL WHERE Efficiency_Percent_Specification = @Spec_Id
  UPDATE Prod_Units SET Production_Rate_Specification = NULL WHERE Production_Rate_Specification = @Spec_Id
  UPDATE Prod_Units SET Waste_Percent_Specification = NULL WHERE Waste_Percent_Specification = @Spec_Id
  --
  -- Delete the actual specification.
  --
  SELECT  @Old_Order = Spec_Order,@Prop_Id = Prop_Id FROM Specifications WHERE Spec_Id = @Spec_Id
  --
  DELETE FROM Specifications WHERE Spec_Id = @Spec_Id
  UPDATE Specifications Set Spec_Order = Spec_Order - 1 Where Spec_Order > @Old_Order AND Prop_Id = @Prop_Id
  --
  -- Commit our transaction and return success.
  --
  COMMIT TRANSACTION
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
