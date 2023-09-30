Create Procedure dbo.spDBR_Get_Unit_List_From_Vars
@varlist text = '<Root></Root>'
as
 	 create table #Variables([Variable Name] varchar(50), [Variable ID] varchar(50)) 	 
 	 insert into #Variables EXECUTE spDBR_Prepare_Table @Varlist
create table #Units
(
 	 unit int
)
create table #distinctunits
(
 	 unit int
)
declare
  @@var_id int, @@unit_id int, @@unit_count int, @@unit_list varchar(1000)
Declare VAR_Cursor INSENSITIVE CURSOR
  For Select distinct([Variable ID]) from #Variables 
  For Read Only
  Open VAR_Cursor  
VAR_Loop:
  Fetch Next From VAR_Cursor Into @@var_id
  If (@@Fetch_Status = 0)
    Begin
 	 insert into #units select pu_id from variables where var_id = @@var_id
      Goto VAR_LOOP
    End
Close VAR_Cursor 
Deallocate VAR_Cursor
insert into #distinctunits select distinct(unit) from #units
set @@unit_count = 0
Declare UNIT_Cursor INSENSITIVE CURSOR
  For Select unit from #distinctunits
  For Read Only
  Open UNIT_Cursor  
UNIT_Loop:
  Fetch Next From UNIT_Cursor Into @@unit_id
  If (@@Fetch_Status = 0)
    Begin
 	 if (@@unit_count = 0)
 	 begin
 	  	 set @@unit_list = CONVERT(varchar(10),@@unit_id)
 	 end
 	 else
 	 begin
 	  	 set @@unit_list = @@unit_list + ',' + CONVERT(varchar(10),@@unit_id)
 	 end
 	 set @@unit_count = @@unit_count + 1
      Goto UNIT_LOOP
    End
Close UNIT_Cursor 
Deallocate UNIT_Cursor
select  @@unit_list as unitlist
