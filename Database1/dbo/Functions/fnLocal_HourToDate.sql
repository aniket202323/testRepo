


-------------------------------------------------------------------------------------------------

-------------------------------------[Creation Of Function]--------------------------------------
CREATE FUNCTION [dbo].[fnLocal_HourToDate] (@Time varchar(6), @CurDate datetime)
/*
-------------------------------------------------------------------------------------------------
1.1			04-June-2012	Namrata Kumar			Appversions corrected
Created by	:	Vincent Rouleau (System Technologies for Industry Inc)
Date			:	2006-03-20
Version		:	1.0.0
Purpose		:	Builds a date with an hour string
					
-------------------------------------------------------------------------------------------------
*/

RETURNS datetime

AS
BEGIN
	DECLARE
	@NewDate datetime,
	@Hour		int,
	@Minute	int

	set @NewDate = dateadd(ms, -datepart(ms, @CurDate),
							dateadd(s, -datepart(s, @CurDate),
								dateadd(mi, -datepart(mi, @CurDate),
									dateadd(hh, -datepart(hh, @CurDate), @CurDate))))

	set @Hour = cast(right(left(@Time, 4), 2) as int)
	set @Minute = cast(right(@Time, 2) as int)

	set @NewDate = dateadd(mi, @Minute, dateadd(hh, @Hour, @NewDate))

	RETURN @NewDate

END


