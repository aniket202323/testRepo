Create Procedure dbo.spDBR_Get_Dialogue_Collection
@templateid int,
@languageid int = 0
AS
 	 create table #dialogue_collection
 	 (
 	  	 dashboard_dialogue_id int,
 	  	 dashboard_dialogue_name_id int, 
 	  	 dashboard_dialogue_name varchar(100),
 	  	 dialogue_order int,
 	  	 Parameter_Count int,
 	  	 Parameter_Description varchar(500),
 	  	 URL varchar(7000)
 	 )
 	 create table #parameter_collection
 	 (
 	  	 dashboard_dialogue_id int,
 	  	 dashboard_parameter_id int,
 	  	 dashboard_parameter_name varchar(100),
 	  	 dashboard_parameter_order int
 	 )
 	 
 	 create table #final_collection
 	 (
 	  	 dashboard_dialogue_id int,
 	  	 dashboard_dialogue_name_id int, 
 	  	 dashboard_dialogue_name varchar(100),
 	  	 dialogue_order int,
 	  	 Parameter_Count int,
 	  	 Parameter_Description varchar(500),
 	  	 URL varchar(7000)
 	 )
 	 
 	 insert into #dialogue_collection 
 	  	 select distinct(d.dashboard_dialogue_id),  	 
 	  	 case when isnumeric(dashboard_dialogue_name) = 1 then cast(dashboard_dialogue_name as int) else 0 end, 
 	  	 case when isnumeric(dashboard_dialogue_name) = 1 then (dbo.fnDBTranslate(@languageid, dashboard_dialogue_name, dashboard_dialogue_name)) else (dashboard_dialogue_name) end, 
 	  	 t.dashboard_template_parameter_order,d.Parameter_Count, '', d.URL 
 	  	 from dashboard_dialogues d, dashboard_template_dialogue_parameters p, dashboard_template_parameters t
 	  	 where t.dashboard_template_id = @templateid
 	  	  	 and p.dashboard_template_parameter_id = t.dashboard_template_parameter_id
 	  	  	 and d.dashboard_dialogue_id = p.dashboard_dialogue_id
 	  	  	 order by t.dashboard_template_parameter_order
 	  
 	 
 	 declare @dbid int
 	 declare @dbid_var_count int 	 
 	 declare @dbid_order int
 	 set @dbid = (select min(dashboard_dialogue_id) from #dialogue_collection)
 	 set @dbid_var_count = (select min(parameter_count) from #dialogue_collection where dashboard_dialogue_id = @dbid)
 	 set @dbid_order = (select min(dialogue_order) from #dialogue_collection where dashboard_dialogue_id = @dbid)
 	 
 	 
 	 while (not @dbid is null)
 	 begin
 	  	 insert into #parameter_collection select @dbid, t.dashboard_template_parameter_id,
 	  	 case when isnumeric(t.dashboard_template_parameter_name) = 1 then (dbo.fnDBTranslate(@languageid, t.dashboard_template_parameter_name, t.dashboard_template_parameter_name)) 
 	  	 else (t.dashboard_template_parameter_name)
 	  	 end as dashboard_template_parameter_name, 	 
 	  	 t.dashboard_template_parameter_order 
 	  	 from dashboard_template_dialogue_parameters d, dashboard_template_parameters t
 	  	 where t.dashboard_template_id = @templateid
 	  	  	 and d.dashboard_dialogue_id = @dbid
 	  	  	 and d.dashboard_template_parameter_id = t.dashboard_template_parameter_id
 	 
 	  	 declare @porder int, @pid int, @pdesc varchar(100)
 	  	 declare @paramnum int
 	  	 declare @paramstring varchar(10)
 	  	 
 	  	 set @paramstring = 'Parameter'
 	  	 set @paramnum = 1
 	  	 set @porder = (select min(dashboard_parameter_order) from #parameter_collection)
 	  	 set @pid = (select dashboard_parameter_id from #parameter_collection where dashboard_parameter_order = @porder)
 	  	 
 	  	 set @pdesc = (select dashboard_parameter_name from #parameter_Collection where @pid = dashboard_parameter_id)
 	  	 while(not @pid is null)
 	  	 begin
 	  	  	 while (not @pid is null and (@paramnum <= @dbid_var_count or @dbid_var_count = -1))
 	  	  	 begin
 	  	  	  	 if (@paramnum = 1)
 	  	  	  	 begin
 	  	  	  	  	 update #dialogue_collection set URL = URL + '?' + @paramstring + Convert(varchar(10), @paramnum) + '=' + Convert(varchar(200),@pid) where dashboard_dialogue_id = @dbid and dialogue_order = @dbid_order
 	  	  	  	  	 update #dialogue_collection set Parameter_Description = Parameter_Description + @pdesc where dashboard_dialogue_id = @dbid and dialogue_order = @dbid_order
 	  	  	  	 end
 	  	  	  	 else
 	  	  	  	 begin
 	  	  	  	  	 update #dialogue_collection set URL = URL + '&' + @paramstring + Convert(varchar(10), @paramnum) + '=' + Convert(varchar(200),@pid) where dashboard_dialogue_id = @dbid and dialogue_order = @dbid_order
 	  	  	  	  	 update #dialogue_collection set Parameter_Description = Parameter_Description + ' and ' + @pdesc where dashboard_dialogue_id = @dbid and dialogue_order = @dbid_order
 	  	  	  	 end
 	  	  	  	 delete from #parameter_collection where dashboard_parameter_id = @pid
 	  	  	  	 set @porder = (select min(dashboard_parameter_order) from #parameter_collection)
 	  	  	  	 set @pid = (select dashboard_parameter_id from #parameter_collection where dashboard_parameter_order = @porder)
 	  	  	  	 set @pdesc = (select dashboard_parameter_name from #parameter_Collection where @pid = dashboard_parameter_id)
 	  	  	  	 set @paramnum = @paramnum + 1
 	  	  	 
 	  	  	 end
 	  	  	 set @paramnum = 1
 	  	  	 insert into #final_collection select dashboard_dialogue_id, dashboard_dialogue_name_id, dashboard_dialogue_name, dialogue_order,parameter_count, parameter_Description, url from #dialogue_collection where dashboard_dialogue_id = @dbid and dialogue_order = @dbid_order
 	  	  	 delete from #dialogue_collection where dashboard_dialogue_id = @dbid and dialogue_order = @dbid_order
 	  	  	 set @dbid_order = (select min(dialogue_order) from #dialogue_collection where dashboard_dialogue_id = @dbid)
 	  	 end
 	  	 
 	  	 delete from #dialogue_collection where dashboard_dialogue_id = @dbid
 	  	 set @dbid = (select min(dashboard_dialogue_id) from #dialogue_collection)
 	  	 set @dbid_var_count = (select min(parameter_count) from #dialogue_collection where dashboard_dialogue_id = @dbid)
 	  	 set @dbid_order = (select min(dialogue_order) from #dialogue_collection where dashboard_dialogue_id = @dbid)
 	 end
update #final_collection set dialogue_order = (select max(dialogue_order) + 1 from #final_collection) where dashboard_dialogue_name = dbo.fnDBTranslate(@languageid, '38078', 'Options')
 	 declare @@dorder int, @@neworder int
 	 set @@neworder = 1
 	 
    Declare Dialogue_Cursor INSENSITIVE CURSOR
 	 For Select dialogue_order from #final_collection order by dialogue_order
 	 For Read Only
 	 Open Dialogue_Cursor  
 	 Dialogue_Loop:
 	 Fetch Next From Dialogue_Cursor Into @@dorder
 	 If (@@Fetch_Status = 0)
    Begin
 	  	 update #final_collection set dialogue_order = @@neworder where dialogue_order = @@dorder
 	  	 set @@neworder = @@neworder+1
      Goto Dialogue_Loop
    End
 	 
 	 Close Dialogue_Cursor 
 	 Deallocate Dialogue_Cursor
 	 
 	 select * from #final_collection order by dialogue_order
 	 drop table #dialogue_collection
 	 drop table #parameter_collection
 	 drop table #final_collection
 	 
 	  	  	  
