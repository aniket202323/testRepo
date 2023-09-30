CREATE PROCEDURE dbo.spEM_OrderEventHeaders
  @ERL_Id      int,
  @NewHeaderOrder int,
  @ForceReorder tinyint,
  @User_Id int,
  @ReOrder      tinyint OUTPUT
  AS
  DECLARE @OldHeaderOrder int,
          @TreeName_Id      int,
          @Min_Number   int,
          @Max_Number   int,
          @Total_Count  int,
          @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_OrderEventHeaders',
                Convert(nVarChar(10),@ERL_Id) + ','  + 
 	  	 Convert(nVarChar(10), @NewHeaderOrder) + ','  + 
 	  	 Convert(nVarChar(10), @ForceReorder) + ','  + 
 	  	 Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Return Codes:
  --
  --   0 = Success
  --
  -- Order the Reason Level Headers.
  -- If this is a force reorder skip insert of variable because the whole tree is being rewritten
  --
  IF @ForceReorder = 0 
     BEGIN
      SELECT @OldHeaderOrder =  Reason_Level,@TreeName_Id = Tree_Name_Id
        FROM Event_Reason_Level_Headers Where Event_Reason_Level_Header_Id = @ERL_Id
      IF @OldHeaderOrder > @NewHeaderOrder
      UPDATE Event_Reason_Level_Headers SET Reason_Level = Reason_Level + 1  
         WHERE Tree_Name_Id = @TreeName_Id AND Reason_Level BETWEEN @NewHeaderOrder AND @OldHeaderOrder - 1 
      IF @OldHeaderOrder < @NewHeaderOrder
        UPDATE Event_Reason_Level_Headers SET Reason_Level = Reason_Level - 1 
        WHERE Tree_Name_Id = @TreeName_Id AND  Reason_Level BETWEEN @OldHeaderOrder + 1 AND  @NewHeaderOrder
    END
  UPDATE Event_Reason_Level_Headers SET Reason_Level = @NewHeaderOrder  WHERE Event_Reason_Level_Header_Id = @ERL_Id
  -- Make sure the order is correct  -  If not Have Enterprise Manager rewrite order of entire branch 
  --
  SELECT @Min_Number = Min(Reason_Level ), @Max_Number = MAX(Reason_Level ), @Total_Count = Count(*) 
     FROM Event_Reason_Level_Headers Where Tree_Name_Id = @TreeName_Id
  SELECT @ReOrder = 0
  IF @Min_Number <> 1 OR @Max_Number <> @Total_Count
     SELECT @ReOrder = 1
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0,Output_Parameters = convert(nVarChar(10),@ReOrder)  
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
