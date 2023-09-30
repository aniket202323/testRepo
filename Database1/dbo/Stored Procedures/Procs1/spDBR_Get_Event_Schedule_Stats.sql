Create Procedure dbo.spDBR_Get_Event_Schedule_Stats
@type int,
@scope int,
@filter varchar(100)
AS
 	 create table #schedule_Events
 	 (
 	  	 dashboard_event_name varchar(100),
 	  	 dashboard_event_id int
 	 )
 	 
 	 declare @level int
 	 declare @sqlfilter varchar(100)
 	 
 	 set @sqlfilter = '%' + @filter + '%'
 	 
 	 set @level = (select unit_level_event from dashboard_event_types where dashboard_event_type_id = @type)
 	 
 	 if (@level = 0)  /*do a variable level query*/
 	 begin
 	  	 if (@filter = '')
 	  	 begin
 	  	  	 insert into #schedule_events
 	  	  	 select v.var_desc, v.var_id from variables v, dashboard_schedule_events e 
 	  	  	 where e.dashboard_event_type_id = @type and e.dashboard_event_scope_id = @scope
 	  	  	 and v.var_id = e.var_id 	  	 
 	  	 end
 	  	 else
 	  	 begin
 	  	  	 insert into #schedule_events
 	  	  	 select v.var_desc, v.var_id from variables v, dashboard_schedule_events e 
 	  	  	 where e.dashboard_event_type_id = @type and e.dashboard_event_scope_id = @scope
 	  	  	 and v.var_id = e.var_id and v.var_desc like @sqlfilter
 	  	 end 
 	 end
 	 if (@level = 1) /*do a unit level query*/
 	 begin
 	  	 if (@filter = '')
 	  	 begin
 	  	  	 insert into #schedule_events
 	  	  	 select p.pu_desc, p.pu_id from prod_units p, dashboard_schedule_events e 
 	  	  	 where e.dashboard_event_type_id = @type and e.dashboard_event_scope_id = @scope
 	  	  	 and p.pu_id = e.pu_id 	  	 
 	  	 end
 	  	 else
 	  	 begin
 	  	  	 insert into #schedule_events
 	  	  	 select p.pu_desc, p.pu_id from prod_units p, dashboard_schedule_events e 
 	  	  	 where e.dashboard_event_type_id = @type and e.dashboard_event_scope_id = @scope
 	  	  	 and p.pu_id = e.pu_id and p.pu_desc like @sqlfilter
 	  	 end  	  	 
 	 end
 	 select * from #schedule_events order by dashboard_event_id
 	 drop table #schedule_events
 	 
