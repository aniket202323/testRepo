Create Procedure dbo.spDBR_Get_Resource_List
@levelid int
AS 	 
 	 create table #resources
 	 (
 	  	 Resource_Desc varchar(100),
 	  	 Resource_ID int
 	 )
 	 
/* 	 if (@levelid = 1)
 	 begin
 	  	 insert into #resources (Resource_Desc, Resource_ID)
 	 end
 	 else*/ if (@levelid = 2)
 	 begin
 	  	 insert into #resources (Resource_Desc, Resource_ID) select Pl_Desc, Pl_ID from prod_lines
 	 end
 	 else if (@levelid = 3)
 	 begin
 	  	 insert into #resources (Resource_Desc, Resource_ID) select Pu_Desc, Pu_ID from prod_units
 	 end
 	 select * from #resources where resource_ID > 0
