Create Procedure dbo.spDBR_Add_Parameter
@parameter_desc varchar (100),
@datatypeid int
AS
 	 declare @returnid int
 	 /*declare @iconid int
 	 set @iconid = (select min(dashboard_icon_id) from dashboard_icons)
 	 */
 	 declare @count int
 	 declare @version int
 	 set @version = 1
 	 set @count = (select count(dashboard_parameter_type_id) from dashboard_parameter_types where dashboard_parameter_type_desc = @parameter_desc)
 	 if (@count > 0)
 	 begin
 	  	 set @version = (select max(version) from dashboard_parameter_types where dashboard_parameter_type_Desc = @parameter_desc) + 1
 	 end 	 
 	 insert into dashboard_parameter_types (Dashboard_Parameter_Type_Desc, Dashboard_Parameter_Data_Type_ID/*,Dashboard_Icon_ID*/,locked,version)
 	 values (@parameter_desc, @datatypeid,/*@iconid,*/0, @version)
 	 
 	 set @returnid = (select scope_identity())
 	 
 	 select @returnid as id
 	 
