Create Procedure dbo.spDBR_Get_Widget_Attributes
@WidgetType int
AS
 	 select a.Attribute_Desc, a.widget_attribute_id from Dashboard_Widget_Attributes a where Widget_Type_ID = @WidgetType order by Attribute_Desc
