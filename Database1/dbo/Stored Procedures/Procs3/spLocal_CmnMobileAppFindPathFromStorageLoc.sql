--------------------------------------------------------------------------------
CREATE Procedure [dbo].[spLocal_CmnMobileAppFindPathFromStorageLoc]
@RTCISLocation					varchar(30),
@SOAUnitName					varchar(50)

AS

DECLARE
@ErrMsg							varchar(1000),	
@CallingSP						varchar(50),
@Unit							varchar(30),
@DebugOnline					bit,

--ULIN info
@ULINpuid						int,
@EquipmentPropertyName			varchar(50),

--PaTH
@PathId							int, 
@PathCode						varchar(50),

@UseRTCIS						bit,
@UsePrIME						bit



SET @DebugOnline = 1
SET @CallingSP = 'spLocal_CmnMobileAppFindPathFromStorageLoc'
IF @DebugOnline = 1
BEGIN
	IF @RTCISLocation IS NUll
		SET @RTCISLocation = ''
	IF @SOAUnitName IS NUll
		SET @SOAUnitName = ''

	SET @ErrMsg =	'0010 ' +
					'SP started ' +
					'  RTCISLocation: ' + @RTCISLocation + 
					'  SOAUnitName: ' + @SOAUnitName 

	INSERT into Local_Debug(Timestamp, CallingSP, Message) 
	VALUES(	getdate(), 
			@CallingSP,
			@ErrMsg 
			)
END



-----------------------------------------------------------------------------------------
--  Retrieve WMS system 
-----------------------------------------------------------------------------------------
EXEC [splocal_CmnGetWMSSystemUDPs] NULL, @UseRTCIS OUTPUT, @UsePrIME OUTPUT, NULL, NULL, NULL



--Need to get the PPA pu_id

--Case RTCIS location
IF @UseRTCIS = 1
BEGIN

	IF @RTCISLocation != ''
	BEGIN
		SET @EquipmentPropertyName = 'AT_LOCATN'

		SELECT	@ULINPuID	= 	PU_Id				
		FROM	dbo.Property_Equipment_EquipmentClass peec	WITH(NOLOCK)
		JOIN	dbo.Equipment e								WITH(NOLOCK)	ON peec.EquipmentID = e.EquipmentID
		JOIN	dbo.PAEquipment_Aspect_SOAEquipment a		WITH(NOLOCK)	ON e.EquipmentId = a.Origin1EquipmentId
		WHERE	Value = @RTCISLocation
		AND		peec.Name = @EquipmentPropertyName
	END

END
ELSE IF @UsePrIME = 1
BEGIN
	SET @SOAUnitName = @RTCISLocation;
END


IF @SOAUnitName !=''
BEGIN
	SET @ULINPuID = (SELECT pu_id FROM dbo.prod_units WITH(NOLOCK) WHERE pu_desc = @SOAUnitName)
END

IF @ULINPuID IS NULL
	SET @ULINPuID = 0

IF @DebugOnline = 1
BEGIN
		SET @ErrMsg =	'0050 ' +
						'ULINPuID: ' + CONVERT(varchar(30),@ULINPuID)

		INSERT into Local_Debug(Timestamp, CallingSP, Message) 
		VALUES(	getdate(), 
				@CallingSP,
				@ErrMsg 
				)
END

IF @ULINPuID = 0
BEGIN
	SELECT -1, ''
	RETURN
END

-----------------------------------------------------------------------
--Get the production Path
-----------------------------------------------------------------------
SET @PathId = (	SELECT TOP 1 ppu.path_id
				FROM dbo.prdExec_Input_Sources peis		WITH(NOLOCK)
				JOIN dbo.prdExec_Inputs pei				WITH(NOLOCK) ON pei.pei_id = peis.pei_id AND peis.pu_id = @ULINPuID
				JOIN dbo.PrdExec_Path_Units ppu			WITH(NOLOCK) ON pei.pu_id = ppu.pu_id -- AND is_production_point = 1 -- 1.1
				)

SET @PathCode = (SELECT path_code FROM dbo.prdExec_Paths WITH(NOLOCK) WHERE path_id = @PathId)


SELECT @PathId AS 'path_id', @PathCode AS 'Path_code'




SET NOCOUNT OFF
RETURN