





CREATE PROCEDURE [dbo].[splocal_CmnFlexGetDMSTrigger] 
@Line		VARCHAR(255)
AS
------------------------------------------------------------------------------
--
-- Date         Version Build  Author                 
-- 29-Jun-2016	001		001		Alex Judkowicz (GE Digital)
--
-- This SPROC returns the DMS Trigger information for the passed PL
/*
splocal_CmnFlexGetDMSTrigger 'BC Line 4'
splocal_CmnFlexGetDMSTrigger'FC Eléctricos'
*/
-------------------------------------------------------------------------------
--Initial settings
-------------------------------------------------------------------------------
SET NOCOUNT ON

-------------------------------------------------------------------------------
-- Declare variables
-------------------------------------------------------------------------------
DECLARE	@tOutput TABLE 
(
	ID				INT				IDENTITY(1,1),
	[Key]			VARCHAR(255),		 
	ColorCode		INT,				 
	[Description]	VARCHAR(255),		  	
	[Count]			INT					 
)
-------------------------------------------------------------------------------
-- Populate table (site specific)
-------------------------------------------------------------------------------
INSERT	@tOutput (Description, Count) 
		VALUES ('Disabled', -1)

/*
INSERT	@tOutput (Description, Count) 
		VALUES ('Open High Alarms', 99)
*/
/*
INSERT	@tOutput (Description, Count) 
		VALUES ('Open High High Alarms', 98)
*/
-------------------------------------------------------------------------------
-- Return output
-------------------------------------------------------------------------------
SELECT	[Key],			
		ColorCode,		
		[Description],	
		[Count]			
		FROM			@TOutput	  			
		ORDER
		BY				Id	
