Create Procedure dbo.spDBR_Get_Resource_Name
@levelid int,
@resourceid int
as
 	 declare @resource varchar(50)
 	 if (@levelid = 1)
 	 begin
 	  	 set @resource = 'not implimented'
 	 end
 	 else if (@levelid = 2)
 	 begin
 	  	 set @resource = (select pl_desc from prod_lines where pl_id = @resourceid)
 	 end
 	 else if (@levelid = 3)
 	 begin
 	  	 set @resource = (select pu_desc from prod_units where pu_id = @resourceid)
 	 end
 	  	 
 	  insert into #sp_name_results select @resource
