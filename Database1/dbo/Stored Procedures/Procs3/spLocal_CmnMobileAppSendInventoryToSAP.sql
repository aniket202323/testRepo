-------------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[spLocal_CmnMobileAppSendInventoryToSAP]
	@PathCode		varchar(20),
	@puids			varchar(2000)
	
AS
SET NOCOUNT ON

DECLARE 
		--Generic
		@SPName						varchar(255),

		--Waste loop  --V1.5
		@Wedid						int,					
		@WeventId					int,
		@WAmount					float,

		--SOA
		@SAPLocDesc					varchar(50),


		--Local_integrationMessage table
		@Site						varchar(50),			
		@SystemSource				varchar(50),
		@SystemTarget				varchar(50),
		@MessageType				varchar(50),
		@MessageType2				varchar(50),
		@MainData					varchar(50),
		@Date						datetime,
		@DateStr					varchar(30),
		@Message					varchar(max),
		@Documentitems				varchar(max),
		@Partnerprofile				varchar(50),
		@Id							uniqueidentifier,
		@B2MMLPlantId				varchar(50),
		@ProcessOrder				varchar(50),
		@PathId						int

--1.11
DECLARE	@TableIdProdUnit			int,
		@tableFieldIdStorageLoc		int

DECLARE @StorageLocs	TABLE (
puid					int,
pudesc					varchar(50),
Location				varchar(50)
)



DECLARE @Inventory			TABLE (
		EventId						int,
		ProdId						int,
		ProdCode					varchar(25),
		ProdDesc					varchar(50),
		Batch						varchar(25),
		StatusId					int,
		StatusDesc					varchar(50),
		RemainingQty				float,
		RemainingQtyStr				varchar(50),
		UOM							varchar(20),
		OG							varchar(10),
		puid						int,
		pudesc						varchar(50),
		Location					varchar(50)
	)



DECLARE @Summary			TABLE (
		prodId						int,
		MaterialNumber				varchar(25),
		PlantCode					varchar(25),
		StorageLocation				varchar(10),
		BatchNumber					Varchar(20),
		StockType					varchar(10),
		Quantity					float, -- V1.8 Varchar(30),
		UnitOfMeasure				varchar(30)
)


Declare @OCPallets			TABLE (						--Overconsumed pallets)
		EventId						int,
		ppid						int,
		ppStatusId					int
		)


--V1.5
DECLARE @InitiateWaste		TABLE (
wedid								int,
eventid								int,
amount								float,
PO									varchar(50),
ppid								int
)


--V1.6 
DECLARE  @UpcomingPO		TABLE (
PO									varchar(50)
)


SELECT	@SPName		= 	'spLocal_CmnMobileAppSendInventoryToSAP'

INSERT INTO Local_Debug([TimeStamp], CallingSP, [Message], msg)
VALUES (getdate(),
		@SPName,	
		'0000 - SP triggered',
		@puids)


--1.11
SET @TableIdProdUnit		= (SELECT tableid FROM dbo.tables WITH(NOLOCK) WHERE tableName = 'Prod_Units')	
SET @tableFieldIdStorageLoc	= (SELECT Table_field_id FROM dbo.table_fields WITH(NOLOCK) WHERE tableid = @TableIdProdUnit	AND table_field_desc = 'PE_SAPStorageLoc')

--------------------------------------------------------------
--Build list of production unit
--------------------------------------------------------------
INSERT @StorageLocs (puid)
SELECT value FROM fnLocal_CmnParseListLong(@puids,';')


--1.11
UPDATE sl
SET Location = CONVERT(varchar(100),tfv.Value),
	pudesc = pu.pu_desc
FROM	@StorageLocs sl
JOIN dbo.table_fields_values tfv ON sl.puid = tfv.keyid
									AND tfv.table_field_id = @tableFieldIdStorageLoc
									AND tfv.tableid = @TableIdProdUnit
JOIN dbo.prod_units_Base pu			WITH(NOLOCK) ON pu.pu_id = sl.puid





INSERT INTO Local_Debug([TimeStamp], CallingSP, [Message], msg)
SELECT  getdate(),
		@SPName,	
		'0050 - ' + location + ' / ' + pudesc,
		@puids
FROM @StorageLocs




/*-----------------------------------------------------------------------------------------
2) Get pallet Inventory
-------------------------------------------------------------------------------------------*/
INSERT @Inventory (
		EventId,
		ProdId,
		ProdCode,
		Batch,
		StatusId,
		StatusDesc,
		RemainingQty,
		--UOM,
		--OG,
		puid,
		pudesc,
		location)
