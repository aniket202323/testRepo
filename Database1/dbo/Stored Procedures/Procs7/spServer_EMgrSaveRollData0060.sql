CREATE PROCEDURE dbo.spServer_EMgrSaveRollData0060
@PU_Id int,
@User_Id int,
@TimeStamp datetime,
@RollNum nVarChar(20),
@Customer_Code nVarChar(20),
@Order nVarChar(20),
@Status nVarChar(30),
@Width float,
@Dia float,
@LinFt float,
@Weight float,
@Grd nVarChar(10),
@Bwt nVarChar(10),
@ShipmentNum nVarChar(20),
@ShipmentDate datetime,
@MReelNum nVarChar(20),
@AlternateNum nVarChar(20),
@Success int OUTPUT,
@ErrorMsg nVarChar(255) OUTPUT
 AS
Declare
  @Customer_Id int,
  @Prod_Id int,
  @Order_Id int,
  @Order_Line_Id int,
  @Order_Num nVarChar(100),
  @Shipment_Id int,
  @Shipment_Item_Id int,
  @Event_Id int,
  @Component_Id int,
  @Event_Status int,
  @Event_Type int,
  @MasterEventId int,
  @AddRollMessage nVarChar(255)
Select @ErrorMsg = 'Unknown Error'
Select @Success = 0
Select @Event_Status = 7
If (@Status = 'LOAD')
  Select @Event_Status = 14
If (@Status = 'WIND')
  Select @Event_Status = 5
If (@Status = 'WRAP')
  Select @Event_Status = 9
-- Added on 1/19/2000 because of bug in Report Thing
Select @Event_Status = 5
Select @Event_Type = 1
Select @Prod_Id = NULL
Execute spServer_EMgrProdXRef @PU_Id,@Grd,0,@Prod_Id OUTPUT
If (@Prod_Id = 1)
  Begin
    Select @ErrorMsg = 'Invalid ProdCode [' + @Grd + @Bwt + ']'
    Return
  End
Select @MasterEventId = NULL
Select @MasterEventId = Event_Id From Events Where Event_Num = @MReelNum
If (@MasterEventId Is NULL)
  Begin
    Select @ErrorMsg = 'Invalid Master Event [' + @MReelNum + ']'
    Return
  End
Execute spServer_CmnGetCustomerId @Customer_Code,@Customer_Code,1,@Customer_Id OUTPUT
If (@Customer_Id = 0)
  Begin
    Select @ErrorMsg = 'Error Getting Customer Info [' + @Customer_Code + ']'
    Return
  End
Select @Order_Num = @Customer_Code + @Order
Execute spServer_CmnGetOrderId @Customer_Id,@Order_Num,@User_Id,@Prod_Id,'X','Z',1,1,@Order_Id OUTPUT,@Order_Line_Id OUTPUT
If (@Order_Id = 0) Or (@Order_Line_Id = 0)
  Begin
    Select @ErrorMsg = 'Error Getting Order Info [' + @Customer_Code + @Order + ']'
    Return
  End
Execute spServer_CmnGetShipmentId @ShipmentNum,@ShipmentDate,@Weight,@Order_Id,@Order_Line_Id,1,@Shipment_Id OUTPUT,@Shipment_Item_Id OUTPUT
If (@Shipment_Id = 0) Or (@Shipment_Item_Id = 0)
  Begin
    Select @ErrorMsg = 'Error Getting Shipment Info [' + @ShipmentNum + ']'
    Return
  End
Execute spServer_CmnAddRoll @MasterEventId,@User_Id,@PU_Id,@RollNum,@AlternateNum,@TimeStamp,@Prod_Id,@Event_Status,@Event_Type,@Width,@Dia,@LinFt,@Weight,@Order_Id,@Order_Line_Id,@Shipment_Item_Id,1,@Event_Id OUTPUT,@Component_Id OUTPUT,@AddRollMessage OUTPUT
If (@Event_Id = 0)
  Begin
    Select @ErrorMsg = 'Error Adding Roll Data [Roll-' + @RollNum + '] [Master-' + @MReelNum + '] [' + @AddRollMessage + ']'
    Return
  End
Select @Success = 1
