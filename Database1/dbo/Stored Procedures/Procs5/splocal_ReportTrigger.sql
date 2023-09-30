


CREATE PROCEDURE [dbo].[splocal_ReportTrigger] 
		@LineId				VARCHAR(255),
		@TriggerType		INT,		-- 11 safety-HSE/12 quality
		@Shift				INT			-- 1: current shift, 2: previous shift, 3: shift before previous
AS
------------------------------------------------------------------------------
-- This SP returns shift information
--
--
-- Date         Version Build  Author                  Notes
-- 15-Aug-2016  001     001    Alex Judkowicz         Initial development
/*
 exec splocal_ReportTrigger 'BC Line 4', 11, 1
*/
-------------------------------------------------------------------------------
--Initial settings
-------------------------------------------------------------------------------
SET NOCOUNT ON
-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------
DECLARE	@tOutput TABLE 
(
	Id		INT		IDENTITY(1,1) NOT NULL,
	[value]	INT				NULL,
	[Text]	VARCHAR(255)	NULL
)
-------------------------------------------------------------------------------
-- Populate local table (Site specific)
-------------------------------------------------------------------------------
IF NOT EXISTS (SELECT	Value
						FROM	@tOutput)
BEGIN
		INSERT	@tOutput ([Value], [Text])
				VALUES (-1,' ')
				--VALUES (3,'BAD')
				--VALUES (1,'OKDOK')
END
-------------------------------------------------------------------------------
-- Return output
-------------------------------------------------------------------------------

SELECT	[Value]	[Value],
		[Text]	[Text]
		FROM	@tOutput 
		ORDER
		BY		Id

