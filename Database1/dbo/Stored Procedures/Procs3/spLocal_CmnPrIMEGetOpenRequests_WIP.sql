
--------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_CmnPrIMEGetOpenRequests_WIP
--------------------------------------------------------------------------------------------------
-- Author				: Julien B. Ethier, Symasol
-- Date created			: 2018-08-13
-- Version 				: Version 1.0
-- SP Type				: Mobile App
-- Caller				: PEWebService
-- Description			: Read content of PrIME open request table
-- Editor tab spacing	: 4
-------------------------------------------------------------------------------
--
-- Basic Logic in Task #
--
-------------------------------------------------------------------------------
--The stored proc <spLocal_CmnPrIMEGetOpenRequests_WIP> will
/*


*/


--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ===============================================================================================
-- 1.0		2018-08-13		Julien B. Ethier	Initial Release
-- 1.1		2018-08-20		Julien B. Ethier	Added PE:PrIME_WMS Destination LineId cross reference
-- 1.2		2018-08-21		Julien B. Ethier	Added Location and Material parameters. Removed
--												material parameter.
-- 1.3		2018-09-20		Linda Hudon			Added new status 
-- 1.4		2018-11-06		Linda Hudon			remove picked
-- 1.5		2018-11-08		Linda Hudon			add prime return code 
-- 1.6		2018-12-04		Linda Hudon			Added new status Failed
-- 1.7		2018-12-17		Linda Hudon			Added delivered  statu
-- 1.8		2018-12-19		Linda Hudon			retrive open request for location and empty path
-- 1.9		2019-09-20		Sasha Metlitski		FO-04067 Implement Pre-Staged Material Request Functionality											
--================================================================================================
--


--------------------------------------------------------------------------------------------------
-- TEST CODE:
--------------------------------------------------------------------------------------------------
/*
exec [dbo].[spLocal_CmnPrIMEGetOpenRequests_WIP] 		'PE54RT54','SharedLoc54','99009907'


*/

-------------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[spLocal_CmnPrIMEGetOpenRequests_WIP]
@PathCode			varchar(50),
@LocationId			varchar(50),
@MaterialList		varchar(max)

		
--WITH ENCRYPTION	
AS
SET NOCOUNT ON


DECLARE
--For debug 
@CurrentTime						datetime,
@DefaultUserId						int,
@ErrMsg								varchar(1000),	
@TimeStamp							datetime,
@CallingSP							varchar(100),
@Query								varchar(max),

@PathId								int,
@TableIdPrdExecInput				int,
@TFIDOG								int,
@TFIDPEWMSType						int,
@ppid								int,
@BOMFormId							int,
@TableID							int,
@PUID								int,
@PLCOrderPRGcasUDP					int,
@SharedLocation						varchar(50)

--FO-04067 Change-over Materials Change Request
DECLARE @FlgPreStagedMaterialRequest		int,
		@UDPPreStagedMaterialRequest		varchar(255),
		@StatusPreStaged					varchar(255),
		@DebugFlagOnLine					int -- temporary

