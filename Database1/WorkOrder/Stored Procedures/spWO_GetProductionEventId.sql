CREATE PROCEDURE WorkOrder.spWO_GetProductionEventId
      @EventId					int Output,
      @PUId						int,
      @EventNum					nvarchar(50)
    AS

    Declare
      @Message					NVarChar(2048)

    ------------------------------------------------------------------------------------------------------------------------------
    -- Prod Unit validation
    ------------------------------------------------------------------------------------------------------------------------------
    if (Not Exists(Select * from Prod_Units_Base where PU_Id = @PUId))
    Begin;
    	Set @Message = N'Production Unit (' + Convert(NVarchar(10), @PUId) + N') doesn''t exist';
    	THROW 50001, @Message, 1;
    End;

    ------------------------------------------------------------------------------------------------------------------------------
    -- Prod Event Lookup
    ------------------------------------------------------------------------------------------------------------------------------
    Select @EventId = null
    Select @EventId = Event_Id from Events where Event_Num = @EventNum and PU_Id = @PUId
    if (@EventId is null)
    Begin;
    	Set @Message = N'Production Event (' + @EventNum + N') doesn''t exist on Unit (' + Convert(NVarchar(10), @PUId) + N')';
    	THROW 50002, @Message, 1;
    End;