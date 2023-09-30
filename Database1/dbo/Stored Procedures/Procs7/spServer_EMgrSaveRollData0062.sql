CREATE PROCEDURE dbo.spServer_EMgrSaveRollData0062
@TRFound int,
@PU_Id int,
@UserId int,
@TransType nVarChar(10),
@Field1 nVarChar(50),
@Field2 nVarChar(50),
@Field3 nVarChar(50),
@Field4 nVarChar(50),
@Field5 nVarChar(50),
@Field6 nVarChar(50),
@Field7 nVarChar(50),
@Field8 nVarChar(50),
@Field9 nVarChar(50),
@Field10 nVarChar(50),
@Field11 nVarChar(50),
@Field12 nVarChar(50),
@Field13 nVarChar(50),
@Field14 nVarChar(50),
@Field15 nVarChar(50),
@Field16 nVarChar(50),
@Field17 nVarChar(50),
@Field18 nVarChar(50),
@Field19 nVarChar(50),
@Field20 nVarChar(50),
@Field21 nVarChar(50),
@Field22 nVarChar(50),
@Field23 nVarChar(50),
@Field24 nVarChar(50),
@Field25 nVarChar(50),
@Field26 nVarChar(50),
@Field27 nVarChar(50),
@Field28 nVarChar(50),
@Field29 nVarChar(50),
@Field30 nVarChar(50),
@Success int OUTPUT,
@ErrorMsg nVarChar(255) OUTPUT
AS
Declare
  @TimeStamp datetime,
  @AppliedProdId int,
  @RollNumber nVarChar(50),
  @MasterEventNum nVarChar(50),
  @MasterEventId int,
  @PlantOrderNumber nVarChar(50),
  @EventStatus int,
  @EventType int,
  @OrderId int,
  @OrderLineId int,
  @Dimension_Y float,
  @Dimension_Z float,
  @EventId int,
  @ComponentId int,
  @ShipmentNumber nVarChar(50),
  @ShipmentDate nVarChar(30),
  @ShipmentId int,
  @ShipmentItemId int,
  @Status int,
  @AddRollMessage nVarChar(255),
  @AuditId int,
  @BeforeEventId int,
  @BeforeSrcEventId int,
  @AfterEventId int,
  @AfterSrcEventId int,
  @IgnoreTransaction int
Select @Success = 1
Select @ErrorMsg = ''
Select @IgnoreTransaction = 1
If (@TransType = 'TR10') Or 
   (@TransType = 'TR11') Or 
   (@TransType = 'TR13') Or 
   (@TransType = 'TR20') Or 
   (@TransType = 'TR30')
Select @IgnoreTransaction = 0
If (@IgnoreTransaction = 1)
  Return
Select @Success = 0
Select @ErrorMsg = 'Unknown Error'
Select @TimeStamp = dbo.fnServer_CmnGetDate(GetUTCDate())
Select @ShipmentDate = Convert(nVarChar(30),@TimeStamp)
Select @RollNumber = @Field2
Select @PlantOrderNumber = @Field3
Select @Dimension_Y = Convert(float,@Field14)
Select @Dimension_Z = Convert(float,@Field17)
Select @ShipmentNumber = @Field13
Select @EventStatus = 7
If (@Field4 = 'G')
  Select @EventStatus = 5
If (@Field4 = 'I')
  Select @EventStatus = 9
If (@Field4 = 'D')
  Select @EventStatus = 12
If (@Field4 = 'S')
  Select @EventStatus = 14
Select @EventType = 1
Select @OrderId = NULL
Select @OrderLineId = NULL
Select @OrderId = Order_Id From Customer_Orders Where Plant_Order_Number = @PlantOrderNumber
If (@OrderId Is Not NULL) 
  Select @OrderLineId = Min(Order_Line_Id) From Customer_Order_Line_Items Where (Order_Id = @OrderId)
