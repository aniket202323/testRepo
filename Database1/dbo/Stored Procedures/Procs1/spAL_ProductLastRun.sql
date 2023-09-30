Create Procedure dbo.spAL_ProductLastRun @ProdId int, @StartTime datetime 
AS
  select rtnTime = max(start_time) 
 	 from production_starts where prod_id = @ProdId and start_time < @StartTime
