


CREATE	PROCEDURE [dbo].[splocal_LastThreeShiftBOS] 
		@LineId		VARCHAR(255),
		@Shift		INT		
AS
------------------------------------------------------------------------------
--
-- Date         Version Build  Author                 
-- 29-Jun-2016	001		001		Alex Judkowicz (GE Digital)
--
-- This SPROC counts the number of completed BOS records for the passed in line
-- for the calculated time interval
/*

splocal_LastThreeShiftBOS 'BC Line 4',3
splocal_LastThreeShiftBOS 'BC Line 4',2
splocal_LastThreeShiftBOS 'BC Line 4',1
*/

-------------------------------------------------------------------------------
--Initial settings
-------------------------------------------------------------------------------
SET NOCOUNT ON
-------------------------------------------------------------------------------
-- Declare variables
-------------------------------------------------------------------------------
DECLARE	@tOutput	TABLE
(
	[Value]		INT,
	[Text]		VARCHAR(255)
)
-------------------------------------------------------------------------------
-- Populate local table (Site specific)
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Return output
-------------------------------------------------------------------------------
IF NOT EXISTS (SELECT	Value
						FROM	@tOutput)
BEGIN
		INSERT	@tOutput ([Value], [Text])
				VALUES (-1, '')
				-- VALUES (1, 'OKDOK')
				--VALUES (0, 'BAD')
END

SELECT	[Value]		Value,
		[Text]		Text
		FROM	@tOutput