SELECT	e.event_id,
		e.applied_product,
		p.prod_code,
		CASE CHARINDEX('_',e2.event_num)
			WHEN 0 THEN SUBSTRING(e2.event_num,0,24)
			ELSE SUBSTRING(e2.event_num,0,CHARINDEX('_',e2.event_num))
		END	,
		e.event_status,
		ps.prodStatus_Desc,
		COALESCE(ed.Final_dimension_X,0),
		--CONVERT(varchar(25),pmdmc.value),
		--CONVERT(varchar(25),pmdmc2.value),
		e.pu_id,
		pu.pudesc,
		pu.location
FROM	@StorageLocs	pu
JOIN	dbo.events e											WITH(NOLOCK)	ON e.pu_id = pu.puid
JOIN	dbo.production_Status	ps								WITH(NOLOCK)	ON e.event_status = ps.prodStatus_Id
																					AND (ps.LifecycleStage = 1 OR ps.LifecycleStage = 2)
JOIN	dbo.event_details ed									WITH(NOLOCK)	ON e.event_id = ed.event_id
																					AND ed.final_dimension_x != 0
JOIN	dbo.products p											WITH(NOLOCK)	ON e.applied_product = p.prod_id
JOIN	dbo.Products_Aspect_MaterialDefinition a				WITH(NOLOCK)	ON a.prod_id = p.prod_id
JOIN	dbo.materialDefinition m								WITH(NOLOCK)	ON a.Origin1MaterialDefinitionId = m.materialDefinitionId
LEFT JOIN	dbo.event_components ec								WITH(NOLOCK)	ON ec.event_id = e.event_id
LEFT JOIN	dbo.events e2										WITH(NOLOCK)	ON ec.source_event_id = e2.event_id
LEFT JOIN	dbo.prod_units pu2									WITH(NOLOCK)	ON e2.pu_id = pu2.pu_id		AND		pu2.equipment_type = 'LotStorage'

INSERT INTO Local_Debug([TimeStamp], CallingSP, [Message], msg)
VALUES (getdate(),
		@SPName,	
		'0100 - Inventory retrieved',
		@puids)



--V1.1
INSERT @OCpallets (eventid, ppid,ppstatusid)
SELECT i.EventId, ed.pp_id, pp.pp_status_id
FROM @Inventory i
JOIN event_details ed											WITH(NOLOCK)	ON i.eventid = ed.event_id
JOIN production_plan pp											WITH(NOLOCK)	ON ed.pp_id = pp.pp_id
WHERE i.RemainingQty <0

IF EXISTS(SELECT 1 FROM @OCpallets)
BEGIN
	DELETE @Inventory
	WHERE eventid IN	(	SELECT EventId FROM @OCpallets WHERE ppstatusid = 4	)
END

--------------------------------------------
--V1.5
--Retrieve the waste done on the initiate/Ready pallets
--Those wastes should not be applied during the send inventory snapshot otherwise there will be discrepancy in SAP
-----------------------------------------------
INSERT @UpcomingPO (PO)
SELECT pp.process_order
FROM dbo.production_plan pp				WITH(NOLOCK)
JOIN dbo.production_plan_statuses pps	WITH(NOLOCK) ON pp.pp_status_id = pps.pp_status_id
JOIN dbo.prdExec_paths pep				WITH(NOLOCK) ON pp.path_id = pep.path_id
WHERE pep.path_code = @pathCode
	AND pps.pp_status_desc IN ('Pending', 'Initiate', 'ready')




INSERT @initiateWaste (wedid, eventid, amount, PO)
SELECT wed.wed_id, wed.event_id, wed.amount, wed.work_order_number
FROM dbo.waste_event_details wed	WITH(NOLOCK)
WHERE	pu_id IN (SELECT puid FROM @StorageLocs)
	AND work_order_number IN (SELECT po FROM @UpcomingPO)



