Create Procedure dbo.spAL_LookupEvent
  @PU_Id int,
  @Event_Num nvarchar(25) OUTPUT,
  @Result_On datetime OUTPUT  AS
  -- Declare local variables.
  DECLARE @Event_Id int
  -- Build the result date.
  SELECT @Event_Id = null
  IF @Result_On IS NULL
    BEGIN
      SELECT @Event_Id = Event_Id,
             @Event_Num = Event_Num,
             @Result_On = TimeStamp
        FROM Events WITH (INDEX(Event_By_PU_And_Event_Number))
        WHERE (PU_Id = @PU_Id) AND (Event_Num = @Event_Num)
    END
  ELSE
    BEGIN
      SELECT @Event_Id = Event_Id,
             @Event_Num = Event_Num,
             @Result_On = TimeStamp
        FROM Events WITH (INDEX(Event_By_PU_And_TimeStamp))
        WHERE (PU_Id = @PU_Id) AND (TimeStamp = @Result_On)
    END
  IF @Event_Id is NULL RETURN(1)
  RETURN(100)
