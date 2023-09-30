Create Procedure dbo.spDBR_Get_Path_Code_For_Dialog
@path_id int = 1
as
 	 select path_code from prdexec_paths where path_id = @path_id
