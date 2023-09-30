 
 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_INVN_GetWasteReasons]
		@PUId			INT	,
		@ErrorCode		INT				OUTPUT,
		@ErrorMessage	VARCHAR(255)	OUTPUT
AS	
-------------------------------------------------------------------------------
-- Get Reason level1 of the tree associated with a waste model for the 
-- passed in production unit
/*
exec spLocal_MPWS_INVN_GetWasteReasons 3379
*/
-- Date         Version Build Author  
-- 14-Oct-2015  001     001   Alex Judkowicz (GEIP)  Initial development	
-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------
SET NOCOUNT ON
 
--DECLARE	@tFeedback			TABLE
--(
--	Id						INT					IDENTITY(1,1)	NOT NULL,
--	ErrorCode				INT									NULL,
--	ErrorMessage			VARCHAR(255)						NULL
--)
 
DECLARE	@tOutput			TABLE
(
	Id						INT					IDENTITY(1,1)	NOT NULL,
	ReasonId				INT									NULL,
	ReasonCode				VARCHAR(255)						NULL,
	ReasonDesc				VARCHAR(255)						NULL
)
-------------------------------------------------------------------------------
--  Initialize output values
-------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- Find products associated with the passed PU
-------------------------------------------------------------------------------
INSERT	@tOutput	(ReasonId, ReasonCode, ReasonDesc)
		SELECT	DISTINCT R.Event_Reason_Id, R.Event_Reason_Code, R.Event_Reason_Name
				FROM	dbo.Event_Reasons R				WITH (NOLOCK)
				JOIN	dbo.Event_Reason_Tree_Data ERTD		WITH (NOLOCK)
				ON		ERTD.Level1_Id	= R.Event_Reason_Id
				JOIN	dbo.Prod_Events PE					WITH (NOLOCK)
				ON		ERTD.Tree_Name_Id	= Name_Id
				AND		PE.PU_Id			= @PUId
				AND		PE.Event_Type		= 3 -- Waste
				ORDER
				BY		R.Event_Reason_Name
 
SELECT	@ErrorCode = 1,
		@ErrorMessage = 'Success'
--INSERT	@tFeedback (ErrorCode, ErrorMessage)
--				VALUES (1, 'Success')				
 
/*
IF		@@ROWCOUNT	> 0
		INSERT	@tFeedback (ErrorCode, ErrorMessage)
				VALUES (1, 'Success')
ELSE
		INSERT	@tFeedback (ErrorCode, ErrorMessage)
				VALUES (-1, 'No location found for production unit: ' + CONVERT(VARCHAR(25), @PUId))
*/				
 
-------------------------------------------------------------------------------					
-- Return data tables
-------------------------------------------------------------------------------	
--SELECT	Id						Id,
--		ErrorCode				ErrorCode,
--		ErrorMessage			ErrorMessage
--		FROM	@tFeedback
		
SELECT	Id					Id,
		ReasonId			ReasonId,
		ReasonCode			ReasonCode,
		ReasonDesc			ReasonDesc
		FROM	@tOutput
		ORDER
		BY		Id
 
 
 
 
 
