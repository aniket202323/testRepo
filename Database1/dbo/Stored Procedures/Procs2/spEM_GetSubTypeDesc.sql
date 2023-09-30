Create Procedure dbo.spEM_GetSubTypeDesc
  @PU_Id             int
  AS
  --
  -- Declare local variables.
  --
 	 Select es.Event_Subtype_Desc from Event_Subtypes es
 	   Join Event_Configuration ec on ec.Event_Subtype_Id = es.Event_Subtype_Id
 	    Where ec.pu_id = @PU_Id and ec.ET_Id = 1
