Create Procedure dbo.spDBR_Get_Digital_Dashboard_Prefix
 	 @UserID int = 29,
 	 @Node varchar(50) = ''
AS
--fist get server name
 	 declare @server varchar(50)
 	 set @server = ''
 	 
 	 execute spServer_CmnGetParameter 166,@UserID,@Node, @server output
 	 if (@server = '' or @server is null)
 	 begin
 	  	 set @server = (select @@ServerName)
 	 end
 	 declare @slash varchar(2)
 	 set @slash = (select right(@server, 1))
 	 if ( @slash = '/')
 	 begin
 	  	 set @server =(select LEFT(@server,len(@server)-1))
 	 end
 	 set @slash = (select left(@server, 2))
 	 if ( @slash = '//')
 	 begin
 	  	 set @server =(select RIGHT( @server,LEN(@server)-2))
 	 end
 	 
--second get virtual path on that machine to the digital dashboard
 	 declare @root varchar(50)
 	 set @root = ''
 	 execute spServer_CmnGetParameter 159,@UserID,@Node, @root output
 	 if (@root = '' or @root is null)
 	 begin
 	  	 set @root = 'DashBoard/Dashboard.asp'
 	 end
 	 set @slash = (select left(@root, 1))
 	 if (@slash = '/')
 	 begin
 	  	 set @root = right(@root, len(@root)-1)
 	 end
--third build prefix of dashboardid
 	 declare @prefix varchar(50)
 	 set @prefix = ''
 	  	 
 	 --168 will change to be whatever the paramid of this item is
 	 execute spServer_CmnGetParameter 174, @UserID,@Node, @prefix output
 	 if (@prefix = '' or @prefix is null) 
 	 begin
 	  	 set @prefix = 'DAVCatalog'
 	 end 
 	 set @slash = (select right(@prefix, 1))
 	 if (@slash = '/')
 	 begin
 	  	 set @prefix = left(@prefix, len(@prefix)-1)
 	 end
 	 
 	 set @slash = (select left(@prefix, 1))
 	 if (@slash = '/')
 	 begin
 	  	 set @prefix = right(@prefix, len(@prefix)-1)
 	 end
 	 
 	 
--Check if we use https
 	 declare @useHttps varchar(50)
 	 declare @path varchar(5000)
 	 set @useHttps='0'
 	 set @path="http://"
 	 execute spServer_CmnGetParameter 90, @UserID,'', @useHttps output
 	 if (@useHttps = '1')
 	 begin 
 	  	 set @path="https://"
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
--next start to build path
 	 
 	 set @path = @path + @server+ ":" + @port+'/'+ @root + '?DashboardID=' /*http:' + @server + @prefix*/
 	 select @path as dashboard_path
