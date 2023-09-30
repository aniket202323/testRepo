Create Procedure dbo.spDS_GetEventComponentDetail
@ECId int
AS
---------------------------------------------------------
-- Get Event Component info
--------------------------------------------------------
Select ec.Dimension_X, ec.Dimension_Y, ec.Dimension_Z, ec.Dimension_A, ec.Start_Coordinate_X, ec.Start_Coordinate_Y,
       ec.Start_Coordinate_Z, ec.Start_Coordinate_A, ec.Start_Time, ec.Timestamp, e.Event_Num, Source_Event_Num = e2.Event_Num,
       es.Dimension_X_Name, es.Dimension_Y_Name, es.Dimension_Z_Name, es.Dimension_A_Name, es.Dimension_Y_Enabled, 
       es.Dimension_Z_Enabled, es.Dimension_A_Enabled, es.Event_Subtype_Desc,Default_StartTime = e.timestamp,Default_EndTime = isnull(e.Start_Time,e.Timestamp)
   From Event_Components ec
    Join Events e on e.Event_Id = ec.Event_Id
    Left Outer Join Events e2 on e2.Event_Id = ec.Source_Event_Id
    Left Outer Join Event_Configuration ecfg on ecfg.PU_Id = e2.PU_Id and ecfg.ET_Id = 1
    Left Outer Join Event_Subtypes es on es.Event_Subtype_Id = ecfg.Event_Subtype_id
     Where ec.Component_Id = @ECId
