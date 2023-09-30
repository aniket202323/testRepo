Create Procedure dbo.spAL_DeleteColorScheme
  @CS_Id int AS
  -- Delete the sheet.
  DELETE FROM Color_Scheme WHERE CS_Id = @CS_Id
  -- Return successfully.
  RETURN(100)
