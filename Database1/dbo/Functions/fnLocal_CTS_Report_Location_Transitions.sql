

--------------------------------------------------------------------------------------------------
-- Table function: fnLocal_CTS_Report_Location_Transitions
--------------------------------------------------------------------------------------------------
-- Author				: Francois Bergeron, Symasol
-- Date created			: 2022-02-23
-- Version 				: Version 1.0
-- SP Type				: Proficy Plant Applications
-- Caller				: SQL
-- Description			: This function retrieves the location and status transition of an appliance
-- Editor tab spacing	: 4
-------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ===========================================================================================
-- 1.0		2022-02-23		F. Bergeron				Initial Release 


--================================================================================================
--
--------------------------------------------------------------------------------------------------
-- TEST CODE:
--------------------------------------------------------------------------------------------------
/*

SELECT * FROM [fnLocal_CTS_Report_Location_Transitions](8451, '20-feb-2022', '23-feb-2022') order by movementtime asc

*/


CREATE FUNCTION [dbo].[fnLocal_CTS_Report_Location_Transitions]
(
@LocationId										INTEGER,
@StartTime											DATETIME = NULL,
@EndTime											DATETIME = NULL
)

RETURNS @Output TABLE 
(
	LocationId							INTEGER,
	LocationDesc						VARCHAR(50),
	LocationStatus						VARCHAR(25),
	LocationProcessOrderId				INTEGER,
	LocationProcessOrder				VARCHAR(50),
	LocationProductId					INTEGER,
	LocationProductCode					VARCHAR(50),
	LocationProductDesc					VARCHAR(50),
	ApplianceId							INTEGER,
	ApplianceSerial						VARCHAR(25),
	ApplianceType						VARCHAR(25),
	ApplianceStatus						VARCHAR(25),
	MovementDirection					VARCHAR(10),
	MovementTime						DATETIME,
	FromLocationId						INTEGER,
	FromLocationDesc					VARCHAR(50),
	FromLocationProcessOrderId			INTEGER,
	FromLocationProcessOrder			VARCHAR(50),
	FromLocationProcessOrderProductId	INTEGER,
	FromLocationProcessOrderProductCode	VARCHAR(50),
	FromLocationProcessOrderProductDesc	VARCHAR(50),
	ToLocationId						INTEGER,
	ToLocationDesc						VARCHAR(50),
	ToLocationProcessOrderId			INTEGER,
	ToLocationProcessOrder				VARCHAR(50),
	ToLocationProcessOrderProductId		INTEGER,
	ToLocationProcessOrderProductCode	VARCHAR(50),
	ToLocationProcessOrderProductDesc	VARCHAR(50)
)

