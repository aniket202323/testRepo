/*
Get Production Statistics for a unit by product
@Unit                    - Production Unit Id
@StartTime               - Start time
@EndTime                 - End time
@InTimeZone              - Ex: 'India Standard Time','Central Stardard Time'
*/
CREATE Procedure [dbo].[spBF_UnitStatisticsByProduct_Bak_177]
@Unit                    int,
@StartTime               datetime = NULL,
@EndTime                 datetime = NULL,
@InTimeZone              nVarChar(200) = NULL,
@FilterNonProductiveTime int = 0
, @pageSize 	  	  	  	  	 Int = 9999 	  	  	  	 -- # Results returned
, @pageNum 	  	  	  	  	 Int = 1 	  	  	  	 -- Offest for results
, @SortBy 	  	  	  	  	 Int = 2 	  	  	  	 -- 1 Sort by Description, otherwise Sort By PercentOfTotal
AS
/* ##### spBF_UnitStatisticsByProduct #####
Description 	 : 
Creation Date 	 : if any
Created By 	 : if any
#### Update History ####
DATE 	  	  	  	 Modified By 	  	  	 UserStory/Defect No 	  	  	  	  	 Comments 	  	 
---- 	  	  	  	 ----------- 	  	  	 ------------------- 	  	  	  	  	 --------
2018-05-28 	  	  	 Prasad 	  	  	  	 7.0 SP4 US255630 & US255626 	  	  	 Passed actual filter for NPT
*/
set nocount on
IF rtrim(ltrim(@InTimeZone)) = '' SET @InTimeZone = Null
SET @InTimeZone = coalesce(@InTimeZone,'UTC')
Declare @Results 	 Table( 	 ProductId int, 	  	  	  	 IdealSpeed float null, 	  	 ActualSpeed float null,
 	  	  	  	  	  	  	 IdealProduction float null, 	 PerformanceRate float null, 	 NetProduction float null,
 	  	  	  	  	  	  	 Waste float null, 	  	  	 QualityRate float null, 	  	 PerformanceDowntime float null,
 	  	  	  	  	  	  	 RunTime float null, 	  	  	 Loadtime float null, 	  	 AvaliableRate float null,
 	  	  	  	  	  	  	 OEE float null, 	  	  	  	 TotalProduction float null, 	 PercentOfTotal float null)
 	  	  	  	  	  	  	 
Declare @ResultsAgg 	 Table( 	 ProductId int, 	  	  	  	 IdealSpeed float null, 	  	 ActualSpeed float null,
 	  	  	  	  	  	  	 IdealProduction float null, 	 PerformanceRate float null, 	 NetProduction float null,
 	  	  	  	  	  	  	 Waste float null, 	  	  	 QualityRate float null, 	  	 PerformanceDowntime float null,
 	  	  	  	  	  	  	 RunTime float null, 	  	  	 Loadtime float null, 	  	 AvaliableRate float null,
 	  	  	  	  	  	  	 OEE float null, 	  	  	  	 TotalProduction float null, 	 PercentOfTotal float null)
DECLARE @FilteredProducts TABLE (RowID Int Identity (1,1), ProdDesc nvarchar(100),PercentOfTotal Float)
DECLARE @PagedProducts TABLE  ( RowID int IDENTITY, ProdDesc nvarchar(100))
DECLARE @startRow 	 Int
DECLARE @endRow 	  	 Int
DECLARE @UseAggTable 	 Int = 0
SELECT @UseAggTable = Coalesce(Value,0) FROM Site_parameters where parm_Id = 607
IF @UseAggTable = 0
BEGIN
Insert Into @Results (
 	  	 ProductId,
 	  	 IdealSpeed,
 	  	 ActualSpeed,
 	  	 IdealProduction,
 	  	 PerformanceRate,
 	  	 NetProduction,
 	  	 Waste,
 	  	 QualityRate,
 	  	 PerformanceDowntime,
 	  	 RunTime,
 	  	 Loadtime,
 	  	 AvaliableRate,
 	  	 OEE
 	 )
select 	 ProductId,
 	  	 IdealSpeed,
 	  	 ActualSpeed,
 	  	 IdealProduction,
 	  	 PerformanceRate,
 	  	 NetProduction,
 	  	 Waste,
 	  	 QualityRate,
 	  	 PerformanceDowntime,
 	  	 RunTime,
 	  	 Loadtime,
 	  	 AvaliableRate,
 	  	 OEE
  from 	 fnBF_wrQuickOEESummary(@Unit,@StartTime,@EndTime,@InTimeZone,@FilterNonProductiveTime,4,0)
END
ELSE
 	 BEGIN
 	  	 Insert Into @ResultsAgg (
 	  	 ProductId,
 	  	 IdealSpeed,
 	  	 ActualSpeed,
 	  	 IdealProduction,
 	  	 PerformanceRate,
 	  	 NetProduction,
 	  	 Waste,
 	  	 QualityRate,
 	  	 PerformanceDowntime,
 	  	 RunTime,
 	  	 Loadtime,
 	  	 AvaliableRate,
 	  	 OEE
 	 )
select 	 ProductId,
 	  	 IdealSpeed,
 	  	 ActualSpeed,
 	  	 IdealProduction,
 	  	 PerformanceRate,
 	  	 NetProduction,
 	  	 Waste,
 	  	 QualityRate,
 	  	 PerformanceDowntime,
 	  	 RunTime,
 	  	 Loadtime,
 	  	 AvaliableRate,
 	  	 OEE
  from dbo.fnBF_wrQuickOEESummaryAgg  (@Unit,@StartTime,@EndTime,@InTimeZone,1,@FilterNonProductiveTime)
