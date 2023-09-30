Create Procedure dbo.spDBR_Export_Database_Stored_Procedures
AS
 	 create table #Template_Stored_Procedures
 	 (
 	  	 SP_Name varchar(100) 	 
 	 )
 	 create table #Template_Get_Columns
 	 (
 	  	 SP_Name varchar(100) 	 
 	 )
 	 insert into #Template_Stored_Procedures (SP_Name) select distinct(dashboard_template_procedure) from Dashboard_Templates where (not dashboard_template_procedure is null) and (not dashboard_template_procedure = "")
 	 insert into #Template_Stored_Procedures (SP_Name) select distinct(dashboard_datatable_column_sp) from Dashboard_DataTable_Headers where (not dashboard_datatable_column_sp is null) and (not dashboard_datatable_column_sp = "")
 	 
 	 
 	 
declare @@proc_name varchar(100)
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
