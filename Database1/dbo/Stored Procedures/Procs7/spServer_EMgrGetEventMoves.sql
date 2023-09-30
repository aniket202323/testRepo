CREATE PROCEDURE dbo.spServer_EMgrGetEventMoves  
AS
Select distinct ET_Id, Move_EndTime_Interval
  from Event_Configuration
  where Move_EndTime_Interval is not null and Move_EndTime_Interval > 0
  order by ET_Id, Move_EndTime_Interval
