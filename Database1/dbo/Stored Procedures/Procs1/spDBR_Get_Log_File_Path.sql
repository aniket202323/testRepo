Create Procedure dbo.spDBR_Get_Log_File_Path
@UserID int
AS
declare @path varchar(300)
execute spServer_CmnGetParameter 101,@UserID, '', @path output
select @path as dashboard_logfile_path
 	  	  	 
