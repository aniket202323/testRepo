create function dbo.[fnCmn_SecondsNPTime2]
(@UnitId Int, @StartTime DateTime, @EndTime DateTime, @ReasonId Int)
 	 Returns Float
as
/*
Summary: Gets the percentage of time for a timerange, that is non-productive.
*/
BEGIN
 	 Declare @TotalSeconds Int
 	 Declare @ModifiedStartTime DateTime
 	 Declare @ModifiedEndTime DateTime
 	 Declare @NPSeconds Int
 	 Declare @NPRatio Float
 	 Set @NPSeconds = 0
 	 
 	 Set @TotalSeconds = Datediff(second, @StartTime, @EndTime)
 	 Set @ModifiedStartTime = dbo.[fnCmn_ModifyNPTimeRange2](@UnitId, @StartTime, @EndTime, 1, @ReasonId)
 	 Set @ModifiedEndTime = dbo.[fnCmn_ModifyNPTimeRange2](@UnitId, @StartTime, @EndTime, 0, @ReasonId)
 	 If @ModifiedStartTime Is Null And @ModifiedEndTime Is Null
 	  	 --NP time encompasses this range
 	  	 Set @NPSeconds = @TotalSeconds
 	 Else
 	  	 Begin
 	  	  	 --Figure out how much NP time there is at the beginning and end
 	  	  	 Select @NPSeconds = @NPSeconds + DateDiff(second, @StartTime, @ModifiedStartTime)
 	  	  	 Select @NPSeconds = @NPSeconds + DateDiff(second, @ModifiedEndTime, @EndTime)
 	  	 
 	  	  	 --The range might contain NP time
 	  	  	 Select @NPSeconds = @NPSeconds + IsNull(Sum(DateDiff(second, npd.Start_Time, npd.End_Time)), 0)
 	  	  	 From NonProductive_Detail npd
 	  	  	 Left Outer Join Event_Reason_Tree_Data ertd On (ertd.Event_Reason_Tree_Data_Id = npd.Event_Reason_Tree_Data_Id)
 	  	  	 Left Outer Join Event_reason_category_data ercd On ercd.Event_Reason_Tree_Data_Id = ertd.Event_Reason_Tree_Data_Id
 	  	  	 Left Outer Join Prod_Units pu On pu.PU_Id = npd.PU_Id
 	  	  	 Where npd.Start_Time >= @ModifiedStartTime
 	  	  	 And npd.End_Time <= @ModifiedEndTime
 	  	  	 and npd.PU_Id = @UnitId
 	  	  	 And (@ReasonId Is Null Or ertd.Event_Reason_Id = @ReasonId)
 	  	  	 And (pu.Non_Productive_Category = ercd.ERC_Id)
 	  	 End
 	 
 	 Return @NPSeconds
END
