CREATE PROCEDURE dbo.spEM_OrderPhrases
  @Phrase_Id      int,
  @NewPhraseOrder int,
  @ForceReorder tinyint,
  @User_Id int,
  @ReOrder      tinyint OUTPUT
  AS
  DECLARE @OldPhraseOrder int,
          @Data_Type_Id int,
          @Min_Number   int,
          @Max_Number   int,
          @Total_Count  int,
          @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_OrderPhrases',
                Convert(nVarChar(10),@Phrase_Id) + ','  + 
 	  	 Convert(nVarChar(10), @NewPhraseOrder) + ','  + 
 	  	 Convert(nVarChar(10), @ForceReorder) + ','  + 
 	  	 Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Return Codes:
  --
  --   0 = Success
  --
  -- Order the Phrases. If this is a force reorder skip insert of Phrase because the whole tree is being rewritten
  --
  IF @ForceReorder = 0
     BEGIN
      --
      --  Avoid duplicate Phrase order
      --
  	  SELECT @Data_Type_Id = Data_Type_Id FROM Phrase Where Phrase_Id = @Phrase_Id
     SELECT  @Total_Count = Count(*)  FROM Phrase Where Data_Type_Id = @Data_Type_Id
      IF (SELECT Max(Phrase_Order)FROM Phrase Where Data_Type_Id = @Data_Type_Id) <>   @Total_Count
      BEGIN
 	  	 SELECT @ReOrder = 1
 	  	 Return(0)
      END 
      SELECT @OldPhraseOrder =  Phrase_Order FROM Phrase Where Phrase_Id = @Phrase_Id
      UPDATE Phrase SET Phrase_Order = @Total_Count + 1 WHERE Phrase_Id = @Phrase_Id
      IF @OldPhraseOrder > @NewPhraseOrder
      UPDATE Phrase SET Phrase_Order = Phrase_Order + 1  
        WHERE Data_Type_Id = @Data_Type_Id  AND Phrase_Order BETWEEN @NewPhraseOrder AND @OldPhraseOrder - 1
      IF @OldPhraseOrder < @NewPhraseOrder 
        UPDATE Phrase SET Phrase_Order = Phrase_Order - 1 
        WHERE Data_Type_Id = @Data_Type_Id  AND Phrase_Order BETWEEN @OldPhraseOrder + 1 AND @NewPhraseOrder
    END
    IF @ForceReorder = 1
    BEGIN
 	  	 SELECT @Data_Type_Id = Data_Type_Id FROM Phrase Where Phrase_Id = @Phrase_Id
 	  	 SELECT   @Max_Number = MAX(Phrase_Order)  FROM Phrase Where Data_Type_Id = @Data_Type_Id
 	  	 UPDATE Phrase SET Phrase_Order = @Max_Number + 1 WHERE Phrase_Order = @NewPhraseOrder and Data_Type_Id = @Data_Type_Id
    END
   UPDATE Phrase SET Phrase_Order = @NewPhraseOrder WHERE Phrase_Id = @Phrase_Id
 -- Make sure the order is correct  -  If not Have GradeBook Administrator rewrite order of entire branch 
  --
  SELECT @Min_Number = Min(Phrase_Order), @Max_Number = MAX(Phrase_Order), @Total_Count = Count(*) 
     FROM Phrase Where Data_Type_Id = @Data_Type_Id
  SELECT @ReOrder = 0
  IF @Min_Number <> 1 OR @Max_Number <> @Total_Count
     SELECT @ReOrder = 1
   UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0,Output_Parameters = convert(nVarChar(10),@ReOrder)
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
