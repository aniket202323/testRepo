CREATE PROCEDURE dbo.spServer_EMgrSaveOrderData0061 
@Stage int,
@PlantOrderNum nVarChar(20),
@BasisWt nVarChar(10),
@GradeName nVarChar(50),
@GradeCode nVarChar(10),
@GradeFourthChar nVarChar(5),
@OrderType int,
@QualityStatus nVarChar(5),
@ReadyDate nVarChar(30),
@LastChangedDate nVarChar(30),
@Size nVarChar(10),
@Trademark nVarChar(5), 	  	 
@OrderStatus int,
@StockCode nVarChar(10),
@OrderedUnits nVarChar(10),
@OrderedPounds nVarChar(10),
@OrderedQuantity nVarChar(10),
@MaxTradeAllowance nVarChar(10),
@MinTradeAllowance nVarChar(10),
@CustNameCityState nVarChar(50),
@CustName nVarChar(50),
@CustCity nVarChar(50),
@CustState nVarChar(10),
@CustOrderNum nVarChar(25),
@ConsNameCityState nVarChar(50),
@ConsName nVarChar(50),
@ConsCity nVarChar(50),
@ConsState nVarChar(10),
@ConsPONum nVarChar(25),
@CoreCode nVarChar(10),
@WrapCode nVarChar(10),
@PalletCode nVarChar(10),
@MinDiameter nVarChar(10),
@MaxDiameter nVarChar(10),
@MakeDiameter nVarChar(10),
@ShipVia nVarChar(10),
@LabelsPack nVarChar(5),
@RollsPerPack nVarChar(5),
@TradeGrammage nVarChar(5),
@LogoIndicator nVarChar(5),
@LabelUnit nVarChar(5),
@QualityFlag nVarChar(5),
@ReqDeliveryDate nVarChar(10),
@UseEdgeRollsSW nVarChar(5),
@InCareOfName nVarChar(50),
@Patent1 nVarChar(10),
@Patent2 nVarChar(10),
@CustomerCode nVarChar(10),
@AvgRollWt nVarChar(10),
@OrderFillUOM nVarChar(10),
@FillFromOrder nVarChar(10),
@DontFillFromOrder nVarChar(10),
@UserId int,
@Success int OUTPUT,
@ErrorMsg nVarChar(255) OUTPUT
 AS
Declare
  @OrderId int,
  @CustomerId int,
  @ConsigneeId int,
  @ProdId int,
  @OrderLineId int,
  @NewReadyDate datetime,
  @ProdCode nVarChar(50),
  @NumericBasisWt int,
  @PropId int,
  @CharId int,
  @SpecId int,
  @NewCustomerCode nVarChar(100),
  @NewCustomerName nVarChar(100),
  @NewConsigneeCode nVarChar(100),
  @NewConsigneeName nVarChar(100)
Select @Success = 0
Select @ErrorMsg = 'Unknown Error'
Select @OrderId = NULL
Select @OrderId = Order_Id From Customer_Orders Where Plant_Order_Number = @PlantOrderNum
-- Order Un-Complete Or Complete 
If (@OrderStatus = 8) Or (@OrderStatus = 9)
  Begin
    If (@OrderId Is NULL)
      Begin
        Select @ErrorMsg = 'Missing Order [' + @PlantOrderNum + ']'
        Return
      End
    Select @Success = 1
    Update Customer_Orders
      Set Order_Status = Convert(nVarChar(10),@OrderStatus)
    Where Order_Id = @OrderId
    Return
  End
-- Order Delete
If (@OrderStatus = 2)
  Begin
    If (@OrderId Is NULL)
      Begin
        Select @ErrorMsg = 'Missing Order [' + @PlantOrderNum + ']'
        Return
      End
    Select @Success = 1
    Execute spServer_CmnDeleteOrder @OrderId
    Return
  End
If (@OrderStatus <> 1) And (@OrderStatus <> 4)
  Begin
    Select @ErrorMsg = 'Invalid Order Status [' + Convert(nVarChar(10),@OrderStatus) + ']'
    Return
  End
