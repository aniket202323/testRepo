﻿CREATE FUNCTION dbo.fnBF_GetProductiveTimes(@PU_Id int,@StartTime datetime,@EndTime datetime)
RETURNS @ProductiveTimes  TABLE (StartTime DateTime, EndTime DateTime)
AS
BEGIN
DECLARE @NonProductiveTimes TABLE ( StartTime datetime, Endtime   datetime)
declare @nonproductivecount int
insert into @NonProductiveTimes (StartTime, EndTime) 
 	 select npd.Start_Time, npd.End_Time 
 	 from NonProductive_Detail npd
    Left Outer Join Event_Reason_Tree_Data ertd On (ertd.Event_Reason_Tree_Data_Id = npd.Event_Reason_Tree_Data_Id)
    Left Outer Join Event_reason_category_data ercd On ercd.Event_Reason_Tree_Data_Id = ertd.Event_Reason_Tree_Data_Id
    Left Outer Join Prod_Units pu On pu.PU_Id = npd.PU_Id 
 	 where npd.Start_Time >= @StartTime and npd.End_Time <= @EndTime and npd.PU_Id = @PU_Id
                        And (pu.Non_Productive_Category Is Null Or (pu.Non_Productive_Category = ercd.ERC_Id)) 
insert into @NonProductiveTimes (StartTime, EndTime) 
 	 select @StartTime, npd.End_Time 
 	 from NonProductive_Detail npd
    Left Outer Join Event_Reason_Tree_Data ertd On (ertd.Event_Reason_Tree_Data_Id = npd.Event_Reason_Tree_Data_Id)
    Left Outer Join Event_reason_category_data ercd On ercd.Event_Reason_Tree_Data_Id = ertd.Event_Reason_Tree_Data_Id
    Left Outer Join Prod_Units pu On pu.PU_Id = npd.PU_Id 
 	 where npd.PU_Id = @PU_Id and npd.End_Time <= @EndTime and npd.End_Time >= @StartTime and npd.Start_Time = (select max(start_time) from NonProductive_Detail a where a.Start_Time < @StartTime  and a.PU_Id = @PU_Id) 
                        And (pu.Non_Productive_Category Is Null Or (pu.Non_Productive_Category = ercd.ERC_Id)) 
insert into @NonProductiveTimes (StartTime, EndTime) 
 	 select npd.Start_Time, @EndTime 
 	 from NonProductive_Detail npd
 	 Left Outer Join Event_Reason_Tree_Data ertd On (ertd.Event_Reason_Tree_Data_Id = npd.Event_Reason_Tree_Data_Id)
 	 Left Outer Join Event_reason_category_data ercd On ercd.Event_Reason_Tree_Data_Id = ertd.Event_Reason_Tree_Data_Id
 	 Left Outer Join Prod_Units pu On pu.PU_Id = npd.PU_Id 
 	 where npd.PU_Id = @PU_Id and npd.Start_Time >= @StartTime and npd.Start_Time <= @EndTime and npd.End_Time = (select min(end_time) from NonProductive_Detail a where a.End_Time > @EndTime  and a.PU_Id = @PU_Id)
                        And (pu.Non_Productive_Category Is Null Or (pu.Non_Productive_Category = ercd.ERC_Id)) 
insert into @NonProductiveTimes (StartTime, Endtime) 
 	 select @StartTime, @EndTime 
 	 from NonProductive_Detail npd
    Left Outer Join Event_Reason_Tree_Data ertd On (ertd.Event_Reason_Tree_Data_Id = npd.Event_Reason_Tree_Data_Id)
    Left Outer Join Event_reason_category_data ercd On ercd.Event_Reason_Tree_Data_Id = ertd.Event_Reason_Tree_Data_Id
    Left Outer Join Prod_Units pu On pu.PU_Id = npd.PU_Id 
 	 where npd.PU_Id = @PU_Id and npd.Start_Time < @StartTime and npd.End_Time > @EndTime
                        And (pu.Non_Productive_Category Is Null Or (pu.Non_Productive_Category = ercd.ERC_Id)) 
select @nonproductivecount = (select count(Endtime) from @NonProductiveTimes)
if (@nonproductivecount > 0) 
begin
  	  if (@StartTime < (select min (starttime) from @NonProductiveTimes))
  	  begin
  	    insert into @NonProductiveTimes (StartTime, EndTime) 
 	      select @StartTime, (select min (starttime) 
 	  	                      from @NonProductiveTimes)
  	  end
  	  insert into @ProductiveTimes (StartTime, EndTime) 
 	    select a.EndTime, (select min(b.StartTime) 
 	                       from @NonProductiveTimes b 
 	  	  	  	  	  	   where b.StartTime >= a.EndTime)
 	    from @NonProductiveTimes a
 	  delete from @ProductiveTimes where StartTime = EndTime
  	  update @ProductiveTimes set EndTime = @EndTime where EndTime is null
  	  delete from @ProductiveTimes where StartTime = @EndTime
end
else
begin
  	  insert into @ProductiveTimes (StartTime, EndTime) values (@StartTime, @EndTime)
end
RETURN
END