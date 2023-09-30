CREATE view SDK_V_PACustomerOrderLineSpec
as
select
Customer_Order_Line_Specs.Order_Spec_Id as Id,
Customer.Customer_Code as CustomerCode,
Customer_Orders.Plant_Order_Number as PlantOrderNumber,
Customer_Order_Line_Items.Line_Item_Number as LineItemNumber,
Customer_Order_Line_Specs.Spec_Desc as SpecName,
Data_Type.Data_Type_Desc as DataType,
Customer_Order_Line_Specs.Spec_Precision as SpecPrecision,
Customer_Order_Line_Specs.L_Limit as LowerLimit,
Customer_Order_Line_Specs.Target as Target,
Customer_Order_Line_Specs.U_Limit as UpperLimit,
Customer_Order_Line_Specs.Is_Active as IsActive,
Customer_Order_Line_Items.Order_Id as CustomerOrderId,
Customer_Order_Line_Specs.Order_Line_Id as CustomerOrderLineId,
Customer_Orders.Customer_Id as CustomerId,
Customer_Order_Line_Specs.Data_Type_Id as DataTypeId
FROM Customer_Order_Line_Specs
 INNER JOIN Data_Type ON Customer_Order_Line_Specs.Data_Type_Id = Data_Type.Data_Type_Id 
 INNER JOIN Customer_Order_Line_Items ON Customer_Order_Line_Items.Order_Line_Id = Customer_Order_Line_Specs.Order_Line_Id 
 INNER JOIN Customer_Orders ON Customer_Orders.Order_Id = Customer_Order_Line_Items.Order_Id 
 INNER JOIN Customer ON Customer.Customer_Id = Customer_Orders.Customer_Id
