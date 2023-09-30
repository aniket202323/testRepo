-------------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[spLocal_CmnMobileAppGetPOInfo]
		@ProcessOrder			varchar(50)
	
AS
SET NOCOUNT ON

DECLARE 
		--Generic
		@SPName						varchar(255),
		@UDPIsBOMPLCDownloadDesc	varchar(50),
		@UDPIsBOMPLCDownloadId		int,
		@TableIdPrdExecInputs		int,
		@UDPBOMOGDesc				varchar(50),
		@UDPBOMOGId					int,
		@TableIdBOMfi				int,
		@UDPRMIOGDesc				varchar(50),
		@UDPRMIOGId					int,
		--Variable to get the raw matrial input
		@PuIdProductionPoint		int,
		--Loop
		@PEIID						int,
		@OG							varchar(10),
		@IsDownloadable				bit


DECLARE @MessageType	varchar(255),
		@MainData		varchar(255),
		@PathID			int,
		@PathCode		varchar(50)


DECLARE @PPID			int,
		@PPStatusID		int,
		@PPStatusDesc	varchar(50),
		@OCL04Status	bit,
		@ExpirationDate	varchar(20),
		@BatchID		varchar(50),
		@PlannedQty		float,
		@ProdCode		varchar(25),
		@BOMQty			float,
		@BOMID			int


DECLARE	@tblRMParentInfo TABLE (
		PEIId					int,
		InputName				varchar(50),
		OG						varchar(10),
		IsDownloadable			bit
			)

DECLARE @tblBOMRMList TABLE
		(	BOMRMId						int ,
			PPId						int,
			ProcessOrder				varchar(50),
			ProdId						int,
			ProdCode					varchar(50),
			ProdIdAlt					int,
			ProdCodeAlt					varchar(50),
			Quantity					DECIMAL(15,3),
			OG							varchar(10),
			IsToDownload				bit DEFAULT 0
		)

SELECT	@SPName		= 	'spLocal_CmnMobileAppGetPOInfo'

SET @MessageType	='WorkOrderUpdate'
SET @MainData		= '-ConsConfirmation'

SET		@TableIdPrdExecInputs		= (SELECT TableID			FROM DBO.Tables t WITH(NOLOCK)	WHERE TableName = 'PRDExec_Inputs')	
SET		@TableIdBOMfi				= (SELECT TableID			FROM DBO.Tables t WITH(NOLOCK)	WHERE TableName = 'Bill_of_Material_Formulation_Item')	
SELECT 	@UDPIsBOMPLCDownloadDesc	= 'IsBOMPLCDownload'
SET		@UDPIsBOMPLCDownloadId		= (SELECT Table_FIeld_ID	FROM [DBO].[Table_Fields]		WHERE Table_Field_Desc = @UDPIsBOMPLCDownloadDesc AND tableid = @TableIdPrdExecInputs)
SELECT 	@UDPBOMOGDesc					= 'MaterialOriginGroup'
SET		@UDPBOMOGId					= (SELECT Table_FIeld_ID	FROM [DBO].[Table_Fields]		WHERE Table_Field_Desc = @UDPBOMOGDesc AND tableid = @TableIdBOMfi)
SELECT 	@UDPRMIOGDesc				= 'Origin Group'
SET		@UDPRMIOGId					= (SELECT Table_FIeld_ID	FROM [DBO].[Table_Fields]		WHERE Table_Field_Desc = @UDPRMIOGDesc AND tableid = @TableIdPrdExecInputs)

-----------------------------------------------------------
--  Get PO information 
-----------------------------------------------------------
SELECT	@PPID			=	PP.PP_ID,
		@PPStatusID		=	pps.pp_status_ID,
		@PPStatusDesc	=	pps.pp_Status_Desc,
		@ExpirationDate =	pp.User_General_2, 
		@BatchID		=	pp.User_General_1,
		@PlannedQty		=	pp.Forecast_Quantity,
		@ProdCode		=	p.Prod_Code,
		@BOMID			=	pp.BOM_Formulation_ID
FROM dbo.production_plan pp				WITH(NOLOCK)
JOIN dbo.Production_Plan_Statuses pps	WITH(NOLOCK)	ON	pp.pp_status_id	= pps.pp_status_id
JOIN dbo.Products p WITH(NOLOCK)	ON pp.Prod_ID = p.Prod_Id
WHERE pp.Process_Order = @ProcessOrder


-----------------------------------------------------------
-- REtrieve if OCL04 has been finished
-----------------------------------------------------------
SELECT @OCL04Status = coalesce((SELECT TOP 1 1
								FROM	[dbo].[Local_tblINTIntegrationMessages]
								WHERE	MessageType = @MessageType
								AND		MainData = @ProcessOrder + @MainData),0)




-----------------------------------------------------------------------------------------
--  2 -  Get the BOM info
-----------------------------------------------------------------------------------------

