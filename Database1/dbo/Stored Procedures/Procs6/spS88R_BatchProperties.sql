CREATE procedure [dbo].[spS88R_BatchProperties]
@EventId int,
@InTimeZone nvarchar(200)=NULL
AS
/******************************************************
-- For Testing
--*******************************************************
Select @EventId = 31167
--*******************************************************/
Select UnitId = pu.pu_id,
       Unit = pu.pu_desc,
       BatchNumber = e.Event_Num,
       Product = case when e.applied_product is null Then p1.Prod_Code Else p2.Prod_Code End,
 	    StartTime =    [dbo].[fnServer_CmnConvertFromDbTime] ((coalesce(e.Start_Time, e.Timestamp)),@InTimeZone)  , 
       EndTime =  [dbo].[fnServer_CmnConvertFromDbTime] ([timestamp],@InTimeZone) , 
       Status = psd.ProdStatus_Desc,
       Color = Case 
               When psd.Status_Valid_For_Input > 0 Then 0
               Else 2 
             End,
       ProductId =  case when e.applied_product is null Then p1.Prod_Id Else p2.Prod_Id End
  From Events e
  join prod_units pu on pu.pu_id = e.pu_id
  Join Production_Status psd on psd.ProdStatus_Id = e.Event_Status 
  Join production_starts ps on ps.pu_id = e.pu_id and ps.start_time <= e.timestamp and ((ps.end_time > e.timestamp) or (ps.end_time is null))
  Join Products p1 on p1.Prod_id = ps.prod_id
  Left Outer Join Products p2 on p2.Prod_id = e.Applied_Product
  Where e.event_id = @EventId     
