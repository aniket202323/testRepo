 
 
 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_PLAN_SetPOPriority]
		@Priority		INT,
		@PPIdMask		VARCHAR(8000),
		@ErrorCode		INT				OUTPUT,
		@ErrorMessage	VARCHAR(255)	OUTPUT
		
AS	
-------------------------------------------------------------------------------
-- Update priority for the passed POs
/*
EXEC spLocal_MPWS_PLAN_SetPOPriority 9, '28,39,30,31,32,33,34,35,36'
 
 
*/
-- Date         Version Build Author  
-- 25-Sep-2015  001     001   Alex Judkowicz (GEIP)  Initial development	
-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------
--DECLARE	@tFeedback			TABLE
--(
--	Id						INT					IDENTITY(1,1)	NOT NULL,
--	ErrorCode				INT									NULL,
--	ErrorMessage			VARCHAR(255)						NULL
--)
 
DECLARE	@tPPId				TABLE
(
	Id						INT					IDENTITY(1,1)	NOT NULL,
	PPId					INT									NULL
)	
 
DECLARE	@CountPO			INT,
		@CountUpdate		INT			
-------------------------------------------------------------------------------
--  Parse PP Id string and into a table variable 
-------------------------------------------------------------------------------
INSERT	@tPPId (PPId)
		SELECT	*
		FROM	dbo.fnLocal_CmnParseListLong(@PPIdMask,',')
		
SELECT	@CountPO = @@ROWCOUNT		
------------------------------------------------------------------------------
--  Update priority for received POs
-------------------------------------------------------------------------------
UPDATE	TFV
		SET	TFV.Value = @Priority
		FROM	dbo.Table_Fields_Values TFV		WITH (NOLOCK)
		JOIN	dbo.Tables TB					WITH (NOLOCK)
		ON		TFV.TableId			= TB.TableId
		AND		TB.TableName		= 'Production_Plan'
		JOIN	dbo.Table_Fields TF				WITH (NOLOCK)
		ON		TFV.Table_Field_Id	= TF.Table_Field_Id
		AND		TF.Table_Field_Desc	= 'PreWeighProcessOrderPriority'
		JOIN	@tPPId T
		ON		T.PPId				= TFV.KeyId
		
SELECT	@CountUpdate = @@ROWCOUNT			
 
IF		@CountUpdate = 0
		SELECT	@ErrorCode = -1,
				@ErrorMessage = 'Priority was not updated for ANY selected Process Orders'
		--INSERT	@tFeedback (ErrorCode, ErrorMessage)
		--		VALUES (-1, 'Priority was not updated for ANY selected Process Orders')				
ELSE
		IF	@CountUpdate = @CountPO
			SELECT	@ErrorCode = 1,
					@ErrorMessage = 'Success'
			--INSERT	@tFeedback (ErrorCode, ErrorMessage)
			--		VALUES (1, 'Success')
		ELSE
			SELECT	@ErrorCode = 2,
					@ErrorMessage = 'Priority was not updated for ALL selected Process Orders'
			--INSERT	@tFeedback (ErrorCode, ErrorMessage)
			--	VALUES (2, 'Priority was not updated for ALL selected Process Orders')	
-------------------------------------------------------------------------------					
-- Return data tables
-------------------------------------------------------------------------------	
--SELECT	Id						Id,
--		ErrorCode				ErrorCode,
--		ErrorMessage			ErrorMessage
--		FROM	@tFeedback
 
 
 
 
 
 
