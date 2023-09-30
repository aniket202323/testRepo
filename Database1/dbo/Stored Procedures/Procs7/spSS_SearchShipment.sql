Create Procedure dbo.spSS_SearchShipment
 @ShipmentNumber nVarChar(50) = NULL,
 @PlantOrderNumber nVarChar(50) = NULL,
 @CustomerOrderNumber nVarChar(50) = NULL,
 @CorporateOrderNumber nVarChar(50) = NULL,
 @CarrierCode nVarChar(25) = NULL,
 @CarrierType nVarChar(10) = NULL,
 @CustomerCode nVarChar(50) = NULL,
 @ConsigneeCode nVarChar(50) = NULL,
 @Date1 DateTime = NULL,
 @Date2 DateTime = NULL,
 @Date3 DateTime = NULL,
 @Date4 DateTime = NULL,
 @Products nVarChar(1024) = NULL,
 @PUId Int = NULL,
 @Comment nVarChar(255) = NULL,
 @RegionalServer Int = 0
AS
If @RegionalServer Is Null
 	 Select @RegionalServer = 0
 Declare @SQLCommand Varchar(4500),
 	  	  @SQLCond0 nVarChar(1024),
         @ShipmentId int, 
         @OrderId int,
         @FieldName nVarChar(50),
         @StartTime DateTime, 
         @ProdId int,
         @FlgAnd int,
         @FlgFirst int,
         @EndPosition int
--------------------------------------------
-- Initialize variables
---------------------------------------------
 Select @FlgFirst= 0
 Select @FlgAnd = 0
 Select @SQLCOnd0 = NULL
  Select @SQLCommand = 'Select S.Shipment_Id, SI.Order_Id ' +
                       'From Shipment S ' +
                       'Inner Join Shipment_Line_Items SI On S.Shipment_Id = SI.Shipment_Id ' +
                       'Inner Join Customer_Orders O On SI.Order_Id = O.Order_Id ' + 
                       'Inner Join Customer C On C.Customer_Id = O.Customer_Id ' +
                       'Left Outer Join Customer C2 On C2.Customer_Id = O.Consignee_Id ' +
                       'Left Outer Join Comments CO on S.Comment_Id = CO.COmment_Id ' 
--------------------------------------------------------
-- Shipment Order Number
------------------------------------------------------
 If (@ShipmentNumber Is Not Null  And Len(@ShipmentNumber)>0) 
  Begin
   Select @SQLCond0 = "S.Shipment_Number Like '%" + @ShipmentNumber + "%'"
   If (@FlgAnd=1)
    Begin
     Select @SQLCommand =  @SQLCommand + ' And (' + @SQLCond0 + ')' 	                   
    End
   Else
    Begin
     Select @SQLCommand =  @SQLCommand + ' Where (' + @SQLCond0 + ')' 	  
     Select @FlgAnd = 1  
    End 
  End  
--------------------------------------------------------
-- Plant Order Number
------------------------------------------------------
 If (@PlantOrderNumber Is Not Null  And Len(@PlantOrderNumber)>0) 
  Begin
   Select @SQLCond0 = "O.Plant_Order_Number Like '%" + @PlantOrderNumber + "%'"
   If (@FlgAnd=1)
    Begin
     Select @SQLCommand =  @SQLCommand + ' And (' + @SQLCond0 + ')' 	                   
    End
   Else
    Begin
     Select @SQLCommand =  @SQLCommand + ' Where (' + @SQLCond0 + ')' 	  
     Select @FlgAnd = 1  
    End 
  End  
--------------------------------------------------------
-- Customer Order Number
------------------------------------------------------
 If (@CustomerOrderNumber Is Not Null And Len(@CustomerOrderNumber)>0) 
  Begin
   Select @SQLCond0 = "O.Customer_Order_Number Like '%" + @CustomerOrderNumber + "%'"
   If (@FlgAnd=1)
    Begin
     Select @SQLCommand =  @SQLCommand + ' And (' + @SQLCond0 + ')' 	                   
    End
   Else
    Begin
     Select @SQLCommand =  @SQLCommand + ' Where (' + @SQLCond0 + ')' 	  
     Select @FlgAnd = 1  
    End 
  End  
