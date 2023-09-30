CREATE PROCEDURE dbo.spEM_IEImportOrders
@OrderNumber 	  	 nvarchar(50),
@OrderType  	  	  	 nVarChar(10),
@OrderStatus 	  	 nVarChar(10),
@CustCode 	  	  	 nvarchar(50),
@CustOrdNumb 	  	 nvarchar(50),
@CorpOrdNumb 	  	 nvarchar(50),
@ConsCode 	  	  	 nvarchar(50),
@FMfgDate 	  	  	 nvarchar(25),
@AMfgDate 	  	  	 nvarchar(25),
@FShipDate 	  	  	 nvarchar(25),
@AShipDate 	  	  	 nvarchar(25),
@Instr 	  	  	  	 nvarchar(255),
@ExtInfo 	  	  	 nvarchar(255),
@General1 	  	  	 nvarchar(25),
@General2 	  	  	 nvarchar(25),
@General3 	  	  	 nvarchar(25),
@General4 	  	  	 nvarchar(25),
@General5 	  	  	 nvarchar(25),
@Active 	  	  	  	 nVarChar(10),
@BlockNo 	  	  	 nvarchar(50),
@In_User_Id  	  	 int
As
Select @OrderNumber 	  	 = Ltrim(Rtrim(@OrderNumber))
Select @OrderType 	  	 = Ltrim(Rtrim(@OrderType))
Select @OrderStatus 	  	 = Ltrim(Rtrim(@OrderStatus))
Select @CorpOrdNumb 	  	 = Ltrim(Rtrim(@CorpOrdNumb))
Select @CustOrdNumb 	  	 = Ltrim(Rtrim(@CustOrdNumb))
Select @CustCode 	  	 = Ltrim(Rtrim(@CustCode))
Select @ConsCode 	  	 = Ltrim(Rtrim(@ConsCode))
Select @FMfgDate 	  	 = Ltrim(Rtrim(@FMfgDate))
Select @AMfgDate 	  	 = Ltrim(Rtrim(@AMfgDate))
Select @FShipDate 	  	 = Ltrim(Rtrim(@FShipDate))
Select @AShipDate 	  	 = Ltrim(Rtrim(@AShipDate))
Select @BlockNo 	  	  	 = Ltrim(Rtrim(@BlockNo))
Select @Instr 	  	  	 = Ltrim(Rtrim(@Instr))
Select @General1 	  	 = Ltrim(Rtrim(@General1))
Select @General2 	  	 = Ltrim(Rtrim(@General2))
Select @General3 	  	 = Ltrim(Rtrim(@General3))
Select @General4 	  	 = Ltrim(Rtrim(@General4))
Select @General5 	  	 = Ltrim(Rtrim(@General5))
Select @ExtInfo 	  	  	 = Ltrim(Rtrim(@ExtInfo))
Select @Active 	  	  	 = Ltrim(Rtrim(@Active))
If @OrderNumber = '' 	 Select @OrderNumber = Null
If @OrderType = '' 	  	 Select @OrderType = Null
If @OrderStatus = ''  	 Select @OrderStatus = Null
If @CorpOrdNumb = ''  	 Select @CorpOrdNumb = Null
If @CustOrdNumb = ''  	 Select @CustOrdNumb = Null
If @CustCode = ''  	  	 Select @CustCode = Null
If @ConsCode = ''  	  	 Select @ConsCode = Null
If @FMfgDate = ''  	  	 Select @FMfgDate = Null
If @AMfgDate = ''  	  	 Select @AMfgDate = Null
If @BlockNo = ''  	  	 Select @BlockNo = Null
If @Instr = ''  	  	  	 Select @Instr = Null
If @General1 = ''  	  	 Select @General1 = Null
If @General2 = ''  	  	 Select @General2 = Null
If @General3 = ''  	  	 Select @General3 = Null
If @General4 = ''  	  	 Select @General4 = Null
If @General5 = ''  	  	 Select @General5 = Null
If @ExtInfo = ''  	  	 Select @ExtInfo = Null
If @Active = ''  	  	 Select @Active = Null
If @FShipDate = '' 	  	 Select @FShipDate = Null
IF @AShipDate = '' 	  	 Select @AShipDate = Null
Declare @IsActive 	 bit,
 	  	 @CustomerId int,
 	  	 @CosigneeId int,
 	  	 @OrderId 	 Int,
 	  	 @LineItems  Int,
 	  	 @Now 	  	 DateTime,
 	  	 @FSDate 	  	 DateTime,
 	  	 @ASDate 	  	 DateTime,
 	  	 @FMDate 	  	 DateTime,
 	  	 @AMDate 	  	 DateTime
/*  Non nullable
Order_Type
Order_Status
Customer_Order_Number
Plant_Order_Number
Customer_Id 
*/
Select @Now = dbo.fnServer_CmnGetDate(getUTCdate())
If  @OrderNumber is null --Plant_Order_Number
  Begin
 	 Select  'Order Number Not Found'
 	 Return(-100)
  End
If @OrderType is null 
  Begin
 	 Select  'Order Type Not Found'
 	 Return(-100)
  End
If  @OrderStatus is null 
  Begin
 	 Select  'Order Status Not Found'
 	 Return(-100)
  End
If @CustOrdNumb is null 
  Begin
 	 Select  'Customer Order Number Not Found'
 	 Return(-100)
  End
If  @CustCode is null 
  Begin
 	 Select  'Customer Code Not Found'
 	 Return(-100)
  End
