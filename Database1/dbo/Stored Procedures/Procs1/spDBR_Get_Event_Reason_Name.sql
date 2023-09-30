Create Procedure dbo.spDBR_Get_Event_Reason_Name
@erid int
as
 	 insert into #sp_name_results select event_reason_name from event_reasons where event_reason_id = @erid
