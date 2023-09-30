Create Procedure dbo.spDBR_Add_Template_Parameter
@parameter_name varchar(100),
@template_id int,
@parameter_type int
AS
 	 
 	 declare @paramid int
 	 declare @order int
 	 declare @count int
 	 
 	 set @count = (select count(dashboard_template_parameter_order) from dashboard_template_parameters where dashboard_template_id = @template_id)
 	 
 	 if (@count > 0)
 	 begin
 	  	 set @order = (select max(dashboard_template_parameter_order) from dashboard_template_parameters where dashboard_template_id = @template_id)
 	  	 set @order = @order+1
 	 end
 	 else
 	 begin
 	  	 set @order = 1
 	 end
 	 
 	 insert into Dashboard_Template_Parameters (dashboard_template_parameter_name, dashboard_template_id, dashboard_template_parameter_order, dashboard_parameter_type_id, has_default_value) 
 	                                    values (@parameter_name, @template_id,@order , @parameter_type, 0)
 	 
 	 set @paramid =  (select scope_identity())
 	 declare @dashboard_key int, @altkey int
 	 
 	 set @dashboard_key = (select min(dashboard_dialogue_id) from dashboard_dialogue_parameters where dashboard_parameter_type_id = @parameter_Type and default_dialogue = 1) 	 
 	 set @altkey = (select min(dashboard_dialogue_id) from dashboard_dialogue_parameters where dashboard_parameter_type_id = @parameter_Type)
 	 
 	 set @dashboard_key = (select isnull(@dashboard_key, @altkey))
 	 insert into Dashboard_Template_Dialogue_Parameters (Dashboard_Dialogue_ID, Dashboard_Template_Parameter_ID)
 	  	 values (@dashboard_key, @paramid)
 	  	 
 	 select @paramid as id
