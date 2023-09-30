--------------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[splocal_CmnPPAAutoReturnScan]
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
	@Tag1NewTime		datetime

--WITH ENCRYPTION
AS
SET NOCOUNT ON

DECLARE	
@DefaultUserId					int,
@DefaultUserName				varchar(100),
@SPName							varchar(50),
@ThisTime						datetime,
@FlagDebugOnline				bit,
@DebugFlagManual				bit,
@RTCISSiteClass					varchar(50),
@puidModel						int,

--Pallet/Container
@puid							int,
@eventID						int,
@Timestamp						datetime,
@DimX							float,
@ppid							int,
@ProdStatus						int,


--PO information
@PathId							int,
@ProcessOrder					varchar(12),


--UDPs
@TableIdProdUnits				int,
@TableIdPath					int,
@AutoReturnLocationId			int,
@AutoReturnLocation				varchar(50),
@ReturnValidLocationsForMSG3Id	int,
@ReturnValidLocationsForMSG3	varchar(250),

--Consume event
@ReturnedStatusId				int,
@ConsumedStatusId				int,
@OverConsumedStatusId			int

SET	@ErrMsg = ''
SET	@Success = 1

EXEC	spCmn_ModelParameterLookup
	@FlagDebugOnline OUTPUT,		
	@ECId,				
	'FlagDebugOnline',		
	0	

-- This is for debugging purpose
SET @DebugFlagManual = 0

-------------------------------------------------------------------------------
-- 2. Obtain the PUId from the event manager
-------------------------------------------------------------------------------
SET @SPNAME  = 'splocal_CmnPPAAutoReturnScan'


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

SELECT	@puidModel = PU_Id
FROM	dbo.Event_Configuration WITH(NOLOCK)
WHERE	EC_Id = @ECId


-------------------------------------------------------------------------------
--  Retrieve local parameters.
-------------------------------------------------------------------------------
EXEC	spCmn_ModelParameterLookup
	@DefaultUserName OUTPUT,		
	@ECId,				
	'UserName',		
	'PE.SCO603'	






-------------------------------------------------------------------------------
-- Validate the User
-------------------------------------------------------------------------------

SET @DefaultUserId = NULL
SELECT @DefaultUserId = User_Id
FROM dbo.Users WITH(NOLOCK)
WHERE Username = @DefaultUserName

IF @DefaultUserId IS NULL
	SET @DefaultUserId = (	SELECT  User_Id
							FROM dbo.Users WITH(NOLOCK)
							WHERE Username ='System.PE')



IF @FlagDebugOnline = 1
BEGIN
	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
			GETDATE(),
			'1050 - @UserId = ' + CONVERT(Varchar(30),@DefaultUserId) +
			' @username = ' + @DefaultUserName,
			@ECId
		)
END




--------------------------------------------------------------------------------
--Get information about the scanned pallet
--------------------------------------------------------------------------------
SELECT	TOP 1	@puid				= e.pu_id,
				@eventID			= e.event_id,
				@Timestamp			= e.timestamp,
				@DimX				= ed.final_dimension_x,
				@ppid				= ed.pp_id,
				@ProdStatus			= e.event_status
FROM dbo.events e			WITH(NOLOCK)
JOIN dbo.event_details ed	WITH(NOLOCK)	ON e.event_id = ed.event_id
WHERE e.event_num LIKE @Tag1NewValue + '[_]%'		--V1.2
ORDER BY e.timestamp DESC


IF @eventId IS NULL
BEGIN
	IF @FlagDebugOnline = 1
	BEGIN
		INSERT local_debug (CallingSP,timestamp, message, msg)
		VALUES (	@SPNAME,
				GETDATE(),
				'1091 - Scanned event not found ' +
				'ULID: ' + @Tag1NewValue,
				@ECId
			)
	END
	
	SET	@ErrMsg = '1091 - Scanned event not found ' + @SPNAME
	SET	@Success = 0
	GOTO errCode
END


--------------------------------------------------------------------------------
--Validate the status
--------------------------------------------------------------------------------
--Returned
SET @ReturnedStatusId = (SELECT prodStatus_Id FROM dbo.production_status WITH(NOLOCK) WHERE prodStatus_Desc = 'Returned')
IF @ProdStatus = @ReturnedStatusId
BEGIN
	IF @FlagDebugOnline = 1
	BEGIN
		INSERT local_debug (CallingSP,timestamp, message, msg)
		VALUES (	@SPNAME,
				GETDATE(),
				'1095 - Status Already Returned ' +
				'ULID: ' + @Tag1NewValue,
				@ECId
			)
	END

	SET	@ErrMsg = '1095 - Status Already Returned ' + @SPNAME
	SET	@Success = 0
	GOTO errCode

END


--Consumed
SET @ConsumedStatusId = (SELECT prodStatus_Id FROM dbo.production_status WITH(NOLOCK) WHERE prodStatus_Desc = 'Consumed')
IF @ProdStatus = @ConsumedStatusId
BEGIN
	IF @FlagDebugOnline = 1
	BEGIN
		INSERT local_debug (CallingSP,timestamp, message, msg)
		VALUES (	@SPNAME,
				GETDATE(),
				'1096 - Status Is consumed ' +
				'ULID: ' + @Tag1NewValue,
				@ECId
			)
	END

	SET	@ErrMsg = '1096 - Status Is consumed ' + @SPNAME
	SET	@Success = 0
	GOTO errCode

