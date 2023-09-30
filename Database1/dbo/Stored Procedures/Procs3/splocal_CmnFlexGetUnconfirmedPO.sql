


CREATE	PROCEDURE [dbo].[splocal_CmnFlexGetUnconfirmedPO] 
		@Line		VARCHAR(255)
AS
------------------------------------------------------------------------------
--
-- Date         Version Build  Author                 
-- 29-Jun-2016	001		001		Alex Judkowicz (GE Digital)
--
-- This SPROC returns the unconfirmed PO for the passed PL
/*
splocal_CmnFlexGetUnconfirmedPO 'BC Line 4'
splocal_CmnFlexGetUnconfirmedPO'FC Eléctricos'
*/
-------------------------------------------------------------------------------
--Initial settings
-------------------------------------------------------------------------------
SET NOCOUNT ON
-------------------------------------------------------------------------------
--Declare variables
-------------------------------------------------------------------------------
DECLARE	@tOutput TABLE
(
	Line				VARCHAR(255),
	Process_Order		VARCHAR(255),
	Prod_Code			VARCHAR(255),
	Prod_Desc			VARCHAR(255),
	Actual_Start_Time	DATETIME,
	Actual_End_Time		DATETIME,
	Remaining_Time		VARCHAR(255),
	Remaining_TimeFloat	FLOAT,
	FlagErrorColor		INT
)
-------------------------------------------------------------------------------
--Populate output table (Site specific)
-------------------------------------------------------------------------------
INSERT	@tOutput (FlagErrorColor) 
		VALUES (-1)
-------------------------------------------------------------------------------
--Output data
-------------------------------------------------------------------------------
UPDATE	@tOutput 
		SET		Remaining_TimeFloat	= Remaining_Time
				WHERE	ISNUMERIC(Remaining_Time) = 1
		
UPDATE	@tOutput
		SET		FlagErrorColor = 1
				WHERE	Remaining_TimeFloat	< 0

SELECT * FROM	@tOutput
