Create Procedure dbo.spAL_GetTestArrayID
@TestId BigInt,
@ArrayID int OUTPUT
AS
Select @ArrayID = array_id 
  From Tests
  Where test_id = @TestId
if @ArrayId Is Not Null
  return(100)
else
  return(0)
