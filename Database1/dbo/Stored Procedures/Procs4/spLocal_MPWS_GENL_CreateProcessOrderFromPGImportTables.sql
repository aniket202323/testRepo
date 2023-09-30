 
 
 
CREATE  PROCEDURE [dbo].[spLocal_MPWS_GENL_CreateProcessOrderFromPGImportTables]
 
AS
 
/*
-------------------------------------------------------------------------------
	Create Pre Weigh Process Order from P&G data imported from excel
 
 
exec dbo.spLocal_MPWS_GENL_CreateProcessOrderFromPGImportTables
 
 
	Date         Version Build Author  
	26-Jun-2016  001     001   Jim Cameron (GEIP)  Initial development	
 
 
 
-------------------------------------------------------------------------------
*/
 
DECLARE
	@RowNo		INT,
	@RowMax		INT,
	@CurrDate	DATETIME,
	@PPSetupId	INT,
	@BatchId	VARCHAR(50),
 
	@PreweighPUID	INT = 4321
 
DECLARE
	@ErrorMessage	NVARCHAR(4000),
	@ErrorSeverity	INT,
	@ErrorState		INT
 
DECLARE
	@BOMFI_TableId INT = (SELECT TableId FROM dbo.Tables WHERE TableName = 'Bill_Of_Material_Formulation_Item'),
	@Plan_TableId INT  = (SELECT TableId FROM dbo.Tables WHERE TableName = 'Production_Plan');
 
DECLARE
	@BOMFI_FieldId_DStation INT = (SELECT Table_Field_Id FROM dbo.Table_Fields WHERE TableId = @BOMFI_TableId AND Table_Field_Desc = 'DispenseStationId'),
	@BOMFI_FieldId_ItemStat INT = (SELECT Table_Field_Id FROM dbo.Table_Fields WHERE TableId = @BOMFI_TableId AND Table_Field_Desc = 'BOMItemStatus'),
	@Plan_FieldId_Priority  INT = (SELECT Table_Field_Id FROM dbo.Table_Fields WHERE TableId = @Plan_TableId  AND Table_Field_Desc = 'PreWeighProcessOrderPriority');
	
DECLARE
	@PPId				INT,
	@TransType			INT				= 1,
	@TransNum			INT				= 0,
	@PathId				INT				= 82,
	@CommentId			INT				= NULL,
	@ProdId				INT,
	@ImpliedSequence	INT				= NULL,
	@PPStatusId			INT				= (SELECT PP_Status_Id FROM dbo.Production_Plan_Statuses WHERE PP_Status_Desc = 'Released'),
	@BomfiStatusId		INT				= (SELECT PP_Status_Id FROM dbo.Production_Plan_Statuses WHERE PP_Status_Desc = 'Pending'),
	@PPTypeId			INT				= (SELECT PP_Type_Id FROM dbo.Production_Plan_Types WHERE PP_Type_Name = 'Scheduled'),
	@SourcePPId			INT				= NULL,
	@UserId				INT				= (SELECT [User_Id] FROM dbo.Users_Base WHERE Username = 'comxclient'),
	@ParentPPId			INT				= NULL,
	@ControlType		TINYINT			= NULL,
	@ForecastStartTime	DATETIME,
	@ForecastEndTime	DATETIME,
	@EntryOn			DATETIME,
	@ForecastQuantity	FLOAT,
	@ProductionRate		FLOAT			= NULL,
	@AdjustedQuantity	FLOAT			= NULL,
	@BlockNumber		VARCHAR(50)		= NULL,
	@ProcessOrder		VARCHAR(50),
	@TransactionTime	DATETIME		= NULL,
	@Misc1				INT				= NULL,
	@Misc2				INT				= NULL,
	@Misc3				INT				= NULL,
	@Misc4				INT				= NULL,
	@BOMFormulationId	BIGINT,
	@UserGeneral1		VARCHAR(255)	= NULL,
	@UserGeneral2		VARCHAR(255)	= NULL,
	@UserGeneral3		VARCHAR(255)	= NULL,
	@ExtendedInfo		VARCHAR(255)	= NULL
 
DECLARE @PGOrder TABLE
(
	Id				INT IDENTITY,
	OrderId			VARCHAR(50),
	OrderProdId		VARCHAR(50),
	OrderProdDesc	VARCHAR(50),
	OrderProdQty	FLOAT,
	OrderProdUOM	VARCHAR(10),
	BatchId			VARCHAR(50),
	
	EngUnitId		INT,
	PPId			INT,
	ProcessOrder	AS OrderId,
	BOMId			INT,
	BOMFId			INT,
	ProdId			INT
)
 
