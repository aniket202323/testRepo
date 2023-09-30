 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_KIT_GenerateCarrierNumber]
		@PUId			INT,
		@NewEventNum	VARCHAR(255)= NULL	OUTPUT
AS	
-------------------------------------------------------------------------------
-- Generates a Event Number for Carriers. 
-- Generates with prefix of YYYYMMDD and appends a '_nnn' 
-- wich increments for the number of carriers in that day
/*
spLocal_MPWS_KIT_GenerateCarrierNumber 3368 
*/
-- Date         Version Build Author  
-- 31-May-2016  001     001   Chris Donnelly (GE Digital) Initial development	
-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------
SET NOCOUNT ON
 
DECLARE @DateCode varchar(25)
 
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
			--,@NewEventNum	VARCHAR(255)
------------------------------------------------------------------------------
--  Build Event Num: YYYYMMDD
-------------------------------------------------------------------------------
SET @DateCode = 
			CONVERT(VARCHAR(04), DATEPART(YY, GETDATE()))
				+ RIGHT('00' + CONVERT(VARCHAR(02), DATEPART(MM, GETDATE())),2)
				+ RIGHT('00' + CONVERT(VARCHAR(02), DATEPART(DD, GETDATE())),2)
------------------------------------------------------------------------------
--  Find EventMask-99 event and incremend sufix by 1
-------------------------------------------------------------------------------
SELECT	@MaxEventNum		= MAX(Event_Num)
		FROM	dbo.Events	WITH (NOLOCK)
		WHERE	PU_Id		= @PUId
		AND		Event_Num	LIKE 'CA' + @DateCode + '%'
		
IF @MaxEventNum is NULL 
	SET @MaxEventNum=@DateCode + '_000'
		
SET	@Pos = CHARINDEX('_', @MaxEventNum)
 
 
IF		@Pos = 0
		SET @NewEventNum = 
				'CA' + @DateCode + '_001'
ELSE
BEGIN					
		SET	@Seq = CONVERT(INT, SUBSTRING(@MaxEventNum, @POs +1, 3) + 1)
		SET @NewEventNum = 
				'CA' + @DateCode + '_' + RIGHT('000' + CONVERT(VARCHAR(03), @Seq),3)	
END
	
INSERT	@tFeedback (ErrorCode, ErrorMessage)
		VALUES (1, 'Success')
-------------------------------------------------------------------------------					
---- Return data tables
---------------------------------------------------------------------------------	
SELECT	Id						Id,
		ErrorCode				ErrorCode,
		ErrorMessage			ErrorMessage
		FROM	@tFeedback
		
--INSERT	@tFeedback (ErrorCode, ErrorMessage)
--		VALUES (1, 'Success')
--SELECT	Id						Id,
--		EventNum				EventNum
--		FROM	@tOutput
--		ORDER
--		BY		Id
 
SELECT 1 as ID, @NewEventNum as EventNum
 
 
 
