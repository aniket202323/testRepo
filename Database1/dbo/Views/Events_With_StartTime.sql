Create View [dbo].[Events_With_StartTime]
As
select  dbo.fnCmn_GetEventStartTime (e.event_id) [Actual_Start_Time], * from events e 
