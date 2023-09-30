Create Procedure dbo.spWDGetDelayDetails2
@pPU_Id int,
@pStart datetime,
@pEnd datetime,
@SheetName 	 nvarchar(50) 
AS
Declare @MaxSum Int,@MaxRetries Int
Declare @StartupTimeFrame Int
Declare @IncludeBorderEvents Int
select @IncludeBorderEvents = Coalesce(value,0) from site_Parameters where parm_id = 512
If @SheetName Is Null or @SheetName = ''
 	 Select @MaxSum = 100
Else
BEGIN
 	 Select @MaxSum = isnull(value,100)
 	   FROM sheet_Display_options sdo
 	   JOIN Sheets s on s.Sheet_Id = sdo.Sheet_Id
 	   JOIN Display_Options do On do.Display_Option_Id = sdo.Display_Option_Id and Display_Option_Desc = 'Maximum Summary Size'
 	   WHERE s.Sheet_Desc = @SheetName
END
Select @MaxSum = isnull(@MaxSum,100)
/* Determine If this is a scroll - If so we do not return events on the border */
Declare @Range Int,@IsScroll Int
Declare @SaveStartTime DateTime
Declare @SaveEndTime DateTime
Select @SaveStartTime = @pStart
Select @SaveEndTime = @pEnd
Select @Range = DateDiff(Second,@pStart,@pEnd)
If @Range/60.0 = @Range/60
BEGIN
 	 select @IsScroll = 0
END
Else
 	 BEGIN
 	  	 Select @Range = DatePart(Second,@pStart)
 	  	 If @Range/2.0 = @Range/2
 	  	  	 select @IsScroll = 1
 	  	 Else
 	  	     select @IsScroll = 2
END
If @SheetName Is Null
 	 Select @MaxSum = 100
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
                      ESignature_Level int Null,Start_TimeDB datetime)
/*
select @pStart = Max(Start_Time)
  From Timed_Event_Details
  Where PU_Id = @pPU_Id
  and Start_Time < @pStart
*/
select @pStart = Min(Start_Time)
  From Timed_Event_Details
  Where PU_Id = @pPU_Id
  and Start_Time <= @pEnd  and  (End_Time >= @pStart or End_Time Is Null)
  if @pStart is NULL
    Begin
 	  IF @IsScroll = 1 or @IsScroll = 2
 	  Begin
 	  	 Select SummaryLimit = @MaxRetries
 	  	 Select * From #Output --no date
 	  	 Return  --no data in range for scroll
 	  End
      select @pStart = Max(Start_Time)
      From Timed_Event_Details
      Where PU_Id = @pPU_Id
      select @Summary_ST = @pStart
    End
  else
    Begin
 	 select @Id = NULL, @Start = NULL, @End = NULL
 	 exec spWD_GetDelaySummaryInfo @pPU_Id, @pStart, @MaxSum, @Id OUTPUT, @Start OUTPUT, @End OUTPUT, @MaxRetries OUTPUT
 	 select @pStart = @Start
 	 If  @MaxRetries = 1
 	  	 GOTO Finished
    End
  select @pEnd = Max(Start_Time)
    From Timed_Event_Details
    Where PU_Id = @pPU_Id
    and Start_Time <= @pEnd
  select @Id = NULL, @Start = NULL, @End = NULL
  exec spWD_GetDelaySummaryInfo @pPU_Id, @pEnd, @MaxSum, @Id OUTPUT, @Start OUTPUT, @End OUTPUT, @MaxRetries OUTPUT
  If  @MaxRetries = 1
 	  	 GOTO Finished
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
      exec spWD_GetDelaySummaryInfo @pPU_Id, @Start_Time, @MaxSum, @Id OUTPUT, @Start OUTPUT, @End OUTPUT, @MaxRetries OUTPUT
 	 If  @MaxRetries = 1
 	  	 GOTO Finished
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
Finished:
  Select SummaryLimit = @MaxRetries
if @IncludeBorderEvents = 0
  BEGIN
    If @IsScroll = 0
 	   DELETE FROM #Output Where TESum_Id In (Select TESum_Id From #Output Where  end_time < @SaveStartTime)
    If @IsScroll = 1
 	   DELETE FROM #Output Where TESum_Id In (Select TESum_Id From #Output Where  end_time > @SaveEndTime or end_time is null)
    If @IsScroll = 2
 	   DELETE FROM #Output Where TESum_Id In (Select TESum_Id From #Output Where start_time < @SaveStartTime)
  END
Update #Output set Start_TimeDB = Start_Time
  select O.*, PS.prod_id
  into #t1
  from #Output O  
  join production_starts PS  on ((ps.pu_id = @pPu_Id) and (ps.start_time <= O.start_time) and ((ps.end_time > O.start_time) or (ps.end_time is null)))
  Drop Table #Output
  select d.*, P.Prod_Code, coalesce(s.Start_Time, d.Start_TimeDB) as SortTime
  from #t1 d
  join products p on p.prod_id = d.prod_id
  left join Timed_Event_Details s on s.TEDet_Id = d.TESum_Id
  ORDER BY D.Start_Time ASC
  Drop Table #t1
RETURN(100)
