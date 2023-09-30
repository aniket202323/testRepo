Create Procedure dbo.spDBR_Get_Schedule_Events
@scheduleid int
AS
 	 create table #event_info
 	 (
 	  	 id int IDENTITY (1, 1) NOT NULL,
 	  	 triggername varchar(100),
 	  	 eventtype varchar(100),
 	  	 eventscope varchar(100),
 	  	 triggerid int,
 	  	 typeid int,
 	  	 levelid int,
 	  	 scopeid int
 	 )
 	 
 	 insert into #event_info (eventtype, eventscope, triggerid, typeid, scopeid)
 	 select t.dashboard_event_type, s.dashboard_event_scope, e.pu_id, e.dashboard_event_type_id, e.dashboard_event_scope_id 
 	 from dashboard_schedule_events e, dashboard_event_Types t, dashboard_event_scopes s
 	 where e.dashboard_schedule_id = @scheduleid
 	 and not (pu_id is null)
 	 and t.dashboard_event_type_id = e.dashboard_event_type_id
 	 and s.dashboard_event_scope_id = e.dashboard_event_scope_id
 	 
 	  	 insert into #event_info (eventtype, eventscope, triggerid, typeid, scopeid)
 	 select t.dashboard_event_type, s.dashboard_event_scope, e.var_id, e.dashboard_event_type_id, e.dashboard_event_scope_id 
 	 from dashboard_schedule_events e, dashboard_event_Types t, dashboard_event_scopes s
 	 where e.dashboard_schedule_id = @scheduleid
 	 and not (var_id is null)
 	 and t.dashboard_event_type_id = e.dashboard_event_type_id
 	 and s.dashboard_event_scope_id = e.dashboard_event_scope_id
 	 
 	 declare @eventcount int
 	 declare @index int
 	 declare @type int
 	 declare @based int
 	 declare @triggername varchar(100)
 	 declare @triggerid int
 	 
 	 set @eventcount = (select count(*) from #event_info)
 	 set @index = 1
 	 
 	 while (@index <= @eventcount)
 	 begin
 	  	 set @type = (select typeid from #event_info where id = @index)
 	  	 set @based = (select unit_level_event from dashboard_event_types where dashboard_event_type_id = @type)
 	  	 if (@based = 1)
 	  	 begin
 	  	  	 set @triggerid = (select triggerid from #event_info where id = @index)
 	  	  	 set @triggername = (select pu_desc from prod_units where pu_id = @triggerid)
 	  	  	 update #event_info set triggername = @triggername, levelid = 1 where  id = @index
 	  	 end 	  
 	  	 set @based = (select variable_level_event from dashboard_event_types where dashboard_event_type_id = @type)
 	  	 if (@based = 1)
 	  	 begin
 	  	  	 set @triggerid = (select triggerid from #event_info where id = @index)
 	  	  	 set @triggername = (select var_desc from variables where var_id = @triggerid)
 	  	  	 update #event_info set triggername = @triggername, levelid = 2 where  id = @index
 	  	 end
 	  	 set @index = (@index + 1)
 	 end
 	 select * from #event_info
 	 drop table #event_info
