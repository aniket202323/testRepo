CREATE PROCEDURE dbo.spServer_CmnGetMinEventByType
@MasterUnit int,
@EventType int,
@Timestamp datetime,
@MinTimeStart datetime OUTPUT,
@MinTimeEnd datetime OUTPUT
AS
Declare
  @Id int
Select @MinTimeStart = NULL
Select @MinTimeEnd = NULL
Select @Id = NULL
If (@EventType = 5) -- GradeTime
  Begin
    Select @MinTimeStart = Start_Time,
           @MinTimeEnd = End_Time
      From Production_Starts
      Where (PU_Id = @MasterUnit) And 
            (End_Time Is Not NULL) And
            (End_Time = (Select Min(End_Time) From Production_Starts Where (PU_Id = @MasterUnit) And (End_Time Is Not NULL) And (End_Time > @Timestamp)))
  End
If (@EventType = 26) -- ProductionEventTime
  Begin
    Select @Id = Event_Id, 
           @MinTimeStart = Start_Time,
           @MinTimeEnd = Timestamp
      From Events
      Where (PU_Id = @MasterUnit) And 
            (Timestamp = (Select Min(Timestamp) From Events Where (PU_Id = @MasterUnit) And (Timestamp > @Timestamp)))
    If (@Id Is Not NULL) And (@MinTimeStart Is NULL)
      Select @MinTimeStart = Max(Timestamp) From Events Where (PU_Id = @MasterUnit) And (Timestamp < @MinTimeEnd)
  End
If (@EventType = 5) -- ProcessOrderTime
  Begin
    Select @MinTimeStart = Start_Time,
           @MinTimeEnd = End_Time
      From Production_Plan_Starts
      Where (PU_Id = @MasterUnit) And 
            (End_Time Is Not NULL) And
            (End_Time = (Select Min(End_Time) From Production_Plan_Starts Where (PU_Id = @MasterUnit) And (End_Time Is Not NULL) And (End_Time > @Timestamp)))
  End
