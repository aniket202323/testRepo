
--------------------------------------------------------------------------------------------------
-- Author				: Julien B. Ethier
-- Date created			: 2021-01-15
-- Version 				: 1.0
-- SP Type				: Calculation
-- Caller				: 
-- Description			: Simulation for Prime.  Change Open request status to Delivered
-- Editor tab spacing	: 4
--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
--================================================================================================
-- 1.0		2021-01-15		Julien B. Ethier		Created from PE's spLocal_MPWS_CmnPrIMESimulationDeliveredPallet
--------------------------------------------------------------------------------------------------


CREATE PROCEDURE [dbo].[spLocal_MPWS_CmnPrIMESimulationDeliveredPallet]
		@OutputValue				varchar(25) OUTPUT,
		@ThisTime					datetime,
		@puid						int




-- ManualDebug
/*
selecT* from Local_Prime_openrequests
Declare	@OutputValue	nvarchar(25)

Exec spLocal_MPWS_CmnPrIMESimulationDeliveredPallet
	@OutputValue				OUTPUT,
	'2018-08-29 20:35',				
	1938

	
SELECT @OutputValue as OutputValue
*/


AS
SET NOCOUNT ON


DECLARE @SPNAME						varchar(30),
		@Now						datetime,
		@ProdCode					varchar(30),
		@cnPrimeWMS					varchar(30),
		@pnLocationID				varchar(30),
		@LOCATIONID					varchar(30),
		@PrIMESFlag					bit,
		@WMSSubscriptionID			int,
		@OpenTableID				int,
		@pathID						int,
		@TableID					int,
		@SimulatorUDP				int,
		@usePrIMESimulator			int,
		@TableFieldId				int




SET @SPNAME = 'spLocal_MPWS_CmnPrIMESimulationDeliveredPallet'
SELECT @Now = GETDATE()


SET @WMSSubscriptionID = (	SELECT	s.Subscription_Id
							FROM	dbo.Subscription s
							WHERE	s.Subscription_Desc = 'WMS')	


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
			FROM dbo.PrdExec_Path_Units ppu		WITH(NOLOCK)
			WHERE ppu.PU_Id = @PuID
			)


SET @TableID = (SELECT TableID FROM  dbo.Tables t WITH(NOLOCK) where tableName = 'PrdExec_Paths')
SET @SimulatorUDP = (SELECT Table_Field_ID FROM dbo.Table_Fields tf WITH(NOLOCK) WHERE Table_Field_Desc like 'PPW_Generic_SimulatePrIME' AND @TableID = TableID)
SET @usePrIMESimulator = COALESCE((SELECT Value FROM dbo.Table_Fields_Values tfv WITH(NOLOCK) WHERE Table_Field_ID = @SimulatorUDP AND keyID = @PathID),0)



IF @usePrIMESimulator =0
	RETURN


--get t
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

IF EXISTS(	SELECT OpenTableId 
			FROM  [dbo].[Local_PrIME_OPENREQUESTS]
			WHERE LocationID = @LocationID 
				AND status = 'Picked')
BEGIN
	SET @OpenTableID = (	SELECT TOP 1 OpenTableId 
						FROM  [dbo].[Local_PrIME_OPENREQUESTS]
						WHERE LocationID = @LocationID 
							AND status = 'Picked'
						ORDER BY RequestTime ASC
							)

	UPDATE dbo.[Local_PrIME_OPENREQUESTS]
	SET	
		[LastUpdatedTime]		= @now,
		status = 'Delivered'
	WHERE	OpenTableId = @OpenTableID
	
END

SELECT	@OutputValue =  CONVERT(varchar(30),@thisTime)