DECLARE @PGBOM TABLE
(
	OrderId			VARCHAR(50),
	BOMRefNo		INT,
	MaterialDesc	VARCHAR(50),
	MaterialQty		FLOAT,
	MaterialUOM		VARCHAR(10),
	
	BOMFId			INT,
	BOMFIId			INT,
	ProdId			INT
)
 
DECLARE @bom TABLE 
(
	BOM_Id			INT IDENTITY, 
	BOM_Desc		VARCHAR(50), 
	BOM_Family_Id	INT, 
	Is_Active		INT,
	Something		INT
)
 
DECLARE @bomf TABLE 
(
	BOM_Formulation_Id		INT IDENTITY, 
	BOM_Formulation_Code	VARCHAR(50), 
	BOM_Formulation_Desc	VARCHAR(50), 
	BOM_Id					INT, 
	Eng_Unit_Id				INT, 
	Quantity_Precision		INT, 
	Standard_Quantity		FLOAT,
	Something				INT
)
 
DECLARE @bomfi TABLE 
(
	BOM_Formulation_Item_Id		INT IDENTITY, 
	BOM_Formulation_Id			INT, 
	BOM_Formulation_Order		INT, 
	Eng_Unit_Id					INT, 
	LTolerance_Precision		INT, 
	Prod_Id						INT, 
	Quantity					FLOAT, 
	Quantity_Precision			INT, 
	Scrap_Factor				INT, 
	Use_Event_Components		INT, 
	UTolerance_Precision		INT,
	Something					INT
)
 
/*
Id	OrderId		OrderProdId	OrderProdDesc						OrderProdQty	OrderProdUOM	BatchId		EngUnitId	PPId	ProcessOrder	BOMId	BOMFId	ProdId
1	905045974	98677867	BC162 Main Mix						6000			KG				0004608620	50003		390815	905045974		277522	277636	6535
 
2	905049755	98677867	BC162 Main Mix						6000			KG				0004609455	50003		NULL	905049755		277523	277637	6535
3	905045975	98879577	BC144  CC4005 / CC4004 Main Mix		6200			KG				0004608641	50003		NULL	905045975		277524	277638	6536
4	905045973	98677867	BC162 Main Mix						6000			KG				0004608613	50003		NULL	905045973		277525	277639	6535
5	905049758	98677867	BC162 Main Mix						6000			KG				0004609458	50003		NULL	905049758		277526	277640	6535
 
select * from dbo.bill_of_material where bom_id = 277522
select * from dbo.bill_of_material_formulation where bom_id = 277522
select * from dbo.bill_of_material_formulation_item where bom_formulation_id = 277640
 
select * from dbo.production_plan where process_order = '905049755'
 
 
 
INSERT @PGOrder (OrderId,		OrderProdId,	OrderProdDesc,						OrderProdQty,	OrderProdUOM,	BatchId,		EngUnitId,	PPId,		BOMId,	BOMFId,	ProdId)
VALUES
(	'905049755',	'98677867',	'BC162 Main Mix',						6000,			'KG',				'0004609455',	50003,		NULL,			277523,	277637,	6535),
(	'905045975',	'98879577',	'BC144  CC4005 / CC4004 Main Mix',		6200,			'KG',				'0004608641',	50003,		NULL,			277524,	277638,	6536),
(	'905045973',	'98677867',	'BC162 Main Mix',						6000,			'KG',				'0004608613',	50003,		NULL,			277525,	277639,	6535),
(	'905049758',	'98677867',	'BC162 Main Mix',						6000,			'KG',				'0004609458',	50003,		NULL,			277526,	277640,	6535)
 
select * from @PGOrder
*/
 
BEGIN TRY
 
