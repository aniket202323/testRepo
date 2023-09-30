









/*
---------------------------------------------------------------------------------------------------------------------------------------
Name: spLocal_STLS_parmsel_UnitSchedule1
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
Build #8 No Change
---------------------------------------------------------------------------------------------------------------------------------------
*/


CREATE PROCEDURE spLocal_STLS_parmsel_UnitSchedule1
	--parameters
	@StartDate DateTime,
	@EndDate DateTime,
	@UnitDesc VARCHAR(50)
AS

DECLARE @UnitID INT, @PStartDate smalldatetime

SET @UnitID = (SELECT Prod_Units.PU_Id
		FROM Prod_Units
		WHERE PU_Desc = @UnitDesc)

SET @PStartDate = (SELECT max(Start_DateTime)
                    FROM Local_PG_Line_Status
		    WHERE Start_DateTime < @StartDate
		    AND	Unit_Id = @UnitID
	            AND	UPPER(Update_Status) <> 'DELETE')

IF ( @PStartDate Is Null ) BEGIN
	SET @PStartDate = @StartDate
END

SELECT Local_PG_Line_Status.Status_Schedule_Id, Local_PG_Line_Status.Start_DateTime, Local_PG_Line_Status.Line_Status_Id,
	 Phrase.Phrase_Id, Phrase.Phrase_Value, Convert(VARCHAR,Local_PG_Line_Status.Start_DateTime, 113) as iTime,
	 Convert(VARCHAR,Local_PG_Line_Status.End_DateTime, 113) as eTime
FROM Local_PG_Line_Status

INNER JOIN Phrase ON 	Local_PG_Line_Status.Line_Status_Id = Phrase.Phrase_Id
WHERE 	Start_DateTime >= @PStartDate
	AND	Start_DateTime <= @EndDate
	AND	Unit_Id = @UnitID
	AND	UPPER(Update_Status) <> 'DELETE'

ORDER BY Local_PG_Line_Status.Start_DateTime










