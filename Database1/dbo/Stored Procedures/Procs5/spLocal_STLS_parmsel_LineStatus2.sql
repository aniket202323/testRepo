/*
---------------------------------------------------------------------------------------------------------------------------------------
Name: spLocal_STLS_parmsel_LineStatus2
---------------------------------------------------------------------------------------------------------------------------------------
OLD Name: spLocal_STLS_parmsel_UnitSchedule1
Purpose: Provided a timeframe and line unit description, selects the line unit
	status schedule.
Date: 11/12/2001
---------------------------------------------------------------------------------------------------------------------------------------
Modified by Debbie Linville
On 15-Oct-02			Version 1.0.1
Change : 	Add prior unit status to display
---------------------------------------------------------------------------------------------------------------------------------------
Modified by Debbie Linville
On 15-Jan-03			Version 2.0
Change : 	Add End_DateTime to display
---------------------------------------------------------------------------------------------------------------------------------------
Modified by Vinayak Pate
On 14-Jul-06			
Change : 	Removed sec and msec from dates 
---------------------------------------------------------------------------------------------------------------------------------------
Modified by:	Max Jacob
On:				2019-05-29			
Change : 		Added column to tell if line status is a PR OUT
				Refactoring
---------------------------------------------------------------------------------------------------------------------------------------
Modified by:	Philippe Morin
On:				2019-06-12			
Change : 		Output raw dates instead of strings
---------------------------------------------------------------------------------------------------------------------------------------
Build #8 No Change
---------------------------------------------------------------------------------------------------------------------------------------
*/
CREATE PROCEDURE spLocal_STLS_parmsel_LineStatus2
	@StartDate	DATETIME,
	@EndDate	DATETIME,
	@UnitDesc	VARCHAR(50)
AS

DECLARE
@UnitID		INT, 
@PStartDate	SMALLDATETIME

DECLARE
@PR_OUT_PHRASE	VARCHAR(20) = 'pr out:'

SET @UnitID =	(
					SELECT	pu.PU_Id
					FROM	dbo.Prod_Units_Base	pu	WITH(NOLOCK)
					WHERE	PU_Desc = @UnitDesc
				)

SET @PStartDate =	(
						SELECT	MAX(Start_DateTime)
						FROM	dbo.Local_PG_Line_Status
						WHERE	Start_DateTime			<	@StartDate
						AND		Unit_Id					=	@UnitID
						AND		UPPER(Update_Status)	<>	'DELETE'
					)

IF @PStartDate IS NULL
BEGIN
	SET @PStartDate = @StartDate
END

SELECT	ls.Status_Schedule_Id,
		ls.Start_DateTime,
		ls.Line_Status_Id,
		p.Phrase_Id,
		p.Phrase_Value, 
		ls.Start_DateTime			[iTime],	-- by vinayak
		ls.End_DateTime				[eTime],	-- by vinayak
		CASE
			WHEN CHARINDEX(@PR_OUT_PHRASE, p.Phrase_Value) > 0
				THEN	CONVERT(BIT, 1)
			ELSE
				CONVERT(BIT, 0)
		END															[IsPrOut]
FROM	dbo.Local_PG_Line_Status	ls
JOIN	dbo.Phrase					p	WITH(NOLOCK)	ON 	ls.Line_Status_Id = p.Phrase_Id
WHERE 	Start_DateTime			>=	@PStartDate
AND		Start_DateTime			<=	@EndDate
AND		Unit_Id					=	@UnitID
AND		UPPER(Update_Status)	<>	'DELETE'
ORDER
BY		ls.Start_DateTime

