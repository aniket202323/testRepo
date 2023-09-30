Create Procedure dbo.spAL_AddSheetColumn
  @Sheet_id int,
  @Result_On datetime AS
  -- Make sure that we do not already have a column on the sheet at the specified time.
  IF (SELECT Sheet_Id
        FROM Sheet_Columns
        WHERE (Sheet_Id = @Sheet_Id) AND (Result_On = @Result_On))
    IS NOT NULL RETURN(1)
  -- Add the sheet column.
  INSERT INTO Sheet_Columns(Sheet_Id, Result_On) VALUES(@Sheet_Id, @Result_On)
  RETURN(100)
