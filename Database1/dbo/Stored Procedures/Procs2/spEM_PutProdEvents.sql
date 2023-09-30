Create Procedure dbo.spEM_PutProdEvents
  @PU_Id    int,
  @TreeName_Id int,
  @Event_Type tinyint,
  @User_Id int
  AS
  --
  DECLARE @Insert_Id integer,
 	       @OldPU_Id int
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_PutProdEvents',
                 	 Convert(nVarChar(10),@PU_Id) + ','  + 
 	  	 Convert(nVarChar(10),@TreeName_Id) + ','  + 
 	  	 Convert(nVarChar(10),@Event_Type) + ','  + 
 	  	 Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Return Codes:
  --
  --   0 = Success.
  --
  -- Update the production unit's Event
  --
  SELECT @OldPU_Id = NULL
  SELECT @OldPU_Id = PU_Id FROM Prod_Events 
       WHERE PU_Id = @PU_Id AND Event_Type = @Event_Type 
  IF @OldPU_Id is NULL AND @TreeName_ID is NOT NULL
    INSERT Prod_Events  (Name_Id,PU_Id,Event_Type) VALUES (@TreeName_Id,@PU_Id,@Event_Type)
  ELSE IF @TreeName_Id is NULL
    Begin
          DELETE FROM Prod_Events  WHERE PU_Id = @PU_Id AND Event_Type = @Event_Type 
          UPDATE Timed_Event_Fault set Source_PU_Id = Null, Reason_Level1 = Null, Reason_Level2 = Null, Reason_Level3 = Null, Reason_Level4 = Null,Event_Reason_Tree_Data_Id = Null WHERE Source_PU_Id = @PU_Id
    End
  ELSE
          UPDATE Prod_Events  SET Name_Id = @TreeName_Id WHERE PU_Id = @PU_Id AND Event_Type = @Event_Type 
 UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
 RETURN(0)
