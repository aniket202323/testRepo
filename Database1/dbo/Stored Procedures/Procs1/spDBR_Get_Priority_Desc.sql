Create Procedure dbo.spDBR_Get_Priority_Desc
@id int
as
 	 if (@id = 1)
 	 begin
 	  	 insert into #sp_name_results select 'Low'
 	 end 	 
 	 if (@id = 2)
 	 begin
 	  	 insert into #sp_name_results select 'Medium'
 	 end
 	 if (@id = 3)
 	 begin
 	  	 insert into #sp_name_results select 'High'
 	 end
