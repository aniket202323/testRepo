Create Procedure dbo.spEM_GetTimedEventStatus
  @PU_Id             int
  AS
  --
  -- Declare local variables.
  --
  SELECT  TEStatus_Id, TEStatus_Name, TEStatus_Value
    FROM Timed_Event_Status
    WHERE   PU_Id  = @PU_Id
    ORDER BY TEStatus_Name, TEStatus_Value
