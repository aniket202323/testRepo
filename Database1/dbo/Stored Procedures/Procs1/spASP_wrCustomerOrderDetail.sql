CREATE PROCEDURE [dbo].[spASP_wrCustomerOrderDetail]
  @OrderId int,
  @Command int = NULL,
  @InTimeZone nvarchar(200)=NULL
AS
Declare @Report Table ([Key] nvarchar(255), Value nvarchar(255), Hyperlink Varchar(512) Null)
If @Command = 1
  Begin
 	 Print 'Scrolling forward'
 	 Declare @NextOrderId Int
 	 Select @NextOrderId = Min(o.Order_Id) --Get the order with the next lowest ID
 	  	  	  	 From Customer_Orders o
 	  	  	  	 Where o.Order_Id > @OrderId
 	 If @NextOrderId Is Null
 	  	 --Get the first customer
 	  	 Select @OrderId = Min(o.Order_Id)
 	  	 From Customer_Orders o
 	 Else
 	  	 -- Scroll Next
 	  	 Select @OrderId = @NextOrderId
 	 
  End
Else If @Command = 2
  Begin
 	 Print 'Scrolling Backwards'
 	 Declare @PrevOrderId Int
 	 Select @PrevOrderId = Max(o.Order_Id) --Get the order with the next lowest start time
 	 From Customer_Orders o
 	 Where o.Order_Id < @OrderId
 	 If @PrevOrderId Is Null
 	  	 --Scroll to the last customer
 	  	 Select @OrderId = Max(o.Order_Id)
 	  	 From Customer_Orders o
 	 Else
 	  	 -- Scroll Previous Event
 	  	 Select @OrderId = @PrevOrderId
  End
Select o.[Order_Id]
      ,'Actual_Mfg_Date'=   [dbo].[fnServer_CmnConvertFromDbTime] (o.[Actual_Mfg_Date],@InTimeZone) 
      ,'Actual_Ship_Date'=  [dbo].[fnServer_CmnConvertFromDbTime] (o.[Actual_Ship_Date],@InTimeZone)  
      ,o.[Comment_Id]
      ,o.[Consignee_Id]
      ,o.[Corporate_Order_Number]
      ,o.[Customer_Id]
      ,o.[Customer_Order_Number]
      ,o.[Entered_By]
      ,'Entered_Date' =   [dbo].[fnServer_CmnConvertFromDbTime] (o.[Entered_Date],@InTimeZone)  
      ,o.[Extended_Info]
      ,'Forecast_Mfg_Date' = [dbo].[fnServer_CmnConvertFromDbTime] (o.[Forecast_Mfg_Date],@InTimeZone) 
      ,'Forecast_Ship_Date' =   [dbo].[fnServer_CmnConvertFromDbTime] (o.[Forecast_Ship_Date],@InTimeZone) 
      ,o.[Is_Active]
      ,o.[Order_General_1]
      ,o.[Order_General_2]
      ,o.[Order_General_3]
      ,o.[Order_General_4]
      ,o.[Order_General_5]
      ,o.[Order_Instructions]
      ,o.[Order_Status]
      ,o.[Order_Type]
      ,o.[Plant_Order_Number]
      ,o.[Schedule_Block_Number]
      ,o.[Total_Line_Items], u.Username 'Entered_By_Name', cust.Customer_Name, comm.Comment_Text
Into #TempData
From Customer_Orders o
Left Outer Join Users u On o.Entered_By = u.[User_Id]
Left Outer Join Customer cust On o.Customer_Id = cust.Customer_Id
Left Outer Join Comments comm On o.Comment_Id = comm.Comment_Id
Where o.Order_Id = @OrderId
Insert Into @Report
Select 'Customer Order Number', Customer_Order_Number, Null
From #TempData
Insert Into @Report
Select 'Plant Order Number', Customer_Order_Number, Null
From #TempData
Insert Into @Report
Select 'Corporate Order Number', Customer_Order_Number, Null
From #TempData
Insert Into @Report
Select 'Is Active', Is_Active, Null
From #TempData
Insert Into @Report
Select 'Entered', Entered_Date, Null
From #TempData
Insert Into @Report
Select 'Forecasted Manufacture Date', Forecast_Mfg_Date, Null
From #TempData
Insert Into @Report
Select 'Forcasted Ship Date', Forecast_Ship_Date, Null
From #TempData
Insert Into @Report
Select 'Actual Manufacture Date', Actual_Mfg_Date, Null
From #TempData
Insert Into @Report
Select 'Entered By', Entered_By_Name, Null
From #TempData
Insert Into @Report
Select 'Total Line Items', Total_Line_Items, Null
From #TempData
Insert Into @Report
Select 'Customer', Customer_Name, 'CustomerDetail.aspx?CustomerId=' + Cast(Customer_Id As nvarchar(10))
From #TempData
Insert Into @Report
Select 'Order Instructions', Order_Instructions, Null
From #TempData
Insert Into @Report
Select 'Schedule Block', Schedule_Block_Number, Null
From #TempData
Insert Into @Report
Select 'Order Type', Order_Type, Null
From #TempData
Insert Into @Report
Select 'Status', Order_Status, Null
From #TempData
Insert Into @Report
Select 'Comment', Comment_Text, Null
From #TempData
Select Order_Id As OrderId, [dbo].[fnServer_CmnConvertFromDbTime] (dbo.fnServer_CmnGetDate(getutcdate()),@InTimeZone) As GenerateTime, Plant_Order_Number As OrderNumber --Sarla
From #TempData
Drop Table #TempData
Select * From @Report
