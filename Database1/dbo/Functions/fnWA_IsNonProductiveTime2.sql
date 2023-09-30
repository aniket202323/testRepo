create function dbo.[fnWA_IsNonProductiveTime2]
(@UnitId Int, @Timestamp DateTime, @EndTime DateTime, @ReasonId Int)
 	 Returns Bit
as
/*
Summary: Determines if the specified time (all) is considered non-productive.
Parameters:
 	 UnitId - The ID of the unit to check for non-productive time
 	 Timestamp - Either a single point in time, or the start time of a time range
 	 EndTime - The end time of an occurance where the "Timestamp" is the start time.
Returns: 1 if the time is non-productive, 0 if it's productive.
*/
BEGIN
 	 Declare @IsNPT Bit
 	 Set @IsNPT = 0
 	 If (Select Count(*)
 	  	  	 From NonProductive_Detail nptd
 	  	  	 Left Outer Join Event_Reason_Tree_Data ertd On (ertd.Event_Reason_Tree_Data_Id = nptd.Event_Reason_Tree_Data_Id)
 	  	  	 Left Outer Join Event_reason_category_data ercd On ercd.Event_Reason_Tree_Data_Id = ertd.Event_Reason_Tree_Data_Id
 	  	  	 Left Outer Join Prod_Units pu On pu.PU_Id = nptd.PU_Id
 	  	  	 Where nptd.PU_Id = @UnitId
 	  	  	 And (((@Timestamp Between Start_Time And End_Time) And @EndTime Is Null)
 	  	  	 Or ((@Timestamp Between Start_Time And End_Time) And (@EndTime Between Start_Time And End_Time)))
 	  	  	 And (@ReasonId Is Null Or ertd.Event_Reason_Id = @ReasonId)
 	  	  	 And (pu.Non_Productive_Category = ercd.ERC_Id)
 	  	  	 ) > 0
 	  	 Set @IsNPT = 1
 	 Else
 	  	 Set @IsNPT = 0
 	 Return @IsNPT
END
