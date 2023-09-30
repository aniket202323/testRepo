   /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-22  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Replace temp table for table variable   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_UptimeBetweenProdUnits  
Author:   Vince King (P&G, Albany, Ga)  
Date Created:  02/25/02  
  
Description:  
=========  
Allows Uptime to be calculated between two production units.  For example, if the users want to see downtime  
and Blocked/Starved events on separate displays (which requires separate production units), but the uptime calculation  
should be between both prod units.  So if an event occurs on the downtime prod unit, check both the downtime and  
blocked/starved units to see when the last event occurred.  Then use that end time to calculate uptime.  
  
Change Date Who What  
=========== ==== =====  
  
*/  
  
CREATE PROCEDURE [spLocal_UptimeBetweenProdUnits]  
 @OutputValue varchar(25) OUTPUT,  
 @This_PU_Id integer,  
 @Other_PU_Id integer,  
 @Start_Time datetime  
  
AS  
  
SET NOCOUNT ON  
  
DECLARE  @Uptime real,  
  @Prev_End_Time datetime  
  
/*  
Select @This_PU_Id = 102  
Select @Other_PU_Id = 152  
Select @Start_Time = GetDate()  --'2002-02-25 11:00:00.000'  
*/  
  
DECLARE @LastEvent TABLE(  
 PU_Id integer,  
 start_time datetime,  
 end_time datetime)  
  
insert @LastEvent (PU_Id,start_time,end_time)  
 select top 1 PU_Id, start_time, end_time  
 from [dbo].timed_event_summarys  
 where PU_Id = @This_PU_Id and end_time < @Start_Time  
 order by start_time desc  
  
insert @LastEvent  
 select top 1 PU_Id, start_time, end_time  
 from [dbo].timed_event_summarys  
 where PU_Id = @Other_PU_Id and end_time < @Start_Time  
 order by start_time desc  
  
select top 1 @Prev_End_Time = end_time from @LastEvent  
 order by end_time desc  
  
Select @Uptime = ABS(DateDiff(s,@Prev_End_Time,@Start_Time) / 60.0)  
Select @OutputValue = @Uptime  
  
SET NOCOUNT OFF  
  
