CREATE PROCEDURE dbo.spServer_CmnGetEventInfo
@Event_Id int,
@IgnoreStartTime int,
@PU_Id int OUTPUT,
@Start_Time datetime OUTPUT,
@End_Time datetime OUTPUT,
@SourceEvent int OUTPUT,
@AppProdId int OUTPUT,
@EventNum nVarChar(30) OUTPUT,
@EventStatus int OUTPUT,
@Conformance int OUTPUT,
@TestPctComplete int OUTPUT,
@Found int OUTPUT,
@IsNoHistoryStatus int = null OUTPUT
AS
Select @Found = 0
Select @Start_Time = NULL
Select @End_Time = NULL
Select @End_Time = e.TimeStamp,
       @Start_Time = e.Start_Time,
       @PU_Id = e.PU_Id,
       @SourceEvent = COALESCE(e.Source_Event,0),
       @AppProdId = COALESCE(e.Applied_Product,0),
       @EventStatus = COALESCE(e.Event_Status,0),
       @EventNum = e.Event_Num,
       @Conformance = e.Conformance,
       @TestPctComplete = e.Testing_Prct_Complete,
       @IsNoHistoryStatus = COALESCE(s.NoHistory,0)
  From Events e  WITH (NOLOCK)
  left join Production_Status s on s.ProdStatus_Id = e.Event_Status
  Where (e.Event_Id = @Event_Id)
If @End_Time Is Null
  Return
If (@Conformance Is NULL)
  Select @Conformance = -1
If (@TestPctComplete Is NULL)
  Select @TestPctComplete = -1
If ((@Start_Time Is NULL) Or (@IgnoreStartTime = 1))
  Begin
    Select @Start_Time = NULL
    Select Top 1 @Start_Time = TimeStamp
      From Events
      Where (PU_Id = @PU_Id) And (TimeStamp < @End_Time) order by Timestamp desc
  End
  	  
If @Start_Time Is Null
  Select @Start_Time = DateAdd(HOUR,-1,@End_Time)
Select @Found = 1
