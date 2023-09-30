Create Procedure dbo.spDBR_Get_Web_Part_Path
@UserID int,
@Node varchar(50)
AS
 	 
 	 declare @path varchar(50)
 	 declare @proto varchar(50)
 	 declare @server varchar(50)
 	 execute spServer_CmnGetParameter 160,@UserID, @Node, @path output
 	 execute spServer_CmnGetParameter 167,@UserID, @Node, @server output
--Check if we use https
 	 declare @useHttps varchar(50)
 	 set @useHttps='0'
 	 set @proto='http://' 
 	 execute spServer_CmnGetParameter 90, @UserID,'', @useHttps output
 	 if (@useHttps = '1')
 	 begin 
 	  	 set @proto='https://'
 	 end
--Check Port 	 
 	  declare @port varchar(50)
 	  set @port=80
 	 if (@useHttps='0')
 	 begin
 	  	 execute spServer_CmnGetParameter 91, @UserID,'', @port output 	 
 	 end
 	 else
 	 begin
 	  	 execute spServer_CmnGetParameter 92, @UserID,'', @port output 	 
 	 end
 	 
 	  	 
select @server+':'+@port as Server, @path as Path, 'mswebpart.aspx' as Page
