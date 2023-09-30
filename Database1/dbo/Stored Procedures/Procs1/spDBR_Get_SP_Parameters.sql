Create Procedure dbo.spDBR_Get_SP_Parameters
@SPName varchar(750)
AS
 	 execute sp_help @SPName
