Create Procedure dbo.spDS_UpdateEventDataCont
 @EventID int,
 @CustomerOrderNumber nVarChar(50)= NULL,
 @ProcessOrder nVarChar(50) = NULL
AS
/*
This SP updates fields on customer_orders and production_plan tables as long as there is the
necessary information on the event_details table for the passed EventId
spDS_UpdateEventDataCont
 @EventId=94450,
 @CustomerOrderNumber = 'OrderNumber',
 @ProcessOrder = 'ProcessOrder'
*/
 If (@CustomerOrderNumber Is Not Null)
  Update Customer_Orders
   Set Customer_Order_Number = @CustomerOrderNumber
    From Customer_Orders
     Inner Join Event_Details On Event_Details.Order_id = Customer_Orders.Order_Id
      Where Event_Details.Event_Id = @EventId
 If (@ProcessOrder Is Not Null)
  Update Production_Plan
   Set Process_Order = @ProcessOrder
     From Production_Plan
      Inner Join Event_Details On Event_Details.PP_Id = Production_Plan.PP_Id
       Where Event_Details.Event_Id = @EventId