INSERT @tblBOMRMList (
		BOMRMId						,
		PPId						,
		ProcessOrder				,
		ProdId						,
		ProdCode					,
		ProdIdAlt					,
		ProdCodeAlt					,
		Quantity					,
		OG							,
		IsToDownload
		)
SELECT	bomfi.BOM_Formulation_Item_Id,
		pp.pp_id,
		pp.process_order,
		p1.prod_id,
		p1.prod_code,
		boms.prod_id,
		p2.Prod_Code,
		bomfi.Quantity,
		tfv.Value,
		0
FROM dbo.production_plan pp						WITH(NOLOCK)
JOIN dbo.Bill_Of_Material_Formulation_Item bomfi	WITH(NOLOCK)	ON pp.BOM_Formulation_Id = bomfi.BOM_Formulation_Id
JOIN dbo.products p1								WITH(NOLOCK)	ON bomfi.prod_id = p1.prod_id
JOIN dbo.Table_Fields_Values tfv					WITH(NOLOCK)	ON tfv.tableid = @TableIdBOMfi
																		AND	tfv.table_field_id = @UDPBOMOGId
																		AND tfv.keyid = bomfi.BOM_Formulation_Item_Id
LEFT JOIN dbo.Bill_Of_Material_Substitution boms	WITH(NOLOCK)	ON bomfi.BOM_Formulation_Item_Id = boms.BOM_Formulation_Item_Id
LEFT JOIN dbo.products p2							WITH(NOLOCK)	ON boms.prod_id = p2.prod_id
WHERE pp.pp_id = @PPID
-----------------------------------------------------------------------------------------
--  3 -  Check In raw material Input if this is a downloadable OG
-----------------------------------------------------------------------------------------
--Get the production point unit (current solution can have only one per path)
SELECT	@pathId = pp.path_id		,
		@PathCode = Path_code
FROM	dbo.production_plan		pp WITH(NOLOCK) 
JOIN	dbo.prdexec_paths prd  WITH(NOLOCK)  ON pp.Path_id = prd.Path_id 
WHERE pp_id = @ppid
SET @PuIdProductionPoint	= (SELECT TOP 1 pu_id	FROM dbo.prdExec_path_units	WITH(NOLOCK) WHERE path_id = @pathId AND Is_Production_Point = 1)

-------------------------------------------------------------------------------
--		Based on the Raw Material Input of this Unit,
--		Identify the Raw Material Parent PUs 
------------------------------------------------------------------------------- 

INSERT intO @tblRMParentInfo(
		PEIId			,
		InputName							
							)
SELECT 	pei.pei_id			AS PEIId,
		pei.Input_Name		AS InputName
FROM dbo.PrdExec_Inputs pei WITH(NOLOCK)
--WHERE pei.PU_Id = @PuIdProductionPoint  --v1.5
WHERE pei.PU_Id IN (SELECT pu_id FROM prdExec_path_units WHERE path_id = @pathId)  --V1.6

SET @PEIID = (SELECT MIN(peiid) FROM @tblRMParentInfo)
	
WHILE @PEIID IS NOT NULL
BEGIN
	--Get OG
		SET @OG = (	SELECT Value
					FROM  dbo.Table_Fields_Values  WITH(NOLOCK)
					WHERE TableId = @TableIdPrdExecInputs
						AND Table_Field_id = @UDPRMIOGId
						AND KeyId = @PEIID
						)


	--GET IsDownloadable
		SET @IsDownloadable = (	SELECT COALESCE(Value,0)
								FROM  dbo.Table_Fields_Values  WITH(NOLOCK)
								WHERE TableId = @TableIdPrdExecInputs
								AND Table_Field_id = @UDPIsBOMPLCDownloadId
								AND KeyId = @PEIID
								)

		IF @IsDownloadable IS NOT NULL
		BEGIN
			--Update the main outputtable table
			UPDATE @tblBOMRMList
			SET IsToDownload = @IsDownloadable
			WHERE OG = @OG
		END

	SET @PEIID = (SELECT min(peiid) FROM @tblRMParentInfo WHERE PEIId > @PEIID)
END


SET @BOMQty = (SELECT COUNT(1) FROM  @tblBOMRMList WHERE IsToDownload = 1)


SELECT	@PPID			AS PPID,
		@ProcessOrder	AS PO,
		@PPStatusID		AS StatusID,
		@PPStatusDesc	AS StatusDesc,
		@OCL04Status	AS OLC04Completion,
		@ExpirationDate	AS ExpirationDate,
		@BatchID		AS BatchID,
		@PlannedQty		AS PlannedQty,
		@ProdCode		AS MaterialCode,
		@BOMQty			AS BOMQty,
		@PathID			AS PathID,
		@PathCode		AS PathCode
		

SET NOCOUNT OFF
RETURN