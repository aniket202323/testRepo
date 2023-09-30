
--------------------------------------------------------------------------------------------------
-- Author				: Julien B. Ethier
-- Date created			: 15-Jan-2021
-- Version 				: 1.0
-- SP Type				: Calculation
-- Caller				: 
-- Description			:  Simulation for PrIME. Create pallet in PPA if there is room to
-- Editor tab spacing	: 4
--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
--================================================================================================
-- 1.0		15-Jan-2021		Julien B. Ethier	Created from PE's spLocal_PrIME_SimulationInventoryPallet

--------------------------------------------------------------------------------------------------




CREATE PROCEDURE [dbo].[spLocal_MPWS_CmnPrIMESimulationInventoryPallet]
		@OutputValue				varchar(25) OUTPUT,
		@ThisTime					datetime,
		@puid						int




-- ManualDebug
/*
Declare	@OutputValue	nvarchar(25)

Exec spLocal_MPWS_CmnPrIMESimulationInventoryPallet
	@OutputValue				OUTPUT,
	'2019-02-14 13:01:44',				
	5636

	
SELECT @OutputValue as OutputValue
*/


AS
SET NOCOUNT ON


DECLARE @SPNAME							varchar(30),
		@Now							datetime,
		@ProdCode						varchar(30),
		@ProdId							int,
		@cnPrIMEWMS						varchar(30),
		@pnLocationID					varchar(30),
		@LOCATIONID						varchar(50),
		@PrIMEsFlag						bit,
		@WMSSubscriptionID				int,
		@RequestId						varchar(50),
		@OG								varchar(4),
		@Count							int,
		@CountWait						int,
		@CapacityOriginGroupCapacity	int,
		@ULID							varchar(50),
		@Quantity						float,
		@Material						varchar(8),
		@VendorLot						varchar(50),
		@UserName						varchar(50),
		@ModifiedDate					Datetime,
		@OpentableId					int,
		@Batch							varchar(50),
		@PathId							int,
		@TableID						int,
		@SimulatorUDP					int,
		@usePrIMESimulator				int,
		@ErroCode						int,
		@CreateEventonDelivery			int,
		@CreateEventonDeliveryUDP		varchar(50),
		@TableProdUnits					int,
		@TableFieldId					int

------------------------------------------------------
--Variable table declaration
------------------------------------------------------
DECLARE @PRDExecInputs TABLE (
			PUID						int,
			PEIID						int,
			OG							varchar(50)

			)

DECLARE @OpenRequest TABLE(
Id					int IDENTITY(1,1),
OpentableId			int)



SET @SPNAME = 'spLocal_MPWS_CmnPrIMESimulationInventoryPallet'
SELECT @Now = GETDATE()



SET @WMSSubscriptionID = (SELECT Subscription_Id
							FROM dbo.Subscription
							WHERE Subscription_Desc = 'WMS')	

SET @TableId		= (SELECT	t.TableID			FROM dbo.Tables t			WITH (NOLOCK) WHERE upper(t.TableName)			= 'SUBSCRIPTION')
SET @TableFieldId	= (SELECT	tf.Table_Field_ID	FROM dbo.Table_Fields tf	WITH (NOLOCK) WHERE upper(tf.Table_Field_Desc)	= 'USE_PRIME' and tf.TableId = @TableId)

SET @PrIMESFlag  =	(	SELECT	tfv.Value
						FROM	dbo.Table_Fields_Values tfv	WITH(NOLOCK)
						WHERE	tfv.KeyId			=	@WMSSubscriptionID	
						and		tfv.Table_Field_Id	=	@TableFieldId
						and		tfv.TableId			=	@TableID			
					)

IF @PrIMESFlag = 0
	RETURN


SET @PathId = (	SELECT TOP 1 ppu.path_id
			FROM dbo.PrdExec_Path_Units ppu	WITH(NOLOCK)		
			WHERE ppu.PU_Id = @puid
			)