--------------------------------------------------------
-- Corporate Order Number
------------------------------------------------------
 If (@CorporateOrderNumber Is Not Null And Len(@CorporateOrderNumber)>0)
  Begin
   Select @SQLCond0 = "O.Corporate_Order_Number Like '%" + @CorporateOrderNumber + "%'"
   If (@FlgAnd=1)
    Begin
     Select @SQLCommand =  @SQLCommand + ' And (' + @SQLCond0 + ')' 	                   
    End
   Else
    Begin
     Select @SQLCommand =  @SQLCommand + ' Where (' + @SQLCond0 + ')' 	  
     Select @FlgAnd = 1  
    End 
  End  
--------------------------------------------------------
-- Carrier Code
------------------------------------------------------
 If (@CarrierCode Is Not Null And Len(@CarrierCode)>0) 
  Begin
   Select @SQLCond0 = "S.Carrier_Code= '" + @CarrierCode + "'"
   If (@FlgAnd=1)
    Begin
     Select @SQLCommand =  @SQLCommand + ' And (' + @SQLCond0 + ')' 	                   
    End
   Else
    Begin
     Select @SQLCommand =  @SQLCommand + ' Where (' + @SQLCond0 + ')' 	  
     Select @FlgAnd = 1  
    End 
  End  
--------------------------------------------------------
-- Carrier Type
------------------------------------------------------
 If (@CarrierType Is Not Null And Len(@CarrierType)>0 )
  Begin
   Select @SQLCond0 = "S.Carrier_Type= '" + @CarrierType + "'"
   If (@FlgAnd=1)
    Begin
     Select @SQLCommand =  @SQLCommand + ' And (' + @SQLCond0 + ')' 	                   
    End
   Else
    Begin
     Select @SQLCommand =  @SQLCommand + ' Where (' + @SQLCond0 + ')' 	  
     Select @FlgAnd = 1  
    End 
  End  
--------------------------------------------------------
-- Customer code
------------------------------------------------------
 If (@CustomerCode Is Not Null And Len(@CustomerCode)>0 )
  Begin
   Select @SQLCond0 = "C.Customer_Code Like '%" + @CustomerCode + "%'"
   If (@FlgAnd=1)
    Begin
     Select @SQLCommand =  @SQLCommand + ' And (' + @SQLCond0 + ')' 	                   
    End
   Else
    Begin
     Select @SQLCommand =  @SQLCommand + ' Where (' + @SQLCond0 + ')' 	  
     Select @FlgAnd = 1  
    End 
  End  
--------------------------------------------------------
-- Consignee code
------------------------------------------------------
 If (@ConsigneeCode Is Not Null And Len(@ConsigneeCode)>0 )
  Begin
   Select @SQLCond0 = "C2.Customer_Code Like  '%" + @ConsigneeCode + "%'"
   If (@FlgAnd=1)
    Begin
     Select @SQLCommand =  @SQLCommand + ' And (' + @SQLCond0 + ')' 	                   
    End
   Else
    Begin
     Select @SQLCommand =  @SQLCommand + ' Where (' + @SQLCond0 + ')' 	  
     Select @FlgAnd = 1  
    End 
  End  
--------------------------------------------------------------------
-- Date condition 1
--------------------------------------------------------------------
 If (@Date1 Is Not Null And @Date1>'01-Jan-1970')
  Begin
   Select @FieldName = NULL 
   Select @FieldName = 'S.Shipment_Date'
 --  Select @FieldName = Case @OrderDateType1
 --   When 0 Then 'O.Entered_Date'
 --   When 1 Then 'O.Forecast_Mfg_Date'
 --   When 2 Then 'O.Forecast_Ship_Date'
 --   When 3 Then 'O.Actual_Mfg_Date'
 --   When 4 Then 'O.Actual_Ship_Date'
 --  End
  If (@FieldName Is Not NUll)  
   Begin
    Select @SQLCond0 = @FieldName + " Between '" + Convert(nVarChar(30), @Date1) + "' And '" +
                                                   Convert(nVarChar(30), @Date2) + "'"   
    If (@FlgAnd=1)
     Begin
      Select @SQLCommand =  @SQLCommand + ' And (' + @SQLCond0 + ')' 	                   
     End
    Else
     Begin
      Select @SQLCommand =  @SQLCommand + ' Where (' + @SQLCond0 + ')' 	  
      Select @FlgAnd = 1  
     End
   End
  End
