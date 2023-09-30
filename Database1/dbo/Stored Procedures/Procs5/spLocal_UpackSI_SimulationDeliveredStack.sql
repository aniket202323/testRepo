CREATE PROCEDURE [dbo].[spLocal_UpackSI_SimulationDeliveredStack]
		@OutputValue				varchar(25) OUTPUT,
		@ThisTime					datetime,
		@puid						int




-- ManualDebug
/*
Declare	@OutputValue	nvarchar(25)

Exec spLocal_UpackSI_SimulationDeliveredStack
	@OutputValue				OUTPUT,
	'2017-11-08 11:45',				
	4822

	
SELECT @OutputValue as OutputValue
*/


AS
SET NOCOUNT ON


DECLARE @SPNAME						varchar(30),
		@Now						datetime,
		@ProdCode					varchar(30),
		@cnSiWMS					varchar(30),
		@pnLocation					varchar(30),
		@LOCATION					varchar(30),
		@WAMASFlag					bit,
		@RTCISSubscriptionID		int,
		@pnLineID					varchar(50),
		@LineID						varchar(25),
		@OpenTableID				int,
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



SET @SPNAME = 'spLocal_UpackSI_SimulationDeliveredStack'
SELECT @Now = GETDATE()


SET @RTCISSubscriptionID = (SELECT Subscription_Id
							FROM dbo.Subscription
							WHERE Subscription_Desc = 'WMS')	


SET @TableId		= (SELECT	t.TableID			FROM dbo.Tables t			WITH (NOLOCK) WHERE upper(t.TableName)			= 'SUBSCRIPTION')
SET @TableFieldId	= (SELECT	tf.Table_Field_ID	FROM dbo.Table_Fields tf	WITH (NOLOCK) WHERE upper(tf.Table_Field_Desc)	= 'USE_WAMAS' and tf.TableId = @TableId)
	
SET @WAMASFlag = (	SELECT	CONVERT(bit, tfv.Value)
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
			WHERE  	LineId = @LineID
				AND status = 'Picked')
BEGIN
	SET @OpenTableID = (	SELECT TOP 1 OpenTableId 
						FROM  [dbo].[Local_WAMAS_OPENREQUESTS]
						WHERE  	LineId = @LineID
							AND status = 'Picked'
						ORDER BY RequestTime ASC
							)

	UPDATE dbo.[Local_WAMAS_OPENREQUESTS]
	SET	
		[LastUpdatedTime]		= @now,
		status = 'Delivered'
	WHERE	OpenTableId = @OpenTableID
	
END

SELECT	@OutputValue =  CONVERT(varchar(30),@thisTime)