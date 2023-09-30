CREATE PROCEDURE dbo.spServer_CmnGetClosestEvent
@PUId int,
@TimeStamp datetime,
@Window int,
@AppProdId int OUTPUT,
@SrcEventId int OUTPUT,
@EventStatus int OUTPUT,
@EventId int OUTPUT
 AS
Declare
  @StartTime datetime,
  @EndTime datetime,
  @BeforeTime datetime,
  @BeforeEventId int,
  @BeforeAppProdId int,
  @BeforeSrcEventId int,
  @BeforeEventStatus int,
  @BeforeDiff int,
  @AfterTime datetime,
  @AfterEventId int,
  @AfterAppProdId int,
  @AfterSrcEventId int,
  @AfterEventStatus int,
  @AfterDiff int
Select @EventId = NULL
Select @AppProdId = NULL
Select @SrcEventId = NULL
Select @EventStatus = NULL
Select @StartTime = @TimeStamp
If (@Window = 0)
  Select @StartTime = DateAdd(Year,-1,@StartTime)
Else
  Select @StartTime = DateAdd(Minute,-@Window,@StartTime)
Select @EndTime = @TimeStamp
If (@Window = 0)
  Select @EndTime = DateAdd(Year,1,@EndTime)
Else
  Select @EndTime = DateAdd(Minute,@Window,@EndTime)
Select @BeforeTime = NULL
Select @BeforeEventId  = NULL
Select @BeforeAppProdId  = NULL
Select @BeforeSrcEventId  = NULL
Select @BeforeEventStatus  = NULL
Select @AfterTime  = NULL
Select @AfterEventId  = NULL
Select @AfterAppProdId  = NULL
Select @AfterSrcEventId  = NULL
Select @AfterEventStatus  = NULL
Select @BeforeTime = TimeStamp,
       @BeforeEventId  = Event_Id,
       @BeforeAppProdId  = Applied_Product,
       @BeforeSrcEventId  = Source_Event,
       @BeforeEventStatus  = Event_Status
  From Events
  Where (PU_Id = @PUId) And
        (TimeStamp = (Select Max(TimeStamp) From Events Where (PU_Id = @PUId) And (TimeStamp > @StartTime) And (TimeStamp <= @TimeStamp)))
Select @AfterTime = TimeStamp,
       @AfterEventId  = Event_Id,
       @AfterAppProdId  = Applied_Product,
       @AfterSrcEventId  = Source_Event,
       @AfterEventStatus  = Event_Status
  From Events
  Where (PU_Id = @PUId) And
        (TimeStamp = (Select Min(TimeStamp) From Events Where (PU_Id = @PUId) And (TimeStamp < @EndTime) And (TimeStamp > @TimeStamp)))
If (@BeforeEventId Is NOT NULL) Or (@AfterEventId Is NOT NULL)
  Begin
    If (@AfterEventId Is NULL)
      Begin
        Select @EventId = @BeforeEventId
        Select @AppProdId = @BeforeAppProdId
        Select @SrcEventId = @BeforeSrcEventId 
        Select @EventStatus = @BeforeEventStatus
      End
    Else
      If (@BeforeEventId Is NULL)
        Begin
          Select @EventId = @AfterEventId
          Select @AppProdId = @AfterAppProdId
          Select @SrcEventId = @AfterSrcEventId 
          Select @EventStatus = @AfterEventStatus
        End
      Else
        Begin
 	   Select @BeforeDiff = DateDiff(Second,@BeforeTime,@TimeStamp)
 	   Select @AfterDiff = DateDiff(Second,@TimeStamp,@AfterTime)
 	   If (@BeforeDiff < @AfterDiff)
            Begin
              Select @EventId = @BeforeEventId
              Select @AppProdId = @BeforeAppProdId
              Select @SrcEventId = @BeforeSrcEventId 
              Select @EventStatus = @BeforeEventStatus
            End
          Else
            Begin
              Select @EventId = @AfterEventId
              Select @AppProdId = @AfterAppProdId
              Select @SrcEventId = @AfterSrcEventId 
              Select @EventStatus = @AfterEventStatus
            End
        End
  End
If (@EventId Is NULL)
  Select @EventId = 0
If (@AppProdId Is NULL)
  Select @AppProdId = 0
If (@SrcEventId Is NULL)
  Select @SrcEventId = 0
If (@EventStatus Is NULL)
  Select @EventStatus = 0
