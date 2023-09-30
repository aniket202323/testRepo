Create Procedure dbo.spDBR_Get_PO_Status_Description
@status_id int
as
 	 insert into #sp_name_results Select pp_status_desc from production_plan_statuses where pp_status_id = @status_id 
