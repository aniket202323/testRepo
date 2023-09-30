Create Procedure dbo.spDBR_Update_Dashboard_Stats
@dashboard_key varchar(100)
AS
 	 declare @numhits int
 	 set @numhits = (select number_hits from dashboard_statistics where dashboard_key = @dashboard_key)
 	 set @numhits = @numhits + 1
-- 	 update dashboard_dashboards set dashboard_number_hits = @numhits, dashboard_last_access = dbo.fnServer_CmnGetDate(getutcdate()) where dashboard_key = @dashboard_key
update dashboard_statistics set number_hits = @numhits, last_access = dbo.fnServer_CmnGetDate(getutcdate()) where dashboard_key = @dashboard_key 	 
 	 
