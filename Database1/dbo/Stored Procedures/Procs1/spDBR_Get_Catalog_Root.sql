Create Procedure dbo.spDBR_Get_Catalog_Root
 	 @UserID int,
 	 @Node varchar(50)
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
 	 if (not @slash = '/')
 	 begin
 	  	 set @server = @server + '/'
 	 end
 	 set @slash = (select left(@server, 2))
 	 if (not @slash = '//')
 	 begin
 	  	 set @server = '//' + @server
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
--/Dashboards
 	 set @slash = (select right(@prefix, 1))
 	 if (not @slash = '/')
 	 begin
 	  	 set @prefix = @prefix + '/'
 	 end
 	 
 	 set @slash = (select left(@prefix, 1))
 	 if (@slash = '/')
 	 begin
 	  	 set @prefix = right(@prefix, len(@prefix)-1)
 	 end
 	 set @prefix = @prefix + 'Dashboards'
 	  	 
--next start to build path
 	 declare @path varchar(2000)
 	 set @path = 'http:' + @server + @prefix
 	 select @path as dashboard_path
