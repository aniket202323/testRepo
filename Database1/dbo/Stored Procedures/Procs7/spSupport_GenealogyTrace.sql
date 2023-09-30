CREATE Procedure dbo.spSupport_GenealogyTrace @Parent_Event_Id Int
as
set nocount on
Declare @GenealogyLevel Int
create table #CMR (EventId int, Event_Num VarChar(25),EventUnit int, TimeStamp datetime, GenealogyLevel int NULL)
Insert INTO #CMR(EventId,Event_Num, TimeStamp, EventUnit, GenealogyLevel)
 	 Select  @Parent_Event_Id,Event_Num,TimeStamp,PU_Id,1
 	  	 From Events where event_Id = @Parent_Event_Id
create table #CMS (EventId int)
Insert Into #CMS (EventId) Select EventId From #CMR
select @GenealogyLevel = 1
-- Loop Forwards In Genealogy Until No More Events Found
While ((Select Count(EventId) From #CMS) > 0)
  Begin
     Select @GenealogyLevel = @GenealogyLevel + 1
     Insert Into #CMR (EventId, TimeStamp, EventUnit, GenealogyLevel,Event_Num)
       Select ec.Event_Id, ed.TimeStamp, ed.PU_Id, @GenealogyLevel,ed.Event_Num
         From Event_Components ec
         Join #CMS se On ec.Source_Event_Id = se.EventId  
         Join Events ed on ec.Event_Id = ed.Event_Id         
     Delete From #CMS
     Insert Into #CMS (EventId)
       Select EventId From #CMR Where GenealogyLevel = @GenealogyLevel  
 	 Select 'Done Looking For Level:' + Convert(Varchar(10),@GenealogyLevel )
 	 Select * from #CMR
  End
dROP TABLE #CMS
Drop Table #CMR
set nocount off