SET @TableID			= (SELECT TableID FROM  dbo.Tables t WITH(NOLOCK) where tableName = 'PrdExec_Paths')
SET @SimulatorUDP		= (SELECT Table_Field_ID FROM dbo.Table_Fields tf WITH(NOLOCK) WHERE Table_Field_Desc like 'PPW_Generic_SimulatePrIME' AND @TableID = TableID)
SET @usePrIMESimulator	= COALESCE((SELECT Value FROM dbo.Table_Fields_Values tfv WITH(NOLOCK) WHERE Table_Field_ID = @SimulatorUDP AND keyID = @PathID),0)


IF @usePrIMESimulator =0
	RETURN

--get the location from the SOA property

SET @cnPrIMEWMS	=	'PPW:PrIME_WMS'

SET @pnLocationID	=	'PPWLocationID'

SET	@LocationID	=		(SELECT  convert(varchar(50), pee.Value)
						FROM dbo.Equipment e								WITH(NOLOCK)
						JOIN dbo.PAEquipment_Aspect_SOAEquipment	a		WITH(NOLOCK)	ON e.equipmentid = a.Origin1EquipmentId
						JOIN dbo.property_equipment_equipmentclass pee		WITH(NOLOCK)	ON (e.EquipmentId = pee.EquipmentId)
						WHERE	a.pu_id = @puid
							AND pee.Class = @cnPrIMEWMS
							AND pee.Name = @pnLocationID )


SET @TableProdUnits = (SELECT TABLEID  FROM dbo.Tables WITH(NOLOCK)WHERE TableName ='Prod_Units' )

SET @CreateEventonDeliveryUDP = (SELECT Table_Field_ID FROM dbo.Table_Fields tf WITH(NOLOCK) WHERE Table_Field_Desc  ='PPW_PPA_CreateEventOnDelivery' AND TableId = @TableProdUnits)
SET @CreateEventonDelivery = (SELECT Value FROM dbo.Table_Fields_Values tfv WITH(NOLOCK) WHERE Table_Field_Id = @CreateEventonDeliveryUDP ANd TableId = @TableProdUnits AND KEYID =  @puid)




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

INSERT @OpenRequest (OpentableId)
SELECT OpenTableId 
			FROM  [dbo].[Local_PrIME_OPENREQUESTS]
			WHERE  	LocationID = @LocationID
				AND status = 'Delivered'


 
SET @OpentableId = (	SELECT MIN(OpentableId) FROM @OpenRequest	)
WHILE @OpentableId IS NOT NULL
BEGIN


	--Need to get the Capacity of the storage location.
	--1) get the product
	--2) get the OG
	--3 find the capacity from the SOA property
	IF COALESCE(@CreateEventonDelivery ,1) =0
	BEGIN
		-- PPA do not need to be created , set the local_prime_OpenRequest to Consumed 		
	
		 UPDATE   [dbo].[Local_PrIME_OPENREQUESTS] 
		 SET Status =  'Consumed',
		 LastUpdatedTime =getdate()
		 WHERE OpenTableId = @OpentableId
	 
		INSERT into Local_Debug(Timestamp, CallingSP, Message) 
		VALUES(	getdate(), 
				@SPNAME,
					'0176  OpenREquest is consumed : '  + convert(varchar(40),coalesce(@OpentableId,''))		)				
	
	
		DELETE FROM   [dbo].[Local_PrIME_OPENREQUESTS]   WHERE OpenTableId = @OpentableId

	END
	ELSE
	BEGIN
		
		SET @ProdId = (	SELECT p.prod_id
						FROM dbo.[Local_PrIME_OPENREQUESTS] wor		WITH(NOLOCK)
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
	
			
		SELECT	@ULID = [ULID],
					@Quantity = [QuantityValue],
					@Material = [GCAS],
					@Batch = Batch,
					@UserName = 'System.pe',
					@ModifiedDate = GETDATE()
			FROM  [dbo].[Local_PrIME_OPENREQUESTS]  WITH(NOLOCK)
			WHERE OpenTableId = @OpentableId

		EXEC dbo.[spLocal_CmnPrIMECreateDeliveredPallet] @ErroCode OUTPUT,@ULID,@Material,@Batch,@ModifiedDate, @LocationID, @Quantity,@UserName

			
	END
	SET @OpentableId = (SELECT MIN(OpentableId) FROM @OpenRequest WHERE OpentableId > @OpentableId	)
	
END


SELECT	@OutputValue =  CONVERT(varchar(30),@thisTime)


