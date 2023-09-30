Create Procedure dbo.spDBR_Get_Resource_Level_Desc
@level int
as
 	 if (@level = 1)
 	 begin
 	  	 insert into #sp_name_results select 'Department'
 	 end
 	 if (@level = 2)
 	 begin
 	  	 insert into #sp_name_results select 'Line'
 	 end
 	 if (@level = 3)
 	 begin
 	  	 insert into #sp_name_results select 'Unit'
 	 end
