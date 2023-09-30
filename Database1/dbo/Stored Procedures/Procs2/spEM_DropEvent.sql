CREATE Procedure dbo.spEM_DropEvent
  @Event_Id int
 AS
 	 Update User_Defined_Events set Event_Id = Null Where Event_Id = @Event_Id
 	 Delete From Event_Details Where Event_Id = @Event_Id
-- 	 Delete From Event_History Where Event_Id = @Event_Id
 	 Delete From Event_Components  Where Event_Id = @Event_Id
 	 Delete From Event_Components  WHERE Source_Event_Id  = @Event_Id
 	 Delete From Waste_Event_Details  Where Event_Id = @Event_Id
 	 Update Events Set Source_Event = Null    Where Source_Event = @Event_Id
 	 DELETE FROM Event_PU_Transitions Where Event_Id = @Event_Id
 	 Delete From prdexec_input_Event  Where Event_Id = @Event_Id
 	 Delete From Events  Where Event_Id = @Event_Id