END


--Overconsumed
SET @OverConsumedStatusId = (SELECT prodStatus_Id FROM dbo.production_status WITH(NOLOCK) WHERE prodStatus_Desc = 'Overconsumed')
IF @ProdStatus = @OverConsumedStatusId
BEGIN
	IF @FlagDebugOnline = 1
	BEGIN
		INSERT local_debug (CallingSP,timestamp, message, msg)
		VALUES (	@SPNAME,
				GETDATE(),
				'1097 - Status Is Overconsumed ' +
				'ULID: ' + @Tag1NewValue,
				@ECId
			)
	END

	SET	@ErrMsg = '1097 - Status Is Overconsumed ' + @SPNAME
	SET	@Success = 0
	GOTO errCode

END


--------------------------------------------------------------------------------
--Trap 0 or negative value
--------------------------------------------------------------------------------
IF @DimX <= 0
BEGIN
	IF @FlagDebugOnline = 1
	BEGIN
		INSERT local_debug (CallingSP,timestamp, message, msg)
		VALUES (	@SPNAME,
				GETDATE(),
				'1098 - Invalid qty 0 or less ' +
				'ULID: ' + @Tag1NewValue,
				@ECId
			)
	END

	SET	@ErrMsg = '1098 - Invalid qty 0 or less ' + @SPNAME
	SET	@Success = 0
	GOTO errCode
END






--Get model UDP
EXEC	spCmn_ModelParameterLookup
	@RTCISSiteClass OUTPUT,		
	@ECId,				
	'RTCISSiteClass',		
	'PE:SiteClasses'	


--------------------------------------------------------------------------------
--Validate the return location
--------------------------------------------------------------------------------

SET @TableIdProdUnits	= (SELECT Tableid FROM dbo.tables WITH(NOLOCK) WHERE tablename = 'prod_Units')
SET @TableIdPath		= (SELECT Tableid FROM dbo.tables WITH(NOLOCK) WHERE tablename = 'prdExec_paths')

--Get the required table fields
SET @AutoReturnLocationId			= (SELECT table_Field_id FROM dbo.table_fields WITH(NOLOCK) WHERE table_field_desc = 'PE_AutoReturnLocation' AND Tableid = @TableIdProdUnits)
SET @ReturnValidLocationsForMSG3Id	= (SELECT table_Field_id FROM dbo.table_fields WITH(NOLOCK) WHERE table_field_desc = 'PE_MA_Return_ValidLocationsForMSG3' AND Tableid = @TableIdPath)

SET @AutoReturnLocation = (SELECT CONVERT(varchar(50),value) FROM dbo.table_fields_values WITH(NOLOCK) WHERE table_field_id = @AutoReturnLocationId AND keyId = @puidModel)

--Get the pathId
--1) from the pp_id
SELECT	@pathId = path_id ,
		@Processorder = process_order
FROM dbo.production_plan WITH(NOLOCK) 
WHERE pp_id = @ppid
IF @pathId IS NULL
BEGIN
	SET @pathId = (	SELECT TOP 1 pepu.path_id
					FROM dbo.prdExec_input_sources peis	WITH(NOLOCK)
					JOIN dbo.prdExec_inputs	pei			WITH(NOLOCK)	ON pei.pei_id = peis.pei_id
					JOIN dbo.prdExec_path_units pepu	WITH(NOLOCK)	ON pepu.pu_id = pei.pu_id
					WHERE peis.pu_id = @puid
					)
END

IF @pathId IS NULL
BEGIN
	IF @FlagDebugOnline = 1
	BEGIN
		INSERT local_debug (CallingSP,timestamp, message, msg)
		VALUES (	@SPNAME,
				GETDATE(),
				'1120 - cannot find path ',
				@ECId
			)
	END

	SET	@ErrMsg = '1120 - cannot find path ' + @SPNAME
	SET	@Success = 0
	GOTO errCode

END

SET @ReturnValidLocationsForMSG3 = (SELECT CONVERT(varchar(250),value) FROM dbo.table_fields_values WITH(NOLOCK) WHERE table_field_id = @ReturnValidLocationsForMSG3Id AND keyId = @pathId)

IF (SELECT CHARINDEX(@AutoReturnLocation, @ReturnValidLocationsForMSG3,0)) = 0
BEGIN
	--Invalid return Location
	IF @FlagDebugOnline = 1
	BEGIN
		INSERT local_debug (CallingSP,timestamp, message, msg)
		VALUES (	@SPNAME,
				GETDATE(),
				'1200 - Invalid return Location ' +
				'ULID: ' + @Tag1NewValue,
				@ECId
			)
	END

	SET	@ErrMsg = '1200 - Invalid return Location ' + @SPNAME
	SET	@Success = 0
	GOTO errCode

END



--------------------------------------------------------------------------------
--Call the return material stored proc
--------------------------------------------------------------------------------
EXEC [dbo].[spLocal_CmnMobileAppReturnMaterial]
		@eventid,		
		'Returned',
		@dimX,
		@Tag1NewTime,
		@ProcessOrder,
		@RTCISSiteClass,
		@AutoReturnLocation,
		@DefaultUserName

IF @FlagDebugOnline = 1
BEGIN
	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
			GETDATE(),
			'2000 - SP has been called ' ,
			@ECId
		)
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