--V1.6  add case special if no event id in @inventory
SET @Wedid = (SELECT min(wedid) FROM @initiateWaste)
WHILE @Wedid IS NOT NULL
BEGIN
	SELECT	@Weventid = eventid,
			@Wamount = amount
	FROM @initiateWaste WHERE wedid = @wedid

	IF EXISTS(SELECT eventid FROM @Inventory WHERE eventid = @Weventid)
	BEGIN
		--Update the existing event
		UPDATE @Inventory
		SET RemainingQty = RemainingQty + @Wamount
		WHERE eventid = @Weventid
	END
	ELSE
	BEGIN
		--Special case where a waste was created and this consumed the pallets (during the initate/Ready phase)
		INSERT @Inventory (
				EventId,
				ProdId,
				ProdCode,
				Batch,
				RemainingQty,
				puid,
				pudesc,
				location)
		SELECT	e.event_id,
				e.applied_product,
				p.prod_code,
				CASE CHARINDEX('_',e2.event_num)
					WHEN 0 THEN SUBSTRING(e2.event_num,0,24)
					ELSE SUBSTRING(e2.event_num,0,CHARINDEX('_',e2.event_num))
				END	,
				COALESCE(ed.Final_dimension_X,0)+ @Wamount,
				e.pu_id,
				pu.pudesc,
				pu.location
		FROM	@StorageLocs	pu
		JOIN	dbo.events e											WITH(NOLOCK)	ON e.pu_id = pu.puid
		JOIN	dbo.event_details ed									WITH(NOLOCK)	ON e.event_id = ed.event_id
		JOIN	dbo.products p											WITH(NOLOCK)	ON e.applied_product = p.prod_id
		LEFT JOIN	dbo.event_components ec								WITH(NOLOCK)	ON ec.event_id = e.event_id
		LEFT JOIN	dbo.events e2										WITH(NOLOCK)	ON ec.source_event_id = e2.event_id
		LEFT JOIN	dbo.prod_units pu2									WITH(NOLOCK)	ON e2.pu_id = pu2.pu_id		AND		pu2.equipment_type = 'LotStorage'
		WHERE e.event_id = @Weventid
	END

	SET @Wedid = (SELECT min(wedid) FROM @initiateWaste WHERE wedid > @Wedid)
END






/*-----------------------------------------------------------------------------------------
3) Make summary
-------------------------------------------------------------------------------------------*/

INSERT @Summary	 (
		prodId				,
		MaterialNumber		,
		--PlantCode			,
		StorageLocation		,
		BatchNumber			,
		--StockType			,
		Quantity				)
SELECT prodId,ProdCode,location,Batch, SUM(RemainingQty)
FROM @Inventory
GROUP BY prodid,ProdCode,Batch, location


IF (SELECT COUNT(1) FROM @Summary) = 0
BEGIn
	INSERT INTO Local_Debug([TimeStamp], CallingSP, [Message], msg)
	VALUES (getdate(),
		@SPName,	
		'0995 - No Inventory',
		@puids)
	RETURN
END

/*Get plant code Id FO-05301 -- get the latest activated Process order  on the path*/
SET @PathID = (SELECT Path_ID FROM dbo.Prdexec_PAths WHere Path_code = @pathCode)
SET @ProcessOrder = (SELECT TOP 1 Process_order
FROM dbo.Production_plan p WITH(NOLOCK) 
WHERE Path_ID =@PathID 
ORDER BY Actual_Start_Time DESC )



	--Get Partner profile
	SELECT @B2MMLPlantId = dbo.fnLocal_CmnGetPEIntegrationProfileValue(@ProcessOrder,'PE_IntegrationPlantCodeId')
	SELECT @Partnerprofile = dbo.fnLocal_CmnGetPEIntegrationProfileValue(@ProcessOrder,'SAP_PartnerProfile');


IF @B2MMLPlantId IS NULL
BEGIN
	/*Alternative way*/
	SET @B2MMLPlantId = (	SELECT TOP 1 CONVERT(varchar(10),b.value)
							FROM dbo.equipment e	WITH(NOLOCK)
							JOIN dbo.Property_Equipment_EquipmentClass b	WITH(NOLOCK)	ON e.equipmentId = b.equipmentId
							WHERE b.name = 'B2MMLPlantId' AND e.type = 'Site' )

	IF @B2MMLPlantId IS NULL
		SET @B2MMLPlantId = ''
END

UPDATE @Summary
SET MaterialNumber = REPLICATE('0',18-LEN(MaterialNumber)) + MaterialNumber,
	PlantCode = @B2MMLPlantId,
	StockType = ''



--Get the UOM
UPDATE s
SET UnitOfMeasure = CONVERT(varchar(25),pmdmc.value)
FROM @Summary s
JOIN	dbo.Products_Aspect_MaterialDefinition a				WITH(NOLOCK)	ON a.prod_id = s.prodid
JOIN	dbo.materialDefinition m								WITH(NOLOCK)	ON a.Origin1MaterialDefinitionId = m.materialDefinitionId
JOIN	dbo.Property_MaterialDefinition_MaterialClass pmdmc		WITH(NOLOCK)	ON pmdmc.MaterialDefinitionId = m.MaterialDefinitionid
																					AND pmdmc.Name = 'UOM'
