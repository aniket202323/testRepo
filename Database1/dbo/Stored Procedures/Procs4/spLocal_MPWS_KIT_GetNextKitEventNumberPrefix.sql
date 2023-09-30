 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_KIT_GetNextKitEventNumberPrefix]
		@PUId			INT			= NULL,
		@EventMask		VARCHAR(25)	= NULL,
		@NextPrefix		INT	= NULL OUTPUT
AS	
-------------------------------------------------------------------------------
-- Locates Max ID of Kit Production Events
-- Returns next available Kit Prefix number
/*
DECLARE @NextPrefix INT 
exec spLocal_MPWS_KIT_GetNextKitEventNumberPrefix 3378,'20151123145424', @NextPrefix output
SELECT @NextPrefix
*/
-- Date         Version Build	Author  
-- 27-May-2016  001     001		Chris Donnelly (GE Digital)  Initial development	
-- 30-Jun-2016	001		002		Chris Donnelly (GE Digital)	Added handling of (optional) leading K in Event Num
-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------
SET NOCOUNT ON
 
DECLARE	@tFeedback			TABLE
(
	Id						INT					IDENTITY(1,1)	NOT NULL,
	ErrorCode				INT									NULL,
	ErrorMessage			VARCHAR(255)						NULL
)
 
DECLARE		@MaxEventNum	VARCHAR(255)
 
		SELECT	
		@MaxEventNum		= MAX(Event_Num)
				FROM	dbo.Events	WITH (NOLOCK)
				WHERE	PU_Id		= @PUId
				AND		Event_Num	LIKE '%-' + @EventMask
 
-- Set the output
SET @NextPrefix =  ISNULL(SUBSTRING(@MaxEventNum,PATINDEX('K%',@MaxEventNum)+1,2) + 1,1)	--ISNULL(LEFT(@MaxEventNum,2) + 1,1)
 
-------------------------------------------------------------------------------					
-- Return data tables
-------------------------------------------------------------------------------	
		INSERT	@tFeedback (ErrorCode, ErrorMessage)
				VALUES (1, 'Success')
 
SELECT	Id						Id,
		ErrorCode				ErrorCode,
		ErrorMessage			ErrorMessage
		FROM	@tFeedback
 
 
 
 
 
