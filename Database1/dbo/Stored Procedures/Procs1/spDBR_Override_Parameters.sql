Create Procedure dbo.spDBR_Override_Parameters
@reportid int,
@templateid int,
@overrides text
AS
 	 create table #ParamOverrides
 	 (
 	  	 XMLID int,
 	  	 ParameterName nvarchar(100)
 	 )
 	 create table #ParamValues
 	 (
 	  	 ParameterID int,
 	  	 XMLID int,
 	  	 ParameterValue text --nvarchar(4000)
 	 )
 	 declare @hDoc int
 	 Exec sp_xml_preparedocument @hDoc OUTPUT, @overrides 
 	 
 	 
 	 insert into #ParamOverrides (ParameterName, XMLID)
 	 (select text, 
 	 (select b.parentid from OpenXML(@hDoc, N'/root/Parameter') b where b.id = a.parentid)
 	  	 from OpenXML(@hDoc, N'/root/Parameter') a 
 	 where a.nodetype = 3 and (select localname from OpenXML(@hDoc, N'/root/Parameter') b where b.id = a.parentid) = 'ParameterName')
 	 update #ParamOverrides 
 	  	 set ParameterName = dashboard_template_parameter_name
 	  	  	  	     from dashboard_template_Parameters 
 	  	  	  	     where dashboard_template_id = @templateid and
 	  	  	  	     ParameterName = 
 	  	  	  	     case when (isnumeric(ParameterName) = 1) then
 	  	  	  	  	 dashboard_template_parameter_name
 	  	  	  	     else
 	  	  	  	  	 case when (isnumeric(dashboard_template_parameter_name) = 1) then
 	  	  	  	  	  	 (dbo.fnDBTranslate(N'0', dashboard_template_parameter_name, dashboard_template_parameter_name))
 	  	  	  	  	 else
 	  	  	  	  	  	 (dashboard_template_parameter_name)
 	  	  	  	  	 end
 	  	  	  	     end
 	 insert into #ParamValues (ParameterValue, XMLID)
 	 (select text, 
 	 (select b.parentid from OpenXML(@hDoc, N'/root/Parameter') b where b.id = a.parentid)
 	 from OpenXML(@hDoc, N'/root/Parameter') a 
 	 where a.nodetype = 3 and (select localname from OpenXML(@hDoc, N'/root/Parameter') b where b.id = a.parentid) = 'ParameterValue')
 	 exec sp_xml_removedocument @hdoc
 	 update #ParamValues set ParameterID = dashboard_template_parameter_id 
 	  	 from dashboard_template_parameters t, #ParamOverrides p 
 	  	 where t.dashboard_template_id = @templateid and dashboard_template_parameter_name = p.parametername
 	  	 and p.xmlid = #ParamValues.xmlid
 	 
 	 update #ParamValues set ParameterValue = null where ParameterValue like '%null%'
 	 delete from #ParamValues where ParameterID is null
 	  	 
declare
  @@paramid int, @@paramvalue varchar(8000)
Declare Value_Cursor INSENSITIVE CURSOR
  For Select parameterid, parametervalue from #paramvalues order by parameterid
  For Read Only
  Open Value_Cursor 
Value_Loop:
  Fetch Next From Value_Cursor Into @@paramid, @@paramvalue
  If (@@Fetch_Status = 0)
    Begin
 	   if (substring(@@paramvalue, 1,10) = '<ROWENTRY>')
 	   begin
 	  	 update #ParamVAlues set ParameterValue = '<root><PARAMETER><ID>' + Convert(varchar(7), ParameterID) + '</ID>' + @@paramvalue + '</PARAMETER></root>'
 	  	  	 where parameterid = @@paramid
 	   end 
 	   else
 	   begin
 	  	 update #ParamVAlues set ParameterValue = '<root><PARAMETER><ID>' + Convert(varchar(7), ParameterID) + '</ID><ROWENTRY><COLUMN>'+ Convert(varchar(7),(select min(dashboard_datatable_column) as dashboard_datatable_column from dashboard_datatable_headers where Dashboard_DataTable_Presentation = 0 and dashboard_parameter_type_id = (select dashboard_parameter_type_id from dashboard_template_parameters where dashboard_template_parameter_id = parameterid))) +'</COLUMN><ROW>1</ROW><VALUE>' + @@paramvalue + '</VALUE><VALUETYPE>2</VALUETYPE></ROWENTRY></PARAMETER></root>' where parameterid = @@paramid
 	   end
      Goto Value_Loop
    End
Close Value_Cursor 
Deallocate Value_Cursor
Declare Value_Update_Cursor INSENSITIVE CURSOR
For Select parameterid, parametervalue from #paramvalues order by parameterid
For Read Only
Open Value_Update_Cursor 
Value_Update_Loop:
 	 Fetch Next From Value_Update_Cursor Into @@paramid, @@paramvalue
 	 If (@@Fetch_Status = 0)
 	  	 Begin
 	  	 execute spDBR_Overwrite_Parameter_Value @reportid, @@paramid, @@paramvalue
--set @@paramvalue = (select parametervalue from #paramvalue where parameterid = @@paramid)
--@@paramvalue
       	 Goto Value_Update_Loop
    End
Close Value_Update_Cursor 
Deallocate Value_Update_Cursor
