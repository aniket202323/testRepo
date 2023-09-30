Create Procedure dbo.spDBR_Get_Web_Application_Physical_Path
 	 @UserID int,
 	 @Node varchar(50)
AS
 	 
 	 declare @path varchar(300)
 	 declare @localpath varchar(5000)
 	 declare @server varchar(50)
 	 execute spServer_CmnGetParameter 160,@UserID, @Node, @path output
 	 execute spServer_CmnGetParameter 172,@UserID, @Node, @localpath output
 	 execute spServer_CmnGetParameter 167,@UserID, @Node, @server output
 	 
 	 select @server as Server, @path as PhysicalPath, @localpath as LocalPhysicalPath
