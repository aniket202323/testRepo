Create Procedure dbo.spSS_GetInitialShipment
AS
 Declare @NoCarrierCode nVarChar(50),
         @NoCarrierType nVarChar(50),
         @NoProductGroup nVarChar(50),
 	  @NoProductionUnit nVarChar(50),
         @NoCustomerCode nVarChar(50),
         @NoConsigneeCode nVarChar(50) 
 Select @NoCarrierType = '<Any>'
 Select @NoCarrierCode = '<Any>'
 Select @NoProductGroup = '<Any>'
 Select @NoProductionUnit =  '<Any>'
 Select @NoCustomerCode =  '<Any>'
 Select @NoConsigneeCode =  '<Any>'
---------------------------------------------------------
-- Defaults
--------------------------------------------------------
 Select @NoCarrierType as NoCarrierType, @NoCarrierCode as NoCarrierCode, 
        @NoProductGroup as NoProductGroup, @NoProductionUnit as NoProductionUnit,
        @NoCustomerCode as NoCustomerCode, @NoConsigneeCode as NoConsigneeCode
----------------------------------------------------------
-- CarrierCode combo box
--------------------------------------------------------
/*
 Create Table #CA (Carrier_Code nVarChar(25) Null)
 Insert Into #CA
  Select Distinct (Carrier_Code)
   From Shipment
    Where Carrier_Code Is Not NULL
 Insert Into #CA
   Values (@NoCarrierCode)
 Select Carrier_Code 
  From #CA
   Order By Carrier_Code
 Drop Table #CA
*/
----------------------------------------------------------
-- CarrierTYPE combo box
--------------------------------------------------------
/*
 Create Table #CT (Carrier_Type nVarChar(25) Null)
 Insert Into #CT
  Select Distinct (Carrier_Type)
   From Shipment
    Where Carrier_Type Is Not NULL
 Insert Into #CT
   Values (@NoCarrierType)
 Select Carrier_Type 
  From #CT
   Order By Carrier_Type
 Drop Table #CT
*/
-----------------------------------------------------------
-- Product Group combo box
-----------------------------------------------------------
 Create Table #PG (Product_Grp_Id int, Product_Grp_Desc  nVarChar(50))
 Insert Into #PG 
  Select Product_Grp_Id, Product_Grp_Desc
   From Product_Groups
 Insert Into #PG
  Select 0, @NoProductGroup
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
