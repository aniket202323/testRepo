












/*
---------------------------------------------------------------------------------------------------------------------------------------
Created by Vinayak Pate
Purpose: View Deleted Line Status
On 14-Jul-06			
---------------------------------------------------------------------------------------------------------------------------------------
Build #8: No Change
---------------------------------------------------------------------------------------------------------------------------------------
*/


CREATE    PROCEDURE spLocal_STLS_parmsel_DeletedLineStatus2
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
                    FROM Local_PG_Line_Status_History
		    WHERE Start_DateTime < @StartDate
		    AND	Unit_Id = @UnitID)
	        --    AND	UPPER(Update_Status) <> 'DELETE')

IF ( @PStartDate Is Null ) BEGIN
	SET @PStartDate = @StartDate
END

SELECT Local_PG_Line_Status_History.Status_Schedule_Id, 
	Local_PG_Line_Status_History.Start_DateTime, 
	Convert(VARCHAR,Local_PG_Line_Status_History.Modified_DateTime, 113) as Deleted_On,
	Phrase.Phrase_Value, 
	users.username, 
	Left(Convert(VARCHAR,Local_PG_Line_Status_History.Start_DateTime, 113),17) as iTime,	-- by vinayak
	Left(Convert(VARCHAR,Local_PG_Line_Status_History.End_DateTime, 113),17) as eTime	-- by vinayak
FROM Local_PG_Line_Status_History

INNER JOIN Phrase ON 	Local_PG_Line_Status_History.Line_Status_Id = Phrase.Phrase_Id
INNER JOIN Users ON 	Local_PG_Line_Status_History.User_Id = Users.User_Id
WHERE 	Start_DateTime >= @PStartDate
	AND	Start_DateTime <= @EndDate
	AND	Unit_Id = @UnitID
	--AND	UPPER(Update_Status) <> 'DELETE'

ORDER BY Local_PG_Line_Status_History.Start_DateTime













