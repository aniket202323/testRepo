CREATE PROCEDURE dbo.spServer_EMgrTransStatusUpd
@PU_Id int,
@TransitionTime datetime,
@From_Event_Status int,
@To_Event_Status int,
@Event_Id int OUTPUT,
@Event_Num nVarChar(100) OUTPUT,
@EventYear int OUTPUT,
@EventMonth int OUTPUT,
@EventDay int OUTPUT,
@EventHour int OUTPUT,
@EventMin int OUTPUT,
@EventSec int OUTPUT,
@Applied_Product int OUTPUT,
@Source_Event int OUTPUT,
@Confirmed int OUTPUT
 AS
Declare
  @TimeStamp DateTime,
  @Result int
Select @EventYear = 0
Select @EventMonth = 0
Select @EventDay = 0
Select @EventHour = 0
Select @EventMin = 0
Select @EventSec = 0
Select @Event_Id = COALESCE(Event_Id,0),
       @Event_Num = Event_Num,
       @TimeStamp = TimeStamp,
       @Applied_Product = Applied_Product,
       @Source_Event = Source_Event,
       @Confirmed = Confirmed
  From Events
  Where (PU_Id = @PU_Id) And
        (TimeStamp = (Select TimeStamp = Min(TimeStamp) 
 	  	         From Events
 	  	         Where (PU_Id = @PU_Id) And
 	  	               (Event_Status = @From_Event_Status)))
If @Event_Id Is Null
  Select @Event_Id = 0
If @Event_Id <> 0
  Begin
    Select @EventYear = DatePart(Year,@TimeStamp)
    Select @EventMonth = DatePart(Month,@TimeStamp)
    Select @EventDay = DatePart(Day,@TimeStamp)
    Select @EventHour = DatePart(Hour,@TimeStamp)
    Select @EventMin = DatePart(Minute,@TimeStamp)
    Select @EventSec = DatePart(Second,@TimeStamp)
    Execute @Result = spServer_DBMgrUpdEvent 
 	  	 @Event_Id,
 	  	 @Event_Num,
 	  	 @PU_Id,
 	  	 @TimeStamp,
 	  	 @Applied_Product,
 	  	 @Source_Event,
 	  	 @To_Event_Status,
 	  	 2,
 	  	 0,NULL,NULL,NULL,NULL,NULL,NULL,0
    If @Result <> 2
      Select @Event_Id = 0
    If @Applied_Product Is Null
      Select @Applied_Product = 0
    If @Source_Event Is Null
      Select @Source_Event = 0
    If @Confirmed Is Null
      Select @Confirmed = 0
  End