Select @EventId = NULL
Select @EventId = Event_Id From Events Where (PU_Id = @PU_Id) And (Event_Num = @RollNumber)
-- ******************************************** Audit Stuff Below 
/*
Insert Into Local_RollAudit (TRFound,PU_Id,UserId,TransType,Field1,Field2,Field3,Field4,Field5,Field6,Field7,Field8,Field9,Field10,Field11,Field12,Field13,Field14,Field15,Field16,Field17,Field18,Field19,Field20,Field21,Field22,Field23,Field24,Field25,Field26,Field27,Field28,Field29,Field30,TransTime)
  Values(@TRFound,@PU_Id,@UserId,@TransType,@Field1,@Field2,@Field3,@Field4,@Field5,@Field6,@Field7,@Field8,@Field9,@Field10,@Field11,@Field12,@Field13,@Field14,@Field15,@Field16,@Field17,@Field18,@Field19,@Field20,@Field21,@Field22,@Field23,@Field24,@Field25,@Field26,@Field27,@Field28,@Field29,@Field30,dbo.fnServer_CmnGetDate(GetUTCDate()))
Select @AuditId = Scope_identity()
Select @BeforeEventId = @EventId
Select @BeforeSrcEventId = NULL
If (@BeforeEventId Is Not NULL)
  Select @BeforeSrcEventId = Source_Event_Id From Event_Components Where (Event_Id = @BeforeEventId)
Update Local_RollAudit
  Set BeforeEventId = @BeforeEventId,
      BeforeSrcEventId = @BeforeSrcEventId
  Where Id = @AuditId
*/
-- ******************************************** Audit Stuff Above 
-- Roll Create
If (@TransType = 'TR10') And (@EventId Is NULL)
  Begin
    If (SubString(@RollNumber,1,2) = '37') Or (SubString(@RollNumber,1,2) = '39')
      Begin
        Select @Success = 1
        Goto RollUpdateComplete
      End
    If (@TRFound = 1)
      Select @MasterEventNum = Substring(@RollNumber,1,7)
    Else
      Select @MasterEventNum = Substring(@RollNumber,1,8)
    Select @MasterEventId = NULL
    Select @MasterEventId = Event_Id From Events Where Event_Num = @MasterEventNum
    If (@MasterEventId Is NULL)
      Begin
        Select @ErrorMsg = '(' + @TransType + ') Invalid Master Event [' + @MasterEventNum + ']'
        Goto RollUpdateComplete
      End
    Execute spServer_CmnAddRoll @MasterEventId,@UserId,@PU_Id,@RollNumber,NULL,@TimeStamp,NULL,@EventStatus,@EventType,NULL,@Dimension_Y,@Dimension_Z,NULL,@OrderId,@OrderLineId,NULL,1,@EventId OUTPUT,@ComponentId OUTPUT,@AddRollMessage OUTPUT
    If (@EventId = 0)
      Begin
        Select @ErrorMsg = '(' + @TransType + ') Error Adding Roll [' + @RollNumber + '] [' + @AddRollMessage + ']'        
        Goto RollUpdateComplete
      End
    Select @Success = 1
    Goto RollUpdateComplete
  End
if (@EventId Is Not NULL)
  Begin
    Select @TimeStamp = TimeStamp,
           @AppliedProdId = Applied_Product
    From Events 
    Where (Event_Id = @EventId)
  End
-- Roll Edit Or Wrap
If (@TransType = 'TR11') Or (@TransType = 'TR13') Or (@TransType = 'TR10')
  Begin
    If (@EventId Is NULL)
      Begin
        Select @ErrorMsg = '(' + @TransType + ') Roll Number Not Found [' + @RollNumber + ']'
        Goto RollUpdateComplete
      End
    Execute @Status = spServer_DBMgrUpdEvent 
 	  	 @EventId,
 	  	 @RollNumber,
 	  	 @PU_Id,
 	  	 @TimeStamp,
 	  	 @AppliedProdId,
 	  	 NULL,
 	  	 @EventStatus,
 	  	 2,
 	  	 0,NULL,NULL,NULL,NULL,NULL,NULL,0
    If (@Status <> 2) And (@Status <> 4)
      Begin
        Select @ErrorMsg = '(' + @TransType + ') Error Updating Roll [' + @RollNumber + ']'
        Goto RollUpdateComplete
      End
    Update Event_Details
      Set Order_Id = @OrderId,
          Order_Line_Id = @OrderLineId,
          Final_Dimension_Y = @Dimension_Y,
          Final_Dimension_Z = @Dimension_Z
      Where Event_Id = @EventId
    Select @Success = 1
    Goto RollUpdateComplete
  End
