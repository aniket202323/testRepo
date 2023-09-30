





CREATE PROCEDURE [dbo].[splocal_CmnFlexGetBlockCasesTotal] 
		@Line	VARCHAR(255) = NULL
AS
------------------------------------------------------------------------------
-- This SP returns the block cases total
--
--
-- Date         Version Build  Author                  Notes
-- 30-Jun-2016  001     001    Alex Judkwoicz         Initial development
/*
 exec splocal_CmnFlexGetBlockCasesTotal
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
	[value]	INT		NULL
)
-------------------------------------------------------------------------------
-- Populate local table (Site specific)
-------------------------------------------------------------------------------
IF NOT EXISTS (SELECT	Value
						FROM	@tOutput)
BEGIN
		INSERT	@tOutput ([Value])
				VALUES (-1)
				--VALUES (2)
				--VALUES (1)
END
-------------------------------------------------------------------------------
-- Return output
-------------------------------------------------------------------------------

SELECT	[value]	[value]
		FROM	@tOutput 
		ORDER
		BY		Id


