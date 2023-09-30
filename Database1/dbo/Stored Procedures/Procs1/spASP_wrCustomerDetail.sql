CREATE PROCEDURE [dbo].[spASP_wrCustomerDetail]
  @CustomerId int,
  @Command int = NULL,
  @InTimeZone nvarchar(200)=NULL
AS
Declare @Report Table ([Key] nvarchar(255), Value nvarchar(255))
If @Command = 1
  Begin
 	 Print 'Scrolling forward'
 	 Declare @NextCustomerId Int
 	 Select @NextCustomerId = Min(c.Customer_Id) --Get the customer with the next lowest ID
 	  	  	  	 From Customer c
 	  	  	  	 Where c.Customer_Id > @CustomerId
 	 If @NextCustomerId Is Null
 	  	 --Get the first customer
 	  	 Select @CustomerId = c.Customer_Id
 	  	 From Customer c
 	  	 Where c.Customer_Id = (Select Min(c.Customer_Id)
 	  	  	  	  	  	  	  	 From Customer c)
 	 Else
 	  	 -- Scroll Next
 	  	 Select @CustomerId = c.Customer_Id
 	  	 From Customer c
 	  	 Where c.Customer_Id = @NextCustomerId
 	 
  End
Else If @Command = 2
  Begin
 	 Print 'Scrolling Backwards'
 	 Declare @PrevCustomerId Int
 	 Select @PrevCustomerId = Max(c.Customer_Id) --Get the start with the next lowest start time
 	 From Customer c
 	 Where c.Customer_Id < @CustomerId
 	 If @PrevCustomerId Is Null
 	  	 --Scroll to the last customer
 	  	 Select @CustomerId = c.Customer_Id
 	  	 From Customer c
 	  	 Where c.Customer_Id = (Select Max(c.Customer_Id)
 	  	  	  	  	  	  	  	 From Customer c)
 	 Else
 	  	 -- Scroll Previous Event
 	  	 Select @CustomerId = c.Customer_Id 
 	  	 From Customer c
 	  	 Where c.Customer_Id = @PrevCustomerId
  End
Select c.*, ct.Customer_Type_Desc
Into #TempData
From Customer c
Join Customer_Types ct On ct.Customer_Type_Id = c.Customer_Type
Where c.Customer_Id = @CustomerId
Insert Into @Report
Select 'Customer Name', Customer_Name
From #TempData
Insert Into @Report
Select 'Is Active', Is_Active
From #TempData
Insert Into @Report
Select 'Customer Type', Customer_Type_Desc
From #TempData
Insert Into @Report
Select 'Contact Name', Contact_Name
From #TempData
Insert Into @Report
Select 'Contact Phone', Contact_Phone
From #TempData
Insert Into @Report
Select 'Address Line 1', Address_1
From #TempData
Insert Into @Report
Select 'Address Line 2', Address_2
From #TempData
Insert Into @Report
Select 'Address Line 3', Address_3
From #TempData
Insert Into @Report
Select 'Address Line 4', Address_4
From #TempData
Insert Into @Report
Select 'City, State, Zip', City_State_Zip
From #TempData
Insert Into @Report
Select 'County', County
From #TempData
Insert Into @Report
Select 'Consignee Name', Consignee_Name
From #TempData
Select Customer_Name CustomerName, dbo.fnServer_CmnGetDate(getutcdate()) As GenerateTime, Customer_Id As CustomerId 
From #TempData
Drop Table #TempData
Select * From @Report
