Create Procedure dbo.spAL_CheckColumnResultOn
  @Result_On datetime,
  @Sheet_Id int
AS
  -- Declare local variables.
  Declare
    @TimeStamp datetime
  -- See if record exists by resulton.
  SELECT @TimeStamp = NULL
  SELECT @TimeStamp = Result_On
    FROM Sheet_Columns  WITH (NOLOCK)
    WHERE (Sheet_Id = @Sheet_Id) AND (Result_On = @Result_On)
  IF @TimeStamp IS NOT NULL RETURN(2)
  -- Return successfully.
  RETURN(100)
