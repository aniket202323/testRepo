Create Procedure dbo.spAL_GetEventMask
@UnitId int,
@EventMask nVarChar(25) OUTPUT
AS
Select @EventMask = Event_Mask 
  From Event_Configuration c
  Join Event_Subtypes s on s.Event_Subtype_Id = c.Event_Subtype_Id
  Where PU_Id = @UnitId and s.ET_Id = 1
return(100)
