Create Procedure dbo.spWDGetDelayDetails
@pPU_Id int,
@pStart datetime,
@pEnd datetime
AS
set nocount on
Declare @Summary_ST datetime,
        @Summary_ET datetime,
        @TEDet_Id int,
        @Start_Time datetime,
        @End_Time datetime,
        @PU_Id int,
        @Id int,
        @Start datetime,
        @End datetime,
        @Min_Start_Time datetime,
        @Min_End_Time datetime
Create Table #Output (TESum_Id Int Null, TEDet_Id Int, PU_Id int, Source_PU_Id int Null, Start_Time DateTime, End_Time DateTime Null, 
                      Duration real Null, TEStatus_Id int Null, TEFault_Id int Null, 
                      Reason_Level1 int Null, Reason_Level2 int Null, Reason_Level3 int Null, Reason_Level4 int Null, 
                      Action_Level1 int Null, Action_Level2 int Null, Action_Level3 int Null, Action_Level4 int Null,
                      Detail_Cause_Comment_Id int Null, Detail_Action_Comment_Id int Null, Detail_Research_Comment_Id int Null,
                      Summary_Cause_Comment_Id int Null, Summary_Action_Comment_Id int Null, Summary_Research_Comment_Id int Null,
                      ESignature_Level int Null)
  select @pStart = Max(Start_Time)
  From Timed_Event_Details
  Where PU_Id = @pPU_Id
  and Start_Time < @pStart
  if @pStart is NULL
    Begin
      select @pStart = Min(Start_Time)
      From Timed_Event_Details
      Where PU_Id = @pPU_Id
      select @Summary_ST = @pStart
    End
  else
    Begin
      select @Id = NULL, @Start = NULL, @End = NULL
      exec spServer_DBMgrUpdCmnTimedEventSummaryInfo @pPU_Id, @pStart, 2, @Id OUTPUT, @Start OUTPUT, @End OUTPUT
      select @pStart = @Start
    End
  select @pEnd = Max(Start_Time)
    From Timed_Event_Details
    Where PU_Id = @pPU_Id
    and Start_Time <= @pEnd
  select @Id = NULL, @Start = NULL, @End = NULL
  exec spServer_DBMgrUpdCmnTimedEventSummaryInfo @pPU_Id, @pEnd, 1, @Id OUTPUT, @Start OUTPUT, @End OUTPUT
  select @pEnd = Coalesce(@End, @pEnd)
  Insert Into #Output (TESum_Id, TEDet_Id, PU_Id, Source_PU_Id, Start_Time, End_Time, Duration, TEStatus_Id, TEFault_Id, 
                      Reason_Level1, Reason_Level2, Reason_Level3, Reason_Level4, 
                      Action_Level1, Action_Level2, Action_Level3, Action_Level4,
                      Detail_Cause_Comment_Id, Detail_Action_Comment_Id, Detail_Research_Comment_Id,
                      Summary_Cause_Comment_Id, Summary_Action_Comment_Id, Summary_Research_Comment_Id)
    Select Null, TEDet_Id, PU_Id, Source_PU_Id, Start_Time, End_Time, Duration, TEStatus_Id, TEFault_Id, 
                      Reason_Level1, Reason_Level2, Reason_Level3, Reason_Level4, 
                      Action_Level1, Action_Level2, Action_Level3, Action_Level4,
                      Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id,
                      Summary_Cause_Comment_Id, Summary_Action_Comment_Id, Summary_Research_Comment_Id
    From Timed_Event_Details D 
    Where (D.pu_id = @pPu_Id) and ((D.start_time >= @pStart) and (D.end_time <= @pEnd))
  Insert Into #Output (TESum_Id, TEDet_Id, PU_Id, Source_PU_Id, Start_Time, End_Time, Duration, TEStatus_Id, TEFault_Id, 
                      Reason_Level1, Reason_Level2, Reason_Level3, Reason_Level4, 
                      Action_Level1, Action_Level2, Action_Level3, Action_Level4,
                      Detail_Cause_Comment_Id, Detail_Action_Comment_Id, Detail_Research_Comment_Id,
                      Summary_Cause_Comment_Id, Summary_Action_Comment_Id, Summary_Research_Comment_Id)
    Select Null, TEDet_Id, PU_Id, Source_PU_Id, Start_Time, End_Time, Duration, TEStatus_Id, TEFault_Id, 
                      Reason_Level1, Reason_Level2, Reason_Level3, Reason_Level4, 
                      Action_Level1, Action_Level2, Action_Level3, Action_Level4,
                      Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id,
                      Summary_Cause_Comment_Id, Summary_Action_Comment_Id, Summary_Research_Comment_Id
    From Timed_Event_Details D 
    Where (D.pu_id = @pPu_Id) and (((D.start_time <= @pEnd) and (D.start_time >= @pStart)) and (D.end_time is null))
  While (0=0) 
    Begin
 	   Select @Min_Start_Time = Null
      select @Min_Start_Time = Min(Start_Time) From #Output Where TESum_Id Is Null
      if @Min_Start_Time is NULL
        break
      select @TEDet_Id = TEDet_Id, @Start_Time = Start_Time, @End_Time = End_Time From #Output Where  Start_Time = @Min_Start_Time
      select @Id = NULL, @Start = NULL, @End = NULL
      exec spServer_DBMgrUpdCmnTimedEventSummaryInfo @pPU_Id, @Start_Time, 1, @Id OUTPUT, @Start OUTPUT, @End OUTPUT
      if @End is NULL
        Update #Output Set TESum_Id = @TEDet_Id 
       	  	 Where TESum_Id is NULL
      else
        Update #Output Set TESum_Id = @TEDet_Id 
       	  	 Where (Start_Time >= @Start) and (End_Time <= @End)        
     End
  Update #Output set ESignature_Level = ec.ESignature_Level
    From Event_Configuration ec
      Where ec.PU_Id = @pPU_Id and ec.ET_Id = 2 and ec.Is_Active = 1
  select O.*, PS.prod_id
  into #t1
  from #Output O  
  join production_starts PS  on ((ps.pu_id = @pPu_Id) and (ps.start_time <= O.start_time) and ((ps.end_time > O.start_time) or (ps.end_time is null)))
  Drop Table #Output
  select d.*, P.Prod_Code
  from #t1 d
  join products p on p.prod_id = d.prod_id
  ORDER BY D.Start_Time ASC
  Drop Table #t1
set nocount off
RETURN(100)
