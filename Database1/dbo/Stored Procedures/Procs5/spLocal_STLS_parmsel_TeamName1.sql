










/*
----------------------------------------
Name: spLocal_STLS_parmsel_TeamName1
Purpose: Get Team Name per ID
Date: 11/12/2001
----------------------------------------
Build #8 No Change
----------------------------------------
*/

CREATE PROCEDURE spLocal_STLS_parmsel_TeamName1
	--Parameters
	@TeamID INT
AS

	SELECT * 
	FROM Local_PG_Teams
	WHERE TeamID = @TeamID











