CREATE PROCEDURE dbo.spEM_OrderUnit
  @PU_Id      int,
  @NewUnitOrder int,
  @ForceReorder tinyint,
  @User_Id int,
  @ReOrder      tinyint OUTPUT
  AS
  DECLARE @OldUnitOrder int,
          @PL_Id      int,
          @Min_Number   int,
          @Max_Number   int,
          @Total_Count  int,
          @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_OrderUnit',
                Convert(nVarChar(10),@PU_Id) + ','  + 
 	  	 Convert(nVarChar(10), @NewUnitOrder) + ','  + 
 	  	 Convert(nVarChar(10), @ForceReorder) + ','  + 
 	  	 Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Return Codes:
  --
  --   0 = Success
  --
  -- Order the Specification. If this is a force reorder skip insert of variable because the whole tree is being rewritten
  --
  IF @ForceReorder = 0 
     BEGIN
      SELECT @OldUnitOrder =  PU_Order,@PL_Id = PL_Id FROM Prod_Units Where PU_Id = @PU_Id
      IF @OldUnitOrder > @NewUnitOrder
      UPDATE Prod_Units_Base SET PU_Order = PU_Order + 1  
      WHERE PL_Id = @PL_Id AND Pu_Order BETWEEN @NewUnitOrder AND @OldUnitOrder - 1 
      IF @OldUnitOrder < @NewUnitOrder
        UPDATE Prod_Units_Base SET PU_Order = PU_Order - 1 
        WHERE PL_Id = @PL_Id AND  PU_Order BETWEEN @OldUnitOrder + 1 AND  @NewUnitOrder
    END
  UPDATE Prod_Units_Base SET PU_Order = @NewUnitOrder  WHERE PU_Id = @PU_Id
  -- Make sure the order is correct  -  If not Have Enterprise Manager rewrite order of entire branch 
  --
  SELECT @Min_Number = Min(PU_Order), @Max_Number = MAX(PU_Order), @Total_Count = Count(*) 
     FROM Prod_Units Where PL_Id = @PL_Id
  SELECT @ReOrder = 0
  IF @Min_Number <> 1 OR @Max_Number <> @Total_Count
     SELECT @ReOrder = 1
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0,Output_Parameters = convert(nVarChar(10),@ReOrder)  
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
