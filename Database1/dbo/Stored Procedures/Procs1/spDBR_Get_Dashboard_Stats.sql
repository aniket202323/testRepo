Create Procedure dbo.spDBR_Get_Dashboard_Stats
 	 @UserID int,
 	 @Node varchar(50),
 	 @dashboard_key varchar(1000)
AS
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
 	  
 	  
 	 declare @sqlquery nvarchar(4000)
-- 	 set @dashboard_key = (select replace(@dashboard_key, '{', ''))
-- 	 set @dashboard_key = (select replace(@dashboard_key, '}', ''))
 	 declare @count int
 	 set @count = (select count(statistic_id) from dashboard_statistics where dashboard_key = @dashboard_key)
 	 if (@count = 0)
 	 begin
 	  	 insert into dashboard_statistics (dashboard_key, number_hits, last_access) values (@dashboard_key, 0, dbo.fnServer_CmnGetDate(getutcdate()))
 	 end
--- 	 set @sqlquery = 'select ds.number_hits, ds.last_access from dashboard_statistics ds,  
 -- 	  	  	  	  	 where dashboard_key ="' +  @dashboard_key + '"'
select ds.number_hits, ds.last_access from dashboard_statistics ds where dashboard_key = @dashboard_key 
--select @sqlquery
--execute sp_executesql @sqlquery
