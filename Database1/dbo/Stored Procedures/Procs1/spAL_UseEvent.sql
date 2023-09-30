Create Procedure dbo.spAL_UseEvent
  @Event_Num nvarchar(100),
  @PU_Id int,
  @Result_On datetime AS
  -- Declare local variables.
  Declare
    @Event_Id int,
    @NewTimeStamp datetime,
    @Status int,
    @AppliedProd_Id int,
    @MasterEventId int,
    @Event_Status int,
    @TimeStamp datetime
  -- See if record exists by reel num
  SELECT @TimeStamp = NULL
  SELECT @TimeStamp = TimeStamp
    FROM Events
    WHERE (PU_Id = @PU_Id) AND (Event_Num = @Event_Num)
  IF @TimeStamp IS NOT NULL RETURN(1)
  -- See if record exists by resulton.
  SELECT @TimeStamp = NULL
  SELECT @TimeStamp = TimeStamp
    FROM Events
    WHERE (PU_Id = @PU_Id) AND (TimeStamp = @Result_On)
  IF @TimeStamp IS NOT NULL RETURN(2)
  -- Create a new Event.JG: Changed 7/9/2001
     --INSERT INTO Events(Event_Num, PU_Id, TimeStamp)
     --  VALUES(@Event_Num, @PU_Id, @Result_On)
  Select @Event_Id = 0, @NewTimeStamp = @Result_On
  Execute @Status = spServer_DBMgrUpdEvent 
 	 @Event_Id OUTPUT,
 	 @Event_Num,
 	 @PU_Id,
 	 @NewTimeStamp,
 	 NULL, --Applied Product
 	 NULL, --Master Event
 	 NULL, --Event Status
 	 1,
 	 0,NULL,NULL,NULL,NULL,NULL,NULL,2
  If (@Status <> 1) Or (@Event_Id = 0) Or (@Event_Id Is NULL) Return(1)
  -- Return successfully.
  RETURN(100)
