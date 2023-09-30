create function dbo.[fnCmn_SecondsNPTime]
(@UnitId Int, @StartTime DateTime, @EndTime DateTime)
 	 Returns Float
as
/*
Summary: Gets the percentage of time for a timerange, that is non-productive.
*/
BEGIN
 	 Return dbo.fnCmn_SecondsNPTime2(@UnitId, @StartTime, @EndTime, Null)
END
