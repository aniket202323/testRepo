Create Procedure dbo.spDBR_Export_Template_Stored_Procedures
@template_id int = 64
AS
 	 create table #Template_Stored_Procedures
 	 (
 	  	 SP_Name varchar(100) 	 
 	 )
 	 create table #Template_Get_Columns
 	 (
 	  	 SP_Name varchar(100) 	 
 	 )
 	 create table #Dashboard_DataTable_Headers
 	 (
 	  	 Dashboard_DataTable_Column_SP varchar(100) 
 	 )
 	 create table #Dashboard_Templates
 	 (
 	  	 Dashboard_Template_ID int,
 	  	 Dashboard_Template_Procedure varchar(100),
 	 )
 	 create table #Dashboard_Template_Parameters
 	 ( 	 
 	  	 Dashboard_Parameter_Type_ID int,
 	 )
 	 create table #Dashboard_Template_Links
 	 (
 	  	 Dashboard_Template_Link_ID int,
 	  	 Dashboard_Template_Link_From int,
 	  	 Dashboard_Template_Link_To int 
 	 )
 	 
 	 declare @oldrowcount int
 	 set @oldrowcount = 0
 	 declare @newrowcount int
 	 
 	 insert into #Dashboard_Template_Links (dashboard_template_link_id, dashboard_template_link_from, dashboard_template_link_to) select dashboard_template_link_id, dashboard_template_link_from, dashboard_template_link_to from dashboard_Template_links where Dashboard_Template_Link_From = @template_id
 	 
 	 set @newrowcount = (select count(dashboard_template_link_to) from #dashboard_template_links)
 	 
 	 while (@newrowcount > @oldrowcount)
 	 begin
 	  	 set @oldrowcount = @newrowcount
 	  	 insert into #dashboard_template_links (dashboard_template_link_id, dashboard_template_link_from, dashboard_template_link_to) select dashboard_template_link_id, dashboard_template_link_from, dashboard_template_link_to from dashboard_template_links where (not dashboard_template_link_from = @template_id) 
 	  	  	 and (not dashboard_template_link_from in (select dashboard_template_link_from from #dashboard_Template_links))
 	  	  	 and (dashboard_template_link_from in
 	  	  	  	 (select dashboard_template_link_to from #dashboard_Template_links))
 	  	 set @newrowcount = (select count(dashboard_template_link_to) from #dashboard_template_links)
 	 end
 	 
 	 insert into #Dashboard_Templates (dashboard_template_id, dashboard_template_procedure) select t.dashboard_Template_id, t.dashboard_template_procedure from dashboard_templates t where t.dashboard_template_id in (select distinct(dashboard_template_link_to) from #dashboard_template_links)
 	 
 	 set @newrowcount = (select count(dashboard_Template_link_id) from #dashboard_template_links where dashboard_Template_link_to = @template_id)
 	 
 	 if (@newrowcount = 0)
 	 begin
 	  	 insert into #Dashboard_Templates (dashboard_template_id, dashboard_template_procedure) select t.dashboard_Template_id, t.dashboard_template_procedure from dashboard_templates t where t.dashboard_template_id = @template_id
 	 end 	  	 
 	 
 	 insert into #Dashboard_Template_Parameters (Dashboard_Parameter_Type_ID) select p.dashboard_parameter_type_id from dashboard_template_parameters p, #dashboard_templates t where p.dashboard_template_id = t.dashboard_template_id
 	 insert into #Dashboard_DataTable_Headers (Dashboard_DataTable_Column_SP) select dth.dashboard_datatable_column_sp from dashboard_datatable_headers dth, #dashboard_template_parameters pt where dth.dashboard_parameter_type_id = pt.dashboard_parameter_type_id
 	 insert into #Template_Stored_Procedures (SP_Name) select distinct(dashboard_template_procedure) from #Dashboard_Templates where (not dashboard_template_procedure is null) and (not dashboard_template_procedure = "")
 	 insert into #Template_Stored_Procedures (SP_Name) select distinct(dashboard_datatable_column_sp) from #Dashboard_DataTable_Headers where (not dashboard_datatable_column_sp is null) and (not dashboard_datatable_column_sp = "")
 	 
 	 
 	 
create table #proc_stuff
(
 	 one varchar(50),
 	 two varchar(50),
 	 three varchar(50),
 	 four varchar(50),
 	 five varchar(50),
 	 six varchar(50),
 	 seven varchar(50),
 	 eight varchar(50)
)
declare @@proc_name varchar(100)
Declare Proc_Cursor INSENSITIVE CURSOR
  For Select SP_Name from #Template_Stored_Procedures
  For Read Only
  Open Proc_Cursor  
Proc_Loop:
  Fetch Next From Proc_Cursor Into @@proc_name
  If (@@Fetch_Status = 0)
    Begin
 	 set @@proc_name = @@proc_name + '%_Get_Columns'
 	 insert into #proc_stuff exec sp_stored_procedures @@proc_name, 'dbo'
 	 insert into #Template_Get_Columns select three from #proc_stuff
 	 delete from #proc_stuff
       	 Goto Proc_Loop
    End
Close Proc_Cursor 
Deallocate Proc_Cursor
insert into #Template_Stored_Procedures select * from #Template_Get_Columns
select * from #Template_Stored_Procedures 	 
