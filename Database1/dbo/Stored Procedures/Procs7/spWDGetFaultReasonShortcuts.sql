Create Procedure dbo.spWDGetFaultReasonShortcuts
@pPU_Id int,
@pApp_Id int = NULL
AS
IF @pApp_Id IS NULL
  SELECT @pApp_Id = 2
IF @pApp_Id = 2
  SELECT * FROM Timed_Event_Fault
    WHERE PU_Id = @pPU_Id
ELSE IF @pApp_Id = 3
  SELECT * FROM Waste_Event_Fault
    WHERE PU_Id = @pPU_Id
RETURN(100)
