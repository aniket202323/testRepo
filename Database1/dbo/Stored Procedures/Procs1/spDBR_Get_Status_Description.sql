Create Procedure dbo.spDBR_Get_Status_Description
@status_id int
as
 	 insert into #sp_name_results select prodstatus_desc from production_status where prodstatus_id = @status_id
