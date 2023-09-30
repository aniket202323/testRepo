CREATE PROCEDURE dbo.spEM_GetVarRepSTData
  @Var_Id int
  AS
  --
  -- Declare local variables.
  --
  DECLARE @Input_Tag nvarchar(255)
  --
  -- Determine the input tag for the variable.
  --
  SELECT @Input_Tag = Input_Tag FROM Variables WHERE Var_Id = @Var_Id
  SELECT Input_Tag = @Input_Tag
  --
  -- For a non-null actual tag, find all the sampling types.
  --
  IF @Input_Tag IS NOT NULL
    SELECT Var_Id, Sampling_Type
      FROM Variables
      WHERE (Input_Tag = @Input_Tag) AND
           (DS_Id = (SELECT DS_Id FROM Data_Source WHERE DS_Desc = 'Historian'))
