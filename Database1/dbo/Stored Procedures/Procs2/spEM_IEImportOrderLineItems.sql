CREATE PROCEDURE dbo.spEM_IEImportOrderLineItems
@OrderNumber 	  	 nvarchar(50),
@LineItem  	  	  	 nVarChar(10),
@ProdCode 	  	  	 nvarchar(25),
@Quanity 	  	  	 nvarchar(50),
@UOM 	  	  	  	 nvarchar(50),
@ShipToCode 	  	  	 nvarchar(50),
@ConsCode 	  	  	 nvarchar(50),
@DimX 	  	  	  	 nVarChar(10),
@DimY 	  	  	  	 nVarChar(10),
@DimZ 	  	  	  	 nVarChar(10),
@DimA 	  	  	  	 nVarChar(10),
@DimXTol 	  	  	 nVarChar(10),
@DimYTol 	  	  	 nVarChar(10),
@DimZTol 	  	  	 nVarChar(10),
@DimATol 	  	  	 nVarChar(10),
@CompleteDate 	  	 nvarchar(25),
@COADate 	  	  	 nvarchar(25),
@ExtInfo 	  	  	 nvarchar(255),
@General1 	  	  	 nvarchar(255),
@General2 	  	  	 nvarchar(255),
@General3 	  	  	 nvarchar(255),
@General4 	  	  	 nvarchar(255),
@General5 	  	  	 nvarchar(255),
@In_User_Id  	  	 int
As
Select @OrderNumber 	  	 = Ltrim(Rtrim(@OrderNumber))
Select @LineItem 	  	 = Ltrim(Rtrim(@LineItem))
Select @ProdCode 	  	 = Ltrim(Rtrim(@ProdCode))
Select @Quanity 	  	  	 = Ltrim(Rtrim(@Quanity))
Select @UOM 	  	  	  	 = Ltrim(Rtrim(@UOM))
Select @ShipToCode 	  	 = Ltrim(Rtrim(@ShipToCode))
Select @ConsCode 	  	 = Ltrim(Rtrim(@ConsCode))
Select @COADate 	  	  	 = Ltrim(Rtrim(@COADate))
Select @CompleteDate 	 = Ltrim(Rtrim(@CompleteDate))
Select @ExtInfo 	  	  	 = Ltrim(Rtrim(@ExtInfo))
Select @General1 	  	 = Ltrim(Rtrim(@General1))
Select @General2 	  	 = Ltrim(Rtrim(@General2))
Select @General3 	  	 = Ltrim(Rtrim(@General3))
Select @General4 	  	 = Ltrim(Rtrim(@General4))
Select @General5 	  	 = Ltrim(Rtrim(@General5))
Select @DimA 	  	  	 = Ltrim(Rtrim(@DimA))
Select @DimX 	  	  	 = Ltrim(Rtrim(@DimX))
Select @DimY 	  	  	 = Ltrim(Rtrim(@DimY))
Select @DimZ 	  	  	 = Ltrim(Rtrim(@DimZ))
Select @DimATol 	  	  	 = Ltrim(Rtrim(@DimATol))
Select @DimXTol 	  	  	 = Ltrim(Rtrim(@DimXTol))
Select @DimYTol 	  	  	 = Ltrim(Rtrim(@DimYTol))
Select @DimZTol 	  	  	 = Ltrim(Rtrim(@DimZTol))
If @OrderNumber = '' 	 Select @OrderNumber = Null
If @LineItem = '' 	  	 Select @LineItem = Null
If @ProdCode = ''  	  	 Select @ProdCode = Null
If @Quanity = ''  	  	 Select @Quanity = Null
If @UOM = ''  	  	  	 Select @UOM = Null
If @ShipToCode = ''  	 Select @ShipToCode = Null
If @ConsCode = ''  	  	 Select @ConsCode = Null
If @COADate = ''  	  	 Select @COADate = Null
If @CompleteDate = ''  	 Select @CompleteDate = Null
If @ExtInfo = ''  	  	 Select @ExtInfo = Null
If @General1 = ''  	  	 Select @General1 = Null
If @General2 = ''  	  	 Select @General2 = Null
If @General3 = ''  	  	 Select @General3 = Null
If @General4 = ''  	  	 Select @General4 = Null
If @General5 = ''  	  	 Select @General5 = Null
If @DimA = ''  	  	  	 Select @DimA = Null
If @DimX = ''  	  	  	 Select @DimX = Null
If @DimY = '' 	  	  	 Select @DimY = Null
IF @DimZ = '' 	  	  	 Select @DimZ = Null
If @DimATol = ''  	  	 Select @DimATol = Null
If @DimXTol = ''  	  	 Select @DimXTol = Null
If @DimYTol = ''  	  	 Select @DimYTol = Null
If @DimZTol = ''  	  	 Select @DimZTol = Null
Declare 	 @ShipToId int,
 	  	 @CosigneeId int,
 	  	 @OrderId 	 Int,
 	  	 @LineItems  Int,
 	  	 @Now 	  	 DateTime,
 	  	 @ProdId 	  	 Int,
 	  	 @OrderLineId Int,
 	  	 @dCOADate 	 DateTime,
 	  	 @CDate 	  	 DateTime,
 	  	 @fQuanity 	 Float,
 	  	 @fDimA 	  	 Float,
 	  	 @fDimX 	  	 Float,
 	  	 @fDimY 	  	 Float,
 	  	 @fDimZ 	  	 Float,
 	  	 @fDimATol 	 Float,
 	  	 @fDimXTol 	 Float,
 	  	 @fDimYTol 	 Float,
 	  	 @fDimZTol 	 Float,
 	  	 @iLineItem 	 Int
