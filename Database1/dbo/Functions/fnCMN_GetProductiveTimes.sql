CREATE FUNCTION dbo.fnCMN_GetProductiveTimes(@UnitId int, @StartTime datetime, @EndTime datetime) 
 	 returns  @RunTimes Table(Run_Start datetime, Run_End datetime)
AS 
Begin
-------------------------------------
-- Local Variables
-------------------------------------
Declare @ReasonId int
Declare @NPTimes Table(NP_Start datetime, NP_End datetime)
Declare @NP_Start datetime, @NP_End datetime, @OldNP_Start datetime, @OldNP_End datetime
---------------------------------------------
-- Get Non Productive Times
---------------------------------------------
insert into @NPTimes(NP_Start, NP_End)
select start_time, End_Time
From NonProductive_Detail nptd
Left Outer Join Event_Reason_Tree_Data ertd On (ertd.Event_Reason_Tree_Data_Id = nptd.Event_Reason_Tree_Data_Id)
Left Outer Join Event_reason_category_data ercd On ercd.Event_Reason_Tree_Data_Id = ertd.Event_Reason_Tree_Data_Id
Left Outer Join Prod_Units pu On pu.PU_Id = nptd.PU_Id
Where nptd.PU_Id = @UnitId
AND End_Time > @StartTime
And Start_Time < @EndTime
And (@ReasonId Is Null Or ertd.Event_Reason_Id = @ReasonId)
And pu.Non_Productive_Category = ercd.ERC_Id
Order By Start_Time asc
-- Seed Loop
Select @OldNP_End = @StartTime
---------------------------------------------
-- Get All Productive Times Between NP Times
---------------------------------------------
Declare MyCursor  CURSOR
  For Select NP_Start, NP_End From @NPTimes ORDER BY NP_Start
  For Read Only
  Open MyCursor  
  Fetch Next From MyCursor Into @NP_Start, @NP_End 
  While (@@Fetch_Status = 0)
    Begin
 	  	 If @OldNP_End < @NP_Start
 	  	 insert into @Runtimes(Run_Start, Run_End)
 	  	  	 Select @OldNP_End, @NP_Start
 	  	 
 	  	 Select @OldNP_Start = @NP_Start, @OldNP_End = @NP_End
 	  	 Fetch Next From MyCursor Into @NP_Start, @NP_End 
    End 
Close MyCursor
Deallocate MyCursor
If @OldNP_End < @EndTime
insert into @Runtimes(Run_Start, Run_End)
 	 Select @OldNP_End, @Endtime
--select * from @Runtimes
--/*********************************************
     RETURN
END
--********************************************/
