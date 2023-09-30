Create Procedure dbo.spSS_GetInitialOrder
AS
 Declare @NoOrderType nVarChar(50),
         @NoOrderStatus nVarChar(50),
         @NoProductGroup nVarChar(50),
 	  @NoProductionUnit nVarChar(50),
         @NoCustomerCode nVarChar(50),
         @NoConsigneeCode nVarChar(50),
         @AllProduct nVarChar(50)
 Select @NoOrderType = '<Any>'
 Select @NoOrderStatus = '<Any>'
 Select @NoProductGroup = '<Any>'
 Select @NoProductionUnit =  '<Any>'
 Select @NoCustomerCode = '<Any>'
 Select @NoConsigneeCode = '<Any>'
 Select @AllProduct = '<All>'
---------------------------------------------------------
-- Defaults
--------------------------------------------------------
 Select @NoOrderType as NoOrderType, @NoOrderStatus as NoOrderStatus, 
        @NoProductGroup as NoProductGroup, @NoProductionUnit as NoProductionUnit,
        @NoCustomerCode as NoCustomerCode, @NoConsigneeCode as NoConsigneeCode,
        @AllProduct as AllProduct
----------------------------------------------------------
-- Order Type combo box
--------------------------------------------------------
 Create Table #OT (TypeDesc nVarChar(50) Null)
 Insert Into #OT
  Select Distinct (Order_Type)
   From Customer_Orders
    Where Order_Type Is Not NULL
 Insert Into #OT
   Values (@NoOrderType)
 Select TypeDesc 
  From #OT
   Order By TypeDesc
 Drop Table #OT
----------------------------------------------------------
-- Order Status combo box
--------------------------------------------------------
Create Table #OS (StatusDesc nVarChar(50) Null)
 Insert Into #OS
  Select Distinct (Order_Status)
   From Customer_Orders
    Where Order_Status Is Not NULL
 Insert Into #OS
   Values (@NoOrderStatus)
 Select StatusDesc 
  From #OS
   Order By StatusDesc
 Drop Table #OS
-----------------------------------------------------------
-- Product Group combo box
-----------------------------------------------------------
 Create Table #PG (Product_Grp_Id int, Product_Grp_Desc  nVarChar(50))
 Insert Into #PG 
  Select Product_Grp_Id, Product_Grp_Desc
   From Product_Groups
 Insert Into #PG
  Select 0, @NoProductGroup
 Insert Into #PG
  Select -1, @AllProduct
 Select * From #PG
  Order by Product_Grp_Desc
 Drop Table #PG
-----------------------------------------------------------
-- Product Unit combo box
-----------------------------------------------------------
 Create Table #PU (PU_Id int, PU_Desc nVarChar(50))
 Insert Into #PU 
  Select PU_Id, PU_Desc
   From Prod_Units PU  
    Where PU_Id<>0
 Insert Into #PU
  Select 0, @NoProductionUnit  
 Select PU_Id, PU_Desc
  From #PU  
   Order by PU_Desc
 Drop Table #PU
----------------------------------------------------------
-- Customer Code combo box
-----------------------------------------------------------
 Create Table #Customer (CustomerCode nVarChar(50) null)
 Insert Into #Customer
  Select Distinct C.Customer_Code 
   From Customer C Inner Join Customer_Orders O
    On C.Customer_Id = O.Customer_Id
 Insert Into #Customer
  Select @NoCustomerCode
 Select CustomerCode
  From #Customer
   Order By CustomerCode
 Drop Table #Customer   
----------------------------------------------------------
-- Consignee Code combo box
-----------------------------------------------------------
 Create Table #Consignee (ConsigneeCode nVarChar(50) null)
 Insert Into #Consignee
  Select Distinct C.Customer_Code 
   From Customer C Inner Join Customer_Orders O
    On C.Customer_Id = O.Consignee_Id
 Insert Into #Consignee
  Select @NoConsigneeCode
 Select ConsigneeCode
  From #Consignee
   Order By ConsigneeCode
 Drop Table #Consignee   
