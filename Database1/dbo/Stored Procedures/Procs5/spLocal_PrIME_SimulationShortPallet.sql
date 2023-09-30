CREATE PROCEDURE [dbo].[spLocal_PrIME_SimulationShortPallet]

@OutputValue				varchar(25) OUTPUT,
@ThisTime					datetime,
@puid						int




-- ManualDebug
/*
Declare	@OutputValue	nvarchar(25)

Exec spLocal_PrIME_SimulationShortPallet
	@OutputValue				OUTPUT,
	'20-Aug-2018 17:10',				
	2002

	
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
		@TimeStamp					datetime
------------------------------------------------------
--Variable table declaration
------------------------------------------------------
DECLARE @PRDExecInputs TABLE (
			PUID						int,
			PEIID						int,
			OG							varchar(50)

			)



SET @SPNAME = 'spLocal_PrIME_SimulationShortPallet'
SELECT @Now = GETDATE()
SET @Count = 0



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
				WHERE LocationID = @LocationID AND Status = 'Short')

SET @count = 0

WHILE @WMSid IS NOT NULL
BEGIN
	
	SET @Status = 'Created'
	
	SET @TimeStamp  = (SELECT [LastUpdatedTime]
	FROM [dbo].[Local_PrIME_OPENREQUESTS] WITH(NOLOCK)
	WHERE  [OpenTableId] = @WMSid)

	IF Datediff(MINUTE,@TimeStamp ,@now) > 3
	BEGIN

		UPDATE dbo.[Local_PrIME_OPENREQUESTS]
		SET	[LastUpdatedTime]	= @now,
			[Status]			= @Status
		WHERE  [OpenTableId] = @WMSid
		SET @count =  @count + 1 
	END
	
	SET @WMSid = (	SELECT min([OpenTableId]) 
				FROM [dbo].[Local_PrIME_OPENREQUESTS] WITH(NOLOCK) 
				WHERE LocationId = @LOCATIONID AND Status = 'Short'
				AND [OpenTableId] > @WMSid )

END


SELECT	@OutputValue =  CONVERT(varchar(30),@count) + ' Pallet created'