CREATE PROCEDURE [dbo].[spLocal_PrIME_SimulationPickPallet]

@OutputValue				varchar(25) OUTPUT,
@ThisTime					datetime,
@puid						int




-- ManualDebug
/*
Declare	@OutputValue	nvarchar(25)

Exec spLocal_PrIME_SimulationPickPallet
	@OutputValue				OUTPUT,
	'29-Aug-2018 14:55',				
	1938

	
SELECT @OutputValue as OutputValue
*/


AS
SET NOCOUNT ON


DECLARE @SPNAME						varchar(50),
		@UserId						int,
		@userName					varchar(50),
		@Now						datetime,
		@TableID					int,
		@SimulatorUDP				int,
		@PathId						int,
		@usePrIMESimulator			int,
		@ProdCode					varchar(30),
		@cnPrIMEWMS					varchar(30),
		@triggerValue				bit,
		@WMSid						int,
		@UOMPerPallet				Int,
		@UOM						varchar(50),
		@ULID						varchar(50),
		@Batch						varchar(50),
		@Count						int,
		@PrIMESFlag					bit,
		@WMSSubscriptionID			int,
		@pnLocationID					varchar(50),
		@LocationID					varchar(50),
		@CountBatch					int,			--V1.9
		@BatchInt					bigint	,
		@PorpertyBatchNumber		nvarchar(255),
		@ProdID						int,
		@TableFieldId				int
------------------------------------------------------
--Variable table declaration
------------------------------------------------------
DECLARE @PRDExecInputs TABLE (
			PUID						int,
			PEIID						int,
			OG							varchar(50)

			)

			

SET @SPNAME = 'spLocal_PrIME_SimulationPickPallet'
SELECT @Now = GETDATE()
SET @Count = 0

SET @PorpertyBatchNumber	='RTCISSimulatorBatchID'

	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
				GETDATE(),
				'0100 - ' +
				' @excuting'	,
				@puid			)


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

If @PathId is null
BEGIN
	SET @TableId		= (SELECT	t.TableID			FROM dbo.Tables t			WITH (NOLOCK) WHERE upper(t.TableName)			= 'PROD_UNITS')
	SET @TableFieldId	= (SELECT	tf.Table_Field_ID	FROM dbo.Table_Fields tf	WITH (NOLOCK) WHERE upper(tf.Table_Field_Desc)	= 'PE_SHAREDLOC_SIMULATEPRIME' and tf.TableId = @TableId)
	
	SET @usePrIMESimulator = (	SELECT	CONVERT(bit, tfv.Value)
								FROM	dbo.Table_Fields_Values tfv	WITH(NOLOCK)
								WHERE	tfv.KeyId			=	@PUID
								and		tfv.Table_Field_Id	=	@TableFieldId
								and		tfv.TableId			=	@TableId);
END


IF @PrIMESFlag = 0
	RETURN

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



	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
				GETDATE(),
				'0100 - ' +
				' @excuting'	+ coalesce(@LocationID,''),
				@puid			)


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
				WHERE LocationID = @LocationID AND Status = 'Created')



	--INSERT local_debug (CallingSP,timestamp, message, msg)
	--VALUES (	@SPNAME,
	--			GETDATE(),
	--			'0100 - ' +
	--			' @excuting'	+ coalesce(convert(varchar(50),@WMSid),''),
	--			@puid			)
