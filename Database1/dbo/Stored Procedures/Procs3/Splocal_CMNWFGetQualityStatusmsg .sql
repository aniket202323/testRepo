
--------------------------------------------------------------------------------------------------
-- Stored Procedure: [dbo].[spLocal_CmnWKInsertTransactionMessage]
--------------------------------------------------------------------------------------------------
-- Author				: BalaMurugan Rajendran
-- Date created			: 09-25-2013
-- Version 				: 1.0
-- SP Type				: Get Quality staus record
-- Caller				: Called from WF
-- Description			: Fetches records from transaction table.
--						  
-- Editor tab spacing	: 4
--------------------------------------------------------------------------------------------------
-- Sections		Description

--------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
--================================================================================================
-- 1.0		05-Jan-2017 	TCS Rajendran BalaMurugan					Created Stored Procedure


--================================================================================================
-- ManualDebug
-- exec Splocal_CMNWFGetQualityStatusmsg  'MES', 10, 'Quality Status', 'SAP', 'brtc-mslab2199', 0




CREATE PROCEDURE   [dbo].[Splocal_CMNWFGetQualityStatusmsg ]

 		@SystemTarget	VARCHAR(255)	= 'MES',
		@MaxRecords		INT				= 10,
		@MessageType	VARCHAR(255)	= NULL,
		@SystemSource	VARCHAR(255)	= NULL,
		@Site			VARCHAR(255)	= NULL,
		@ErrorCode		INT				= NULL




AS

BEGIN
-------------------------------------------------------------------------------

--

-------------------------------------------------------------------------------
------------------------------------------------------------------------------- 
-- Configure environment
-------------------------------------------------------------------------------
SET NOCOUNT ON
-------------------------------------------------------------------------------
-- Handle Parameters
-------------------------------------------------------------------------------
IF	@MaxRecords	= 0
	OR @MaxRecords IS NULL
	SELECT	@MaxRecords = 3
	
	
IF	@SystemSource = ''
	SELECT	@SystemSource = NULL
	
IF	@Site = ''
	SELECT	@Site = NULL	
-------------------------------------------------------------------------------
-- Return Pending records
-------------------------------------------------------------------------------	
IF	@Site IS NULL
BEGIN
		IF	@SystemSource IS NULL
		BEGIN
				-------------------------------------------------------------------------------
				-- Return Pending records if Site and Source are NULL
				-------------------------------------------------------------------------------
				SELECT	TOP (@MaxRecords)
				Id				Id, 
				SystemSource	[SystemSource],
				SystemTarget	[SystemTarget],
				[Message]		[Message],
				MessageType		[MessageType],
				InsertedDate	[InsertedDate],
				NextRetryDate	[NextRetryDate],
				ProcessedDate	[ProcessedDate],
				ErrorCode		[ErrorCode],
				ErrorMessage	[ErrorMessage],
				Site			[Site],
				MainData		[MainData],
				TriggerId		[TriggerId] 
				FROM	 GBDB.DBO.Local_tblINTIntegrationMessages	WITH	(NOLOCK)
				WHERE	[SystemTarget]		= @SystemTarget
				AND		[MessageType]		= @MessageType
				AND		[ProcessedDate]		IS NULL
				ORDER
				BY		InsertedDate, ID
		END		
		ELSE
		BEGIN
				-------------------------------------------------------------------------------
				-- Return Pending records if Site and Source is not NULL
				-------------------------------------------------------------------------------
				SELECT	TOP (@MaxRecords)
						Id				Id, 
						SystemSource	[SystemSource],
						SystemTarget	[SystemTarget],
						[Message]		[Message],
						MessageType		[MessageType],
						InsertedDate	[InsertedDate],
						NextRetryDate	[NextRetryDate],
						ProcessedDate	[ProcessedDate],
						ErrorCode		[ErrorCode],
						ErrorMessage	[ErrorMessage],
						Site			[Site],
						MainData		[MainData],
						TriggerId		[TriggerId]  
						FROM	GBDB.DBO.Local_tblINTIntegrationMessages	WITH	(NOLOCK)
						WHERE	[SystemSource]		= @SystemSource
						AND		[SystemTarget]		= @SystemTarget
						AND		[MessageType]	= @MessageType
						AND		[ProcessedDate]	IS NULL
						ORDER
						BY		InsertedDate, ID
		END						
END
ELSE
BEGIN
		IF	@SystemSource IS NULL
		BEGIN
				-------------------------------------------------------------------------------
				-- Return Pending records if Site is not NULL  and Source is NULL
				-------------------------------------------------------------------------------
				SELECT	TOP (@MaxRecords)
				Id				Id, 
				SystemSource	[SystemSource],
				SystemTarget	[SystemTarget],
				[Message]		[Message],
				MessageType		[MessageType],
				InsertedDate	[InsertedDate],
				NextRetryDate	[NextRetryDate],
				ProcessedDate	[ProcessedDate],
				ErrorCode		[ErrorCode],
				ErrorMessage	[ErrorMessage],
				Site			[Site],
				MainData		[MainData],
				TriggerId		[TriggerId]  
				FROM	GBDB.DBO.Local_tblINTIntegrationMessages	WITH	(NOLOCK)
				WHERE	[Site]			= @Site
				AND		[SystemTarget]	= @SystemTarget
				AND		[MessageType]	= @MessageType
				AND		[ProcessedDate]	IS NULL
				ORDER
				BY		InsertedDate, ID
		END		
		ELSE
		BEGIN
				-------------------------------------------------------------------------------
				-- Return Pending records if Site and Source are not NULL
				-------------------------------------------------------------------------------
				SELECT	TOP (@MaxRecords)
						Id				Id, 
						SystemSource	[SystemSource],
						SystemTarget	[SystemTarget],
						[Message]		[Message],
						MessageType		[MessageType],
						InsertedDate	[InsertedDate],
						NextRetryDate	[NextRetryDate],
						ProcessedDate	[ProcessedDate],
						ErrorCode		[ErrorCode],
						ErrorMessage	[ErrorMessage],
						Site			[Site],
						MainData		[MainData],
						TriggerId		[TriggerId]  
						FROM	GBDB.DBO.Local_tblINTIntegrationMessages	WITH	(NOLOCK)
						WHERE	[Site]			= @Site
						AND		[SystemSource]	= @SystemSource
						AND		[SystemTarget]	= @SystemTarget
						AND		[MessageType]	= @MessageType
						--AND		[ProcessedDate]	IS NULL --MK 28-03-2013
						AND		[ErrorCode]		= @ErrorCode
						ORDER
						BY		InsertedDate, ID
		END			
END


END



