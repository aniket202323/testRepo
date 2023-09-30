Create Procedure dbo.spAL_DeleteSheet
  @Sheet_Id int AS
  DECLARE @Test int
  -- Locate the sheet to delete.
  SELECT @Test = NULL
  SELECT @Test = Initial_Count FROM Sheets WHERE Sheet_Id = @Sheet_Id
  IF @Test IS NULL
    BEGIN
      RETURN(1)
    END
  -- Delete the sheet.
  BEGIN TRANSACTION
  DELETE FROM Sheet_Columns WHERE Sheet_Id = @Sheet_Id
  DELETE FROM Sheet_Variables WHERE Sheet_Id = @Sheet_Id
  DELETE FROM Sheets WHERE Sheet_Id = @Sheet_Id
  COMMIT TRANSACTION
  -- Return successfully.
  RETURN(100)
