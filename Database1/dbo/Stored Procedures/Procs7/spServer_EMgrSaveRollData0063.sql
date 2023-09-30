CREATE PROCEDURE dbo.spServer_EMgrSaveRollData0063
@PU_Id int,
@User_Id int,
@TimeStamp datetime,
@RollNum nVarChar(20),
@MReelNum nVarChar(20),
@Customer_Code nVarChar(20),
@Customer_Name nVarChar(50),
@Order_Num nVarChar(100),
@ItemNo int,
@Status nVarChar(30),
@DemX float,
@DemY float,
@DemZ float,
@DemA float,
@CustOrderNum nVarChar(50),
@Success int OUTPUT,
@ErrorMsg nVarChar(255) OUTPUT
 AS
Declare
  @Customer_Id int,
  @Prod_Id int,
  @Order_Id int,
  @Order_Line_Id int,
  @Event_Id int,
  @Component_Id int,
  @Event_Status int,
  @Event_Type int,
  @MasterEventId int,
  @MasterPUId int,
  @MasterTimeStamp datetime,
  @AddRollMessage nVarChar(255),
  @StopTime datetime
Select @ErrorMsg = 'Unknown Error'
Select @Success = 0
Select @Event_Status = 9
If (@Status = 'G')
  Select @Event_Status = 5
Select @Event_Type = 1
Select @StopTime = DateAdd(Month,-11,dbo.fnServer_CmnGetDate(GetUTCDate()))
Select @MasterEventId = NULL
Select @MasterEventId = Event_Id,
       @MasterPUId = PU_Id,
       @MasterTimeStamp = TimeStamp
  From Events 
  Where (SubString(Event_Num,4,50) = @MReelNum) And
        (TimeStamp > @StopTime)
If (@MasterEventId Is NULL)
  Begin
    Select @ErrorMsg = 'Invalid Master Event [' + @MReelNum + ']'
    Return
  End
Select @Prod_Id = NULL
Select @Prod_Id = Prod_Id
  From Production_Starts
  Where (PU_Id = @MasterPUId) And
        (Start_Time < @MasterTimeStamp) And
        ((End_Time >= @MasterTimeStamp) Or (End_Time Is NULL))
Execute spServer_CmnGetCustomerId @Customer_Code,@Customer_Name,1,@Customer_Id OUTPUT
If (@Customer_Id = 0)
  Begin
    Select @ErrorMsg = 'Error Getting Customer Info [' + @Customer_Code + ']'
    Return
  End
Execute spServer_CmnGetOrderId @Customer_Id,@Order_Num,@User_Id,@Prod_Id,'X','Z',@ItemNo,1,@Order_Id OUTPUT,@Order_Line_Id OUTPUT
If (@Order_Id = 0) Or (@Order_Line_Id = 0)
  Begin
    Select @ErrorMsg = 'Error Getting Order Info [' + @Order_Num + ']'
    Return
  End
Update Customer_Orders
  Set Customer_Order_Number = @CustOrderNum
  Where Order_Id = @Order_Id
Execute spServer_CmnAddRoll @MasterEventId,@User_Id,@PU_Id,@RollNum,NULL,@TimeStamp,@Prod_Id,@Event_Status,@Event_Type,@DemX,@DemY,@DemZ,@DemA,@Order_Id,@Order_Line_Id,NULL,1,@Event_Id OUTPUT,@Component_Id OUTPUT,@AddRollMessage OUTPUT
If (@Event_Id = 0)
  Begin
    Select @ErrorMsg = 'Error Adding Roll Data [Roll-' + @RollNum + '] [Master-' + @MReelNum + '] [' + @AddRollMessage + ']'
    Return
  End
Select @Success = 1
