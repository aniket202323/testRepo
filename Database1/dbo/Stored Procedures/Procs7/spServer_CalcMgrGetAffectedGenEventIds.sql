CREATE PROCEDURE dbo.spServer_CalcMgrGetAffectedGenEventIds
@SrcEventId int,
@EventId int,
@OldWay int = 1
AS
declare @@Id int
declare @ParamMaxGenealogyLevel int 
declare @GenealogyLevel int 
declare @tmptime datetime
declare @Count int
Declare @MaxGenealogyLevel Int
declare @StartGenealogyLevel int 
declare @@TheEndTime datetime
declare @Start_Time datetime
declare @@EU int
create table #CMGetSearchEvents (EventId int)
CREATE INDEX CMGetSearchEvents_IDX_EventId ON #CMGetSearchEvents(EventId)
create table #CMGetSearchEventsResults (EventId int, EventUnit int, GenealogyLevel int, EndTime datetime, StartTime datetime null)
CREATE INDEX CMGetSearchEventsResults_IDX_EventId ON #CMGetSearchEventsResults(EventId)
-- Get the max levels parameter
select @ParamMaxGenealogyLevel = NULL
exec spServer_CmnGetParameter 104, 26, HOST_NAME, @ParamMaxGenealogyLevel output
if @ParamMaxGenealogyLevel is null 
 	 select @ParamMaxGenealogyLevel = 20
--
-- **** Get Genealogy Information ****
--
Select @GenealogyLevel = 1
Insert Into #CMGetSearchEvents (EventId) Select @EventId 
select @StartGenealogyLevel = @GenealogyLevel
-- Loop Forwards In Genealogy Until No More Events Found
While ((Select Count(EventId) From #CMGetSearchEvents) > 0)  and (@GenealogyLevel <= @ParamMaxGenealogyLevel)
  Begin
     Select @GenealogyLevel = @GenealogyLevel + 1
     Insert Into #CMGetSearchEventsResults (EventId, EndTime, EventUnit, GenealogyLevel, StartTime)
       Select Distinct ec.Event_Id, ed.TimeStamp, ed.PU_Id, @GenealogyLevel, ed.Start_Time
         From Event_Components ec
         Join #CMGetSearchEvents se On ec.Source_Event_Id = se.EventId  
         Join Events ed on ec.Event_Id = ed.Event_Id         
     Truncate table #CMGetSearchEvents
     Insert Into #CMGetSearchEvents (EventId) Select EventId From #CMGetSearchEventsResults Where GenealogyLevel = @GenealogyLevel  
  	    Delete From #CMGetSearchEvents
 	   	  	  From #CMGetSearchEvents
 	  	  	  Join #CMGetSearchEventsResults On #CMGetSearchEvents.EventId = #CMGetSearchEventsResults.EventId and GenealogyLevel < @GenealogyLevel and GenealogyLevel > @StartGenealogyLevel 
  End
Delete From #CMGetSearchEvents
-- Loop Backwards In Genealogy Until No More Events Found
Insert Into #CMGetSearchEvents (EventId)  Select @SrcEventId 
select @MaxGenealogyLevel = @GenealogyLevel + @ParamMaxGenealogyLevel
select @StartGenealogyLevel = @GenealogyLevel
While ((Select Count(EventId) From #CMGetSearchEvents) > 0) and (@GenealogyLevel <= @MaxGenealogyLevel)
  Begin
     Select @GenealogyLevel = @GenealogyLevel + 1
     Insert Into #CMGetSearchEventsResults (EventId, EndTime, EventUnit, GenealogyLevel, StartTime)
       Select Distinct  ec.Source_Event_Id, ed.TimeStamp, ed.PU_Id, @GenealogyLevel, ed.Start_Time
         From Event_Components ec
         Join #CMGetSearchEvents se On ec.Event_Id = se.EventId  
         Join Events ed on ec.Source_Event_Id = ed.Event_Id         
         Where ec.Event_Id <> ec.Source_Event_Id         
     Truncate table  #CMGetSearchEvents
     Insert Into #CMGetSearchEvents (EventId) Select EventId From #CMGetSearchEventsResults Where GenealogyLevel = @GenealogyLevel  
 	    Delete From #CMGetSearchEvents 
 	  	  	  From #CMGetSearchEvents
 	  	  	  Join #CMGetSearchEventsResults On #CMGetSearchEvents.EventId = #CMGetSearchEventsResults.EventId and GenealogyLevel < @GenealogyLevel and GenealogyLevel > @StartGenealogyLevel 
  End
Insert Into #CMGetSearchEventsResults (EventId, EndTime, EventUnit, GenealogyLevel)
   Select @EventId, TimeStamp, PU_Id, -1 from Events where @EventId = Event_Id         
Insert Into #CMGetSearchEventsResults (EventId, EndTime, EventUnit, GenealogyLevel)
   Select @SrcEventId, TimeStamp, PU_Id, -1 from Events where @SrcEventId = Event_Id  
if (@OldWay <> 1)
begin
 	 Declare StartTime_Cursor INSENSITIVE CURSOR For (Select EventId, EndTime, EventUnit from #CMGetSearchEventsResults where starttime is null) For Read Only
 	 Open StartTime_Cursor  
 	 Fetch_Loop:
 	   Fetch Next From StartTime_Cursor Into @@Id, @@TheEndTime, @@EU
 	   If (@@Fetch_Status = 0)
 	     Begin
 	  	     Select @Start_Time = NULL
 	    	   Select @Start_Time = Max(TimeStamp)  From Events Where (PU_Id = @@EU) And (TimeStamp < @@TheEndTime)
 	  	  	  	 if (@Start_Time is not null)
 	  	  	  	  	 update #CMGetSearchEventsResults  set StartTime=@Start_Time where EventId = @@Id
 	       Goto Fetch_Loop
 	     End
 	 Close StartTime_Cursor
 	 Deallocate StartTime_Cursor
end
if (@OldWay = 1)
 	 select distinct EventId, EventUnit, EndTime from #CMGetSearchEventsResults 
else
 	 select distinct EventId, EventUnit, EndTime, StartTime from #CMGetSearchEventsResults 
drop table #CMGetSearchEvents
drop table #CMGetSearchEventsResults 
