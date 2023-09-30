Create Procedure dbo.spServer_CmnRecollectEventData
@PUId int,
@StartTime nVarChar(30),
@EndTime nVarChar(30) = NULL
AS
Declare
  @Statement nVarChar(1000),
  @@EventId int,
  @@Timestamp datetime
Select @Statement = 'Declare Evt_Cursor CURSOR Global Static For (Select Event_Id,TimeStamp From Events Where '
If (@PUId Is Not NULL) And (@PUId > 0)
  Select @Statement = @Statement + ' (PU_Id = ' + convert(nVarChar(10),@PUId) + ' ) AND '
Select @Statement = @Statement + ' (TimeStamp >= ''' + @StartTime + ''') ' 
If (@EndTime Is Not NULL) 
  Select @Statement = @Statement + ' AND (TimeStamp <= ''' + @EndTime + ''')'
Select @Statement = @Statement + ') For Read Only'
Execute (@Statement)
Open Evt_Cursor  
Evt_Loop:
  Fetch Next From Evt_Cursor Into @@EventId,@@Timestamp
  If (@@Fetch_Status = 0)
    Begin
      Execute spServer_CmnAddScheduledTask @@EventId,1,@PUId,@@Timestamp
      Goto Evt_Loop
    End
Close Evt_Cursor
Deallocate Evt_Cursor
