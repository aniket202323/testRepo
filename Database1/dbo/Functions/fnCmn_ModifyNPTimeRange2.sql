create function dbo.[fnCmn_ModifyNPTimeRange2]
(@UnitId Int, @StartTime DateTime, @EndTime DateTime, @Start Bit, @ReasonId Int)
 	 Returns DateTime
as
/*
Summary: Gets the start time of a timerange, accounting for NP time.
Parameters:
 	 - @Start - If 1, then a modified start time will be returned, otherwise
 	  	 a modified end time will be returned.
Returns:
 	 - If the time range is encompassed by NP time, then NULL is returned for the start and end time
 	 - If the time is different than the start time or end time, then it's being affected by NP time
 	 - If the time range contains NP time, then the normal start time and end time are returned
 	 - If the time range is not affected by NP time, then the normal start time and end time are returned
*/
BEGIN
 	 Declare @ModifiedTime DateTime
 	 --Check if there is a NP event that encompasses our range
 	 If Exists (Select *
 	  	  	  	  	  	  	 From NonProductive_Detail npd
 	  	  	  	  	  	  	 Left Outer Join Event_Reason_Tree_Data ertd On (ertd.Event_Reason_Tree_Data_Id = npd.Event_Reason_Tree_Data_Id)
 	  	  	  	  	  	  	 Left Outer Join Event_reason_category_data ercd On ercd.Event_Reason_Tree_Data_Id = ertd.Event_Reason_Tree_Data_Id
 	  	  	  	  	  	  	 Left Outer Join Prod_Units pu On pu.PU_Id = npd.PU_Id
 	  	  	  	  	  	  	 Where npd.PU_Id = @UnitId
 	  	  	  	  	  	  	 And Start_Time <= @StartTime
 	  	  	  	  	  	  	 And End_Time >= @EndTime
 	  	  	  	  	  	  	 And pu.Non_Productive_Category = ercd.ERC_Id)
 	  	 Begin
 	  	  	 Return Null
 	  	 End
 	 --Check if there is NP time that changes the start time or end time
 	 Select @ModifiedTime = Case @Start When 1 Then End_Time Else Start_Time End
 	  	  	 From NonProductive_Detail nptd
 	  	  	 Left Outer Join Event_Reason_Tree_Data ertd On (ertd.Event_Reason_Tree_Data_Id = nptd.Event_Reason_Tree_Data_Id)
 	  	  	 Left Outer Join Event_reason_category_data ercd On ercd.Event_Reason_Tree_Data_Id = ertd.Event_Reason_Tree_Data_Id
 	  	  	 Left Outer Join Prod_Units pu On pu.PU_Id = nptd.PU_Id
 	  	  	 Where nptd.PU_Id = @UnitId
 	  	  	 --See if there are NP time ranges that would delay the start time
 	  	  	 And (@Start = 0 Or (Start_Time <= @StartTime And End_Time > @StartTime And End_Time <= @EndTime))
 	  	  	 --See if there are NP time ranges that would move up the end time
 	  	  	 And (@Start = 1 Or (Start_Time >= @StartTime And Start_Time < @EndTime And End_Time >= @EndTime))
 	  	  	 And (@ReasonId Is Null Or ertd.Event_Reason_Id = @ReasonId)
 	  	  	 And pu.Non_Productive_Category = ercd.ERC_Id
 	  	  	 Order By Start_Time Desc
 	 --If we didn't find a NP range that ends in this range, we will just use our normal time.
 	 If @ModifiedTime Is Null
 	  	 If @Start = 1
 	  	  	 Set @ModifiedTime = @StartTime
 	  	 Else
 	  	  	 Set @ModifiedTime = @EndTime
 	 Return @ModifiedTime
END
