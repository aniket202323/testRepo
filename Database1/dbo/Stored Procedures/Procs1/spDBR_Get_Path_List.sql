Create Procedure dbo.spDBR_Get_Path_List
@lineid int = -1
AS 	  	 
 	 
 	 if (not @lineid = -1)
 	 begin
 	  	 select path_id, path_code from prdexec_paths where pl_id = @lineid
 	 end
 	 else
 	 begin
 	  	 select path_id, path_code from prdexec_paths
 	 end