-- Roll Shipped
If (@TransType = 'TR20')
  Begin
    If (@EventId Is NULL)
      Begin
        Select @ErrorMsg = '(' + @TransType + ') Roll Number Not Found [' + @RollNumber + ']'
        Goto RollUpdateComplete
      End
    Select @EventStatus = 14
    Execute spServer_CmnGetShipmentId @ShipmentNumber,@ShipmentDate,0,@OrderId,@OrderLineId,1,@ShipmentId OUTPUT,@ShipmentItemId OUTPUT
    If (@ShipmentId = 0) Or (@ShipmentItemId = 0)
      Begin
        Select @ErrorMsg = '(TR20) Error Adding Shipment Info [' + @ShipmentNumber + ']'
        Goto RollUpdateComplete
      End
    Execute @Status = spServer_DBMgrUpdEvent 
 	  	 @EventId,
 	  	 @RollNumber,
 	  	 @PU_Id,
 	  	 @TimeStamp,
 	  	 @AppliedProdId,
 	  	 NULL,
 	  	 @EventStatus,
 	  	 2,
 	  	 0,NULL,NULL,NULL,NULL,NULL,NULL,0
    If (@Status <> 2) And (@Status <> 4)
      Begin
        Select @ErrorMsg = '(' + @TransType + ') Error Updating Roll [' + @RollNumber + ']'
        Goto RollUpdateComplete
      End
    Update Event_Details
      Set Shipment_Item_Id = @ShipmentItemId,
          Order_Id = @OrderId,
          Order_Line_Id = @OrderLineId
      Where Event_Id = @EventId
    Select @Success = 1
    Goto RollUpdateComplete
  End
-- Roll Salvage
If (@TransType = 'TR30')
  Begin
    Select @EventStatus = 15
    Select @Dimension_Y = NULL
    Select @Dimension_Z = NULL
    Select @MasterEventNum = @Field5
    If (@RollNumber = @MasterEventNum)
      Begin
        Select @Success = 1
        Goto RollUpdateComplete
      End
    Select @MasterEventId = NULL
    Select @MasterEventId = Event_Id From Events Where Event_Num = @MasterEventNum
    If (@MasterEventId Is NULL)
      Begin
        Select @ErrorMsg = '(' + @TransType + ') Invalid Parent Roll [' + @MasterEventNum + ']'
        Goto RollUpdateComplete
      End
    If (@OrderId Is NULL)
      Begin
 	 Select @OrderId = NULL
 	 Select @OrderId = Order_Id From Event_Details Where Event_Id = @MasterEventId
 	 If (@OrderId Is Not NULL) 
 	   Select @OrderLineId = Min(Order_Line_Id) From Customer_Order_Line_Items Where (Order_Id = @OrderId)
      End
    Execute spServer_CmnAddRoll @MasterEventId,@UserId,@PU_Id,@RollNumber,NULL,@TimeStamp,NULL,@EventStatus,@EventType,NULL,@Dimension_Y,@Dimension_Z,NULL,@OrderId,@OrderLineId,NULL,1,@EventId OUTPUT,@ComponentId OUTPUT,@AddRollMessage OUTPUT
    If (@EventId = 0)
      Begin
        Select @ErrorMsg = '(' + @TransType + ') Error Adding Salvage Roll [' + @RollNumber + '] [' + @AddRollMessage + ']'        
        Goto RollUpdateComplete
      End
    Select @Success = 1
    Goto RollUpdateComplete
  End
Select @Success = 1
RollUpdateComplete:
If (@Success = 1)
  Select @ErrorMsg = 'Success'
-- ******************************************** Audit Stuff Below 
/*
Select @AfterEventId = @EventId
Select @AfterSrcEventId = NULL
If (@AfterEventId Is Not NULL)
  Select @AfterSrcEventId = Source_Event_Id From Event_Components Where (Event_Id = @AfterEventId)
Update Local_RollAudit
  Set AfterEventId = @AfterEventId,
      AfterSrcEventId = @AfterSrcEventId
  Where Id = @AuditId
*/
-- ******************************************** Audit Stuff Above 