INSERT INTO Local_Debug([TimeStamp], CallingSP, [Message], msg)
VALUES (getdate(),
		@SPName,	
		'0200 - Summary Done',
		@puids)





SET @Documentitems = (SELECT MaterialNumber,BatchNumber,PlantCode,StorageLocation,StockType,CAST(CAST(Quantity AS DECIMAL(38,3)) as VARCHAR(40))as Quantity,UnitOfMeasure  --V1.2  --V1.8  --V1.9
						FROM @Summary
						ORDER BY MaterialNumber,BatchNumber
						FOR XML PATH('DocumentItem'), ROOT('DocumentItems')
						)



INSERT INTO Local_Debug([TimeStamp], CallingSP, [Message], msg)
VALUES (getdate(),
		@SPName,	
		'0220 - XML material done',
		@puids)


/*-----------------------------------------------------------------------------------------
4) Set header + Complete B2MML
-------------------------------------------------------------------------------------------*/
--set ID
SET @Id = (SELECT NEWID())

--Define B2MML message
SELECT @Date = GETDATE()
SET @DateStr = CONVERT(varchar(30),@Date,112)


/*Get Partner profile FO-05301*/

IF @Partnerprofile IS NULL
BEGIN
	/*Alternative way*/
	SET @Partnerprofile = (	SELECT TOP 1 CONVERT(varchar(10),b.value)
							FROM dbo.equipment e	WITH(NOLOCK)
							JOIN dbo.Property_Equipment_EquipmentClass b	WITH(NOLOCK)	ON e.equipmentId = b.equipmentId
							WHERE b.name = 'PartnerProfile' AND Type = 'Site' )

	IF @Partnerprofile IS NULL
		SET @Partnerprofile = ''
END


INSERT INTO Local_Debug([TimeStamp], CallingSP, [Message], msg)
VALUES (getdate(),
		@SPName,	
		'0300 - ' + 
		' /@DateStr: ' + @DateStr +
		' /@Partnerprofile: ' + @Partnerprofile ,
		@puids)

SET @Message = '<?xml version="1.0" encoding="UTF-8"?>'
SET @Message = @Message + '<InventorySnapshot><DocumentHeader><ID>'+CONVERT(varchar(50),@Id)+'</ID>'
SET @Message = @Message + '<EquipmentID>'+@Partnerprofile+'</EquipmentID>'
SET @Message = @Message + '<DocumentDate>'+@DateStr+'</DocumentDate>'
SET @Message = @Message + '<PostingDate>'+@DateStr+'</PostingDate>'
SET @Message = @Message + '<PathName>'+@PathCode+'</PathName></DocumentHeader>'


SET @Message = @Message + @Documentitems + '</InventorySnapshot>'

INSERT INTO Local_Debug([TimeStamp], CallingSP, [Message], msg)
VALUES (getdate(),
		@SPName,	
		'0320 - B2MML complete',
		@puids)


/*-----------------------------------------------------------------------------------------
4) Insert in Local_TblIntIntegrationMessages table
-------------------------------------------------------------------------------------------*/
--Define constant variable
--Get site
SET @Site			= (SELECT TOP 1 S95Id FROM dbo.equipment WITH(NOLOCK) WHERE type = 'site')
SET @SystemSource	= 'MES'
SET @SystemTarget	= 'SAP'
SET @MessageType2	= 'InventoryUpdate'
SET @MessageType	= 'WorkOrderUpdate'		--V1.4

SET @MainData		= @PathCode+'-'+@MessageType2

		
--Insert in the interfacing table
INSERT  [dbo].[Local_tblINTIntegrationMessages] (
SITE, 
SystemSource, 
SystemTarget, 
MessageType, 
MainData, 
InsertedDate, 
TriggerID,
errorCode, 
Message
)
VALUES (
@Site,
@SystemSource,
@SystemTarget, 
@MessageType,
@MainData, 
GETDATE(),
1,
0,
@message
	)

INSERT INTO Local_Debug([TimeStamp], CallingSP, [Message], msg)
VALUES (getdate(),
		@SPName,	
		'0999 - Insert Done, end of SP',
		@puids)
		


SET NOCOUNT OFF
RETURN