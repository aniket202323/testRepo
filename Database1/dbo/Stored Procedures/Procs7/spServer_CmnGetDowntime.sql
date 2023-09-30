/*
Set Nocount ON
Declare @Unit int, @StartTime datetime, @EndTime datetime, @TotalDuration int
Select @Unit=5, @StartTime='2006-05-16 08:44:09.000', @EndTime='2006-05-16 09:00:36.653'
Select @Unit=2, @StartTime='2006-01-01 9:50:00', @EndTime='2006-01-01 10:00:00'
exec spServer_CmnGetDowntime @Unit, @StartTime, @EndTime, @TotalDuration output
Select @TotalDuration
*/
CREATE PROCEDURE dbo.spServer_CmnGetDowntime
@Unit int,
@StartTime datetime,
@EndTime datetime,
@TotalDuration int OUTPUT
 AS 
-------------------------------------------------
-- Local Variables
-------------------------------------------------
Declare @Downtime_Scheduled_Category int, @Downtime_External_Category int, @Performance_Downtime_Category int
Declare @Downtime Table(id int identity (1,1), Start_Time datetime, End_Time datetime, ERC_ID int, DurationSeconds int)
Declare @Now DateTime
Select @Now = dbo.fnServer_CmnGetDate(GetUTCDate())
-------------------------------------------------
-- Get Excused Downtime Categories
-------------------------------------------------
Select 
   	   @Downtime_Scheduled_Category = Coalesce(Downtime_Scheduled_Category, 0) ,
   	   @Downtime_External_Category = Coalesce(Downtime_External_Category, 0),
   	   @Performance_Downtime_Category = Coalesce(Performance_Downtime_Category, 0)
From Prod_Units_Base Where PU_Id = @Unit
-------------------------------------------------
-- Get Downtime Records From Timed_Event_Details
-------------------------------------------------
/*
insert into @Downtime(Start_Time, End_Time, ERC_ID)
   	   Select d.Start_Time, d.End_Time, c.ERC_ID
   	   From Timed_Event_Details d
   	   Left Join Event_Reason_Category_Data c on c.Event_Reason_Tree_Data_id = d.Event_Reason_Tree_Data_Id   	   
   	    Where  d.pu_id = @Unit and (
   	      	      	   ((d.Start_Time between @StartTime and @EndTime )and d.End_Time >= @EndTime)
   	      	      	   or    	      	   
   	      	      	   (d.Start_Time >= @StartTime and d.End_Time <= @EndTime)
   	      	      	   or
   	      	      	   (d.Start_Time <= @StartTime and d.End_Time >= @EndTime)
   	      	      	   or
   	      	      	   (d.Start_Time <= @StartTime and (d.End_Time between @StartTime and @EndTime))
   	      	      	   or
   	      	      	   (d.Start_Time <= @StartTime and d.End_Time is null)
   	      	      	   or
   	      	      	   ((d.Start_Time between @StartTime and @EndTime) and d.End_Time is Null)   	      	   
   	   )
*/
insert into @Downtime(Start_Time, End_Time, ERC_ID)
   	   Select d.Start_Time, Isnull(d.End_Time,@Now), c.ERC_ID
   	   From Timed_Event_Details d
   	   Left Join Event_Reason_Category_Data c on c.Event_Reason_Tree_Data_id = d.Event_Reason_Tree_Data_Id   	   
   	    Where  d.pu_id = @Unit and  ((D.Start_Time >= @StartTime) And (D.Start_Time < @EndTime))  	   
insert into @Downtime(Start_Time, End_Time, ERC_ID)
   	   Select d.Start_Time, Isnull(d.End_Time,@Now), c.ERC_ID
   	   From Timed_Event_Details d
   	   Left Join Event_Reason_Category_Data c on c.Event_Reason_Tree_Data_id = d.Event_Reason_Tree_Data_Id   	   
   	    Where  d.pu_id = @Unit and  (((D.End_Time > @StartTime) or (D.End_Time Is Null)) And (D.Start_Time < @StartTime))
-------------------------------------------------
-- Remove Downtime for Excused Categories
-------------------------------------------------
Delete from @Downtime where ERC_ID in (@Downtime_Scheduled_Category, @Downtime_External_Category, @Performance_Downtime_Category)
-------------------------------------------------
-- Update Timestamps where they cross boundaries
-------------------------------------------------
Update @Downtime Set Start_Time = @StartTime where Start_Time < @StartTime
Update @Downtime Set End_Time = @EndTime where End_Time > @EndTime
-------------------------------------------------
-- Calculate Duration
-------------------------------------------------
Update @Downtime Set DurationSeconds =  DateDiff(s, Start_Time, End_Time)
select @TotalDuration = Sum(DurationSeconds) from @Downtime Where DurationSeconds is not Null
select @TotalDuration = isnull(@TotalDuration,0)