WHILE @WMSid IS NOT NULL
BEGIN
	SELECT @prodcode = [PrimaryGCAS]
	FROm dbo.[Local_PrIME_OPENREQUESTS] WITH(NOLOCK) 
	WHERE OpenTableid = @WMSid
	
	SET @ProdID = (SELECT Prod_Id FROM  dbo.Products_Base WITH(NOLOCK)  WHERE Prod_Code = @ProdCode)
	SET @UOMPerPallet = (	SELECT convert(varchar(50), pmm.Value)
							FROM dbo.Property_MaterialDefinition_MaterialClass pmm	WITH(NOLOCK)
							JOIN dbo.Products_Aspect_MaterialDefinition	a			WITH(NOLOCK)	ON pmm.MaterialDefinitionId = Origin1MaterialDefinitionId
							JOIN dbo.Products p										WITH (NOLOCK)	ON (p.Prod_id = a.prod_id)
							WHERE p.Prod_Code = @prodcode
								AND pmm.Name = 'UOM Per Pallet')



	SET @UOM			= (	SELECT convert(varchar(50), pmm.Value)
							FROM dbo.Property_MaterialDefinition_MaterialClass pmm	WITH(NOLOCK)
							JOIN dbo.Products_Aspect_MaterialDefinition	a			WITH(NOLOCK)	ON pmm.MaterialDefinitionId = Origin1MaterialDefinitionId
							JOIN dbo.Products p										WITH (NOLOCK)	ON (p.Prod_id = a.prod_id)
							WHERE p.Prod_Code = @prodcode
								AND pmm.Name = 'UOM')




--V1.9  New ULID format
	--SET @ULID = CONVERT(varchar(3),CONVERT(int, rand() * 100))
	SET @ULID = '00' + CONVERT(varchar(30),@WMSid)
	SET @ULID = @ULID + CONVERT(varchar(10),@puid) 
	SET @ULID = @ULID + CONVERT(varchar(10),DATEPART(YYYY, @ThisTime))
	SET @ULID = @ULID + CONVERT(varchar(10),DATEPART(MM, @ThisTime))
	SET @ULID = @ULID + CONVERT(varchar(10),DATEPART(DD, @ThisTime))
	SET @ULID = @ULID + CONVERT(varchar(10),DATEPART(HH, @ThisTime))
	--SET @ULID = @ULID + CONVERT(varchar(10),DATEPART(Mi, @ThisTime))

	--select @ULID
	SET @ULID = substring(@ULID, 1,20)
	--get 20 chars
	IF LEN(@ULID) < 20
	BEGIN
		SET @ULID = (SELECT REPLICATE('0', 20 - DATALENGTH(@ULID)) + @ULID)
	END



	SET @Batch = (SELECT	convert(varchar(25),pmdmc.value)
							FROM	[dbo].Property_MaterialDefinition_MaterialClass pmdmc WITH(NOLOCK)
								JOIN [dbo].MaterialDefinition md WITH(NOLOCK) ON pmdmc.MaterialDefinitionId = md.MaterialDefinitionid
							JOIN [dbo].Products_Aspect_MaterialDefinition a	WITH(NOLOCK)	ON md.MaterialDefinitionID = a.Origin1MaterialDefinitionID
							WHERE	a.prod_id = @ProdID
								AND pmdmc.Name = @PorpertyBatchNumber)


	IF @Batch IS NULL
		SET @Batch = '0000000000'


	UPDATE dbo.[Local_PrIME_OPENREQUESTS]
	SET	ULID				= @ULID,
		[QuantityValue]	= @UOMPerPallet,
		[QuantityUOM]		= @UOM,
		Batch			= @Batch,
		[LastUpdatedTime]	= @now,
		[Status]			= 'InTransit',
		CurrentLocation = 'Conveyor',
		[GCAS]				= @prodcode
	WHERE  [OpenTableId] = @WMSid

	
	SET @count = @count +1

	-- get the next OR
	--SET @WMSid = (	SELECT min(WMS_Transaction_ID) 
	--				FROM dbo.Local_WMS_Transaction WITH(NOLOCK) 
	--				WHERE	Location = @LOCATION 
	--					AND WMS_Status_ID = 1
	--					AND WMS_Transaction_ID > @WMSid )

	SET @WMSid = (	SELECT min([OpenTableId]) 
				FROM [dbo].[Local_PrIME_OPENREQUESTS] WITH(NOLOCK) 
				WHERE LocationId = @LOCATIONID AND Status = 'Created'
				AND [OpenTableId] > @WMSid )

END






SELECT	@OutputValue =  CONVERT(varchar(30),@count) + ' Stack In Transit'