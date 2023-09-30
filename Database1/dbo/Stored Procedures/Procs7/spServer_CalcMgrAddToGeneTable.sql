CREATE PROCEDURE dbo.spServer_CalcMgrAddToGeneTable
@eventid int
as
declare @GenealogyLevel int 
declare @MaxGenealogyLevel int 
declare @ParamMaxGenealogyLevel int 
declare @StartGenealogyLevel int 
declare @tmptime datetime
declare @Count int
declare @Value varchar(5000)
select @Count=Count(OriginalEventId) from CalcMgrGenealogyCache where OriginalEventId=@eventId
if @Count > 0
  return
Declare @CMSearchEvents Table (EventId int PRIMARY KEY (EventId))
-- Get the max levels parameter
select @Value = NULL
exec dbo.spServer_CmnGetParameter 104, 26, HOST_NAME, @Value output
if @Value is NULL
 	 select @ParamMaxGenealogyLevel = 20
else
 	 select @ParamMaxGenealogyLevel = CONVERT(INT,@Value)
--
-- **** Get Genealogy Information ****
--
Select @GenealogyLevel = 1
Insert Into @CMSearchEvents (EventId) Select @EventId 
-- Loop Forwards In Genealogy Until No More Events Found
select @MaxGenealogyLevel = @ParamMaxGenealogyLevel
select @StartGenealogyLevel = @GenealogyLevel
While ((Select Count(EventId) From @CMSearchEvents) > 0)  and (@GenealogyLevel <= @MaxGenealogyLevel)
  Begin
     Select @GenealogyLevel = @GenealogyLevel + 1
     Insert Into CalcMgrGenealogyCache (ComponentId, OriginalEventId, EventId, TimeStamp, EventUnit, GenealogyLevel)
       Select ec.component_id, @EventId, ec.Event_Id, ed.TimeStamp, ed.PU_Id, @GenealogyLevel
         From Event_Components ec
         Join @CMSearchEvents se On ec.Source_Event_Id = se.EventId  
         Join Events ed on ec.Event_Id = ed.Event_Id         
     Delete @CMSearchEvents
     Insert Into @CMSearchEvents (EventId)
       Select Distinct EventId From CalcMgrGenealogyCache Where OriginalEventId=@EventId and GenealogyLevel = @GenealogyLevel  
 	    Delete From @CMSearchEvents
 	  	  	  From @CMSearchEvents se
 	  	  	  Join CalcMgrGenealogyCache cgc On se.EventId = cgc.EventId and @EventId = cgc.OriginalEventId and cgc.GenealogyLevel < @GenealogyLevel and cgc.GenealogyLevel > @StartGenealogyLevel 
  End
Delete @CMSearchEvents
-- Loop Backwards In Genealogy Until No More Events Found
Insert Into @CMSearchEvents (EventId)  Select @EventId 
select @MaxGenealogyLevel = @GenealogyLevel + @ParamMaxGenealogyLevel
select @StartGenealogyLevel = @GenealogyLevel
While ((Select Count(EventId) From @CMSearchEvents) > 0) and (@GenealogyLevel <= @MaxGenealogyLevel)
  Begin
     Select @GenealogyLevel = @GenealogyLevel + 1
     Insert Into CalcMgrGenealogyCache (ComponentId, OriginalEventId, EventId, TimeStamp, EventUnit, GenealogyLevel)
       Select ec.component_id, @EventId, ec.Source_Event_Id, ed.TimeStamp, ed.PU_Id, @GenealogyLevel
         From Event_Components ec
         Join @CMSearchEvents se On ec.Event_Id = se.EventId  
         Join Events ed on ec.Source_Event_Id = ed.Event_Id         
         Where ec.Event_Id <> ec.Source_Event_Id         
     Delete @CMSearchEvents
     Insert Into @CMSearchEvents (EventId)
       Select Distinct EventId From CalcMgrGenealogyCache Where OriginalEventId=@EventId and GenealogyLevel = @GenealogyLevel 
 	    Delete From @CMSearchEvents
 	  	  	  From @CMSearchEvents se
 	  	  	  Join CalcMgrGenealogyCache cgc On se.EventId = cgc.EventId and @EventId = cgc.OriginalEventId and cgc.GenealogyLevel < @GenealogyLevel and cgc.GenealogyLevel > @StartGenealogyLevel 
  End
