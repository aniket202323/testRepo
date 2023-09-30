Create Procedure dbo.spSupport_RescheduleHistorianDataForEvents 
@PUId int,
@Start Datetime, 
@End Datetime
AS
Declare @EventId int
Declare MyCursor INSENSITIVE CURSOR
  For (Select Event_Id from Events Where (Timestamp between @Start and @End) and 
         PU_Id = @PUId)
  For Read Only
  Open MyCursor  
MyLoop1:
  Fetch Next From MyCursor Into @EventId
  If (@@Fetch_Status = 0)
    Begin
      Exec spServer_CmnAddScheduledTask @EventId, 1
      Goto MyLoop1
    End
Close MyCursor
Deallocate MyCursor
