CREATE PROCEDURE [dbo].[spLocal_PrIME_SimulationCreatedShortPallet]

@OutputValue				varchar(25) OUTPUT,
@ThisTime					datetime,
@puid						int




-- ManualDebug
/*
Declare	@OutputValue	nvarchar(25)

Exec spLocal_PrIME_SimulationCreatedShortPallet
	@OutputValue				OUTPUT,
	'21-Sep-2018 08:54',				
	5719

	
SELECT @OutputValue as OutputValue
*/


AS
SET NOCOUNT ON


DECLARE @SPNAME						varchar(30),
		@UserId						int,
		@userName					varchar(50),
		@Now						datetime,		
		@PathId						int,
		@usePrIMESimulator			int,
		@ProdCode					varchar(30),
		@cnPrIMEWMS					varchar(30),
		@WMSid						int,	
		@Count						int,
		@PrIMESFlag					bit,		
		@pnLocationID				varchar(50),
		@LocationID					varchar(50),
		@Status						varchar(50),
		@countPal					int,
		@TableId					int,
		@TableFieldId				int
		
------------------------------------------------------
--Variable table declaration
------------------------------------------------------
DECLARE @PRDExecInputs TABLE (
			PUID						int,
			PEIID						int,
			OG							varchar(50)

			)


SET @SPNAME = 'spLocal_PrIME_SimulationCreatedShortPallet'
SELECT @Now = GETDATE()
SET @Count = 0


SET @TableId		= (SELECT	t.TableID			FROM dbo.Tables t			WITH (NOLOCK) WHERE upper(t.TableName)			= 'PROD_UNITS')
SET @TableFieldId	= (SELECT	tf.Table_Field_ID	FROM dbo.Table_Fields tf	WITH (NOLOCK) WHERE upper(tf.Table_Field_Desc)	= 'PE_SHAREDLOC_SIMULATEPRIME' and tf.TableId = @TableId)

SET @PathId = (	SELECT TOP 1 ppu.path_id
			FROM dbo.prdExec_Input_Sources peis		WITH(NOLOCK)
			JOIN dbo.prdExec_Inputs pei				WITH(NOLOCK) ON pei.pei_id = peis.pei_id AND peis.pu_id = @PuID
			JOIN dbo.PrdExec_Path_Units ppu			WITH(NOLOCK) ON pei.pu_id = ppu.pu_id 
			)



SET @PathId = (	SELECT TOP 1 ppu.path_id
			FROM dbo.prdExec_Input_Sources peis		WITH(NOLOCK)
			JOIN dbo.prdExec_Inputs pei				WITH(NOLOCK) ON pei.pei_id = peis.pei_id AND peis.pu_id = @PuID
			JOIN dbo.PrdExec_Path_Units ppu			WITH(NOLOCK) ON pei.pu_id = ppu.pu_id 
			)

EXEC		[splocal_CmnGetWMSSystemUDPs] @PathId, NULL ,@PrIMESFlag output,NULL ,NULL,@usePrIMESimulator output


IF @PrIMESFlag = 0
	RETURN



--1.1
If @PathId is null
BEGIN
	SET @usePrIMESimulator = (	SELECT	CONVERT(bit, tfv.Value)
								FROM	dbo.Table_Fields_Values tfv	WITH(NOLOCK)
								WHERE	tfv.KeyId = @PUID
								and		tfv.Table_Field_Id	=	@TableFieldId
								and		tfv.TableId			=	@TableId);
END

IF @usePrIMESimulator =0
	RETURN

--get the location from the SOA property

SET @cnPrIMEWMS	=	'PE:PrIME_WMS'

SET @pnLocationID	=	'LocationID'

SET	@LocationID	=		(SELECT  convert(varchar(50), pee.Value)
						FROM dbo.Equipment e								WITH(NOLOCK)
						JOIN dbo.PAEquipment_Aspect_SOAEquipment	a		WITH(NOLOCK)	ON e.equipmentid = a.Origin1EquipmentId
						JOIN dbo.property_equipment_equipmentclass pee		WITH(NOLOCK)	ON (e.EquipmentId = pee.EquipmentId)
						WHERE	a.pu_id = @puid
							AND pee.Class = @cnPrIMEWMS
							AND pee.Name = @pnLocationID )


IF @LocationID IS NULL 
BEGIN
	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
				GETDATE(),
				'0100 - ' +
				' @Location not found'	,
				@puid			)
	
	SELECT	@OutputValue =  '@Location not found'
	RETURN
END

SET @WMSid = (	SELECT min([OpentableId])  --1.7
				FROM [dbo].[Local_PrIME_OPENREQUESTS] WITH(NOLOCK) 
				WHERE LocationID = @LocationID AND Status = 'RequestMaterial')

SET @countPal =0

WHILE @WMSid IS NOT NULL
BEGIN
	SELECT @prodcode = [PrimaryGCAS]
	FROm dbo.[Local_PrIME_OPENREQUESTS] WITH(NOLOCK) 
	WHERE OpenTableid = @WMSid
	
	SET @count = (SELECT COUNT(1) 
							FROM [dbo].[Local_PrIME_OpenRequests] 
							WHERE [PrimaryGCAS] = @prodcode 
							AND LocationId = @LocationID)

	IF @count > 20
	BEGIN
		SET @Status = 'Short'
	END
	ELSE
	BEGIN
		SET @Status = 'Created'
	END

	UPDATE dbo.[Local_PrIME_OPENREQUESTS]
	SET	[Status]			= @Status,
		[LastUpdatedTime]	= @now
	WHERE  [OpenTableId] = @WMSid

	
	SET @WMSid = (	SELECT min([OpenTableId]) 
				FROM [dbo].[Local_PrIME_OPENREQUESTS] WITH(NOLOCK) 
				WHERE LocationId = @LOCATIONID AND Status = 'RequestMaterial'
				AND [OpenTableId] > @WMSid )
	SET @countPal = @countPal +1
END


SELECT	@OutputValue =  CONVERT(varchar(30),@countPal) + ' Pallet created'