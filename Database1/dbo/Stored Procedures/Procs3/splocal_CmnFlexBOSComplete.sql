



CREATE	PROCEDURE [dbo].[splocal_CmnFlexBOSComplete] 
@PLMask		VARCHAR(255)
AS
------------------------------------------------------------------------------
--
-- Date         Version Build  Author                 
-- 29-Jun-2016	001		001		Alex Judkowicz (GE Digital)
--
-- This SPROC counts the number of BOS records with closing date matching the
-- current day
/*
splocal_CmnFlexBOSComplete 'BC Line 4'
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
	CountId		INT
)

INSERT	@tOutput (CountId)
		VALUES (-1)
		--VALUES (0)
		--VALUES (1)
-------------------------------------------------------------------------------
-- Populate local table (Site specific)
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Return output
-------------------------------------------------------------------------------
SELECT	CountId
		FROM	@tOutput