-- Stock Order
If (@OrderType = 1) Or (@OrderType = 3)
  Begin
    Select @PropId = NULL
    Select @PropId = Prop_Id From Product_Properties Where Prop_Desc = 'Stock Table Lookup'
    If (@PropId Is NULL)
      Begin
        Select @ErrorMsg = 'Stock - Property [Stock Table Lookup] is Missing'
        Return
      End
    Select @CharId = NULL
    Select @CharId = Char_Id From Characteristics Where (Prop_Id = @PropId) And (Char_Desc = 'Grade Code')
    If (@CharId Is NULL)
      Begin
        Select @ErrorMsg = 'Stock - Characteristic [Grade Code] is Missing'
        Return
      End
    Select @SpecId = NULL
    Select @SpecId = Spec_Id From Specifications Where (Prop_Id = @PropId) And (Spec_Desc = @StockCode)  
    If (@SpecId Is NULL)
      Begin
        Select @ErrorMsg = 'Stock - Specification [' + @StockCode + '] is Missing'
        Return
      End
    Select @ProdCode = NULL
    Select @ProdCode = Target From Active_Specs Where (Spec_Id = @SpecId) And (Char_Id = @CharId) And (Expiration_Date Is NULL) 
    If (@ProdCode Is NULL)
      Begin
        Select @ErrorMsg = 'Stock - Active Specification [' + @StockCode + '] is Missing'
        Return
      End
  End
Else
  Begin
    Select @NumericBasisWt = Convert(int,Convert(float,@BasisWt))
    If (@NumericBasisWt < 100)
      Select @ProdCode = @GradeCode + '-0' + Convert(nVarChar(10),@NumericBasisWt)
    Else
      Select @ProdCode = @GradeCode + '-' + Convert(nVarChar(10),@NumericBasisWt)
  End
Select @ProdId = NULL
Select @ProdId = Prod_Id From Products Where Prod_Code = @ProdCode
If (@ProdId Is NULL)
  Begin
    Select @ErrorMsg = 'Invalid ProdCode [' + @ProdCode + ']'
    Return
  End
If (@OrderId Is NULL)
  Begin
    If (@Stage = 1)
      Begin
 	 Select @CustName = 'STOCK'
 	 Select @CustCity = 'ORDER'
 	 Select @CustState = ''
 	 Select @CustOrderNum = 'STOCK'
      End
    Select @NewCustomerCode = @CustName + @CustCity + @CustState
    Select @NewCustomerName = @CustName + ' ' + @CustCity + ', ' + @CustState
    Execute spServer_CmnGetCustomerId @NewCustomerCode,@NewCustomerName,1,@CustomerId OUTPUT
    Insert Into Customer_Orders(Customer_Id,Customer_Order_Number,Plant_Order_Number,Entered_By,Order_Type,Order_Status,Entered_Date)
      Values(@CustomerId,@CustOrderNum,@PlantOrderNum,@UserId,'X',Convert(nVarChar(10),@OrderStatus),dbo.fnServer_CmnGetDate(GetUTCDate()))
    Select @OrderId = Scope_identity()
  End
Else
  Begin
    Select @CustomerId = Customer_Id From Customer_Orders Where Order_Id = @OrderId
  End
If (@ReadyDate = '') Or (@ReadyDate = '000000')
  Select @NewReadyDate = NULL
Else
  Select @NewReadyDate = Substring(@ReadyDate,3,2) + '/' + Substring(@ReadyDate,1,2) + '/' + Substring(@ReadyDate,5,2)
Update Customer_Orders
  Set Order_Status = Convert(nVarChar(10),@OrderStatus),
      Forecast_Mfg_Date = @NewReadyDate
  Where Order_Id = @OrderId
Select @OrderLineId = NULL
Select @OrderLineId = Order_Line_Id From Customer_Order_Line_Items Where (Order_Id = @OrderId) And (Prod_Id = @ProdId)
If (@OrderLineId Is NULL)
  Begin
    Insert Into Customer_Order_Line_Items(Order_Id,Line_Item_Number,Prod_Id,Ordered_Quantity,Dimension_X)
      Values(@OrderId,1,@ProdId,Convert(float,@OrderedQuantity),Convert(float,@Size))
    Select @OrderLineId = Scope_identity()
  End
Update Customer_Order_Line_Items
  Set Dimension_X = Convert(float,@Size),
      Ordered_Quantity = Convert(float,@OrderedQuantity)
  Where Order_Line_Id = @OrderLineId
If (@Stage >= 3)
  Begin
    Select @NewConsigneeCode = @ConsName + @ConsCity + @ConsState
    Select @NewConsigneeName = @ConsName + ' ' + @ConsCity + ', ' + @ConsState
    Execute spServer_CmnGetConsigneeId @NewConsigneeCode,@NewConsigneeName,1,@ConsigneeId OUTPUT
    Update Customer_Orders
      Set Consignee_Id = @ConsigneeId
      Where Order_Id = @OrderId
    Update Customer_Order_Line_Items
      Set Dimension_Y = Convert(float,@MakeDiameter)
      Where Order_Line_Id = @OrderLineId
  End
If (@Stage = 5)
  Begin
    Update Customer_Order_Line_Items
      Set Ordered_UOM = @OrderFillUOM
      Where Order_Line_Id = @OrderLineId
  End
Select @Success = 1
