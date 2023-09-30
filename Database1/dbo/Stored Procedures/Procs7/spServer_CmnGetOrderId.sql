CREATE PROCEDURE dbo.spServer_CmnGetOrderId
@Customer_Id int,
@Order_Number nVarChar(50),
@User_Id int,
@Prod_Id int,
@DefOrder_Type nVarChar(10),
@DefOrder_Status nVarChar(10),
@LineItemNo int,
@AddIfMissing int,
@Order_Id int OUTPUT,
@Order_Line_Id int OUTPUT
 AS
Select @Order_Id = NULL
Select @Order_Id = Order_Id 
  From Customer_Orders 
  Where (Customer_Id = @Customer_Id) And 
        (Plant_Order_Number = @Order_Number)
If (@Order_Id Is NULL)
  Begin
    If (@AddIfMissing = 1)
      Begin
 	 Insert Into Customer_Orders(Customer_Id,Customer_Order_Number,Plant_Order_Number,Entered_By,Order_Type,Order_Status,Entered_Date)
          Values (@Customer_Id,@Order_Number,@Order_Number,@User_Id,@DefOrder_Type,@DefOrder_Status,dbo.fnServer_CmnGetDate(GetUTCDate()))
        Select @Order_Id = Scope_identity()
      End
    Else
      Begin
        Select @Order_Id = 0
        Select @Order_Line_Id = 0
        Return
      End
  End
Select @Order_Line_Id = NULL
Select @Order_Line_Id = Order_Line_Id From Customer_Order_Line_Items Where (Order_Id = @Order_Id) And (Prod_Id = @Prod_Id)
If (@Order_Line_Id Is NULL)
  Begin
    If (@AddIfMissing = 1)
      Begin
 	 Insert Into Customer_Order_Line_Items(Order_Id,Prod_Id,Line_Item_Number)
          Values(@Order_Id,@Prod_Id,@LineItemNo)
        Select @Order_Line_Id = Scope_identity()
 	 Update Customer_Orders
 	   Set Total_Line_Items = (Select Count(Order_Id) From Customer_Order_Line_Items Where Order_Id = @Order_Id) 
 	   Where (Order_Id = @Order_Id)
      End
    Else
      Begin
        Select @Order_Line_Id = 0
        Return
      End
  End
Else
  Begin
    Update Customer_Orders
      Set Total_Line_Items = (Select Count(Order_Id) From Customer_Order_Line_Items Where Order_Id = @Order_Id)
      Where (Order_Id = @Order_Id)
  End
