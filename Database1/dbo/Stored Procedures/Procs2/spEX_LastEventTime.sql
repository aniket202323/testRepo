Create Procedure dbo.spEX_LastEventTime
@PU_Id int,
@LastTime datetime OUTPUT
AS
Declare @Id int,
        @Start datetime,
        @End datetime,
        @Start_Time datetime
select @Start_Time =  dbo.fnServer_CmnGetDate(getUTCdate())
exec spServer_DBMgrUpdCmnTimedEventSummaryInfo @PU_Id, @Start_Time, 1, @Id OUTPUT, @Start OUTPUT, @End OUTPUT
select @LastTime = @Start
If @LastTime Is Null Select @LastTime =  dbo.fnServer_CmnGetDate(getUTCdate())
return(100)
