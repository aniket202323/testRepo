CREATE PROCEDURE dbo.spEM_FindPhraseUsage
  @Phrase_Id int,
  @VarOrSpec int
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Error: Can't find phrase.
  --
  -- Declare local variables.
  --
  DECLARE @Data_Type_Id int,
          @Phrase_Value nvarchar(25)
  --
  -- Initialize local variables.
 -- No Checks for test data
 SELECT @Phrase_Value = Phrase_Value, @Data_Type_Id = Data_Type_Id
    FROM Phrase WHERE Phrase_Id = @Phrase_Id
  IF @Data_Type_Id IS NULL RETURN(1)
  --
  -- Report any instances of the phrase in the test, test history, or variable
  -- specification tables. We will return the variable id being used.
  --
  IF @VarOrSpec = 0 
   BEGIN
     SELECT Var_Id
       INTO #V
       FROM Variables
       WHERE  Data_Type_Id = @Data_Type_Id
     IF @@ROWCOUNT > 0
      BEGIN
        SELECT DISTINCT s.Var_Id
         FROM Var_Specs s
         JOIN #V on #V.Var_Id = s.Var_Id
           WHERE (s.Expiration_Date IS NULL or s.Expiration_Date > dbo.fnServer_CmnGetDate(getUTCdate())) AND
                ((s.L_Entry = @Phrase_Value) OR
                 (s.L_Reject = @Phrase_Value) OR          
                 (s.L_Warning = @Phrase_Value) OR
                 (s.L_User = @Phrase_Value) OR
                 (s.Target = @Phrase_Value) OR
                 (s.U_User = @Phrase_Value) OR
                 (s.U_Warning = @Phrase_Value) OR 
                 (s.U_Reject = @Phrase_Value) OR
                 (s.U_Entry = @Phrase_Value) OR
                 (s.L_Control = @Phrase_Value) OR
                 (s.T_Control = @Phrase_Value) OR
                 (s.U_Control = @Phrase_Value))
        DROP TABLE #V
      END
     ELSE
      BEGIN
         -- Empty result set for var specs
         SELECT DISTINCT Var_Id FROM #V
         DROP TABLE #V
      END
   END
  ELSE
   BEGIN
    -- Check Active Specs
    SELECT Spec_Id
     INTO #S
     FROM Specifications
     WHERE  Data_Type_Id = @Data_Type_Id
    IF @@ROWCOUNT > 0
      BEGIN
        SELECT DISTINCT a.Spec_Id
        FROM Active_Specs a
        JOIN #S  ON (#S.Spec_Id = a.Spec_Id)
        WHERE (a.Expiration_Date IS NULL or a.Expiration_Date > dbo.fnServer_CmnGetDate(getUTCdate())) AND
             ((a.L_Entry = @Phrase_Value) OR
              (a.L_Reject = @Phrase_Value) OR          
              (a.L_Warning = @Phrase_Value) OR
              (a.L_User = @Phrase_Value) OR
              (a.Target = @Phrase_Value) OR
              (a.U_User = @Phrase_Value) OR
              (a.U_Warning = @Phrase_Value) OR 
              (a.U_Reject = @Phrase_Value) OR
              (a.U_Entry = @Phrase_Value) OR
              (a.L_Control = @Phrase_Value) OR
              (a.T_Control = @Phrase_Value) OR
              (a.U_Control = @Phrase_Value))
        DROP TABLE #s
      END
    ELSE
      BEGIN
         SELECT DISTINCT Spec_Id FROM #S
         DROP TABLE #S
      END
   END 
  --
  -- Return success.
  --
  RETURN(0)
