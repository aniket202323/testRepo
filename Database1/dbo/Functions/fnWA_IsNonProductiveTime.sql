create function dbo.[fnWA_IsNonProductiveTime]
(@UnitId Int, @Timestamp DateTime, @EndTime DateTime = Null)
 	 Returns Bit
as
/*
Summary: See dbo.fnWA_IsNonProductiveTime2 for information.
*/
BEGIN
 	 Return dbo.fnWA_IsNonProductiveTime2(@UnitId, @Timestamp, @EndTime, Null)
END
