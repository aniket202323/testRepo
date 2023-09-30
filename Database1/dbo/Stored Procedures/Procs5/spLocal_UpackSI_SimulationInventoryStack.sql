CREATE PROCEDURE [dbo].[spLocal_UpackSI_SimulationInventoryStack]
		@OutputValue				varchar(25) OUTPUT,
		@ThisTime					datetime,
		@puid						int




-- ManualDebug
/*
Declare	@OutputValue	nvarchar(25)

Exec spLocal_UpackSI_SimulationInventoryStack
	@OutputValue				OUTPUT,
	'4-Jul-2017 14:17:44',				
	4822

	
SELECT @OutputValue as OutputValue
*/


AS
SET NOCOUNT ON


DECLARE @SPNAME							varchar(30),
		@Now							datetime,
		@ProdCode						varchar(30),
		@ProdId							int,
		@cnSiWMS						varchar(30),
		@pnLocation						varchar(30),
		@LOCATION						varchar(30),
		@WAMASFlag						bit,
		@RTCISSubscriptionID			int,
		@RequestId						varchar(50),
		@OG								varchar(4),
		@Count							int,
		@CountWait						int,
		@CapacityOriginGroupCapacity	int,
		@ULID							varchar(50),
		@Quantity						float,
		@Material						varchar(25),
		@VendorLot						varchar(50),
		@UserName						varchar(50),
		@ModifiedDate					Datetime,
		@pnLineID						varchar(50),
		@LineID							varchar(25),
		@OpentableId					int,
		@TableId						int,
		@TableFieldId					int

------------------------------------------------------
--Variable table declaration
------------------------------------------------------
DECLARE @PRDExecInputs TABLE (
			PUID						int,
			PEIID						int,
			OG							varchar(50)

			)



SET @SPNAME = 'spLocal_UpackSI_SimulationInventoryStack'
SELECT @Now = GETDATE()


SET @RTCISSubscriptionID = (SELECT Subscription_Id
							FROM dbo.Subscription
							WHERE Subscription_Desc = 'WMS')	


SET @TableId		= (	SELECT	t.TableID			FROM dbo.Tables t			WITH (NOLOCK) WHERE upper(t.TableName)			= 'SUBSCRIPTION')
SET @TableFieldId	= (	SELECT	tf.Table_Field_ID	FROM dbo.Table_Fields tf	WITH (NOLOCK) WHERE upper(tf.Table_Field_Desc)	= 'USE_WAMAS' and tf.TableId = @TableId)
	
SET @WAMASFlag		= (	SELECT	CONVERT(bit, tfv.Value)
						FROM	dbo.Table_Fields_Values tfv	WITH(NOLOCK)
						WHERE	tfv.KeyId			=	@RTCISSubscriptionID
						and		tfv.Table_Field_Id	=	@TableFieldId
						and		tfv.TableId			=	@TableId);

IF @WAMASFlag = 1
	RETURN

--get the location from the SOA property

SET @cnSiWMS	=	'PE:SI_WMS'
SET @pnLineID	=	'Destination LineID'

SET	@LineID	=		(SELECT  convert(varchar(50), pee.Value)
						FROM dbo.Equipment e								WITH(NOLOCK)
						JOIN dbo.PAEquipment_Aspect_SOAEquipment	a		WITH(NOLOCK)	ON e.equipmentid = a.Origin1EquipmentId
						JOIN dbo.property_equipment_equipmentclass pee		WITH(NOLOCK)	ON (e.EquipmentId = pee.EquipmentId)
						WHERE	a.pu_id = @puid
							AND pee.Class = @cnSiWMS
							AND pee.Name = @pnLineID )


IF @LineID IS NULL 
BEGIN
	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
				GETDATE(),
				'0100 - ' +
				' @LineID not found'	,
				@puid			)
	
	SELECT	@OutputValue =  '@LineID not found'
	RETURN
END
SET @pnLocation	=	'Destination Location'

