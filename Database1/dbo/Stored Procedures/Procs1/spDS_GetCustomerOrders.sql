Create Procedure dbo.spDS_GetCustomerOrders
 @CustomerOrderNumber nVarChar(50) = NULL,
 @OrderStatus nVarChar(10) = NULL, 
 @ProdId int,
 @EventId int,
 @RegionalServer Int = 0
AS
If @RegionalServer Is Null
 	 Select @RegionalServer = 0
 Declare @SQLCommand Varchar(4500),
 	  	 @SQLCond0 nVarChar(1024),
 	  	 @FlgAnd int,
 	  	 @OrderId int,
 	  	 @DimensionX decimal(8,3),
 	  	 @DimensionY decimal(8,3),
 	  	 @DimensionZ decimal(8,3),
 	  	 @DimensionA decimal(8,3)
-------------------------------------------
-- Get Event Final Dimensions
-------------------------------------------
Select @DimensionX = Coalesce(Final_Dimension_X, 0), @DimensionY = Coalesce(Final_Dimension_Y, 0), @DimensionZ = Coalesce(Final_Dimension_Z, 0), @DimensionA = Coalesce(Final_Dimension_A, 0)
  From Event_Details
    Where Event_Id = @EventId
-------------------------------------------
-- Initialize variables
---------------------------------------------
 Select @FlgAnd = 1
 Select @SQLCOnd0 = NULL
  Select @SQLCommand = 'Select Distinct O.Order_Id, O.Customer_Order_Number, O.Plant_Order_Number, ' +
                       'O.Corporate_Order_Number, C.Customer_Code, O.Customer_Id, ' +
                       'O.Order_Type, O.Order_Status, O.Entered_Date, O.Forecast_Mfg_Date, ' +
 	   	        'O.Forecast_Ship_Date, O.Actual_Mfg_Date, O.Actual_Ship_Date, ' +
 	  	        'O.Order_Instructions, O.Total_Line_Items, ' + 	 
                       'C2.Customer_Code as Consignee_Name, O.Consignee_Id ' +
 	  	        'From Customer_Orders O Inner Join Customer C On C.Customer_Id = O.Customer_Id ' +
                       'Left Outer Join Customer C2 On C2.Customer_Id = O.Consignee_Id ' +
                       'Where O.Is_Active = 1 '
--------------------------------------------------------
-- Customer Order Number
------------------------------------------------------
 If (@CustomerOrderNumber Is Not Null  And Len(@CustomerOrderNumber)>0) 
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
-- Status Type
------------------------------------------------------
 If (@OrderStatus Is Not Null And Len(@OrderStatus)>0 )
  Begin
   Select @SQLCond0 = "O.Order_Status= '" + @OrderStatus + "'"
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
 Create Table #OrderTemp (
  Order_Id Int NULL,
  Customer_Order_Number nVarChar(50) NULL,
  Plant_Order_Number nVarChar(50) NULL,
  Corporate_Order_Number nVarChar(50) NULL,
  Customer_Code nVarChar(50),
  Customer_Id Int NULL,
  Order_Type nVarChar(10) NULL,
  Order_Status nVarChar(10) NULL,
  Entered_Date DateTime NULL,
  ForeCast_Mfg_Date DateTime NULL,
  ForeCast_Ship_Date DateTime NULL,
  Actual_Mfg_Date DateTime NULL,
  Actual_Ship_Date DateTime NULL,
  Order_Instructions nVarChar(255),
  Total_Line_Item Int NULL,
  Consignee_Name nVarChar(50) NULL,
  Consignee_Id Int NULL
 )
  Select @SQLCommand = 'Insert Into #OrderTemp ' + @SQLCommand   
  Exec (@SQLCommand)
