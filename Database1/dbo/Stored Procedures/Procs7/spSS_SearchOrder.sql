Create Procedure dbo.spSS_SearchOrder
 @PlantOrderNumber nVarChar(50) = NULL,
 @CustomerOrderNumber nVarChar(50) = NULL,
 @CorporateOrderNumber nVarChar(50) = NULL,
 @ProcessOrderNumber nVarChar(50) = NULL,
 @OrderType nVarChar(10) = NULL,
 @OrderStatus nVarChar(10) = NULL,
 @CustomerCode nVarChar(50) = NULL,
 @ConsigneeCode nVarChar(50) = NULL,
 @Date1 DateTime = NULL,
 @Date2 DateTime = NULL,
 @Date3 DateTime = NULL,
 @Date4 DateTime = NULL,
 @Products nVarChar(1024) = NULL,
 @PUId Int = NULL,
 @OrderInstruction nVarChar(255) = NULL,
 @OrderSelectStatus Int = NULL,
 @OrderDateType1 Int = NULL,
 @OrderDateType2 Int = NULL,
 @RegionalServer Int = 0
AS
If @RegionalServer Is Null
 	 Select @RegionalServer = 0
 Declare @SQLCommand Varchar(4500),
 	  @SQLCond0 nVarChar(1024),
         @OrderId int, 
         @CountItems Int,
         @CountClosedItems int,
         @FieldName nVarChar(50),
         @StartTime DateTime, 
         @ProdId int,
         @FlgAnd int,
         @FlgFirst int,
         @EndPosition int
-- Insert Into DebugSearchAlarm Values (getDate(), @StartDate1, @StartDate2)
--------------------------------------------
-- Initialize variables
---------------------------------------------
 Select @FlgFirst= 0
 Select @FlgAnd = 0
 Select @SQLCOnd0 = NULL
-- Any modification to this select statement should also be done on the #alarm table
  Select @SQLCommand = 'Select Distinct O.Order_Id, O.Customer_Id, O.Consignee_Id, ' +
                       'O.Customer_Order_Number, O.Plant_Order_Number, O.Corporate_Order_Number, ' +
                       'O.Order_Type, O.Order_Status, O.Entered_Date, O.Forecast_Mfg_Date, ' +
 	   	        'O.Forecast_Ship_Date, O.Actual_Mfg_Date, O.Actual_Ship_Date, ' +
 	  	        'O.Order_Instructions, O.Total_Line_Items, O.Comment_Id, C.Customer_Code,' + 	 
                       'C2.Customer_Code as Consignee_Code ' +
 	  	        'From Customer_Orders O Inner Join Customer C On C.Customer_Id = O.Customer_Id ' +
                       'Left Outer Join Customer C2 On C2.Customer_Id = O.Consignee_Id '