SET	@LOCATION	=		(SELECT  convert(varchar(50), pee.Value)
						FROM dbo.Equipment e								WITH(NOLOCK)
						JOIN dbo.PAEquipment_Aspect_SOAEquipment	a		WITH(NOLOCK)	ON e.equipmentid = a.Origin1EquipmentId
						JOIN dbo.property_equipment_equipmentclass pee		WITH(NOLOCK)	ON (e.EquipmentId = pee.EquipmentId)
						WHERE	a.pu_id = @puid
							AND pee.Class = @cnSiWMS
							AND pee.Name = @pnLocation )


IF @LOCATION IS NULL 
BEGIN
	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
				GETDATE(),
				'0100 - ' +
				' Destination not found'	,
				@puid			)
	
	SELECT	@OutputValue =  'Destination not found'
	RETURN
END

--V1.2
IF EXISTS(	SELECT OpenTableId 
			FROM  [dbo].[Local_WAMAS_OPENREQUESTS]
			WHERE  	LineID = @LineID
				AND status = 'Delivered')
BEGIN
	SET @OpentableId = (	SELECT TOP 1 OpenTableId 
						FROM  [dbo].[Local_WAMAS_OPENREQUESTS]
						WHERE  	LineID = @LineID
							AND status = 'Delivered'
						ORDER BY RequestTime ASC
							)


	--Need to get the Capacity of the storage location.
	--1) get the product
	--2) get the OG
	--3 find the capacity from the SOA property

	SET @ProdId = (	SELECT p.prod_id
					FROM dbo.[Local_WAMAS_OPENREQUESTS] wor		WITH(NOLOCK)
					JOIN dbo.products_base p					WITH(NOLOCK) ON wor.GCAS = p.prod_code
					WHERE wor.OpenTableId = @OpentableId )


	--Get OG for SOA model
	SET @OG = (	SELECT convert(varchar(50), pmm.Value)
								FROM dbo.Property_MaterialDefinition_MaterialClass pmm	WITH(NOLOCK)
								JOIN [dbo].[Products_Aspect_MaterialDefinition] pam		WITH(NOLOCK) ON pmm.materialDefinitionId = pam.[Origin1MaterialDefinitionId]
								WHERE pam.prod_id = @ProdId
									AND pmm.Name = 'Origin Group')

	--get capacity
	SET @CapacityOriginGroupCapacity =	( SELECT convert(varchar(50), pee.Value)
										FROM dbo.property_equipment_equipmentclass pee		WITH(NOLOCK) 
										JOIN [dbo].[PAEquipment_Aspect_SOAEquipment] pae	WITH(NOLOCK) ON pae.Origin1EquipmentId= pee.EquipmentId
										WHERE	pae.[PU_Id] = @puid
											AND pee.Name = 'Capacity' + ' ' +  @OG + '.' + 'Origin Group' +' '+'Capacity')


	
	SET @Count = (	SELECT COUNT(event_id) 
					FROM dbo.events	e				WITH(NOLOCK) 
					JOIN dbo.production_status ps	WITH(NOLOCK) ON e.event_status = ps.prodStatus_id
					WHERE e.pu_id = @puid
						AND ps.prodStatus_Desc IN ('Delivered', 'Running', 'To Be Returned'))

	--Get pallet that are to be returned, but no more on the plant floor
	SET @CountWait = (	SELECT COUNT(OpenTableId) 
						FROM dbo.[Local_WAMAS_OPENREQUESTS] wor		WITH(NOLOCK)
						WHERE LineID = @lineid
							AND [Status] = 'ToBeReturned')


	
	SET @Count = @Count - @CountWait


	IF @Count<@CapacityOriginGroupCapacity
	BEGIN
		SELECT	@ULID = [ULID],
				@Quantity = [QuantityValue],
				@Material = [GCAS],
				@VendorLot = [VendorLotID],
				@UserName = 'System.pe',
				@ModifiedDate = GETDATE()
		FROM  [dbo].[Local_WAMAS_OPENREQUESTS]  WITH(NOLOCK)
		WHERE OpenTableId = @OpentableId


		EXEC dbo.[spLocal_CmnSICreateStack] @ULID,@Quantity,@Location,@Material,@VendorLot,@UserName,@ModifiedDate

	END
END

SELECT	@OutputValue =  CONVERT(varchar(30),@thisTime)