CREATE view SDK_V_PACustomerOrder
as
select
Customer_Orders.Order_Id as Id,
Customer_Orders.Is_Active as IsActive,
Customer_Orders.Entered_Date as EnteredDate,
Customer_Orders.Forecast_Mfg_Date as ForecastMfgDate,
Customer_Orders.Forecast_Ship_Date as ForecastShipDate,
Customer_Orders.Actual_Mfg_Date as ActualMfgDate,
Customer_Orders.Actual_Ship_Date as ActualShipDate,
consignee.Customer_Code as ConsigneeCode,
Customer_Orders.Total_Line_Items as TotalLineItems,
Customer.Customer_Code as CustomerCode,
Customer_Orders.Order_General_1 as OrderGeneral1,
Customer_Orders.Order_General_2 as OrderGeneral2,
Customer_Orders.Order_General_3 as OrderGeneral3,
Customer_Orders.Order_General_4 as OrderGeneral4,
Customer_Orders.Order_General_5 as OrderGeneral5,
Customer_Orders.Order_Instructions as OrderInstructions,
Customer_Orders.Order_Type as OrderType,
Customer_Orders.Order_Status as OrderStatus,
Customer_Orders.Customer_Order_Number as CustomerOrderNumber,
Customer_Orders.Plant_Order_Number as PlantOrderNumber,
Customer_Orders.Corporate_Order_Number as CorporateOrderNumber,
Customer_Orders.Comment_Id as CommentId,
Customer_Orders.Extended_Info as ExtendedInfo,
Customer_Orders.Customer_Id as CustomerId,
Customer_Orders.Consignee_Id as ConsigneeId,
Comments.Comment_Text as CommentText,
Customer_Orders.Entered_By as EnteredByUserId,
Users.Username as EnteredByUsername,
Customer.Customer_Name as CustomerName,
consignee.Customer_Name as ConsigneeName,
customer_orders.Schedule_Block_Number as ScheduleBlockNumber
FROM Customer_Orders
 INNER JOIN Customer ON Customer.Customer_Id = Customer_Orders.Customer_Id
 LEFT JOIN Customer consignee ON consignee.Customer_Id = Customer_Orders.Consignee_Id
 LEFT JOIN Customer_Order_Line_Items ON Customer_Order_Line_Items.Order_Id = Customer_Orders.Order_Id
 LEFT JOIN Users ON Users.User_Id = Customer_Orders.Entered_By
LEFT JOIN Comments Comments on Comments.Comment_Id=customer_orders.Comment_Id
