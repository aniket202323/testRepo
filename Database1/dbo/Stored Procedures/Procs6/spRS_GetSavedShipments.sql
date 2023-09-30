CREATE PROCEDURE dbo.spRS_GetSavedShipments
@InputStr varchar(1000)
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
    Select Null 'Shipment_Item_Id', Null 'Shipment_Number', Null 'Customer_Code', Null 'Shipment_Date'
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
Select sl.Shipment_Item_Id,  s.Shipment_Number, c.Customer_Code, s.Shipment_Date
From Shipment_Line_Items sl
Join Shipment s on s.Shipment_Id = sl.Shipment_Id
Join Customer_Orders co on co.Order_Id = sl.Order_Id
Join Customer c on c.Customer_Id = co.Customer_Id
Where sl.Shipment_Item_Id in(
  Select *
  From #Temp_Table
  Where Shipment_Id <> 0)
Order By s.Shipment_Number