AS
BEGIN
	DECLARE
	@TableIdProdUnit INTEGER,
	@tfIdApplianceType INTEGER

	DECLARE @AppliancePU TABLE
	(
	PUId INTEGER,
	ApplianceType VARCHAR(25)
	)


	SET @TableIdProdUnit = (SELECT tableId FROM dbo.Tables WITH(NOLOCK) WHERE TableName = 'Prod_Units'	)
	SET @tfIdApplianceType = (	SELECT table_field_id FROM dbo.Table_Fields WITH(NOLOCK) WHERE TableId = @TableIdProdUnit AND Table_Field_Desc = 'CTS Appliance type')

	INSERT INTO @AppliancePU (PUId,ApplianceType)
	SELECT	PUB.PU_ID,TFV.Value 
	FROM	dbo.Table_Fields_Values TFV WITH(NOLOCK)
			JOIN dbo.prod_units_base PUB WITH(NOLOCK)
				ON PUB.PU_id = TFV.KeyId
	WHERE	TFV.Table_Field_Id = @tfIdApplianceType
			AND PUB.equipment_type = 'CTS Appliance'
	--------------------------------------------------------------------------------------------------
	--GET ALL CTS MOVEMENTS FOR PERIOD
	--------------------------------------------------------------------------------------------------
	DECLARE @All_Movements TABLE
	(
	ApplianceId		INTEGER,
	ApplianceSerial VARCHAR(25),
	ApplianceType	VARCHAR(25),
	ApplianceStatus	VARCHAR(25),
	TransitionId	INTEGER,
	MovementTime	DATETIME,
	DestinationPUId	INTEGER,
	SourcePUId		INTEGER,
	RowNum			INTEGER

	)

	IF @StartTime IS NULL
		SET @StartTime = '01-01-1970'
	IF @EndTime IS NULL
		SET @EndTime = GETDATE()



	INSERT INTO  @ALL_Movements
	(
	ApplianceId,
	ApplianceSerial,
	ApplianceType,
	ApplianceStatus,
	TransitionId,
	MovementTime,
	DestinationPUId,
	SourcePUId,
	rownum
	)
	SELECT	EC.source_event_id,
			EDAPP.alternate_event_num,
			APU.ApplianceType,
			PS.ProdStatus_Desc,
			EC.event_id,
			EC.timestamp,
			ETRANS.PU_id,
			NULL,
			ROW_NUMBER() OVER(PARTITION BY EC.Source_event_id ORDER BY EC.timestamp ASC)  'Rownum' 
	FROM	dbo.event_components EC WITH(NOLOCK) 
			JOIN dbo.events ETRANS WITH(NOLOCK) 
				ON ETRANS.event_id = EC.event_id
			JOIN dbo.events EAPP WITH(NOLOCK) 
				ON EAPP.event_id = EC.Source_event_id
			CROSS APPLY(SELECT *,ROW_NUMBER() OVER(PARTITION BY ETRANSST.event_id ORDER BY ETRANSST.Start_time ASC)  'Rownum'  
						FROM dbo.event_status_transitions ETRANSST WITH(NOLOCK)
						WHERE ETRANSST.event_id = ETRANS.event_id)Q1
			JOIN dbo.production_status PS WITH(NOLOCK)
				ON PS.prodStatus_id = Q1.event_status
			JOIN @AppliancePU APU
				ON EAPP.pu_Id = APU.puid
			JOIN dbo.event_details EDAPP WITH(NOLOCK)
				ON EAPP.event_id = EDAPP.event_id
			JOIN dbo.prod_units_Base PUBAPP WITH(NOLOCK)
				ON PUBAPP.pu_id = EAPP.pu_id 
	WHERE	EC.timestamp > @StartTime 
			AND EC.timestamp <= @EndTime
			AND Q1.rownum = 1
	

	UPDATE @ALL_Movements 
	SET SourcePUId = Q.DestinationPUId
	FROM @ALL_Movements AM
	CROSS APPLY (SELECT DestinationPUId
	FROM @ALL_Movements
	WHERE ApplianceId = AM.ApplianceId AND rownum = AM.rownum -1
	)Q





	--------------------------------------------------------------------------------------------------
	--GET INBOUND MOVEMENTS
	--------------------------------------------------------------------------------------------------
	INSERT INTO @Output
	(
	LocationId,
	LocationDesc,
	LocationStatus,
	LocationProcessOrderId,	
	LocationProductId,
	LocationProcessOrder,
	LocationProductCode,
	LocationProductDesc,
	ApplianceId,
	ApplianceSerial,
	ApplianceType,
	ApplianceStatus,
	MovementDirection,
	MovementTime,
	FromLocationId
	
	)
	SELECT 
			@LocationId,
			(SELECt PU_Desc FROM dbo.prod_units_base WHERE pu_id = @LocationId),
			(SELECT Location_status FROM fnLocal_CTS_Location_Status(@LocationId,Dateadd(second,-0,MovementTime))),
			(SELECT Last_Process_Order_Id FROM fnLocal_CTS_Location_Status(@LocationId,Dateadd(second,0,MovementTime))),
			(SELECT Last_product_Id FROM fnLocal_CTS_Location_Status(@LocationId,Dateadd(second,0,MovementTime))),
			NULL,
			NULL,
			NULL,
			ApplianceId,
			ApplianceSerial,
			ApplianceType,
			Appliancestatus,
			'INBOUND',
			MovementTime,
			SourcePUId
	FROM	@All_Movements
	WHERE	DestinationPUId = @locationId


	--------------------------------------------------------------------------------------------------
	--GET OUTBOUND MOVEMENTS
	--------------------------------------------------------------------------------------------------
	INSERT INTO @Output
	(
	LocationId,
	LocationDesc,
	LocationStatus,
	LocationProcessOrderId,	
	LocationProductId,
	LocationProcessOrder,
	LocationProductCode,
	LocationProductDesc,
	ApplianceId,
	ApplianceSerial,
	ApplianceType,
	ApplianceStatus,
	MovementDirection,
	MovementTime,
	ToLocationId
	)
	SELECT 
			@LocationId,
			(SELECt PU_Desc FROM dbo.prod_units_base WHERE pu_id = @LocationId),
			(SELECT Location_status FROM fnLocal_CTS_Location_Status(@LocationId,Dateadd(second,-1,MovementTime))),
			(SELECT Last_Process_Order_Id FROM fnLocal_CTS_Location_Status(@LocationId,Dateadd(second,-1,MovementTime))),
			(SELECT Last_product_Id FROM fnLocal_CTS_Location_Status(@LocationId,Dateadd(second,-1,MovementTime))),
			NULL,
			NULL,
			NULL,
			ApplianceId,
			ApplianceSerial,
			ApplianceType,
			Appliancestatus,
			'OUTBOUND',
			MovementTime,
			DestinationPUId
	FROM	@All_Movements
	WHERE	SourcePUId = @locationId

	RETURN	
END
