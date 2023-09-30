Create Procedure dbo.spEM_GetDomainNames 
AS
SELECT DefaultDomain = coalesce(value,'') FROM Site_Parameters where Parm_Id = 69
SELECT DISTINCT UserDomainName = SUBSTRING(WindowsUserInfo , 1,CHARINDEX( '\',WindowsUserInfo) - 1)
 	 From Users
 	 WHERE  CHARINDEX( '\',WindowsUserInfo) > 0
