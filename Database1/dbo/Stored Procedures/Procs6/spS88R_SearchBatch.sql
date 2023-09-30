CREATE PROCEDURE [dbo].[spS88R_SearchBatch]
--Declare
@Unit int,
@StartTime datetime,
@EndTime datetime,
@ProductMask nVarChar(50),
@NameMask nVarChar(50),
@InTimeZone nVarChar(200)=NULL
AS
 	 SELECT @StartTime=[dbo].[fnServer_CmnConvertToDbTime] (@StartTime,@InTimeZone)
 	 SELECT @EndTime=[dbo].[fnServer_CmnConvertToDbTime] (@EndTime,@InTimeZone)
 /******************************************************
-- For Testing
--*******************************************************
Select @Unit = 52
Select @StartTime = '1-jan-01'
Select @EndTime = '1-jan-04'
Select @ProductMask = NULL
Select @NameMask = NULL
--*******************************************************/
Declare @UnitName nVarChar(100)
Select @UnitName = pu_desc from prod_units where pu_id = @Unit
 	  	 Select [Id] = e.Event_Id, BatchName = e.Event_Num, Product = Case when e.Applied_Product Is Null Then p1.Prod_Code Else p2.Prod_Code End, 
 	  	        UnitName = @UnitName, Timestamp =   [dbo].[fnServer_CmnConvertFromDbTime] (e.Timestamp,@InTimeZone)  , Status = s.ProdStatus_Desc, Comment = c.Comment_Text  
 	  	   From Events e
 	  	   join production_starts ps on ps.pu_id = @Unit and ps.start_time <= e.Timestamp and ((ps.end_time > e.Timestamp) or (ps.end_time is null))
 	  	   join products p1 on p1.prod_id = ps.prod_id
 	  	   join production_status s on s.prodstatus_id = e.event_status 
 	  	   left outer join products p2 on p2.prod_id = e.applied_product
 	  	   left outer join comments c on c.comment_id = e.comment_id 
 	  	   Where e.pu_id = @Unit and 
 	  	         e.Timestamp Between @StartTime and @EndTime and
 	  	         e.event_Num like '%' + coalesce(@NameMask, '') + '%' and
            Case when e.Applied_Product Is Null Then p1.Prod_Code Else p2.Prod_Code End like '%' + coalesce(@ProductMask, '') + '%'