----------------------------------------------------------------
-- Check if at least one order item for each order matches the product of the event
----------------------------------------------------------------
  Create Table #OrderProd (
  Order_Id Int NULL,
  Customer_Order_Number nVarChar(50) NULL,
  Plant_Order_Number nVarChar(50) NULL,
  Corporate_Order_Number nVarChar(50) NULL,
  Customer_Code nVarChar(50),
  Customer_Id Int NULL,
  Order_Type nVarChar(10) NULL,
  Order_Status nVarChar(10) NULL,
  Entered_Date DateTime NULL,
  ForeCast_Mfg_Date DateTime NULL,
  ForeCast_Ship_Date DateTime NULL,
  Actual_Mfg_Date DateTime NULL,
  Actual_Ship_Date DateTime NULL,
  Order_Instructions nVarChar(255),
  Total_Line_Item Int NULL,
  Consignee_Name nVarChar(50) NULL,
  Consignee_Id Int NULL
   )
  Declare ProdCursor INSENSITIVE CURSOR
    For (Select Order_Id From #OrderTemp)
     For Read Only
  Open ProdCursor
  ProdLoop:
   Fetch Next From ProdCursor Into @OrderId
   If (@@Fetch_Status = 0)
   Begin
    If (Select Count(I.Prod_Id)
     From Customer_Order_Line_Items I 
      Where I.Order_id = @OrderId And I.Prod_Id = @ProdId
            And @DimensionX between Convert(Decimal(8,3), (Coalesce(I.Dimension_X, 0.0) - Coalesce(I.Dimension_X_Tolerance, 0.0))) and Convert(Decimal(8,3), (Coalesce(I.Dimension_X, 0.0) + Coalesce(I.Dimension_X_Tolerance, 0.099)))
            And @DimensionY between Convert(Decimal(8,3), (Coalesce(I.Dimension_Y, 0.0) - Coalesce(I.Dimension_Y_Tolerance, 0.0))) and Convert(Decimal(8,3), (Coalesce(I.Dimension_Y, 0.0) + Coalesce(I.Dimension_Y_Tolerance, 0.099)))
            And @DimensionZ between Convert(Decimal(8,3), (Coalesce(I.Dimension_Z, 0.0) - Coalesce(I.Dimension_Z_Tolerance, 0.0))) and Convert(Decimal(8,3), (Coalesce(I.Dimension_Z, 0.0) + Coalesce(I.Dimension_Z_Tolerance, 0.099)))
            And @DimensionA between Convert(Decimal(8,3), (Coalesce(I.Dimension_A, 0.0) - Coalesce(I.Dimension_A_Tolerance, 0.0))) and Convert(Decimal(8,3), (Coalesce(I.Dimension_A, 0.0) + Coalesce(I.Dimension_A_Tolerance, 0.099)))) > 0
     Begin
      Insert Into #OrderProd
       Select * From #OrderTemp Where Order_Id = @OrderId
     End
     Goto ProdLoop
   End
  Close ProdCursor
  Deallocate ProdCursor
  Delete From #OrderTemp
  Insert Into #OrderTemp
   Select * From #OrderProd 
  Drop Table #OrderProd
--------------------------------------------------------
-- Output the result
--------------------------------------------------------
IF @RegionalServer = 1
BEGIN
 	 DECLARE @T Table  (TimeColumns nVarChar(100))
 	 DECLARE @CHT Table  (HeaderTag Int,Idx Int)
 	 Insert into @T(TimeColumns) Values ('Entered Date')
 	 Insert into @T(TimeColumns) Values ('Forecast Mfg Date')
 	 Insert into @T(TimeColumns) Values ('Forecast Ship Date')
 	 Insert into @T(TimeColumns) Values ('Actual Mfg Date')
 	 Insert into @T(TimeColumns) Values ('Actual Ship Date')
 	 Insert into @CHT(HeaderTag,Idx) Values (16295,1) -- Customer
 	 Insert into @CHT(HeaderTag,Idx) Values (16311,2) -- Consignee
 	 Insert into @CHT(HeaderTag,Idx) Values (16307,3) -- Plant Order#
 	 Insert into @CHT(HeaderTag,Idx) Values (16308,4) -- Customer Order#
 	 Insert into @CHT(HeaderTag,Idx) Values (16309,5) -- Corporate Order#
 	 Insert into @CHT(HeaderTag,Idx) Values (16312,6) -- Type
 	 Insert into @CHT(HeaderTag,Idx) Values (16313,7) -- Status
 	 Insert into @CHT(HeaderTag,Idx) Values (16078,8) -- Entered Date
 	 Insert into @CHT(HeaderTag,Idx) Values (16314,9) -- Forecast Mfg Date
 	 Insert into @CHT(HeaderTag,Idx) Values (16315,10) -- Forecast Ship Date
 	 Insert into @CHT(HeaderTag,Idx) Values (16316,11) -- Actual Mfg Date
 	 Insert into @CHT(HeaderTag,Idx) Values (16317,12) -- Actual Ship Date
 	 Insert into @CHT(HeaderTag,Idx) Values (16318,13) -- Instructions
 	 Select TimeColumns From @T
 	 Select HeaderTag From @CHT Order by Idx
 Select [Tag] = Order_Id, 
 	  	 [Customer] = Customer_Code, 
 	  	 [Consignee] = Consignee_Name,
 	  	 [Plant Order#] = Plant_Order_Number,
        [Customer Order#] = Customer_Order_Number, 
        [Corporate Order#] = Corporate_Order_Number, 
 	  	 [Type] = Order_Type, 
        [Status] = Order_Status, 
 	  	 [Entered Date] = Entered_Date , 
 	  	 [Forecast Mfg Date] = ForeCast_Mfg_Date,
        [Forecast Ship Date] = ForeCast_Ship_Date, 
 	  	 [Actual Mfg Date] = Actual_Mfg_Date, 
        [Actual Ship Date] = Actual_Ship_Date , 
 	  	 [Instructions] = Order_Instructions,
 	  	 [Customer Id] =  Customer_Id , 
 	  	 [Consignee Id] = Consignee_Id, 
        [Total Line Items] = Total_Line_Item
   From #OrderTemp  
    Order By Order_Id
END
ELSE
BEGIN
 Select Order_Id, Customer_Id as "Customer Id", Consignee_Id as "Consignee Id", 
        Customer_Order_Number as "Customer Order Number", Plant_Order_Number as "Plant Order Number",
        Corporate_Order_Number as "Corporate Order Number", Order_Type as "Order Type", 
        Order_Status as "Order Status", Entered_Date as "Entered Date", ForeCast_Mfg_Date as "Forecast Mfg Date",
        ForeCast_Ship_Date as "Forecast Ship Date", Actual_Mfg_Date as "Actual Mfg Date", 
        Actual_Ship_Date as "Actual Ship Date", Order_Instructions as "Order Instructions",
        Total_Line_Item as "Total Line Items", Customer_Code as "Customer Name", Consignee_Name as "Consignee Name"
   From #OrderTemp  
    Order By Order_Id
END
 Drop Table #OrderTemp
