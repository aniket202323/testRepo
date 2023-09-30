 
 
 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_GENL_UpdateTransactionsTableById]
		@TransactionId			INT,
		@ErrorCode				INT,
		@ErrorMessage			VARCHAR(255),
		@OutField01				VARCHAR(255)	= NULL,
		@OutField02				VARCHAR(255)	= NULL,
		@OutField03				VARCHAR(255)	= NULL,
		@OutField04				VARCHAR(255)	= NULL,
		@OutField05				VARCHAR(255)	= NULL
AS	
-------------------------------------------------------------------------------
-- Update the Transaction record. this SPROC is called by the dispatcher workflow,
-- this workflow updates the transaction record with the feedback received by
-- the executer workflow
/*
EXEC spLocal_MPWS_GENL_UpdateTransactionsTableById  3 , 1, 'Success'
 
 
*/
-- Date         Version Build Author  
-- 29-Sep-2015  001     001   Alex Judkowicz (GEIP)  Initial development	
-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------
DECLARE	@tFeedback			TABLE
(
	Id						INT					IDENTITY(1,1)	NOT NULL,
	ErrorCode				INT									NULL,
	ErrorMessage			VARCHAR(255)						NULL
)
-------------------------------------------------------------------------------
--  Update the transaction record
-------------------------------------------------------------------------------
UPDATE	dbo.Local_MPWS_GENL_Transactions
		SET		ErrorCode		= @ErrorCode,
				ErrorMessage	= @ErrorMessage,
				ProcessedDate	= GETDATE(),
				OutField01		= @OutField01,
				OutField02		= @OutField02,
				OutField03		= @OutField03,
				OutField04		= @OutField04,
				OutField05		= @OutField05
		WHERE	Id				= @TransactionId		
 
IF		@@ROWCOUNT = 1				
		INSERT	@tFeedback (ErrorCode, ErrorMessage)
				VALUES (1, 'Success')
ELSE				
		INSERT	@tFeedback (ErrorCode, ErrorMessage)
				VALUES (-1, 'Transaction Record Not Found:' + CONVERT(VARCHAR(25), COALESCE(@TransactionId, -1)))
-------------------------------------------------------------------------------					
-- Return data tables
-------------------------------------------------------------------------------	
SELECT	Id						Id,
		ErrorCode				ErrorCode,
		ErrorMessage			ErrorMessage
		FROM	@tFeedback
		
 
 
 
 
 
