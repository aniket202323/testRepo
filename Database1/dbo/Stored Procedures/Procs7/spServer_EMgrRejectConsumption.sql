CREATE PROCEDURE dbo.spServer_EMgrRejectConsumption
@Event_Id int,
@Success int OUTPUT,
@PU_Id int OUTPUT,
@Event_Num nVarChar(100) OUTPUT,
@EvtYear int OUTPUT,
@EvtMonth int OUTPUT,
@EvtDay int OUTPUT,
@EvtHour int OUTPUT,
@EvtMin int OUTPUT,
@Source_Event int OUTPUT,
@Confirmed int OUTPUT,
@AppProdId int OUTPUT
 AS
Declare
  @Result int,
  @TimeStamp Datetime
Select @PU_Id = PU_Id,
       @Event_Num = Event_Num,
       @TimeStamp = TimeStamp,
       @Source_Event = Source_Event,
       @Confirmed = Confirmed,
       @AppProdId = Applied_Product
  From Events
  Where Event_Id = @Event_Id
Select @Success = 0
If (@PU_Id Is Null)
  Return
Execute @Result = spServer_DBMgrUpdEvent 
 	 @Event_Id,
 	 @Event_Num,
 	 @PU_Id,
 	 @TimeStamp,
 	 @AppProdId,
 	 @Source_Event,
 	 7,
 	 2,
 	 0,NULL,NULL,NULL,NULL,NULL,NULL,0
If (@Result != 2)
  Return
Select @EvtYear = DatePart(Year,@TimeStamp)
Select @EvtMonth = DatePart(Month,@TimeStamp)
Select @EvtDay = DatePart(Day,@TimeStamp)
Select @EvtHour = DatePart(Hour,@TimeStamp)
Select @EvtMin = DatePart(Minute,@TimeStamp)
If (@Source_Event Is Null)
  Select @Source_Event = 0
If (@Confirmed Is Null)
  Select @Confirmed = 0
If (@AppProdId Is Null)
  Select @AppProdId = 0
Select @Success = 1
