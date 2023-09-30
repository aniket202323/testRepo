CREATE PROCEDURE dbo.spServer_CmnGetMaxEventByType
@MasterUnit int,
@EventType int,
@Timestamp datetime,
@MaxTimeStart datetime OUTPUT,
@MaxTimeEnd datetime OUTPUT
AS
Declare
  @Id int
Select @MaxTimeStart = NULL
Select @MaxTimeEnd = NULL
Select @Id = NULL
If (@EventType = 5) -- GradeTime
  Begin
    Select @MaxTimeStart = Start_Time,
           @MaxTimeEnd = End_Time
      From Production_Starts
      Where (PU_Id = @MasterUnit) And 
            (End_Time Is Not NULL) And
            (End_Time = (Select Max(End_Time) From Production_Starts Where (PU_Id = @MasterUnit) And (End_Time Is Not NULL) And (End_Time < @Timestamp)))
  End
If (@EventType = 26) -- ProductionEventTime
  Begin
    Select @Id = Event_Id, 
           @MaxTimeStart = Start_Time,
           @MaxTimeEnd = Timestamp
      From Events
      Where (PU_Id = @MasterUnit) And 
            (Timestamp = (Select Max(Timestamp) From Events Where (PU_Id = @MasterUnit) And (Timestamp < @Timestamp)))
    If (@Id Is Not NULL) And (@MaxTimeStart Is NULL)
      Select @MaxTimeStart = Max(Timestamp) From Events Where (PU_Id = @MasterUnit) And (Timestamp < @MaxTimeEnd)
  End
If (@EventType = 28) -- ProcessOrderTime
  Begin
    Select @MaxTimeStart = Start_Time,
           @MaxTimeEnd = End_Time
      From Production_Plan_Starts
      Where (PU_Id = @MasterUnit) And 
            (End_Time Is Not NULL) And
            (End_Time = (Select Max(End_Time) From Production_Plan_Starts Where (PU_Id = @MasterUnit) And (End_Time Is Not NULL) And (End_Time < @Timestamp)))
  End