--------------------------------------------------------
-- Process Order Number
------------------------------------------------------
 If (@ProcessOrderNumber Is Not Null And Len(@ProcessOrderNumber)>0)
  Begin
   Select @SQLCond0 = "Join Customer_Order_Line_Items OL on OL.Order_Id = O.Order_Id " + 
                      "Join Production_Setup_Detail PSD on PSD.Order_Line_Id = OL.Order_Line_Id " +
                      "Join Production_Setup PS on PS.PP_Setup_Id = PSD.PP_Setup_Id " +
                      "Join Production_Plan PP on PP.PP_Id = PS.PP_Id " +
                      "Where PP.Process_Order = '" + @ProcessOrderNumber + "'"
   Select @SQLCommand =  @SQLCommand + ' ' + @SQLCond0
   Select @FlgAnd = 1
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
-- Order Type
------------------------------------------------------
 If (@OrderType Is Not Null And Len(@OrderType)>0) 
  Begin
   Select @SQLCond0 = "O.Order_Type= '" + @OrderType + "'"
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
--------------------------------------------------------
-- Customer code
------------------------------------------------------
 If (@CustomerCode Is Not Null And Len(@CustomerCode)>0 )
  Begin
  -- Select @SQLCond0 = "C.Customer_Code= '" + @CustomerCode + "'"
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
--   Select @SQLCond0 = "C2.Customer_Code= '" + @ConsigneeCode + "'"
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
--insert into local_test (TimeStampTst, MessageTst)
-- values (getDate(), 'starting date condition1')
 If (@Date1 Is Not Null And @Date1>'01-Jan-1970')
  Begin
   Select @FieldName = NULL 
   Select @FieldName = Case @OrderDateType1
    When 0 Then 'O.Entered_Date'
    When 1 Then 'O.Forecast_Mfg_Date'
    When 2 Then 'O.Forecast_Ship_Date'
    When 3 Then 'O.Actual_Mfg_Date'
    When 4 Then 'O.Actual_Ship_Date'
   End
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
   Select @FieldName = Case @OrderDateType2
    When 0 Then 'O.Entered_Date'
    When 1 Then 'O.Forecast_Mfg_Date'
    When 2 Then 'O.Forecast_Ship_Date'
    When 3 Then 'O.Actual_Mfg_Date'
    When 4 Then 'O.Actual_Ship_Date'
   End
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
-- Instructions
------------------------------------------------------------------
 If (@OrderInstruction Is Not Null And Len(@OrderInstruction)>0)
  Begin
   Select @SQLCond0 = "O.Order_Instructions Like '%" + @OrderInstruction + "%'"
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
--------------------------------------------------------------
--  Select Order Status - Future Orders
--------------------------------------------------------------
 If (@OrderSelectStatus=1) -- future
  Begin
   Select @SQLCond0 = "O.Forecast_Mfg_Date > '" + Convert(nVarChar(25),GetDate(),13)  + "'"
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
  Customer_Id Int NULL,
  Consignee_Id Int NULL,
  Customer_Order_Number nVarChar(50) NULL,
  Plant_Order_Number nVarChar(50) NULL,
  Corporate_Order_Number nVarChar(50) NULL,
  Order_Type nVarChar(10) NULL,
  Order_Status nVarChar(10) NULL,
  Entered_Date DateTime NULL,
  ForeCast_Mfg_Date DateTime NULL,
  ForeCast_Ship_Date DateTime NULL,
  Actual_Mfg_Date DateTime NULL,
  Actual_Ship_Date DateTime NULL,
  Order_Instructions nVarChar(255),
  Total_Line_Item Int NULL,
  Comment_Id Int NULL,
  Customer_Code nVarChar(50),
  Consignee_Code nVarChar(50)
 )
 Select @SQLCommand = 'Insert Into #OrderTemp ' + @SQLCommand 
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
   Create Table #OrderProd (
    Order_Id Int NULL,
    Customer_Id Int NULL,
    Consignee_Id Int NULL,
    Customer_Order_Number nVarChar(50) NULL,
    Plant_Order_Number nVarChar(50) NULL,
    Corporate_Order_Number nVarChar(50) NULL,
    Order_Type nVarChar(10) NULL,
    Order_Status nVarChar(10) NULL,
    Entered_Date DateTime NULL,
    ForeCast_Mfg_Date DateTime NULL,
    ForeCast_Ship_Date DateTime NULL,
    Actual_Mfg_Date DateTime NULL,
    Actual_Ship_Date DateTime NULL,
    Order_Instructions nVarChar(255),
    Total_Line_Item Int NULL,
    Comment_Id Int NULL,
    Customer_Code nVarChar(50),
    Consignee_Code nVarChar(50)
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
    For (Select Order_Id From #OrderTemp)
     For Read Only
   Open ProdCursor
 ProdLoop:
   Fetch Next From ProdCursor Into @OrderId
   If (@@Fetch_Status = 0)
   Begin
    If (Select Count(I.Prod_Id)
     From Customer_Order_Line_Items I 
      Where I.Order_id = @OrderId And I.Prod_Id In (Select Prod_Id From #Prod))>0
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
   Create Table #OrderPU (
    Order_Id Int NULL,
    Customer_Id Int NULL,
    Consignee_Id Int NULL,
    Customer_Order_Number nVarChar(50) NULL,
    Plant_Order_Number nVarChar(50) NULL,
    Corporate_Order_Number nVarChar(50) NULL,
    Order_Type nVarChar(10) NULL,
    Order_Status nVarChar(10) NULL,
    Entered_Date DateTime NULL,
    ForeCast_Mfg_Date DateTime NULL,
    ForeCast_Ship_Date DateTime NULL,
    Actual_Mfg_Date DateTime NULL,
    Actual_Ship_Date DateTime NULL,
    Order_Instructions nVarChar(255),
    Total_Line_Item Int NULL,
    Comment_Id Int NULL,
    Customer_Code nVarChar(50),
    Consignee_Code nVarChar(50)
   )
   Insert Into #ProdPU
    Select PP.Prod_Id 
     From PU_Products PP
      Where PP.PU_Id = @PuId
   Declare ProdCursor INSENSITIVE CURSOR
    For (Select Order_Id From #OrderTemp)
     For Read Only
   Open ProdCursor
 PULoop:
   Fetch Next From ProdCursor Into @OrderId
   If (@@Fetch_Status = 0)
   Begin
    If (Select Count(I.Prod_Id)
     From Customer_Order_Line_Items I 
      Where I.Order_id = @OrderId And I.Prod_Id In (Select Prod_Id From #ProdPU))>0
     Begin
      Insert Into #OrderPU
       Select * From #OrderTemp Where Order_Id = @OrderId
     End
     Goto PULoop
   End
   Close ProdCursor
   Deallocate ProdCursor
   Delete From #OrderTemp
   Insert Into #OrderTemp
    Select * From #OrderPU 
   Drop Table #OrderPU
   Drop Table #ProdPU
  End
----------------------------------------------------------------
-- If passed Select Order Status IN-Process or Complete
----------------------------------------------------------------------
 If (@OrderSelectStatus=2) Or (@OrderSelectStatus=3) -- Completed/In-Process
  Begin
   Create Table #OrderST (
    Order_Id Int NULL,
    Customer_Id Int NULL,
    Consignee_Id Int NULL,
    Customer_Order_Number nVarChar(50) NULL,
    Plant_Order_Number nVarChar(50) NULL,
    Corporate_Order_Number nVarChar(50) NULL,
    Order_Type nVarChar(10) NULL,
    Order_Status nVarChar(10) NULL,
    Entered_Date DateTime NULL,
    ForeCast_Mfg_Date DateTime NULL,
    ForeCast_Ship_Date DateTime NULL,
    Actual_Mfg_Date DateTime NULL,
    Actual_Ship_Date DateTime NULL,
    Order_Instructions nVarChar(255),
    Total_Line_Item Int NULL,
    Comment_Id Int NULL,
    Customer_Code nVarChar(50),
    Consignee_Code nVarChar(50)
   )
   Declare ProdCursor INSENSITIVE CURSOR
    For (Select Order_Id From #OrderTemp)
     For Read Only
   Open ProdCursor
 STLoop:
   Fetch Next From ProdCursor Into @OrderId
   If (@@Fetch_Status = 0)
   Begin
    If (@OrderSelectStatus=2) -- completed
     Begin
      If (Select Count(*) From Customer_Order_Line_Items I Where I.Order_Id = @OrderId And I.Complete_Date Is Null)=0
       Begin
        Insert Into #OrderST
         Select * From #OrderTemp Where Order_Id = @OrderId
       End
     End      
    Else
     Begin    -- orderSelectStatus = 3, in-process
      Select @CountItems=0
      Select @CountClosedItems = 0
      Select @CountItems=Count(*) From Customer_Order_Line_Items Where Order_Id = @OrderId
      Select @CountClosedItems =Count(*) From Customer_Order_Line_Items I 
       Where I.Order_Id = @OrderId And I.Complete_Date Is Not Null
      If (@CountClosedItems>0 And @CountClosedItems<@CountItems)
       Begin
        Insert Into #OrderST
         Select * From #OrderTemp Where Order_Id = @OrderId
       End
     End
     Goto STLoop
   End
   Close ProdCursor
   Deallocate ProdCursor
   Delete From #OrderTemp
   Insert Into #OrderTemp
    Select * From #OrderST
   Drop Table #OrderST
  End
--------------------------------------------------------------------
-- Output the result
-------------------------------------------------------------------
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
 	 Insert into @CHT(HeaderTag,Idx) Values (16319,14) -- Comment
 	 Select TimeColumns From @T
 	 Select HeaderTag From @CHT Order by Idx
 	 Select 	 [Tag] = Order_Id,
 	  	  	 [Customer] = Customer_Code,
 	  	  	 [Consignee] = Consignee_Code,
 	  	  	 [Plant Order#] = Plant_Order_Number,
 	  	  	 [Customer Order#] = Customer_Order_Number,
 	  	  	 [Corporate Order#] = Corporate_Order_Number,
 	  	  	 [Type] = Order_Type,
 	  	  	 [Status] = Order_Status,
 	  	  	 [Entered Date] = Entered_Date,
 	  	  	 [Forecast Mfg Date] = ForeCast_Mfg_Date,
 	  	  	 [Forecast Ship Date] = ForeCast_Ship_Date,
 	  	  	 [Actual Mfg Date] = Actual_Mfg_Date,
 	  	  	 [Actual Ship Date] = Actual_Ship_Date,
 	  	  	 [Instructions] = Order_Instructions,
 	  	  	 [Comment] = Comment_Id,
 	  	  	 [Customer_Id] = Customer_Id,
 	  	  	 [Consignee_Id] = Consignee_Id,
 	  	  	 [Total_Line_Item] = Total_Line_Item
 	 From #OrderTemp
 	 Order By Order_Id
END
ELSE
BEGIN
 Select Order_Id, Customer_Id, Consignee_Id, Customer_Order_Number, Plant_Order_Number,
  Corporate_Order_Number, Order_Type, Order_Status, Entered_Date, ForeCast_Mfg_Date,
  ForeCast_Ship_Date, Actual_Mfg_Date, Actual_Ship_Date, Order_Instructions,
  Total_Line_Item, Comment_Id, Customer_Code,  Consignee_Code
   From #OrderTemp  
    Order By Order_Id
END
 Drop Table #OrderTemp
