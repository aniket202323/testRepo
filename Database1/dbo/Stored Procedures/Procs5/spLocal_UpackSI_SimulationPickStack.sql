CREATE PROCEDURE [dbo].[spLocal_UpackSI_SimulationPickStack]
		@OutputValue				varchar(25) OUTPUT,
		@ThisTime					datetime,
		@puid						int




-- ManualDebug
/*
Declare	@OutputValue	nvarchar(25)

Exec spLocal_UpackSI_SimulationPickStack
	@OutputValue				OUTPUT,
	getdate(),				
	6195

	
SELECT @OutputValue as OutputValue
*/


AS
SET NOCOUNT ON


DECLARE @SPNAME						varchar(30),
		@UserId						int,
		@userName					varchar(50),
		@Now						datetime,
		@ProdCode					varchar(30),
		@cnSiWMS					varchar(30),
		@pnLocation					varchar(30),
		@LOCATION					varchar(30),
		@triggerValue				bit,
		@WMSid						int,
		@UOMPerPallet				Int,
		@UOM						varchar(50),
		@ULID						varchar(50),
		@VendorLot					varchar(50),
		@Count						int,
		@WAMASFlag					bit,
		@RTCISSubscriptionID		int,
		@pnLineID					varchar(50),
		@LineID						varchar(25),
		@CountvendorLot				int,			--V1.9
		@vendorLotInt				bigint,			--V1.9
		@TableId					int,
		@TableFieldId				int,
		@LastEvent					varchar(25),
		@LastEventnbr				int	,
		@extis						int
------------------------------------------------------
--Variable table declaration
------------------------------------------------------
DECLARE @PRDExecInputs TABLE (
			PUID						int,
			PEIID						int,
			OG							varchar(50)

			)


DECLARE @ProdUnit TABLE 
(PUID	int)

SET @SPNAME = 'spLocal_UpackSI_SimulationPickStack'
SELECT @Now = GETDATE()
SET @Count = 0


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

INSERT INTO @ProdUnit(PUID)
SELECT  distinct a.pu_id
						FROM dbo.Equipment e								WITH(NOLOCK)
						JOIN dbo.PAEquipment_Aspect_SOAEquipment	a		WITH(NOLOCK)	ON e.equipmentid = a.Origin1EquipmentId
						JOIN dbo.property_equipment_equipmentclass pee		WITH(NOLOCK)	ON (e.EquipmentId = pee.EquipmentId)
						WHERE	 pee.Class = @cnSiWMS
							AND pee.Name <>''


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




--Removed in V1.2
--SET @WMSid = (	SELECT min(WMS_Transaction_ID) 
--				FROM dbo.Local_WMS_Transaction WITH(NOLOCK) 
--				WHERE Location = @LOCATION AND WMS_Status_ID = 1)
--Added in V1.2
SET @WMSid = (	SELECT min([OpentableId])  --1.7
				FROM [dbo].[Local_WAMAS_OPENREQUESTS] WITH(NOLOCK) 
				WHERE LineID = @lineID AND Status = 'RequestMaterial')



WHILE @WMSid IS NOT NULL
BEGIN
	SELECT @prodcode = [PrimaryGCAS]
	FROm dbo.[Local_WAMAS_OPENREQUESTS] WITH(NOLOCK) 
	WHERE OpenTableid = @WMSid
	
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

	
	SET @lastevent = ( SELECT TOP 1  ULID FROM dbo.Local_WAMAS_OpenRequests WHERE Status in('Picked','Delivered') Order by OPENTABLEID DESC )
	
	
	
	IF  @lastevent is null
	BEGIN
	SET @LastEvent =(SELECT  top 1  Event_num from events where pu_id in (SELECT  puId FROM @ProdUnit)
						ORDER BY EVENT_ID desc )
						
	SET @lastevent = SUBSTRING(@lastevent, 1,(CHARINDEX('_',@lastevent)-1))
	END

	
	
	
	IF ( convert(float,@lastevent)>999999999)
	BEGIN
		SET @LastEvent = 0
	END
	

	
