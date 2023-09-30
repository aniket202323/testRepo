CREATE PROCEDURE dbo.spEM_ActivateEvent
  @EC_Id             int,
  @Is_Active         bit
AS
  --
  -- Update the Event
  --
/*
  UPDATE Event_Config
      SET Is_Active    = @Is_Active
      WHERE EC_Id = @EC_Id
*/
  UPDATE Event_Configuration
      SET Is_Active    = @Is_Active
      WHERE EC_Id = @EC_Id
  RETURN(0)