--------------------------------------------------------------------
-- Date condition 2
--------------------------------------------------------------------
 If (@Date3 Is Not Null And @Date3>'01-Jan-1970')
  Begin
   Select @FieldName = NULL 
   Select @FieldName = 'S.Arrival_Date'
--   Select @FieldName = Case @OrderDateType2
--    When 0 Then 'O.Entered_Date'
--    When 1 Then 'O.Forecast_Mfg_Date'
--    When 2 Then 'O.Forecast_Ship_Date'
--    When 3 Then 'O.Actual_Mfg_Date'
--    When 4 Then 'O.Actual_Ship_Date'
--   End
  If (@FieldName Is Not NUll)  
   Begin
    Select @SQLCond0 = @FieldName + " Between '" + Convert(nVarChar(30), @Date3) + "' And '" +
                                                   Convert(nVarChar(30), @Date4) + "'"   
    If (@FlgAnd=1)
     Begin
      Select @SQLCommand =  @SQLCommand + ' And (' + @SQLCond0 + ')' 	                   
     End
    Else
     Begin
      Select @SQLCommand =  @SQLCommand + ' Where (' + @SQLCond0 + ')' 	  
      Select @FlgAnd = 1  
     End
   End
  End
------------------------------------------------------------------
-- Comment
------------------------------------------------------------------
 If (@Comment Is Not Null And Len(@Comment)>0)
  Begin
   Select @SQLCond0 = "CO.Comment Like '%" + @Comment + "%'"
   If (@FlgAnd=1)
    Begin
     Select @SQLCommand =  @SQLCommand + ' And (' + @SQLCond0 + ')' 	                   
    End
   Else
    Begin
     Select @SQLCommand =  @SQLCommand + ' Where (' + @SQLCond0 + ')' 	  
     Select @FlgAnd = 1  
    End 
  End  
----------------------------------------------------------------
--  Output partial result to a temp table
-----------------------------------------------------------------
 Create Table #ShipmentTemp (
  Shipment_Id Int NULL,
  Order_Id int NULL
 )
 Select @SQLCommand = 'Insert Into #ShipmentTemp ' + @SQLCommand 
/*
   Select Substring(@SQLCommand,1,100)
   Select Substring(@SQLCommand,101,200)
   Select Substring(@SQLCommand,201,300)
   Select Substring(@SQLCommand,301,400)
   Select Substring(@SQLCommand,401,500)
   Select Substring(@SQLCommand,501,600)
   Select Substring(@SQLCommand,601,700)
   Select Substring(@SQLCommand,701,800)
   Select Substring(@SQLCommand,801,900)
   Select Substring(@SQLCommand,901,1000)
*/
  Exec (@SQLCommand)
