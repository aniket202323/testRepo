CREATE PROCEDURE dbo.spEM_OrderSpecification
  @Spec_Id      int,
  @NewSpecOrder int,
  @ForceReorder tinyint,
  @User_Id int,
  @ReOrder      tinyint OUTPUT
  AS
  DECLARE @OldSpecOrder int,
          @Prop_Id      int,
          @Min_Number   int,
          @Max_Number   int,
          @Total_Count  int,
          @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_OrderSpecification',
                Convert(nVarChar(10),@Spec_Id) + ','  + 
 	  	 Convert(nVarChar(10), @NewSpecOrder) + ','  + 
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
      SELECT @OldSpecOrder =  Spec_Order,@Prop_Id = Prop_Id FROM Specifications Where Spec_Id = @Spec_Id
      IF @OldSpecOrder > @NewSpecOrder
      UPDATE Specifications SET Spec_Order = Spec_Order + 1  
      WHERE Prop_Id = @Prop_Id AND Spec_Order BETWEEN @NewSpecOrder AND @OldSpecOrder - 1 
      IF @OldSpecOrder < @NewSpecOrder
        UPDATE Specifications SET Spec_Order = Spec_Order - 1 
        WHERE Prop_Id = @Prop_Id AND  Spec_Order BETWEEN @OldSpecOrder + 1 AND  @NewSpecOrder
    END
  UPDATE Specifications SET Spec_Order = @NewSpecOrder  WHERE Spec_Id = @Spec_Id
  -- Make sure the order is correct  -  If not Have Enterprise Manager rewrite order of entire branch 
  --
  SELECT @Min_Number = Min(Spec_Order), @Max_Number = MAX(Spec_Order), @Total_Count = Count(*) 
     FROM Specifications Where Prop_Id = @Prop_Id
  SELECT @ReOrder = 0
  IF @Min_Number <> 1 OR @Max_Number <> @Total_Count
     SELECT @ReOrder = 1
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0,Output_Parameters = convert(nVarChar(10),@ReOrder) 
     WHERE Audit_Trail_Id = @Insert_Id
 RETURN(0)
