create function dbo.[fnCmn_ModifyNPTimeRange]
(@UnitId Int, @StartTime DateTime, @EndTime DateTime, @Start Bit)
 	 Returns DateTime
as
/*
See dbo.fnCmn_ModifyNPTimeRange2 for usage information.
*/
BEGIN
 	 Return dbo.fnCmn_ModifyNPTimeRange2(@UnitId, @StartTime, @EndTime, @Start, Null)
END
