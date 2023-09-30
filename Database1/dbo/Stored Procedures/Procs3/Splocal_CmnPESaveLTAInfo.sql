--------------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[Splocal_CmnPESaveLTAInfo]
	@Success			int  			OUTPUT,
	@ErrMsg				varchar(255) 	OUTPUT,
	@JumpToTime			datetime		OUTPUT,
	@ECId				int,
	@ReservedInput1		varchar(30),
	@ReservedInput2		varchar(30),
	@ReservedInput3		varchar(30),
	@ChangedTagNum		int,
	@ChangedPrevValue	varchar(12),
	@ChangedNewValue	varchar(12),
	@ChangedPrevTime	datetime,
	@ChangedNewTime		datetime,
	@Tag1PrevValue		varchar(30),
	@Tag1NewValue		varchar(30),
	@Tag1PrevTime		datetime,
	@Tag1NewTime		datetime,
	@Tag2PrevValue		varchar(30),
	@Tag2NewValue		varchar(30),
	@Tag2PrevTime		datetime,
	@Tag2NewTime		datetime,
	@Tag3PrevValue		varchar(30),
	@Tag3NewValue		varchar(30),
	@Tag3PrevTime		datetime,
	@Tag3NewTime		datetime

--WITH ENCRYPTION
AS
SET NOCOUNT ON

DECLARE	
@SPName							varchar(50),
@ThisTime						datetime,
@FlagDebugOnline				bit,
@Timestamp						datetime,
@PUId							int,
@maxEventTime					datetime

SET	@ErrMsg = ''
SET	@Success = 1

EXEC	spCmn_ModelParameterLookup
	@FlagDebugOnline OUTPUT,		
	@ECId,				
	'FlagDebugOnline',		
	0	


-------------------------------------------------------------------------------
-- 2. Obtain the PUId from the event manager
-------------------------------------------------------------------------------
SET @SPNAME  = 'Splocal_CmnPESaveLTAInfo'


IF @FlagDebugOnline = 1
BEGIN
	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
				GETDATE(),
				'1000 - SP started'+
				' Tag value = ' + @Tag1NewValue + 
				' Tag time = ' + CONVERT(varchar(30), @Tag1NewTime , 20)	,
				@ECId
			)
END


-------------------------------------------------------------------------------
--Check for a reload
-------------------------------------------------------------------------------
SELECT	@PUId = PU_Id
FROM	dbo.Event_Configuration WITH(NOLOCK)
WHERE	EC_Id = @ECId

SET @Timestamp = @ChangedNewTime;

SET @maxEventTime =  (SELECT MAX(timestamp) FROM dbo.Local_PE_LTAfromPLC WITH(NOLOCK) WHERE LTAPUID = @PUId)

IF @JumpToTime IS NOT NULL
BEGIN

	IF @FlagDebugOnline = 1
	BEGIN
		INSERT local_debug (CallingSP,timestamp, message, msg)
		VALUES (	@SPNAME,
					GETDATE(),
					'1050 - JumpToTime Before = ' + CONVERT(VARCHAR(30), @JumpToTime),
					@ECId
				)
	END

	-- Set JumpToTime to 1 second after last PP_Start Start_Time or End_Time
	IF @maxEventTime > @Timestamp
	BEGIN
		SET @JumpToTime = DATEADD(SECOND, 1, @maxEventTime);
	END

	IF @FlagDebugOnline = 1
	BEGIN
		INSERT local_debug (CallingSP,timestamp, message, msg)
		VALUES (	@SPNAME,
					GETDATE(),
					'1075 - JumpToTime After = ' + CONVERT(VARCHAR(30), @JumpToTime),
					@ECId
				)
	END
END


--EXIT on reload
IF @maxEventTime > @Timestamp
BEGIN
	SET	@ErrMsg = ''
	SET	@Success = 1
	GOTO errCode
END


IF @FlagDebugOnline = 1
BEGIN
	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
			GETDATE(),
			'1100 - ' +
			' @Tag1NewValue = ' + COALESCE(@Tag1NewValue,'-') +
			' @Tag1NewTime = ' + CONVERT(Varchar(30),@Tag1NewTime,20) +
			' @Tag2NewValue = ' + COALESCE(@Tag2NewValue,'-') +
			' @Tag2NewTime = ' + CONVERT(Varchar(30),@Tag2NewTime,20) +
			' @Tag3NewValue = ' + COALESCE(@Tag3NewValue,'-') +
			' @Tag3NewTime = ' + CONVERT(Varchar(30),@Tag3NewTime,20) ,
			@ECId
		)
END


IF @Tag1NewValue IS NULL
BEGIN
	--Nothing to insert
	Goto ErrCode
END


IF LEN(@Tag1NewValue) < 6  --Invalid ULID
IF @Tag1NewValue IS NULL
BEGIN
	--Nothing to insert
	Goto ErrCode
END


--Chekc if ULID already created
IF EXISTS(SELECT 1 FROM dbo.Local_PE_LTAfromPLC WHERE LTAPUID = @PUID AND ULID = @Tag1NewValue AND Processorder = @Tag2NewValue)  --V1.1
BEGIN
	--ULID/PrO already created
	Goto ErrCode
END
ELSE
BEGIN
	INSERT dbo.Local_PE_LTAfromPLC(LTApuid, ULID, Processorder, QuantityUL, Timestamp)
	VALUES (@puid, @Tag1NewValue, @Tag2NewValue, @Tag3NewValue, @Timestamp)

	IF @FlagDebugOnline = 1  
	BEGIN
		INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
			VALUES(	getdate(), 
					@SPName,
					'2000' +
					' New ULID inserted in LTA '+
					' @Tag1NewValue = ' + COALESCE(@Tag1NewValue,'-') +
					' LTA puid = ' + CONVERT(varchar(30),COALESCE(@puid,0)),
					@ECId
					)
	END
END


ErrCode:

IF @FlagDebugOnline = 1  
BEGIN
	INSERT INTO Local_Debug([Timestamp], CallingSP, [Message],msg) 
		VALUES(	getdate(), 
				@SPName,
				'9999' +

				' Finished',
				@ECId
				)
END


SET NOcount OFF

RETURN