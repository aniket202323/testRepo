CREATE PROCEDURE dbo.spServer_CMgrActivateSheet
  @Sheet_Id int,
  @New_State tinyint     AS
  -- Declare local variables.
  DECLARE @New_Bit bit,
          @Old_Bit bit  
  IF @New_State = 1
    SELECT @New_Bit = 1
  ELSE 
    SELECT @New_Bit = 0
  -- Find the sheet.
  SELECT @Old_Bit = NULL
  SELECT @Old_Bit = Is_Active
    FROM Sheets
    WHERE Sheet_Id = @Sheet_Id
  -- Make sure we located the sheet.
  IF @Old_Bit IS NULL RETURN(2)
 -- If we are activating a sheet, make sure that it has some variables defined for it.
  IF @New_Bit = 1
    BEGIN
      DECLARE @Var_Count int
      SELECT @Var_Count = COUNT(*) FROM Sheet_Variables WHERE Sheet_Id = @Sheet_Id
      IF @Var_Count = 0 RETURN(3)
    END
  -- See if we need to change the state.
  IF @Old_Bit = @New_Bit RETURN(1)
  -- Update the sheet record.
  UPDATE Sheets
    SET Is_Active = @New_Bit
    WHERE Sheet_Id = @Sheet_Id
  -- Return success.
  RETURN(1)