/*  Non nullable
Line_Item_Number
Prod_Id
Order_Line_Id
Is_Active
Order_Id 
*/
Select @OrderId = Null
Select @Now = dbo.fnServer_CmnGetDate(getUTCdate())
If  @OrderNumber is null --Plant_Order_Number
  Begin
 	 Select  'Order Number Not Found'
 	 Return(-100)
  End
Select @OrderId = Order_Id From Customer_Orders where Plant_Order_Number = @OrderNumber
If @OrderId is null
  Begin
 	 Select  'Order Number Not Found'
 	 Return(-100)
  End
If  isnumeric(@LineItem) = 0
  Begin
 	 Select  'Line Item Not Correct'
 	 Return(-100)
  End
Select @iLineItem = Convert(int,@LineItem)
If  @ProdCode is null 
  Begin
 	 Select  'Product Code Not Found'
 	 Return(-100)
  End
Select @ProdId = Null
Select @ProdId = Prod_Id from Products where Prod_Code = @ProdCode
If  @ProdId is null 
  Begin
 	 Select  'Product Not Found'
 	 Return(-100)
  End
If @COADate is not Null
BEGIN
 	 If Len(@COADate)  <> 14 
 	 BEGIN
 	  	 Select  'COA date date format not correct'
 	  	 Return(-100)
 	 END
 	 SELECT @dCOADate = 0
 	 SELECT @dCOADate = DateAdd(year,convert(int,substring(@COADate,1,4)) - 1900,@dCOADate)
 	 SELECT @dCOADate = DateAdd(month,convert(int,substring(@COADate,5,2)) - 1,@dCOADate)
 	 SELECT @dCOADate = DateAdd(day,convert(int,substring(@COADate,7,2)) - 1,@dCOADate)
 	 SELECT @dCOADate = DateAdd(hour,convert(int,substring(@COADate,9,2)) ,@dCOADate)
 	 SELECT @dCOADate = DateAdd(minute,convert(int,substring(@COADate,11,2)),@dCOADate)
END 	 
IF @CompleteDate is not Null
BEGIN
 	 If Len(@CompleteDate)  <> 14 
 	 BEGIN
 	  	 Select  'Actual ship date format not correct'
 	  	 Return(-100)
 	 END
 	 SELECT @CDate = 0
 	 SELECT @CDate = DateAdd(year,convert(int,substring(@CompleteDate,1,4)) - 1900,@CDate)
 	 SELECT @CDate = DateAdd(month,convert(int,substring(@CompleteDate,5,2)) - 1,@CDate)
 	 SELECT @CDate = DateAdd(day,convert(int,substring(@CompleteDate,7,2)) - 1,@CDate)
 	 SELECT @CDate = DateAdd(hour,convert(int,substring(@CompleteDate,9,2)) ,@CDate)
 	 SELECT @CDate = DateAdd(minute,convert(int,substring(@CompleteDate,11,2)),@CDate)
