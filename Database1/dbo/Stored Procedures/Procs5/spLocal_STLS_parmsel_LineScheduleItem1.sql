/*
----------------------------------------------------------------------------
Name: spLocal_STLS_parmsel_LineScheduleItem1
----------------------------------------------------------------------------
Build #8 no Change
----------------------------------------------------------------------------
Purpose: Selects information related to a particular line schedule record
Date: 11/12/2001
----------------------------------------------------------------------------
*/
CREATE PROCEDURE spLocal_STLS_parmsel_LineScheduleItem1
	@LineScheduleID INT
AS
DECLARE
@Year	VARCHAR(10),
@Month	VARCHAR(20),
@Day	VARCHAR(5),
@Time	VARCHAR(40)


SELECT	@Year	= Year(ls.Start_DateTime),
		@Month	= Month(ls.Start_DateTime),
		@Day	= Day(ls.Start_DateTime),
		@Time	= Convert(VARCHAR, ls.Start_DateTime, 108)
FROM	dbo.Local_PG_Line_Status	ls
WHERE	ls.Status_Schedule_Id = @LineScheduleID

SELECT	ls.Status_Schedule_Id,
		ls.Start_DateTime,
		ls.Line_Status_Id,
		ls.Update_Status,
		ls.Unit_Id,
		p.Phrase_Value,
		@Year					[iYear],
		@Month					[iMonth],
		@Day					[iDay],
		@Time					[iTime],
		ls.End_DateTIme
FROM	Local_PG_Line_Status	ls
JOIN	Phrase					p	ON ls.Line_Status_Id = p.Phrase_Id
WHERE	ls.Status_Schedule_Id = @LineScheduleID