CREATE TABLE #MaterialRequests
(
	OpenTableId			int,
	RequestId			varchar(50),
	PrIMEReturnCode		int,
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

CREATE TABLE #Materials
(
	ProdCode		varchar(50)
)

DECLARE @ProdUnits TABLE 
(
	EquipmentId		varchar(50),
	PUId			int,
	PUDesc			varchar(50)
)
		
CREATE TABLE #RMIs
(
	PEIId			int,
	InputOG			varchar(30),
	PEWMSType		varchar(50),
	PUId			int,
	ULINPUId		int,
	LocationId		varchar(50)

)

SET		@CallingSP = 'spLocal_CmnPrIMEGetOpenRequests_WIP'
SELECT	@DebugflagOnLine = 1

--FO-04067 Change-over Materials Change Request
SELECT	@UDPPreStagedMaterialRequest	= 'PE_PrIME_PreStagedMaterialRequest',
		@StatusPreStaged				= 'Pre-Staged'

SELECT 	@FlgPreStagedMaterialRequest = Null
SELECT 	@FlgPreStagedMaterialRequest = IsNull(tfv.Value,0)
FROM	dbo.TABLE_FIELDS_VALUES tfv
join	dbo.TABLE_FIELDS tf on tfv.TABLE_FIELD_ID = tf.TABLE_FIELD_ID
join	dbo.TABLES t on tf.TABLEID = t.TABLEID
join	dbo.Prdexec_Paths pex on tfv.KeyId = pex.Path_Id
WHERE	t.TABLENAME = 'PrdExec_Paths'
and		tf.TABLE_FIELD_DESC = @UDPPreStagedMaterialRequest
and		pex.Path_Code = @PathCode

IF IsNUll(@DebugflagOnLine,0) = 1 
BEGIN
	INSERT	INTO dbo.Local_Debug(Timestamp, CallingSP, Message) 
			VALUES(	
			getdate(), 
			@CallingSP,
			'0100 started '	 +
			' PathCode: ' + coalesce(@PathCode,'') +
			' LocationId: ' + coalesce(@LocationId,'')  +
			' MaterialList: ' + coalesce(@MaterialList,'')  +
			' FlgPreStagedMaterialRequest: ' + convert(varchar(255), IsNull(@FlgPreStagedMaterialRequest,0))
			)
END
/*-----------------------------------------------------------------------------------------
-- Extract materials
-------------------------------------------------------------------------------------------*/
INSERT INTO #Materials (ProdCode)
SELECT * FROM [dbo].[fnLocal_CmnParseListLong] (@MaterialList, ',');

select '#Materials', * from #Materials

-- verify if its a saherd locaiton to remove the path
SET @tableID = (SELECT TableID FROM dbo.Tables WITH(NOLOCK) WHERE  TableName = 'Prod_Units')

SET @PLCOrderPRGcasUDP = (SELECT Table_Field_ID FROM dbo.Table_Fields WITH(NOLOCK) WHERE Table_Field_Desc  ='PE_PLCSignalOrderPRGCAS' AND TableId = @TableID)

SELECT @PUID = pu.PU_ID
FROM Prod_Units_Base pu WITH(NOLOCK) 
JOIN dbo.PAEquipment_Aspect_SOAEquipment a		WITH(NOLOCK) ON pu.Pu_ID = a.PU_Id
JOIN dbo.Property_Equipment_EquipmentClass peec	WITH(NOLOCK) ON peec.EquipmentId = a.Origin1EquipmentId
WHERE	peec.class = 'PE:PrIME_WMS'
	AND peec.name = 'LocationId'	
	AND peec.Value = @LocationId


SET @SharedLocation = (SELECT Value 
						FROM dbo.Table_Fields_Values tfv  WITH(NOLOCK) 
						JOIN dbo.Prod_Units_Base pu WITH(NOLOCK) ON  tfv.KeyId =pu.pu_id
						WHERE Table_field_Id =@PLCOrderPRGcasUDP 
						AND KeyID = @PuID)

IF @SharedLocation IS NOT NULL
BEGIN
	SET @PathCode = NULL
END

/*-----------------------------------------------------------------------------------------
-- If path code list is not empty, retrieve input sources related to PrIME material
-------------------------------------------------------------------------------------------*/
IF @PathCode IS NOT NULL
BEGIN

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

		INSERT #RMIs (	PEIId, 
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

		DELETE #RMIs WHERE (PEWMSType IS NULL OR PEWMSType <> 'PrIME')

		-- Get Destination location for all input sources
		UPDATE rmi
			SET LocationId = CONVERT(VARCHAR(50),peec.Value)
			FROM #RMIs rmi
			JOIN dbo.PAEquipment_Aspect_SOAEquipment a		WITH(NOLOCK) ON rmi.ULINPUId = a.PU_Id
			JOIN dbo.Property_Equipment_EquipmentClass peec	WITH(NOLOCK) ON peec.EquipmentId = a.Origin1EquipmentId
			WHERE	peec.class = 'PE:PrIME_WMS'
					AND peec.name = 'LocationId'	

END
--get open request for a specific location
IF @LocationId IS NOT NULL AND @MaterialList IS NULL AND @PathCode IS NULL
BEGIN
	
		INSERT #RMIs (	
						InputOG, 
						PEWMSType, 
						pei.PUId, 
						ULINPUId)
			SELECT	
				tfv.value,
				tfv2.value,
				pei.PU_Id,
				peis.PU_Id
			FROM  Prod_Units_Base pu WITH(NOLOCK) 
			JOIN dbo.PAEquipment_Aspect_SOAEquipment a		WITH(NOLOCK) ON pu.Pu_ID = a.PU_Id
			JOIN dbo.Property_Equipment_EquipmentClass peec	WITH(NOLOCK) ON peec.EquipmentId = a.Origin1EquipmentId
			JOIN	dbo.PrdExec_Inputs pei				WITH(NOLOCK) ON   pei.PU_Id =   pu.Pu_ID
			JOIN dbo.PrdExec_Input_Sources peis		WITH(NOLOCK) ON pei.PEI_Id = peis.PEI_Id
			JOIN dbo.Table_Fields_Values tfv		WITH(NOLOCK) ON	tfv.KeyId = pei.PEI_Id
																	AND tfv.Table_Field_Id = @TFIDOG
			LEFT JOIN dbo.table_fields_values tfv2	WITH(NOLOCK) ON	tfv2.KeyId = pei.PEI_Id
																	AND tfv2.Table_Field_Id = @TFIDPEWMSType
			WHERE	peec.class = 'PE:PrIME_WMS'
					AND peec.name = 'LocationId'	
					AND peec.Value = @LocationId

		DELETE #RMIs WHERE (PEWMSType IS NULL OR PEWMSType <> 'PrIME')