----------------------------------------------------------------
-- If Passed Products, Check if at least one order item for each 
-- order matches one of the passed products 
----------------------------------------------------------------
 If (@Products Is Not Null And Len(@Products) > 0) 
  Begin
   Create Table #Prod (
    Prod_id Int Null
   )
   Create Table #ShipmentProd (
    Shipment_Id Int NULL,
    Order_Id int NULL
   )
   Select @EndPosition=CharIndex("\",@Products)
   While (@EndPosition<>0)
    Begin
     Select @ProdId = Convert(Int,Substring(@Products,1,(@EndPosition-1)))
     Insert Into #Prod Values (@ProdId)
     Select @Products =  Right(@Products, Len(@Products)- @EndPosition)
     Select @EndPosition=CharIndex("\",@Products)
    End -- while loop
   Declare ProdCursor INSENSITIVE CURSOR
    For (Select Shipment_Id, Order_Id From #ShipmentTemp)
     For Read Only
   Open ProdCursor
 ProdLoop:
   Fetch Next From ProdCursor Into @ShipmentId, @OrderId
   If (@@Fetch_Status = 0)
   Begin
    If (Select Count(I.Prod_Id)
     From Customer_Order_Line_Items I 
      Where I.Order_id = @OrderId And I.Prod_Id In (Select Prod_Id From #Prod))>0
     Begin
      Insert Into #ShipmentProd
       Select * From #ShipmentTemp Where Shipment_Id = @ShipmentId And Order_Id = @OrderId
     End
     Goto ProdLoop
   End
   Close ProdCursor
   Deallocate ProdCursor
   Delete From #ShipmentTemp
   Insert Into #ShipmentTemp
    Select * From #ShipmentProd 
   Drop Table #ShipmentProd
   Drop Table #Prod
  End
----------------------------------------------------------------
-- If passed PUId, Check if at least one order item for each 
-- order matches one of the products that can be produced on that unit
----------------------------------------------------------------------
 If (@PUId Is Not Null And @PUId>0) 
  Begin
   Create Table #ProdPU (
    Prod_id Int Null
   )
   Create Table #ShipmentPU (
    Shipment_Id Int NULL,
    Order_Id int NULL
   )
   Insert Into #ProdPU
    Select PP.Prod_Id 
     From PU_Products PP
      Where PP.PU_Id = @PuId
   Declare ProdCursor INSENSITIVE CURSOR
    For (Select Shipment_Id, Order_Id From #ShipmentTemp)
     For Read Only
   Open ProdCursor
 PULoop:
   Fetch Next From ProdCursor Into @ShipmentId, @OrderId
   If (@@Fetch_Status = 0)
   Begin
    If (Select Count(I.Prod_Id)
     From Customer_Order_Line_Items I 
      Where I.Order_id = @OrderId And I.Prod_Id In (Select Prod_Id From #ProdPU))>0
     Begin
      Insert Into #ShipmentPU
       Select * From #ShipmentTemp Where Shipment_Id = @ShipmentId And Order_Id = @OrderId
     End
     Goto PULoop
   End
   Close ProdCursor
   Deallocate ProdCursor
   Delete From #ShipmentTemp
   Insert Into #ShipmentTemp
    Select * From #ShipmentPU 
   Drop Table #ShipmentPU
   Drop Table #ProdPU
  End
------------------------------------------------------------------------------------------
-- Run select distinct to get just once the shipment records that comply with parameters
------------------------------------------------------------------------------------------
 Create Table #ShipmentTemp2 (
    Shipment_id Int Null
   )
--select 'temp1'
--select * from #shipmentTemp
  Insert Into #ShipmentTemp2
   Select Distinct Shipment_Id 
    From #ShipmentTemp 
  Drop Table #ShipmentTemp
--------------------------------------------------------------------
-- Output the result
-------------------------------------------------------------------
IF @RegionalServer = 1
BEGIN
 	 DECLARE @T Table  (TimeColumns nVarChar(100))
 	 DECLARE @CHT Table  (HeaderTag Int,Idx Int)
 	 Insert into @T(TimeColumns) Values ('Shipment Date')
 	 Insert into @T(TimeColumns) Values ('Arrival Date')
 	 Insert into @CHT(HeaderTag,Idx) Values (16096,1)
 	 Insert into @CHT(HeaderTag,Idx) Values (16097,2)
 	 Insert into @CHT(HeaderTag,Idx) Values (16098,3)
 	 Insert into @CHT(HeaderTag,Idx) Values (16095,4)
 	 Insert into @CHT(HeaderTag,Idx) Values (16094,5)
 	 Insert into @CHT(HeaderTag,Idx) Values (16319,6)
 	 Select TimeColumns From @T
 	 Select HeaderTag From @CHT Order by Idx
 	 Select 	 [Tag] = S.Shipment_Id,
 	  	  	 [Shipment Number] = S.Shipment_Number, 
 	  	  	 [Shipment Date] = S.Shipment_Date, 
 	  	  	 [Arrival Date] = S.Arrival_Date, 
 	  	  	 [Carrier Code] = S.Carrier_Code,
 	  	  	 [Carrier Type] = S.Carrier_Type, 
 	  	  	 [Comment] = S.Comment_Id  
 	 From Shipment S 
 	 Join #ShipmentTemp2 T On S.Shipment_Id = T.Shipment_Id  
    Order By S.Shipment_Id
END
ELSE
BEGIN
 Select S.ShIpment_Id, S.Shipment_Number, S.Shipment_Date, S.Arrival_Date, S.Carrier_Code,
  S.Carrier_Type, S.Comment_Id  
   From Shipment S Inner Join #ShipmentTemp2 T On S.ShiPment_Id = T.ShipMent_Id  
    Order By S.Shipment_Id
END
 Drop Table #ShipmentTemp2
