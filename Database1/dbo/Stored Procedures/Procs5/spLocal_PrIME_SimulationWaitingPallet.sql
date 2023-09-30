CREATE PROCEDURE [dbo].[spLocal_PrIME_SimulationWaitingPallet]

@OutputValue				varchar(25) OUTPUT,
@ThisTime					datetime,
@puid						int




-- ManualDebug
/*
Declare	@OutputValue	nvarchar(25)

Exec spLocal_PrIME_SimulationWaitingPallet
	@OutputValue				OUTPUT,
	'20-Sep-2018 16:32',				
	2002


	
SELECT @OutputValue as OutputValue
*/


AS
SET NOCOUNT ON


DECLARE @SPNAME						varchar(30),
		@UserId						int,
		@userName					varchar(50),
		@Now						datetime,
		@TableID					int,
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
		@pnLocationID				varchar(50),
		@LocationID					varchar(25),
		@CountBatch					int,			
		@BatchInt					bigint,
		@TableFieldId				int
------------------------------------------------------
--Variable table declaration
------------------------------------------------------
DECLARE @PRDExecInputs TABLE (
			PUID						int,
			PEIID						int,
			OG							varchar(50)

			)



SET @SPNAME = 'spLocal_PrIME_SimulationWaitingPallet'
SELECT @Now = GETDATE()
SET @Count = 0




SET @PathId = (	SELECT TOP 1 ppu.path_id
			FROM dbo.prdExec_Input_Sources peis		WITH(NOLOCK)
			JOIN dbo.prdExec_Inputs pei				WITH(NOLOCK) ON pei.pei_id = peis.pei_id AND peis.pu_id = @PuID
			JOIN dbo.PrdExec_Path_Units ppu			WITH(NOLOCK) ON pei.pu_id = ppu.pu_id 
			)

EXEC		[splocal_CmnGetWMSSystemUDPs] @PathId, NULL ,@PrIMESFlag output,NULL ,NULL,@usePrIMESimulator output


IF @PrIMESFlag = 0
	RETURN

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

SET @WMSid = (	SELECT min([OpentableId]) 
				FROM [dbo].[Local_PrIME_OPENREQUESTS] WITH(NOLOCK) 
				WHERE LocationID = @LocationID AND Status = 'InTransit')



WHILE @WMSid IS NOT NULL
BEGIN
	

		--SELECT @LineID, @VendorLot,@CountVendorLot

	UPDATE dbo.[Local_PrIME_OPENREQUESTS]
	SET	
		[LastUpdatedTime]	= @now,
		CurrentLocation = 'PREP OUT',
		[Status]			= 'InTransit/Waiting'
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
				WHERE LocationId = @LOCATIONID AND Status = 'InTransit'
				AND [OpenTableId] > @WMSid )

END






SELECT	@OutputValue =  CONVERT(varchar(30),@count) + ' Stack in transit'