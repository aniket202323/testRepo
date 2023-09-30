 
 
 
 
 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_GENL_GenerateEventNumber]
		@PUId			INT			= NULL,
		@EventMask		VARCHAR(25)	= NULL
AS	
-------------------------------------------------------------------------------
-- Generates a Event Number. It appends a '-99' if the @EventMask is passed in
-- else generates an event number with the following mask: YYYYMMDDHHMISS
/*
spLocal_GENL_GenerateEventNumber 
go
spLocal_GENL_GenerateEventNumber 3379,'RMCTEST4'
*/
-- Date         Version Build Author  
-- 24-Sep-2015  001     001   Alex Judkowicz (GEIP)  Initial development	
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
 
 
DECLARE	@tOutput			TABLE
(
	Id						INT					IDENTITY(1,1)	NOT NULL,
	EventNum				VARCHAR(25)							NULL
)
 
DECLARE		@MaxEventNum	VARCHAR(255),
			@Pos			INT,
			@Seq			INT
------------------------------------------------------------------------------
--  Build Event Num
-------------------------------------------------------------------------------
IF	@EventMask IS NULL OR LEN(RTRIM(LTRIM(@EventMask))) = 0
BEGIN
		------------------------------------------------------------------------------
		--  Build Event Num: YYYYMMDDHHMISS
		-------------------------------------------------------------------------------
		INSERT	@tOutput (EventNum)
				SELECT	CONVERT(VARCHAR(04), DATEPART(YY, GETDATE()))
						+ RIGHT('00' + CONVERT(VARCHAR(02), DATEPART(MM, GETDATE())),2)
						+ RIGHT('00' + CONVERT(VARCHAR(02), DATEPART(DD, GETDATE())),2)
						+ RIGHT('00' + CONVERT(VARCHAR(02), DATEPART(HH, GETDATE())),2)
						+ RIGHT('00' + CONVERT(VARCHAR(02), DATEPART(MI, GETDATE())),2)
						+ RIGHT('00' + CONVERT(VARCHAR(02), DATEPART(SS, GETDATE())),2)
END
ELSE
BEGIN
		------------------------------------------------------------------------------
		--  Find EventMask-99 event and incremend sufix by 1
		-------------------------------------------------------------------------------
		SELECT	@MaxEventNum		= MAX(Event_Num)
				FROM	dbo.Events	WITH (NOLOCK)
				WHERE	PU_Id		= @PUId
				AND		Event_Num	LIKE @EventMask + '%'
				
		IF @MaxEventNum is NULL 
			SELECT @MaxEventNum=@EventMask
				
		SELECT	@Pos = CHARINDEX('-', @MaxEventNum)
		
		
		IF		@Pos = 0
				INSERT	@tOutput (EventNum)
						VALUES	(@MaxEventNum + '-001')
		ELSE
		BEGIN					
				SELECT	@Seq = CONVERT(INT, SUBSTRING(@MaxEventNum, @POs +1, 3)) + 1
				INSERT	@tOutput (EventNum)
						VALUES	(@EventMask + '-' + RIGHT('000' + CONVERT(VARCHAR(03), @Seq),3))		
		END
END
				
INSERT	@tFeedback (ErrorCode, ErrorMessage)
		VALUES (1, 'Success')
-------------------------------------------------------------------------------					
-- Return data tables
-------------------------------------------------------------------------------	
SELECT	Id						Id,
		ErrorCode				ErrorCode,
		ErrorMessage			ErrorMessage
		FROM	@tFeedback
		
SELECT	Id						Id,
		EventNum				EventNum
		FROM	@tOutput
		ORDER
		BY		Id
 
 
 
 
 
 
 
 
