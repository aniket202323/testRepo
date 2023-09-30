Create Procedure [dbo].spWAIC_GetEventCodeInfo
 	 @EventCode Char,
 	 @KeyId Int
AS
If @EventCode = 'E'
 	 Begin
 	  	 Select PU_Id UnitId, Cast(ET_Id As Int) EventTypeId, Event_Subtype_Id EventSubTypeId
 	  	 From Event_Configuration
 	  	 Where (@KeyId Is Null Or EC_Id = @KeyId)
 	 End
Else If @EventCode = 'A'
 	 Begin
 	  	 Select v.PU_Id UnitId, 11 EventTypeId, v.Var_Id EventSubTypeId
 	  	 From Variables v
 	  	 Where (@KeyId Is Null Or v.Var_Id = @KeyId)
 	 End
Else If @EventCode = 'C'
 	 Begin
 	  	 Select Null UnitId, 0 EventTypeId, 0 EventSubTypeId
 	 End
Else If @EventCode = 'N'
 	 Begin
 	  	 Select @KeyId UnitId, -2 EventTypeId, Null EventSubTypeId
 	 End
