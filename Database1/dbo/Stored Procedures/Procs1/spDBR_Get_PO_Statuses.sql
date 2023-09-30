Create Procedure dbo.spDBR_Get_PO_Statuses
@searchstring varchar(50) = ''
AS 	 
 	 if (@searchstring = '')
 	 begin
 	  	 Select pp_status_id, pp_status_desc from production_plan_statuses where pp_status_id > 0 order by pp_status_desc
 	 end
 	 else
 	 begin
 	  	 set @SearchString = '%' + @SearchString + '%'
 	  	 Select pp_status_id, pp_status_desc from production_plan_statuses where pp_status_id > 0 and pp_status_desc like @SearchString order by pp_status_desc
 	 end