--	SET @LastEventnbr = CONVERT(int,@LastEvent)

	SET @LastEventnbr = CONVERT(int,@LastEvent)
	SET @LastEventnbr =@LastEventnbr + 1

	SET  @ULID  = REPLICATE('0', 10 - lEN(@LastEventnbr)) + convert(varchar(10),@LastEventnbr)
 
  SET @extis = 0
	WHILE (@extis <> 1 )
	BEGIN
		IF (exists(select 1 FROM EVents WHERE event_num like @ULID + '_%' AND PU_ID  in (SELECT  puId FROM @ProdUnit)) OR  exists(select 1 FROM Local_WAMAS_OpenRequests WHERE ULID = @ULID))
		BEGIN
		select * FROM EVents WHERE event_num like @ULID+ '_%' AND PU_ID  in (SELECT  puId FROM @ProdUnit)
		SET @LastEventnbr = @LastEventnbr + 1
		SET  @ULID  = REPLICATE('0', 10 - lEN(@LastEventnbr)) + convert(varchar(10),@LastEventnbr)
			
		END
		ELSE
		BEGIN
		SET @extis= 1
		END
	END



	SET @VendorLot		= (	SELECT TOP 1 vendorLotId 
							FROM dbo.Local_WAMAS_OpenRequests_History 
							WHERE lineid = @LineID 
								AND vendorLotId IS NOT NULL
							ORDER BY [ModifiedOn] DESC)

	 IF @VendorLot IS NULL 
	 BEGIN
		SET @VendorLot		= (	SELECT CONVERT(varchar(30),@puid)+CONVERT(varchar(30),@ThisTime,110))
		SELECT @VendorLot	= REPLACE(@VendorLot,'-','')
		SELECT @VendorLot	= REPLACE(@VendorLot,' ','')
		SELECT @VendorLot	= REPLACE(@VendorLot,':','')
		SELECT  @VendorLot = LEFT(@VendorLot,15)
	 END

	--V1.9
	SET @CountVendorLot = (SELECT COUNT(vendorlotId) 
							FROM [dbo].[Local_WAMAS_OpenRequests_History] 
							WHERE vendorlotId = @VendorLot 
								AND [ModifiedOn] > DATEADD(dd,-1,GETDATE()))

	--SELECT @LineID, @VendorLot,@CountVendorLot

	WHILE @CountVendorLot > 5
	BEGIN

		SET @VendorLot		= (	SELECT CONVERT(varchar(30),@puid)+CONVERT(varchar(30),@ThisTime,110))
		SELECT @VendorLot	= REPLACE(@VendorLot,'-','')
		SELECT @VendorLot	= REPLACE(@VendorLot,' ','')
		SELECT @VendorLot	= REPLACE(@VendorLot,':','')
		SELECT  @VendorLot = LEFT(@VendorLot,15)


		SET @VendorLotint = CONVERT(bigINT ,@VendorLot) + CONVERT(INT,RAND()*100)
		SET @VendorLot = CONVERT(varchar(30),@VendorLotint)

		SET @CountVendorLot = (	SELECT COUNT(vendorlotId) 
								FROM [dbo].[Local_WAMAS_OpenRequests_History] 
								WHERE vendorlotId = @VendorLot 
									AND [ModifiedOn] > DATEADD(dd,-1,GETDATE()))
	END

		--SELECT @LineID, @VendorLot,@CountVendorLot

	UPDATE dbo.[Local_WAMAS_OPENREQUESTS]
	SET	ULID				= @ULID,
		[QuantityValue]	= @UOMPerPallet,
		[QuantityUOM]		= @UOM,
		VendorLotid			= @VendorLot,
		[LastUpdatedTime]	= @now,
		[Status]			= 'Picked',
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
				FROM [dbo].[Local_WAMAS_OPENREQUESTS] WITH(NOLOCK) 
				WHERE LocationId = @LOCATION AND Status = 'RequestMaterial'
				AND [OpenTableId] > @WMSid )

END






SELECT	@OutputValue =  CONVERT(varchar(30),@count) + ' Stack picked'