CREATE FUNCTION [dbo].[fnCmn_GetEventStartTime](
 	  @Event_Id Int)
RETURNS  DateTime
AS
BEGIN
/*
declare @Event_Id int
select @Event_Id = 81022
*/
Declare @ListedEventEndTime datetime, @ThisPUId int
Declare @StartTime datetime, @PreviousEventTimeStamp datetime
Select @StartTime=Start_Time,@ListedEventEndTime=Timestamp, @ThisPUId=pu_id from events where event_Id = @Event_Id
--If there's a starttime then use it otherwise use the previous events end time (if this is the first event just return the current timestamp)
if @StartTime is NULL 
  select @StartTime=isnull(MAX(Timestamp),@ListedEventEndTime) from events where timestamp < @ListedEventEndTime and pu_id = @ThisPUId
return @StartTime
END
