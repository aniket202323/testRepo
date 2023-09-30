 
 
 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_GENL_ReadTransactionsTableById]
		@TransactionId			INT = NULL
AS	
-------------------------------------------------------------------------------
-- Read Transaction record. this SPROC is called by the dispatcher workflow
/*
EXEC spLocal_MPWS_GENL_ReadTransactionsTableById 3
EXEC spLocal_MPWS_GENL_ReadTransactionsTableById 0
 
 
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
 
DECLARE	@tTransaction		TABLE
(
	Id						INT					NULL,
	TransactionName			VARCHAR(255)		NULL,
	StationName				VARCHAR(255)		NULL,
	UserName				VARCHAR(255)		NULL,
	InsertedDate			DATETIME			NULL,
	ProcessedDate			DATETIME			NULL,
	ErrorCode				INT					NULL,
	Errormessage			VARCHAR(255)		NULL,
	Field01					VARCHAR(255)		NULL,			
	Field02					VARCHAR(255)		NULL,			
	Field03					VARCHAR(255)		NULL,			
	Field04					VARCHAR(255)		NULL,			
	Field05					VARCHAR(255)		NULL,			
	Field06					VARCHAR(255)		NULL,			
	Field07					VARCHAR(255)		NULL,			
	Field08					VARCHAR(255)		NULL,			
	Field09					VARCHAR(255)		NULL,			
	Field10					VARCHAR(255)		NULL,			
	Field11					VARCHAR(255)		NULL,			
	Field12					VARCHAR(255)		NULL,			
	Field13					VARCHAR(255)		NULL,			
	Field14					VARCHAR(255)		NULL,			
	Field15					VARCHAR(255)		NULL,			
	Field16					VARCHAR(255)		NULL,			
	Field17					VARCHAR(255)		NULL,			
	Field18					VARCHAR(255)		NULL,			
	Field19					VARCHAR(255)		NULL,			
	Field20					VARCHAR(255)		NULL,
	OutField01				VARCHAR(255)		NULL,			
	OutField02				VARCHAR(255)		NULL,			
	OutField03				VARCHAR(255)		NULL,			
	OutField04				VARCHAR(255)		NULL,			
	OutField05				VARCHAR(255)		NULL			
)	
-------------------------------------------------------------------------------
--  Retrieve the transaction information
-------------------------------------------------------------------------------
IF @TransactionId IS NOT NULL AND @TransactionId <> 0
BEGIN
INSERT	@tTransaction (Id, TransactionName, StationName, UserName, InsertedDate,
		ProcessedDate, ErrorCode, Errormessage, Field01, Field02, Field03, Field04,
		Field05, Field06, Field07, Field08, Field09, Field10, Field11, Field12,
		Field13, Field14, Field15, Field16, Field17, Field18, Field19, Field20,
		OutField01, OutField02, OutField03, OutField04, OutField05)
		SELECT	Id, TransactionName, StationName, UserName, InsertedDate,ProcessedDate, 
				ErrorCode, Errormessage, Field01, Field02, Field03, Field04, Field05, 
				Field06, Field07, Field08, Field09, Field10, Field11, Field12,	
				Field13, Field14, Field15, Field16, Field17, Field18, Field19, Field20,
				OutField01, OutField02, OutField03, OutField04, OutField05	
				FROM	dbo.Local_MPWS_GENL_Transactions		WITH (NOLOCK)
				WHERE	Id	= @TransactionId 
END
ELSE
BEGIN
 --process transactions that are not dispense transactions.
 --get the top unprocessed transaction
INSERT	@tTransaction (Id, TransactionName, StationName, UserName, InsertedDate,
		ProcessedDate, ErrorCode, Errormessage, Field01, Field02, Field03, Field04,
		Field05, Field06, Field07, Field08, Field09, Field10, Field11, Field12,
		Field13, Field14, Field15, Field16, Field17, Field18, Field19, Field20,
		OutField01, OutField02, OutField03, OutField04, OutField05)
		SELECT	TOP 1 Id, TransactionName, StationName, UserName, InsertedDate,ProcessedDate, 
				ErrorCode, Errormessage, Field01, Field02, Field03, Field04, Field05, 
				Field06, Field07, Field08, Field09, Field10, Field11, Field12,	
				Field13, Field14, Field15, Field16, Field17, Field18, Field19, Field20,
				OutField01, OutField02, OutField03, OutField04, OutField05	
				FROM	dbo.Local_MPWS_GENL_Transactions		WITH (NOLOCK)
				WHERE ProcessedDate IS NULL
				AND		TransactionName NOT LIKE 'DISP%'
				ORDER BY Id
END
				
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
 
SELECT	Id						Id,
		TransactionName			TransactionName,
		StationName				StationName,
		UserName				UserName,
		InsertedDate			InsertedDate,
		ProcessedDate			ProcessedDate,
		ErrorCode				ErrorCode,
		Errormessage			Errormessage,
		Field01					Field01,			
		Field02					Field02,			
		Field03					Field03,			
		Field04					Field04,			
		Field05					Field05,			
		Field06					Field06,			
		Field07					Field07,			
		Field08					Field08,			
		Field09					Field09,			
		Field10					Field10,			
		Field11					Field11,			
		Field12					Field12,			
		Field13					Field13,			
		Field14					Field14,			
		Field15					Field15,			
		Field16					Field16,			
		Field17					Field17,			
		Field18					Field18,			
		Field19					Field19,			
		Field20					Field20,
		OutField01				OutField01, 
		OutField02				OutField02, 
		OutField03				OutField03, 
		OutField04				OutField04, 
		OutField05				OutField05
		FROM	@tTransaction
		
--GRANT EXECUTE ON [dbo].[spLocal_MPWS_GENL_ReadTransactionsTableById] TO [public]
 
 
 
 