Delete from @ResultsAgg Where ProductId = 1
  Insert Into @Results (
 	  	 ProductId,
 	  	 IdealSpeed,
 	  	 ActualSpeed,
 	  	 IdealProduction,
 	  	 PerformanceRate,
 	  	 NetProduction,
 	  	 Waste,
 	  	 QualityRate,
 	  	 PerformanceDowntime,
 	  	 RunTime,
 	  	 Loadtime,
 	  	 AvaliableRate,
 	  	 OEE
 	 )
 SELECT ProductId,
    Case WHEN Sum(s.RunTime) = 0 THEN 0 ELSE Sum(s.IdealProduction) / Sum(s.RunTime)END,
     Case WHEN Sum(s.RunTime) = 0 THEN 0 ELSE sum(s.NetProduction)/Sum(s.RunTime) END,
 	  Sum(s.IdealProduction),
 	  case when Sum(s.IdealProduction)  = 0 THEN 0 ELSE (sum(s.NetProduction)+ sum(s.Waste))/Sum(s.IdealProduction) END,
  	  sum(s.NetProduction), 
 	    Sum(s.Waste), 
  	  CASE WHEN (sum(s.NetProduction) + SUM(s.Waste)) = 0 THEN 0  	 ELSE (sum(s.NetProduction) )/(sum(s.NetProduction)+ Sum(s.Waste)) END, 
  	  sum(s.PerformanceDowntime), 
  	   sum(s.RunTime), 
  	   sum(s.LoadTime), 
  	   Case WHEN sum(s.LoadTime) = 0 THEN 0 Else  (sum(s.RunTime) + SUM(PerformanceDowntime))/ sum(s.LoadTime)  END,   	   
  	   0
  	    FROM @ResultsAgg s
 	    group by ProductId 
 	    UPDATE @Results Set QualityRate = QualityRate * 100
 	    UPDATE @Results set QualityRate = Case when QualityRate <0 Then 0 Else QualityRate End, 	    AvaliableRate = Case when QualityRate <0 Then 0 Else AvaliableRate End, 	    PerformanceRate = Case when QualityRate <0 Then 0 Else PerformanceRate End
 	     UPDATE @Results Set OEE = PerformanceRate * AvaliableRate * QualityRate
END 	 
-------------------------------------------------------------------------------------------------
-- Total Downtime
-------------------------------------------------------------------------------------------------
update @Results
 	 set TotalProduction 	 = NetProduction + Waste
Declare @UnitTotalProd Float
Select @UnitTotalProd = 0.0
Select @UnitTotalProd = @UnitTotalProd + coalesce((SELECT sum(TotalProduction) From @Results),0)
-------------------------------------------------------------------------------------------------
-- Calculate percentages
-------------------------------------------------------------------------------------------------
update @Results
 	 set PercentOfTotal 	  	 = Case when @UnitTotalProd > 0 then TotalProduction / @UnitTotalProd * 100 else 0 end
-------------------------------------------------------------------------------------------------
-- Generate Result Set
-------------------------------------------------------------------------------------------------
IF @SortBy = 1
 	 Insert Into @FilteredProducts(ProdDesc,PercentOfTotal)
 	  	 SELECT Distinct Prod_Desc,PercentOfTotal
 	  	 FROM @Results
 	  	 Join Products on Products.Prod_Id = ProductId
 	  	 ORDER BY Prod_Desc
ELSE
 	 Insert Into @FilteredProducts(ProdDesc,PercentOfTotal)
 	  	 SELECT Distinct Prod_Desc,PercentOfTotal
 	  	 FROM @Results
 	  	 Join Products on Products.Prod_Id = ProductId
 	  	 ORDER BY PercentOfTotal,Prod_Desc
SET @pageNum = coalesce(@pageNum,1)
SET @pageSize = coalesce(@pageSize,20)
SET @pageNum = @pageNum -1
SET @startRow = coalesce(@pageNum * @pageSize,0) + 1
SET @endRow = @startRow + @pageSize - 1
INSERT INTO @PagedProducts (ProdDesc)
 	 SELECT ProdDesc
 	  	 FROM @FilteredProducts
 	  	 WHERE RowId Between @startRow and @endRow
IF @SortBy = 1
BEGIN
 	 Select 	 a.ProductId,Product = b.Prod_Desc, 	 a.IdealSpeed,a.ActualSpeed, 	 a.IdealProduction, 	 
 	  	  	 a.PerformanceRate,a.NetProduction,a.Waste,a.QualityRate,a.PerformanceDowntime,
 	  	  	 a.RunTime,a.Loadtime,a.AvaliableRate,a.OEE,a.TotalProduction,
 	  	  	 a.PercentOfTotal,StartTime= '', 	 EndTime = '' 
 	  	 from @Results a
 	  	 Join Products b on b.Prod_Id = ProductId
 	  	 JOIN @PagedProducts  c on b.Prod_Desc = c.ProdDesc
 	  	 order by b.Prod_Desc Asc
END
ELSE
BEGIN
 	 Select 	 a.ProductId,Product = b.Prod_Desc, 	 a.IdealSpeed,a.ActualSpeed, 	 a.IdealProduction, 	 
 	  	  	 a.PerformanceRate,a.NetProduction,a.Waste,a.QualityRate,a.PerformanceDowntime,
 	  	  	 a.RunTime,a.Loadtime,a.AvaliableRate,a.OEE,a.TotalProduction,
 	  	  	 a.PercentOfTotal,StartTime= '', 	 EndTime = '' 
 	  	 from @Results a
 	  	 Join Products b on b.Prod_Id = ProductId
 	  	 JOIN @PagedProducts  c on b.Prod_Desc = c.ProdDesc
 	  	 order by PercentOfTotal desc
END
