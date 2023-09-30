CREATE PROCEDURE dbo.spRS_GetSavedOrders
@InputStr varchar(1000), 
@Flag int
 AS
Declare @StartRead int
Declare @EndRead int
Declare @TempStr varchar(1000)
Declare @Number varchar(1000) -- text between Start and end
Declare @Length int
Declare @ReadPtr int
CREATE TABLE #Temp_Table(
    Shipment_Id int)
If RTrim(LTrim(@InputStr)) = ''
  Begin
    Select Null 'Order_Id', Null 'Order_Number', Null 'Customer_Code', Null 'Order_Status'
    Return (0)
  End
Else
  Select @TempStr = @InputStr
-- Start Loop
BeginLoop:
Select @EndRead = CharIndex(',', @TempStr)
-- at this point endread could be 0
If @EndRead <> 0
 	 Select @Number = SubString(@TempStr,1, @EndRead - 1)
Else
 	 Select @Number = @TempStr
Insert Into #Temp_Table(Shipment_Id) Values(convert(int, @Number))
Select @TempStr = SubString(@TempStr, @EndRead + 1, Len(@TempStr) - @EndRead)
If @EndRead = 0 
  goto EndLoop
Else 
  goto BeginLoop
EndLoop:
-- End Loop
If @Flag = 1
  Begin
    Select o.Order_Id, Order_Number = o.Customer_Order_Number, c.Customer_Code, o.Order_Status
    From Customer_Orders o
    Join Customer c on c.Customer_Id = o.Customer_Id
    Where o.Order_Id in (
      Select *
      From #Temp_Table
      Where Shipment_Id <> 0)
    End
Else
  Begin
    Select o.Order_Id, Order_Number = o.Plant_Order_Number, c.Customer_Code, o.Order_Status
    From Customer_Orders o
    Join Customer c on c.Customer_Id = o.Customer_Id
    Where o.Order_Id in (
      Select *
      From #Temp_Table
      Where Shipment_Id <> 0)
    End
