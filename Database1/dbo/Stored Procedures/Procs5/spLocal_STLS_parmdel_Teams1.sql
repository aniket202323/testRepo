











/*

--------------------------------------------------------------
Name: spLocal_STLS_parmdel_Teams1
--------------------------------------------------------------
Build #8
Modified by Vinayak Pate
Date 14-Dec-2007
Change: maintain proficy standards be removing t ransactions and l ocks
--------------------------------------------------------------
Purpose: Delete Teams from Local_PG_Teams
Date: 11/12/2001
--------------------------------------------------------------
*/

CREATE  PROCEDURE spLocal_STLS_parmdel_Teams1
	--parameter
	@TeamID INT
AS


DELETE FROM  Local_PG_Teams
WHERE TeamID = @TeamID

--Error Check
IF @@ERROR > 0
	BEGIN
	RAISERROR('SQL Error - spLocal_STLS_parmdel_Teams1', 16, 1)
	RETURN 99
	END


RETURN 0


