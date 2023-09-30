Create Procedure dbo.spDBR_Get_Widget_Binding_Info
@widgetID int
AS
 	 
 	 select dashboard_dialogue_data_binding_id, sp_name from dashboard_dialogue_data_bindings where dashboard_dialogue_widget_id = @widgetID