END


select '#RMIs', * from #RMIs
	
SET @Query = 'INSERT INTO #MaterialRequests
				SELECT	OpenTableId,
						RequestId,
						PrIMEReturnCode,
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
				WHERE	OpenTableId IS NOT NULL';
	
IF (SELECT COUNT(*) FROM #RMIs) > 0
BEGIN
	SET @Query = @Query + ' AND LocationId IN (SELECT LocationId FROM #RMIs)';
END

IF @LocationId IS NOT NULL
BEGIN
	SET @Query = @Query + ' AND LocationId = ''' + @LocationId + '''';
END

IF (SELECT COUNT(*) FROM #Materials) > 0
BEGIN
	SET @Query = @Query + ' AND (PrimaryGCas IN (SELECT ProdCode FROM #Materials) OR AlternateGCas IN (SELECT ProdCode FROM #Materials))';
END

SET @Query = @Query + ' AND Status IN (''RequestMaterial'', ''InTransit'', ''Created'', ''InTransit/Waiting'', ''Short'',''Failed'', ''Delivered'',''RequestMaterialPending'')';
SET @Query = @Query + ' ORDER BY RequestTime';


IF IsNUll(@DebugflagOnLine,0) = 1 
BEGIN
	INSERT	INTO dbo.Local_Debug(Timestamp, CallingSP, Message) 
			VALUES(	
			getdate(), 
			@CallingSP,
			'0200 Regular Query: '	 +
			IsNull(@Query, 'Null')
			)
END


EXEC(@Query);	


select 'regular', * from #MaterialRequests
--FO-04067 Implement Pre-Staged Material Request Functionality	
IF IsNull(@FlgPreStagedMaterialRequest,0) >0 --pre-staged functionality is implemented
BEGIN


	--Pre-staged request Implemented on the current Path. Retrieve Un-processed Records from the Table Local_PrIME_PreStaged_Material_Request for the Initiated Process Ordewr

	/*
		Mapping between @Openrequest and dbo.Local_PrIME_PreStaged_Material_Request Fields


		OpenTableId			int,			COUNT	(*)
		RequestId			varchar(50),	Not Relevant
		PrimeReturnCode		int,			Not Relevant
		RequestTime			datetime,		SOAEVENTTIMESLOT ???
		LocationId			varchar(50),	BOMRMTNLOCATN
		CurrentLocation		varchar(50),	Not Relevant
		ULID				varchar(50),	Not Relevant
		Batch				varchar(10),	Not Relevant
		ProcessOrder		varchar(50),	PROCESSORDER
		PrimaryGCAS			varchar(50),	BOMRMPRODCODE
		AlternateGCAS		varchar(50),	BOMRMSUBPRODCODE
		GCAS				varchar(50),	BOMRMPRODCODE
		QuantityValue		float,			derived from the @tblBOMRMListComplete.ProductUOMPerPallet
		QuantityUOM			varchar(50),	Irrelevant
		Status				varchar(50),	Shuld be hardcoded i.e. 'RequestMaterial'
		EstimatedDelivery	datetime,		Not Relevant
		lastUpdatedTime		datetime,		Not Relevant  - may use inserted time
		userId				int,			DEFAULTUSERNAME		
		eventId				int				Not Relevant








	BEGIN
		INSERT	@Openrequest (
				OpenTableId,
				RequestId,
				RequestTime,
				LocationId, 
				CurrentLocation,
				ULID,
				Batch,
				ProcessOrder,
				PrimaryGCAS,
				AlternateGCAS,
				GCAS,
				QuantityValue,
				QuantityUOM,
				Status,
				EstimatedDelivery,
				lastUpdatedTime	,
				userId, 
				eventid	)
		SELECT	1,							-- OpenTableId		(Irrelevant)
				1,							-- RequestId		(Irrelevant)
				lpmr.SOAEVENTTIMESLOT,		-- RequestTime		(Irrelevant)
				lpmr.BOMRMTNLOCATN,			-- LocationId
				lpmr.BOMRMTNLOCATN,			-- CurrentLocation	(irrelevant)
				Null,						-- ULID (irrelevant)
				Null,						-- Batch (irrelevant)
				lpmr.PROCESSORDER,			-- ProcessOrder
				lpmr.BOMRMPRODCODE,			-- PrimaryGCAS
				lpmr.BOMRMSUBPRODCODE,		-- AlternateGCAS
				lpmr.BOMRMPRODCODE,			-- GCAS
				Null,						-- QuantityValue
				Null,						-- QuantityUOM
				'RequestMaterial',			-- Status !!!! ?????? what status should we use
				Null,						-- EstimatedDelivery (Irrelevant)
				lpmr.INSERTEDTIME,			-- lastUpdatedTime
				u.User_Id,					-- userId
				Null						-- eventid (Irrelevant)
		FROM	dbo.Local_PrIME_PreStaged_Material_Request lpmr with (nolock)
		join    dbo.users u on lpmr.DEFAULTUSERNAME = u.Username
		WHERE	lpmr.PROCESSORDER = @NxtPPProcessOrder
		and		lpmr.PROCESSEDTIME Is Null
		and		lpmr.STATUS = @StatusPreStaged
	END 




	OpenTableId			int,
	RequestId			varchar(50),
	PrIMEReturnCode		int,
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



*/

	SELECT @Query = ''
	SELECT @Query = 'INSERT INTO	#MaterialRequests 
					SELECT			1,
									1,
									Null,
									lpmr.SOAEVENTTIMESLOT,
									lpmr.BOMRMTNLOCATN,
									lpmr.BOMRMTNLOCATN,
									Null, 
									Null, 
									lpmr.PROCESSORDER,
									lpmr.BOMRMPRODCODE,
									lpmr.BOMRMSUBPRODCODE,
									lpmr.BOMRMPRODCODE,	
									Quantity,
									Null,
									''RequestMaterial'',		
									Null,
									lpmr.INSERTEDTIME,	
									u.User_Id,
									Null
					FROM			dbo.Local_PrIME_PreStaged_Material_Request lpmr with (nolock)
					left join		dbo.users u on lpmr.DEFAULTUSERNAME = u.Username
					WHERE			lpmr.PROCESSEDTIME Is Null
					and				lpmr.STATUS = ''' + @StatusPreStaged +''''
	
	IF (SELECT COUNT(*) FROM #RMIs) > 0
	BEGIN
		SET @Query = @Query + ' and lpmr.BOMRMTNLOCATN IN (SELECT LocationId FROM #RMIs)';
	END

	IF @LocationId IS NOT NULL
	BEGIN
		SET @Query = @Query + ' AND  lpmr.BOMRMTNLOCATN = ''' + @LocationId + '''';
	END

	IF (SELECT COUNT(*) FROM #Materials) > 0
	BEGIN
		SET @Query = @Query + ' AND (lpmr.BOMRMPRODCODE IN (SELECT ProdCode FROM #Materials) OR lpmr.BOMRMSUBPRODCODE IN (SELECT ProdCode FROM #Materials))';
	END

	--SET @Query = @Query + ' AND Status IN (''RequestMaterial'', ''InTransit'', ''Created'', ''InTransit/Waiting'', ''Short'',''Failed'', ''Delivered'',''RequestMaterialPending'')';
	SET @Query = @Query + ' ORDER BY InsertedTime';
	
	IF IsNUll(@DebugflagOnLine,0) = 1 
	BEGIN
		INSERT	INTO dbo.Local_Debug([Timestamp], [CallingSP], [Message]) 
				VALUES(	
				getdate(), 
				@CallingSP,
				'0300 Pre-Staged Query: '	 +
				IsNull(@Query,'Null')
				)
	END

	EXEC(@Query);	
END
select 'prestaged query', @Query
select 'pre-staged', * from #MaterialRequests

IF @DebugFlagOnLine = 1  
BEGIN
	INSERT INTO dbo.Local_Debug([Timestamp], [CallingSP], [Message]) 
			VALUES(	
			getdate(), 
			@CallingSP,
			'0999 Finished' 
			)
END


SELECT	OpenTableID,
		RequestId,
		PrIMEReturnCode,
		RequestTime,
		LocationID, 
		CurrentLocation, 
		ULID, 
		Batch,
		ProcessOrder, 
		PrimaryGcas,
		AlternateGcas,
		COALESCE(GCAS, PrimaryGcas) AS Gcas,
		QuantityValue,
		QuantityUoM,
		[Status],
		EstimatedDelivery,
		LastUpdatedTime,
		UserId,
		EventId
 FROM #MaterialRequests;

DROP TABLE #MaterialRequests;
DROP TABLE #RMIs;
DROP TABLE #Materials;	

SET NOCOUNT OFF

RETURN

