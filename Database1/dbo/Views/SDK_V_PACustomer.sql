CREATE view SDK_V_PACustomer
as
select
Customer.Customer_Id as Id,
Customer.Address_1 as Address1,
Customer.Address_2 as Address2,
Customer.Address_3 as Address3,
Customer.Address_4 as Address4,
Customer.City as City,
Customer.Consignee_Code as ConsigneeCode,
Customer.Consignee_Name as ConsigneeName,
Customer.Contact_Name as ContactName,
Customer.Contact_Phone as ContactPhone,
Customer.Country as Country,
Customer.Customer_Code as CustomerCode,
Customer.Customer_General_1 as CustomerGeneral1,
Customer.Customer_General_2 as CustomerGeneral2,
Customer.Customer_General_3 as CustomerGeneral3,
Customer.Customer_General_4 as CustomerGeneral4,
Customer.Customer_General_5 as CustomerGeneral5,
Customer.Customer_Name as CustomerName,
Customer_Types.Customer_Type_Desc as CustomerType,
Customer.Extended_Info as ExtendedInfo,
Customer.Is_Active as IsActive,
Customer.State as State,
Customer.ZIP as Zip,
Customer.County as County,
Customer.Customer_Type as CustomerTypeId,
customer.City_State_Zip as CityStateZip
FROM Customer
 INNER JOIN Customer_Types ON Customer_Types.Customer_Type_Id = Customer.Customer_Type
