Create Procedure dbo.spFF_GetDefaultStatus
@PU_Id int,
@DefaultStatus int OUTPUT
AS
Select @DefaultStatus = Valid_Status
  From PrdExec_Status
  Where PU_Id = @PU_Id and Is_Default_Status = 1
