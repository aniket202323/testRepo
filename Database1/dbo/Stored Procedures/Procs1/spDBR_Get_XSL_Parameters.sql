Create Procedure dbo.spDBR_Get_XSL_Parameters
@reportid int
AS
 	 create table #Params
 	 (
 	  	 paramid int,
 	  	 param varchar(100),
 	  	 paramvalue varchar(7000)
 	 )
 	 insert into #params(paramid, param) select dashboard_template_parameter_id, 
 	  	 case when isnumeric(dashboard_template_parameter_name) = 1 then (dbo.fnDBTranslate(N'0', dashboard_template_parameter_name, dashboard_template_parameter_name)) 
 	  	 else (dashboard_template_parameter_name)
 	  	 end as dashboard_template_parameter_name 
from dashboard_template_parameters t, dashboard_reports r
 	  	 where r.dashboarD_report_id = @reportid and t.dashboard_template_id = r.dashboard_template_id
declare
  @@id int
Declare PV_Cursor INSENSITIVE CURSOR
  For Select paramid from #params order by paramid
  For Read Only
  Open PV_Cursor  
PV_Loop:
  Fetch Next From PV_Cursor Into @@id
  If (@@Fetch_Status = 0)
    Begin 	 
 	  	 declare @sqlstmt  nvarchar(50)
 	  	 set @sqlstmt = N'spdbr_get_parameter_value2 ' + Convert(nvarchar, @@id) + ',' + Convert(nvarchar, @reportid)
 	  	 
 	  	 select paramid, param   from #params where paramid = @@id
 	  	 execute sp_executesql @sqlstmt
 	  	 /*insert into #Date execute sp_executesql @sqlstmt
 	  	      
 	  	 select * from #ParamValue
 	  	 delete from #ParamValue 
      */Goto PV_Loop
 	 end
Close PV_Cursor 
Deallocate PV_Cursor
 	 
/* 	 select t.dashboard_template_parameter_name, v.dashboard_parameter_value from dashboard_template_parameters t, dashboard_parameter_values v
 	  	 where t.dashboard_template_parameter_id = v.dashboard_template_parameter_id and v.dashboard_report_id = @reportid 	 
 	 select * from #params
*/
