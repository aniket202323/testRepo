Create Procedure dbo.spDBR_Get_Dashboard_Path
 	 @UserID int,
 	 @Node varchar(50),
 	 @dashboard_key varchar(100)
AS
--set up server name and catalog of database to get dashboard stuff from
 	 declare @catalog varchar(50)
 	 declare @server varchar(50)
 	 set @server = ''
 	 set @catalog = ''
 	  
 	 execute spServer_CmnGetParameter 174,@UserID,@Node, @catalog output
 	 if (@catalog = '' or @catalog is null)
 	 begin
 	  	 set @catalog = 'DAVCatalog'
 	 end
 	  
 	  
 	 execute spServer_CmnGetParameter 166,@UserID,@Node, @server output
 	 if (@server = '' or @server is null)
 	 begin
 	  	 set @server = (select @@ServerName)
 	 end
 	 declare @slash varchar(2)
 	 set @slash = (select right(@server, 1))
 	 if (@slash = '/')
 	 begin
 	  	 set @server = (select left(@server, len(@server)-1))
 	 end
 	 set @slash = (select left(@server, 2))
 	 if (@slash = '//')
 	 begin
 	  	 set @server = (select right(@server, len(@server)-2))
 	 end
 create table #prefix
(
 	 dashboard_prefix varchar(2000)
)
 declare @sqlquery nvarchar(4000)
 	 
set @sqlquery = N'spDBR_Get_Digital_Dashboard_Prefix ' + Convert(nvarchar(50),@UserID) + ',' +  Convert(nvarchar(50),@node)
 	 
insert into #prefix execute (@sqlquery)
 	 
declare @id varchar(4000)
set @id = (select dashboard_prefix from #prefix)
set @id = @id + @dashboard_key --(select id from #id)
select @id as dashboard_path