END
If @ShipToCode is not null
  Begin
 	 Select @ShipToId = Null
 	 Select @ShipToId = Customer_Id From Customer
 	   Where Customer_Code = @ShipToCode
 	 If @ShipToId is null 
 	   Begin
 	  	 Select  'Ship To Code Not Found'
 	  	 Return(-100)
 	   End
  End
If @ConsCode is not Null
  Begin
 	 Select @CosigneeId = Null
 	 Select @CosigneeId = Customer_Id From Customer
 	   Where Customer_Code = @ConsCode
 	 If @CosigneeId is null 
 	   Begin
 	  	 Select  'Consignee Code Not Found'
 	  	 Return(-100)
 	   End
  End
If isnumeric(@Quanity) = 0 and @Quanity is not null
  Begin
 	 Select  'Quanity not correct'
 	 Return(-100)
  End
Select @fQuanity 	 = Convert(Float,@Quanity)
If isnumeric(@DimA) = 0 and @DimA is not null
  Begin
 	 Select  'Dimension A not correct'
 	 Return(-100)
  End
Select @fDimA 	 = Convert(Float,@DimA)
If isnumeric(@DimX) = 0 and @DimX is not null
  Begin
 	 Select  'Dimension X not correct'
 	 Return(-100)
  End
Select @fDimX 	 = Convert(Float,@DimX)
If isnumeric(@DimY) = 0 and @DimY is not null
  Begin
 	 Select  'Dimension Y not correct'
 	 Return(-100)
  End
Select @fDimY 	 = Convert(Float,@DimY)
If isnumeric(@DimZ) = 0 and @DimZ is not null
  Begin
 	 Select  'Dimension Z not correct'
 	 Return(-100)
  End
Select @fDimZ 	 = Convert(Float,@DimZ)
If isnumeric(@DimATol) = 0 and @DimATol is not null
  Begin
 	 Select  'Tolerance A not correct'
 	 Return(-100)
  End
Select @fDimATol 	 = Convert(Float,@DimATol)
If isnumeric(@DimXTol) = 0 and @DimXTol is not null
  Begin
 	 Select  'Tolerance X not correct'
 	 Return(-100)
  End
Select @fDimXTol 	 = Convert(Float,@DimXTol)
If isnumeric(@DimYTol) = 0 and @DimYTol is not null
  Begin
 	 Select  'Tolerance Y not correct'
 	 Return(-100)
  End
Select @fDimYTol 	 = Convert(Float,@DimYTol)
If isnumeric(@DimZTol) = 0 and @DimZTol is not null
  Begin
 	 Select  'Tolerance Z not correct'
 	 Return(-100)
  End
Select @fDimZTol 	 = Convert(Float,@DimZTol)
Select @OrderLineId = Order_Line_Id From Customer_Order_Line_Items
  Where Order_Id = @OrderId and Line_Item_Number = @iLineItem
/* If doesn't exist then create */
If @OrderLineId Is Null
 	 Execute spEMCO_AddLineItem @OrderId,@iLineItem,@ProdId,@fQuanity,@UOM,@fDimX,@fDimY,@fDimZ,@fDimA,@CDate,@General1,@General2,@General3,@General4,@General5,
 	  	 @CosigneeId,@In_User_Id,@OrderLineId  OUTPUT,@fDimATol, 	 @fDimXTol,@fDimYTol,@fDimZTol,@ShipToId
Else
 	 Execute spEMCO_EditLineItem @OrderLineId,@iLineItem,@ProdId,@fQuanity,@UOM,@fDimX,@fDimY,@fDimZ,@fDimA,@CDate,@General1,@General2,@General3,@General4,@General5,
 	  	 @CosigneeId,@In_User_Id,@fDimATol, 	 @fDimXTol,@fDimYTol,@fDimZTol,@ShipToId
 	  	 
If @OrderLineId is null
  Begin 
 	 Select 'Failed - could not create customer order'
 	 Return (-100)
  End
Update Customer_Order_Line_Items set Extended_Info = @ExtInfo Where Order_Line_Id = @OrderLineId
Return(0)
