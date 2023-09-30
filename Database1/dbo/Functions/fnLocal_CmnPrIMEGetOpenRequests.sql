-- SELECT * FROM [dbo].[fnLocal_CmnPrIMEGetOpenRequests]('PESCO03')
--================================================================================================
CREATE FUNCTION [dbo].[fnLocal_CmnPrIMEGetOpenRequests]
(
	@PathCode			varchar(50)
)
RETURNS 
@MaterialRequests TABLE
(
	OpenTableId			int,
	RequestId			varchar(50),
	RequestTime			datetime,
	LocationId			varchar(50),
	CurrentLocation		varchar(50),
	ULID				varchar(50), 
	Batch				varchar(10), 
	ProcessOrder		varchar(50),
	PrimaryGCas			varchar(50),
	AlternateGCas		varchar(50),	
	GCas				varchar(50),				
	QuantityValue		float,
	QuantityUoM			varchar(50),
	[Status]			varchar(50),		
	EstimatedDelivery	datetime,
	LastUpdatedTime		datetime,
	UserId				int,
	EventId				int
)
AS
BEGIN
	
	DECLARE
	--For debug 
	@CurrentTime						datetime,
	@DefaultUserId						int,
	@ErrMsg								varchar(1000),	
	@TimeStamp							datetime,
	@CallingSP							varchar(50),
	@Query								varchar(max),

	@PathId								int,
	@TableIdPrdExecInput				int,
	@TFIDOG								int,
	@TFIDPEWMSType						int,
	@ppid								int,
	@BOMFormId							int,
	@TableID							int,
	@PUID								int

	DECLARE @ProdUnits TABLE 
	(
		EquipmentId		varchar(50),
		PUId			int,
		PUDesc			varchar(50)
	)

	DECLARE @RMIs TABLE
	(
		PEIId			int,
		InputOG			varchar(30),
		PEWMSType		varchar(50),
		PUId			int,
		ULINPUId		int,
		LocationId		varchar(50)

	)

	INSERT INTO @ProdUnits (PUId, PUDesc)
	SELECT pu.Pu_ID, Pu_Desc 
	FROM dbo.PrdExec_Path_Units ppu WITH(NOLOCK)
	JOIN dbo.Prod_Units_Base pu			WITH(NOLOCK) ON ppu.PU_Id = pu.PU_Id														
	WHERE Path_Id IN (SELECT Path_Id FROM Prdexec_Paths WHERE Path_Code = @PathCode);

	--Get TableId for PrdExec_Inputs
	SET @TableIdPrdExecInput = (SELECT TableId FROM dbo.Tables WITH(NOLOCK) WHERE TableName = 'PrdExec_Inputs')

	--Get Table_Field_Id for 'Origin Group'
	SET @TFIDOG = (SELECT Table_Field_Id FROM dbo.Table_Fields WITH(NOLOCK) WHERE	TableId = @TableIdPrdExecInput 
																					AND table_field_desc = 'Origin Group')

	--Get Table_Field_Id for 'PE_WMS_Type'
	SET @TFIDPEWMSType = (SELECT Table_Field_Id FROM dbo.Table_Fields WITH(NOLOCK) WHERE TableId = @TableIdPrdExecInput 
																						AND table_field_desc = 'PE_WMS_System')

	INSERT @RMIs (	PEIId, 
					InputOG, 
					PEWMSType, 
					pei.PUId, 
					ULINPUId)
	SELECT	pei.pei_id,
			tfv.value,
			tfv2.value,
			pei.PU_Id,
			peis.PU_Id
		FROM dbo.PrdExec_Inputs pei				WITH(NOLOCK)
		JOIN dbo.PrdExec_Input_Sources peis		WITH(NOLOCK) ON pei.PEI_Id = peis.PEI_Id
		JOIN dbo.Table_Fields_Values tfv		WITH(NOLOCK) ON	tfv.KeyId = pei.PEI_Id
																AND tfv.Table_Field_Id = @TFIDOG
		LEFT JOIN dbo.table_fields_values tfv2	WITH(NOLOCK) ON	tfv2.KeyId = pei.PEI_Id
																AND tfv2.Table_Field_Id = @TFIDPEWMSType
		WHERE pei.PU_Id IN (SELECT PUId FROM @ProdUnits)

	DELETE @RMIs WHERE (PEWMSType IS NULL OR PEWMSType <> 'PrIME')

	-- Get Destination location for all input sources
	UPDATE rmi
		SET LocationId = CONVERT(VARCHAR(50),peec.Value)
		FROM @RMIs rmi
		JOIN dbo.PAEquipment_Aspect_SOAEquipment a		WITH(NOLOCK) ON rmi.ULINPUId = a.PU_Id
		JOIN dbo.Property_Equipment_EquipmentClass peec	WITH(NOLOCK) ON peec.EquipmentId = a.Origin1EquipmentId
		WHERE	peec.class = 'PE:PrIME_WMS'
				AND peec.name = 'LocationId'	
	

	INSERT INTO @MaterialRequests
	SELECT	OpenTableId,
			RequestId,
			RequestTime,
			LocationId,
			CurrentLocation,
			ULID, 
			Batch, 
			ProcessOrder,
			PrimaryGCas,
			AlternateGCas,	
			GCas,				
			QuantityValue,
			QuantityUoM,
			[Status],		
			EstimatedDelivery,
			LastUpdatedTime,
			UserId,
			EventId
	FROM	dbo.[Local_PrIME_OpenRequests] WITH(NOLOCK)
	WHERE	OpenTableId IS NOT NULL
			AND LocationId IN (SELECT LocationId FROM @RMIs)
			AND [Status] IN ('Created','RequestMaterial', 'Picked', 'Delivered','InTransit','InTransit/Waiting','Short','RequestMaterialPending','Failed')
	ORDER BY RequestTime

	RETURN 
END