BEGIN TRAN
 
	-- move to next set of orders xxxxxx-9 will become xxxxxx-10
	DECLARE @MaxVersion INT;
	select @MaxVersion = MAX(substring(ORDER_ID, charindex('-', ORDER_ID) + 1, 500)) FROM dbo.Local_MPWS_IMPORT_PM_ORDER_LG
	if @MaxVersion is not null
	begin
		UPDATE dbo.Local_MPWS_IMPORT_PM_ORDER_LG
			SET ORDER_ID = REPLACE(ORDER_ID, '-' + CAST(@MaxVersion AS VARCHAR(5)), '-' + CAST(@MaxVersion + 1 AS VARCHAR(5)))
		UPDATE dbo.Local_MPWS_IMPORT_MM_DISP_MATL_LG
			SET ORDER_ID = REPLACE(ORDER_ID, '-' + CAST(@MaxVersion AS VARCHAR(5)), '-' + CAST(@MaxVersion + 1 AS VARCHAR(5)))
		UPDATE dbo.Local_MPWS_IMPORT_PM_BATCH_LG
			SET ORDER_ID = REPLACE(ORDER_ID, '-' + CAST(@MaxVersion AS VARCHAR(5)), '-' + CAST(@MaxVersion + 1 AS VARCHAR(5)))
	end
 
	-- read import orders
	INSERT @PGOrder (OrderId, OrderProdId, OrderProdDesc, OrderProdQty, OrderProdUOM, BatchId, EngUnitId, ProdId)
		SELECT DISTINCT 
			o.ORDER_ID,
			o.ORDER_PROD_ID,
			o.ORDER_PROD_DESC,
			o.ORDER_PROD_QTY,
			o.ORDER_PROD_UOM,
			b.BATCH_ID,
			eu.Eng_Unit_Id,
			p.Prod_Id
		FROM dbo.Local_MPWS_IMPORT_PM_ORDER_LG o
			JOIN dbo.Local_MPWS_IMPORT_PM_BATCH_LG b ON b.ORDER_ID = o.ORDER_ID
			JOIN dbo.Engineering_Unit eu ON eu.Eng_Unit_Code = o.ORDER_PROD_UOM
			LEFT JOIN dbo.Products_Base p ON p.Prod_Code = o.ORDER_PROD_ID
		WHERE ORDER_PROD_DESC <> 'Material Master not downloaded from SAP'
 
	IF EXISTS (SELECT ProdId FROM @PGOrder WHERE ProdId IS NULL)
	BEGIN
 
		PRINT 'Order Missing Product'
		SELECT * FROM @PGOrder WHERE ProdId IS NULL
	
	END
 
	-- read import bom items
	INSERT @PGBOM (OrderId, BOMRefNo, MaterialDesc, MaterialQty, MaterialUOM, ProdId)
		SELECT DISTINCT 
			o.OrderId,
			BOM_REF_NO, 
			MATERIAL_DESC, 
			SUM(MATERIAL_QTY) material_qty, 
			MATERIAL_UOM,
			p.Prod_Id
		FROM dbo.Local_MPWS_IMPORT_MM_DISP_MATL_LG dm
			JOIN @PGOrder o ON o.OrderId = dm.ORDER_ID
			LEFT JOIN dbo.Products_Base p ON p.Prod_Code = dm.MATERIAL_ID
		WHERE dm.DISPENSE_STATUS = 'complete' and dm.MATERIAL_DESC is not null
		GROUP BY o.OrderId, dm.BOM_REF_NO, dm.MATERIAL_DESC, dm.MATERIAL_UOM, p.Prod_Id
 
	IF EXISTS (SELECT ProdId FROM @PGBOM WHERE ProdId IS NULL)
	BEGIN
 
		PRINT 'BOM Missing Product'
		SELECT * FROM @PGBOM WHERE ProdId IS NULL
	
	END
 
	--IF EXISTS (SELECT BOM_Desc FROM dbo.Bill_Of_Material b JOIN @PGOrder o ON o.ProcessOrder = b.BOM_Desc)
	--BEGIN
 
	--	PRINT 'BOM_Desc already exists in dbo.Bill_Of_Material'
	--	SELECT BOM_Desc FROM dbo.Bill_Of_Material b JOIN @PGOrder o ON o.ProcessOrder = b.BOM_Desc
	
	--END
 
	-- create bom
	--MERGE INTO @bom b --dbo.Bill_Of_Material b
	MERGE INTO dbo.Bill_Of_Material b
	USING @PGOrder o ON 1 = 0
	--USING @PGOrder o ON o.ProcessOrder = b.BOM_Desc
	WHEN NOT MATCHED THEN
		INSERT (BOM_Desc, BOM_Family_Id, Is_Active)
		VALUES (o.ProcessOrder, 2, 1)
		OUTPUT inserted.BOM_Id, inserted.BOM_Desc
		INTO @PGOrder (BOMId, OrderId);
 
	UPDATE o
		SET BOMId = bom.BOM_Id
	FROM @PGOrder o
		JOIN dbo.Bill_Of_Material bom ON bom.BOM_Desc = o.ProcessOrder
 
	--UPDATE o1
	--	SET BOMId = o2.BOMId
	--	FROM @PGOrder o1
	--		JOIN @PGOrder o2 ON o1.OrderId = o2.OrderId
	--			AND o2.OrderProdId IS NULL
	--	WHERE o1.OrderProdId IS NOT NULL;
 
	DELETE @PGOrder WHERE OrderProdId IS NULL;
 
	-- create bomf
	--MERGE INTO @bomf b --dbo.Bill_Of_Material_Formulation b
	MERGE INTO dbo.Bill_Of_Material_Formulation b
	USING @PGOrder o ON 1 = 0
	--USING @PGOrder o ON o.ProcessOrder <> b.BOM_Formulation_Desc
	WHEN NOT MATCHED THEN
		INSERT (BOM_Formulation_Code, BOM_Formulation_Desc, BOM_Id, Eng_Unit_Id, Quantity_Precision, Standard_Quantity)
		VALUES (o.ProcessOrder, o.ProcessOrder, o.BOMId, o.EngUnitId, 2, o.OrderProdQty)
		OUTPUT inserted.BOM_Formulation_Id, inserted.BOM_Formulation_Code
		INTO @PGOrder (BOMFId, OrderId);
 
	--UPDATE o
	--	SET BOMFId = bomf.BOM_Formulation_Id
	--FROM @PGOrder o
	--	JOIN dbo.Bill_Of_Material_Formulation bomf ON bomf.BOM_Formulation_Desc = o.OrderId
 
	UPDATE o1
		SET BOMFId = o2.BOMFId
		FROM @PGOrder o1
			JOIN @PGOrder o2 ON o1.OrderId = o2.OrderId
				AND o2.OrderProdId IS NULL
		WHERE o1.OrderProdId IS NOT NULL;
 
	DELETE @PGOrder WHERE OrderProdId IS NULL;
 
	-- create bomfi
	--MERGE INTO @bomfi b --dbo.Bill_Of_Material_Formulation_Item t
	MERGE INTO dbo.Bill_Of_Material_Formulation_Item b
	USING (	SELECT
				b.OrderId,
				b.BOMRefNo,
				o.BOMFId, 
				ROW_NUMBER() OVER (PARTITION BY b.OrderId ORDER BY b.BOMRefNo) BOMOrder,
				b.ProdId,
				b.MaterialQty,
				eu.Eng_Unit_Id
			FROM @PGBOM b 
				JOIN @PGOrder o ON o.OrderId = b.OrderId
				JOIN dbo.Engineering_Unit eu ON eu.Eng_Unit_Code = b.MaterialUOM) s ON 1 = 0
				--JOIN dbo.Engineering_Unit eu ON eu.Eng_Unit_Code = b.MaterialUOM) s ON s.BOMFId = b.BOM_Formulation_Id
	WHEN NOT MATCHED THEN
		INSERT (BOM_Formulation_Id, BOM_Formulation_Order, Eng_Unit_Id, LTolerance_Precision, Prod_Id, 
				Quantity, Quantity_Precision, Scrap_Factor, Use_Event_Components, UTolerance_Precision, PU_Id)
		VALUES (s.BOMFId, s.BOMOrder, s.Eng_Unit_Id, 2, s.ProdId, s.MaterialQty, 2, 0, 1, 2, @PreweighPUID)
		OUTPUT inserted.BOM_Formulation_Item_Id, inserted.BOM_Formulation_Id, s.OrderId, s.BOMRefNo
		INTO @PGBOM (BOMFIId, BOMFId, OrderId, BOMRefNo);
 
	--UPDATE o
	--	SET BOMFIId = bomfi.BOM_Formulation_Item_Id
	--FROM @PGBOM o
	--	JOIN dbo.Bill_Of_Material_Formulation_Item bomfi ON bomfi.BOM_Formulation_Id = o.BOMFId AND bomfi.Prod_Id = o.ProdId
 
	UPDATE o1
		SET BOMFIId = o2.BOMFIId,
			BOMFId	= o2.BOMFId
		FROM @PGBOM o1
			JOIN @PGBOM o2 ON o1.OrderId = o2.OrderId
				AND o1.BOMRefNo = o2.BOMRefNo
				AND o2.MaterialQty IS NULL
		WHERE o1.MaterialQty IS NOT NULL;
 
	DELETE @PGBOM WHERE MaterialQty IS NULL;
 
	select * from @pgorder
	select * from @pgbom
	--select * from @bom
	--select * from @bomf
	--select * from @bomfi
 
	-- bomfi dispense station id udp, null just to create
	INSERT dbo.Table_Fields_Values (KeyId, Table_Field_Id, TableId, Value)
		SELECT
			b.BOMFIId,
			@BOMFI_FieldId_DStation,
			@BOMFI_TableId,
			NULL Value
		FROM @PGBOM b
 
		--SELECT
		--	b.BOM_Formulation_Item_Id,
		--	@BOMFI_FieldId_DStation,
		--	@BOMFI_TableId,
		--	NULL Value
		--FROM @bomfi b
 
	-- bomfi item status udp, 1 (released) just to create
	INSERT dbo.Table_Fields_Values (KeyId, Table_Field_Id, TableId, Value)
		SELECT
			b.BOMFIId,
			@BOMFI_FieldId_ItemStat,
			@BOMFI_TableId,
			@BomfiStatusId Value
		FROM @PGBOM b
 
		--SELECT
		--	b.BOM_Formulation_Item_Id,
		--	@BOMFI_FieldId_ItemStat,
		--	@BOMFI_TableId,
		--	1 Value
		--FROM @bomfi b
 
	SELECT
		@RowNo = 1,
		@RowMax = MAX(Id)
	FROM @PGOrder
 
	WHILE @RowNo <= @RowMax
	BEGIN
 
		SET @CurrDate = GETDATE();
	
		SELECT
			@ProdId				= o.ProdId,
			@ForecastStartTime	= @CurrDate,
			@ForecastEndTime	= DATEADD(hh, 2, @CurrDate),
			@EntryOn			= @CurrDate,
			@ForecastQuantity	= o.OrderProdQty,
			@ProcessOrder		= o.ProcessOrder,
			@BOMFormulationId	= o.BOMFId,
			@BatchId			= o.BatchId,
			@PPId				= NULL
		FROM @PGOrder o
		WHERE o.Id = @RowNo;
 
		EXEC dbo.spServer_DBMgrUpdProdPlan
	--SELECT 'UpdProdPlan',
			@PPId OUTPUT, 
			@TransType,
			@TransNum,
			@PathId,
			@CommentId,
			@ProdId,
			@ImpliedSequence,
			@PPStatusId,
			@PPTypeId,
			@SourcePPId,
			@UserId,
			@ParentPPId,
			@ControlType,
			@ForecastStartTime,
			@ForecastEndTime,
			@EntryOn,
			@ForecastQuantity,
			@ProductionRate,
			@AdjustedQuantity,
			@BlockNumber,
			@ProcessOrder,
			@TransactionTime,
			@Misc1,
			@Misc2,
			@Misc3,
			@Misc4,
			@BOMFormulationId,
			@UserGeneral1,
			@UserGeneral2,
			@UserGeneral3,
			@ExtendedInfo
 
		EXEC dbo.spServer_DBMgrUpdProdSetup
	--SELECT 'UpdProdSetup',
			@PPSetupId OUTPUT,	--@PPSetupId
			1,					--@TransType
			0,					--@TransNum
			@UserId,			--@UserId
			@PPId,				--@PPId
			NULL,				--@ImpliedSequence
			@PPStatusId,		--@PPStatusId
			NULL,				--@PatternRepititions
			NULL,				--@CommentId
			@ForecastQuantity,	--@ForecastQuantity
			NULL,				--@BaseDimensionX
			NULL,				--@BaseDimensionY
			NULL,				--@BaseDimensionZ
			NULL,				--@BaseDimensionA
			NULL,				--@BaseGeneral1
			NULL,				--@BaseGeneral2
			NULL,				--@BaseGeneral3
			NULL,				--@BaseGeneral4
			NULL,				--@Shrinkage
			@BatchId,			--@PatternCode
			@PathId,			--@PathId
			@EntryOn,			--@EntryOn
			@EntryOn,			--@TransactionTime
			NULL,				--@ParentPPSetupId
			NULL				--@Unused
 
		-- create po priority udp
		INSERT dbo.Table_Fields_Values (KeyId, Table_Field_Id, TableId, Value)
			VALUES (@PPId, @Plan_FieldId_Priority, @Plan_TableId, 1)
 
		SELECT @PPId ppid, @Plan_FieldId_Priority priorityfield, @Plan_TableId plantableid, 1 defaultpriority
 
		-- update order table with pp_id
		UPDATE @PGOrder
			SET PPId = @PPId
			WHERE Id = @RowNo;
 
		SET @RowNo += 1;
 
	END
 
COMMIT;
 
END TRY
 
BEGIN CATCH
 
	SELECT
		@ErrorMessage	= ERROR_MESSAGE(),
		@ErrorSeverity	= ERROR_SEVERITY(),
		@ErrorState		= ERROR_STATE()
 
	SELECT
		@ErrorMessage ErrorMessage,
		@ErrorSeverity ErrorSeverity,
		@ErrorState ErrorState
 
	IF @@TRANCOUNT > 0 ROLLBACK;
 
	RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
 
END CATCH
 
SELECT * FROM @PGOrder
SELECT * FROM @PGBOM
 
 
 
 
 
 
 
