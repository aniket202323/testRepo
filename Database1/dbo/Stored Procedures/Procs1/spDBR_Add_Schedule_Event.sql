Create Procedure dbo.spDBR_Add_Schedule_Event
@scheduleID int,
@typeid int,
@scopeid int,
@levelid int,
@triggervalue int
AS
 	 if(@levelid = 1)
 	 begin
 	 
 	  	 insert into dashboard_schedule_Events (Dashboard_Schedule_ID, Dashboard_Event_Scope_ID ,Dashboard_Event_Type_ID ,PU_ID       ,Var_ID) values (@scheduleid, @scopeid, @typeid, @triggervalue, NULL)
 	 end
 	 if(@levelid = 2)
 	 begin
 	  	 insert into dashboard_schedule_Events (Dashboard_Schedule_ID, Dashboard_Event_Scope_ID ,Dashboard_Event_Type_ID ,PU_ID       ,Var_ID) values (@scheduleid, @scopeid, @typeid, NULL, @triggervalue) 	 
 	 end
