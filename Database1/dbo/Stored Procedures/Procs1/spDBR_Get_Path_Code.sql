Create Procedure dbo.spDBR_Get_Path_Code
@path_id int
as
 	 insert into #sp_name_results select path_code from prdexec_paths where path_id = @path_id
