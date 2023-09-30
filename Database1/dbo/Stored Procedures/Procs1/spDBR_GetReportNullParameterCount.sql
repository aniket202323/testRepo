Create Procedure dbo.spDBR_GetReportNullParameterCount
@reportid int
AS
    declare @@templateid int
    select @@templateid = dashboard_template_id from dashboard_reports where dashboard_report_id = @reportid
    declare @@parmid int
    declare @@ready int
    declare @@valuecount int
    select @@ready = 1
    Declare Parameter_Cursor INSENSITIVE CURSOR
 	 For select dashboard_template_parameter_id from dashboard_template_parameters where dashboard_template_id = @@templateid and allow_nulls = 0
 	 For Read Only
 	 Open Parameter_Cursor  
 	 Parameter_Loop:
 	 Fetch Next From Parameter_Cursor Into @@parmid
 	 If (@@Fetch_Status = 0)
    	 Begin
 	  	 select @@valuecount = count(dashboard_parameter_value) from dashboard_parameter_values where dashboard_template_parameter_id = @@parmid and dashboarD_report_id = @reportid
 	  	 if (@@valuecount = 0)
 	  	 begin
 	  	  	 select @@ready = 0
 	  	  	 goto finished
 	  	 end
       	  	 Goto Parameter_Loop
     	 End
Finished: 	 
 	 Close Parameter_Cursor 
 	 Deallocate Parameter_Cursor
select @@ready
return @@ready
 	 
 	  	  	  
