CREATE PROCEDURE dbo.spRS_AdminDeleteReportServerLinks
@Link_Id Int
AS
Delete From Report_Server_Links 
Where  Link_Id = @Link_Id
