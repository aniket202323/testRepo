 
 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_GENL_PopulateTransactionstable]
		@TransactionName		VARCHAR(255),
		@StationName			VARCHAR(255),
		@UserName				VARCHAR(255),
		@Field01				VARCHAR(255)	= NULL,
		@Field02				VARCHAR(255)	= NULL,
		@Field03				VARCHAR(255)	= NULL,
		@Field04				VARCHAR(255)	= NULL,
		@Field05				VARCHAR(255)	= NULL,
		@Field06				VARCHAR(255)	= NULL,
		@Field07				VARCHAR(255)	= NULL,
		@Field08				VARCHAR(255)	= NULL,
		@Field09				VARCHAR(255)	= NULL,
		@Field10				VARCHAR(255)	= NULL,
		@Field11				VARCHAR(255)	= NULL,
		@Field12				VARCHAR(255)	= NULL,
		@Field13				VARCHAR(255)	= NULL,
		@Field14				VARCHAR(255)	= NULL,
		@Field15				VARCHAR(255)	= NULL,
		@Field16				VARCHAR(255)	= NULL,
		@Field17				VARCHAR(255)	= NULL,
		@Field18				VARCHAR(255)	= NULL,
		@Field19				VARCHAR(255)	= NULL,
		@Field20				VARCHAR(255)	= NULL,
		@ErrorCode				INT				OUTPUT,
		@ErrorMessage			VARCHAR(255)	OUTPUT
		
AS	
 
SET NOCOUNT ON
-------------------------------------------------------------------------------
-- Populate Transaction table with information entered by the HMI display
/*
EXEC spLocal_MPWS_GENL_PopulateTransactionsTable 'INVN_GET_UNIT_INFO', 'StationName', 'Admin', '1000000000000000001', 'PW01-Receiving'
 
 
*/
-- Date         Version Build Author  
-- 29-Sep-2015  001     001   Alex Judkowicz (GEIP)  Initial development	
-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------
DECLARE	@NewId				INT
 
--DECLARE	@tFeedback			TABLE
--(
--	Id						INT					IDENTITY(1,1)	NOT NULL,
--	ErrorCode				INT									NULL,
--	ErrorMessage			VARCHAR(255)						NULL
--)
 
DECLARE	@tNewId				TABLE
(
	Id						INT					IDENTITY(1,1)	NOT NULL,
	NewId					INT									NULL
)	
 
-------------------------------------------------------------------------------
--  Parse PP Id string and into a table variable 
-------------------------------------------------------------------------------
INSERT	dbo.Local_MPWS_GENL_Transactions (TransactionName, StationName,
		UserName, InsertedDate, ProcessedDate, ErrorCode, Errormessage,
		Field01, Field02, Field03, Field04, Field05, Field06, Field07, Field08,
		Field09, Field10, Field11, Field12, Field13, Field14, Field15, Field16,
		Field17, Field18, Field19, Field20)
		VALUES (@TransactionName, @StationName,@UserName, GETDATE(), NULL, 0, NULL, 
				@Field01, @Field02, @Field03, @Field04, @Field05, @Field06, @Field07, 
				@Field08, @Field09, @Field10, @Field11, @Field12, @Field13, @Field14, 
				@Field15, @Field16,	@Field17, @Field18, @Field19, @Field20)
				
SELECT	@NewId = @@IDENTITY
	
SELECT	@ErrorCode = -2,
				@ErrorMessage = 'Success'				
--INSERT	@tFeedback (ErrorCode, ErrorMessage)
--		VALUES (1, 'Success')
		
INSERT	@tNewId (NewId)
		VALUES (@NewId)		
-------------------------------------------------------------------------------					
-- Return data tables
-------------------------------------------------------------------------------	
--SELECT	Id						Id,
--		ErrorCode				ErrorCode,
--		ErrorMessage			ErrorMessage
--		FROM	@tFeedback
 
SELECT	Id						Id,
		NewId					NewId
		FROM	@tNewId
 
 
 
 
 
 