If @FShipDate is not Null
BEGIN
 	 If Len(@FShipDate)  <> 14 
 	 BEGIN
 	  	 Select  'Forecast ship date format not correct'
 	  	 Return(-100)
 	 END
 	 SELECT @FSDate = 0
 	 SELECT @FSDate = DateAdd(year,convert(int,substring(@FShipDate,1,4)) - 1900,@FSDate)
 	 SELECT @FSDate = DateAdd(month,convert(int,substring(@FShipDate,5,2)) - 1,@FSDate)
 	 SELECT @FSDate = DateAdd(day,convert(int,substring(@FShipDate,7,2)) - 1,@FSDate)
 	 SELECT @FSDate = DateAdd(hour,convert(int,substring(@FShipDate,9,2)) ,@FSDate)
 	 SELECT @FSDate = DateAdd(minute,convert(int,substring(@FShipDate,11,2)),@FSDate)
END
 	 
IF @AShipDate is not Null
BEGIN
 	 If Len(@AShipDate)  <> 14 
 	 BEGIN
 	  	 Select  'Actual ship date format not correct'
 	  	 Return(-100)
 	 END
 	 SELECT @ASDate = 0
 	 SELECT @ASDate = DateAdd(year,convert(int,substring(@AShipDate,1,4)) - 1900,@ASDate)
 	 SELECT @ASDate = DateAdd(month,convert(int,substring(@AShipDate,5,2)) - 1,@ASDate)
 	 SELECT @ASDate = DateAdd(day,convert(int,substring(@AShipDate,7,2)) - 1,@ASDate)
 	 SELECT @ASDate = DateAdd(hour,convert(int,substring(@AShipDate,9,2)) ,@ASDate)
 	 SELECT @ASDate = DateAdd(minute,convert(int,substring(@AShipDate,11,2)),@ASDate)
END
If @FMfgDate is not Null
BEGIN
 	 If Len(@FMfgDate)  <> 14 
 	 BEGIN
 	  	 Select  'Forecast Manufacturing date format not correct'
 	  	 Return(-100)
 	 END
 	 SELECT @FMDate = 0
 	 SELECT @FMDate = DateAdd(year,convert(int,substring(@FMfgDate,1,4)) - 1900,@FMDate)
 	 SELECT @FMDate = DateAdd(month,convert(int,substring(@FMfgDate,5,2)) - 1,@FMDate)
 	 SELECT @FMDate = DateAdd(day,convert(int,substring(@FMfgDate,7,2)) - 1,@FMDate)
 	 SELECT @FMDate = DateAdd(hour,convert(int,substring(@FMfgDate,9,2)) ,@FMDate)
 	 SELECT @FMDate = DateAdd(minute,convert(int,substring(@FMfgDate,11,2)),@FMDate)
END
If @AMfgDate is not Null
BEGIN
 	 If Len(@AMfgDate)  <> 14 
 	 BEGIN
 	  	 Select  'Actual Manufacturing date format not correct'
 	  	 Return(-100)
 	 END
 	 SELECT @AMDate = 0
 	 SELECT @AMDate = DateAdd(year,convert(int,substring(@AMfgDate,1,4)) - 1900,@AMDate)
 	 SELECT @AMDate = DateAdd(month,convert(int,substring(@AMfgDate,5,2)) - 1,@AMDate)
 	 SELECT @AMDate = DateAdd(day,convert(int,substring(@AMfgDate,7,2)) - 1,@AMDate)
 	 SELECT @AMDate = DateAdd(hour,convert(int,substring(@AMfgDate,9,2)) ,@AMDate)
 	 SELECT @AMDate = DateAdd(minute,convert(int,substring(@AMfgDate,11,2)),@AMDate)
END
If @Active = 'Yes' or @Active = 'TRUE' Or @Active = '1'
 	 Select  @IsActive = 1
Else
 	 Select  @IsActive = 0
/* Initialization */
Select @CustomerId = Null
/* Get Customer Id */
Select @CustomerId = Customer_Id From Customer
  Where Customer_Code = @CustCode
If @CustomerId is null 
  Begin
 	 Select  'Customer Code Not Found'
 	 Return(-100)
  End
If @ConsCode is not Null
  Begin
 	 Select @CosigneeId = Customer_Id From Customer
 	   Where Customer_Code = @ConsCode
 	 If @CosigneeId is null 
 	   Begin
 	  	 Select  'Consignee Code Not Found'
 	  	 Return(-100)
 	   End
  End
Select @LineItems = 0
Select @OrderId = Order_Id,@LineItems =  Total_Line_Items From Customer_Orders
  Where Plant_Order_Number = @OrderNumber
/* If doesn't exist then create */
If @OrderId Is Null
 	 Execute spEMCO_AddOrder @CustomerId,@CustOrdNumb,@OrderNumber,@CorpOrdNumb,@BlockNo,@OrderType,@OrderStatus,@Now,@In_User_Id,@FMDate,
 	  	 @FSDate,@AMDate,@ASDate,@LineItems,@Instr,@General1,@General2,@General3,@General4,@General5,@CosigneeId,@In_User_Id,@OrderId  OUTPUT
Else
 	 Execute spEMCO_EditOrder @OrderId,@CustOrdNumb,@OrderNumber,@CorpOrdNumb,@BlockNo,@OrderType,@OrderStatus,@FMDate,
 	  	 @FSDate,@AMDate,@ASDate,@LineItems,@Instr,@General1,@General2,@General3,@General4,@General5,@CosigneeId,@In_User_Id
If @OrderId is null
  Begin
 	 Select 'Failed - could not create customer order'
 	 Return (-100)
  End
UPDATE Customer_Orders SET  Extended_Info = @ExtInfo WHERE Order_Id = @OrderId
Return(0)
