CREATE PROCEDURE dbo.spServer_CmnAddEventComponent   
@Event_Id int,
@Source_Event_Id int,
@Dimension_X float,
@Dimension_Y float,       
@Dimension_Z float,             
@Dimension_A float
 AS
Insert Into Event_Components(Event_Id,Source_Event_Id,Dimension_X,Dimension_Y,Dimension_Z,Dimension_A)
  Values (@Event_Id,@Source_Event_Id,@Dimension_X,@Dimension_Y,@Dimension_Z,@Dimension_A)
