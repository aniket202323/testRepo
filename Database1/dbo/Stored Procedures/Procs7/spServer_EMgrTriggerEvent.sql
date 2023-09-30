CREATE PROCEDURE dbo.spServer_EMgrTriggerEvent
@PU_Id int,
@TimeStamp datetime
 AS
Declare
  @Before_Event_Id int,
  @After_Event_Id int,
  @Before_Time datetime,
  @After_Time datetime,
  @The_Time datetime,
  @Before_Diff int,
  @After_Diff int
Select @The_Time = @TimeStamp
Select @Before_Event_Id = NULL
Select @Before_Event_Id = Event_Id,
       @Before_Time = TimeStamp
  From Events
  Where (PU_Id = @PU_Id) And
        (TimeStamp = (Select Max(TimeStamp) From Events Where (PU_Id = @PU_Id) And (TimeStamp <= @The_Time)))
Select @After_Event_Id = NULL
Select @After_Event_Id = Event_Id,
       @After_Time = TimeStamp
  From Events
  Where (PU_Id = @PU_Id) And
        (TimeStamp = (Select Min(TimeStamp) From Events Where (PU_Id = @PU_Id) And (TimeStamp > @The_Time)))
If (@Before_Event_Id Is Null) And (@After_Event_Id Is Null)
  Return
If (@Before_Event_Id Is Null)
  Begin
    Execute spServer_CmnAddScheduledTask @After_Event_Id,1,@PU_Id,@After_Time
    Return
  End
If (@After_Event_Id Is Null)
  Begin
    Execute spServer_CmnAddScheduledTask @Before_Event_Id,1,@PU_Id,@Before_Time
    Return
  End
Select @Before_Diff = DateDiff(Minute,@Before_Time,@The_Time)
Select @After_Diff = DateDiff(Minute,@The_Time,@After_Time)
If (@Before_Diff <= @After_Diff)
  Begin
    Execute spServer_CmnAddScheduledTask @Before_Event_Id,1,@PU_Id,@Before_Time
    Return
  End
Execute spServer_CmnAddScheduledTask @After_Event_Id,1,@PU_Id,@After_Time
