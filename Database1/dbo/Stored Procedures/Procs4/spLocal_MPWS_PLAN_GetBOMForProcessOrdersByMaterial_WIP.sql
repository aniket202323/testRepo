 
CREATE   	PROCEDURE [dbo].[spLocal_MPWS_PLAN_GetBOMForProcessOrdersByMaterial_WIP]
		@PathId					INT,
		@PONumberMask			VARCHAR(8000),
		@BOMItemStatusIdMask	VARCHAR(8000)	= NULL,
		@MakingSystem			VARCHAR(50)		= NULL,
		@MaterialMask			VARCHAR(50),
		@ErrorCode		INT				OUTPUT,
		@ErrorMessage	VARCHAR(255)	OUTPUT
--WITH ENCRYPTION			 
AS	
-------------------------------------------------------------------------------
-- Get BOM info for passed in process orders
/*
 
declare @ErrorCode INT, @ErrorMessage VARCHAR(500)
EXEC spLocal_MPWS_PLAN_GetBOMForProcessOrdersByMaterial_WIP 83, null, null, '162 Ligne Renamed', 'mymask', @ErrorCode OUTPUT, @ErrorMessage OUTPUT
select @ErrorCode,@ErrorMessage
*/
-- Date         Version Build Author  
-- 14-Aug-2018  001     001		Andrew Drake		Initial development	

-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------
SET NOCOUNT ON
 

 
DECLARE	@tPO				TABLE
(
	Id						INT					IDENTITY(1,1)	NOT NULL,
	ProcessOrder			VARCHAR(255)						NULL
)
 
DECLARE	@tBOMFIStatusId		TABLE
(
	Id						INT					IDENTITY(1,1)	NOT NULL,
	BOMFIStatusId			VARCHAR(255)						NULL
)
 
DECLARE	@tOutput			TABLE
(
	Id						INT					IDENTITY(1,1)	NOT NULL,
	PPId					INT									NULL,
	ProcessOrder			VARCHAR(25)							NULL,
	MakingSystem			VARCHAR(50)							NULL,
	PPStatusId				INT									NULL,
	PPStatusDesc			VARCHAR(255)						NULL,
	BOMFIId					INT									NULL,
	BOMFormulationOrder		INT									NULL,
	ProdId					INT									NULL,
	ProdCode				VARCHAR(255)						NULL,
	ProdDesc				VARCHAR(255)						NULL,
	PWQuantity				FLOAT								NULL,
	SAPQuantity				FLOAT								NULL,
	DispensedQuantity		FLOAT								NULL,
	RemainingQuantity		FLOAT								NULL,
	UOM						VARCHAR(255)						NULL,
	BOMFIStatusId			INT									NULL,
	BOMFIStatusDesc			VARCHAR(255)						NULL,
	Kit						VARCHAR(50)							NULL,
	EngUnitId				INT									NULL,
	CanOverrideQty			BIT
)
	

insert @tOutput(
	PPId,
	ProcessOrder,
	MakingSystem,
	PPStatusId,
	PPStatusDesc,
	BOMFIId,
	BOMFormulationOrder,
	ProdId,
	ProdCode,
	ProdDesc,
	PWQuantity,
	SAPQuantity,
	DispensedQuantity,
	RemainingQuantity,
	UOM,
	BOMFIStatusId,
	BOMFIStatusDesc,
	Kit,
	EngUnitId,
	CanOverrideQty)

select	1,--PPId,
		'ProcessOrder',--ProcessOrder,
		'MakingSystem',--MakingSystem,
		9,--PPStatusId,
		'Running',--PPStatusDesc,
		222,--BOMFIId,
		3,--BOMFormulationOrder,
		444,--ProdId,
		'ProdCode',--ProdCode,
		'ProdDesc',--ProdDesc,
		111.77,--PWQuantity,
		345,--SAPQuantity,
		2345.88,--DispensedQuantity,
		123.77,--RemainingQuantity,
		'KG',--UOM,
		7,--BOMFIStatusId,
		'BOMFIStatusDesc',--BOMFIStatusDesc,
		'Kit',--Kit,
		50007,--EngUnitId,
		1--CanOverrideQty

ReturnData:
		
SELECT	Id								Id,
		ProdId							ProdId,
		ProdCode						ProdCode,
		ProdDesc						ProdDesc,
		ISNULL(PWQuantity,0)			PWQuantity,
		ISNULL(SAPQuantity,0)			SAPQuantity,
		ISNULL(DispensedQuantity,0)     DispQty,
		ISNULL(RemainingQuantity,0)		RemainQty,
		UOM								UOM,
		PPId							PPId,
		ProcessOrder					ProcessOrder,
		PPStatusId						PPStatusId,
		PPStatusDesc					PPStatusDesc,
		BOMFIId							BOMFIId,
		BOMFormulationOrder				BOMFormulationOrder,
		BOMFIStatusId					BOMFIStatusId,
		BOMFIStatusDesc					BOMFIStatusDesc,
		Kit								Kit,
		MakingSystem					MakingSystem,
		CanOverrideQty 
		FROM	@tOutput
		--WHERE	@MakingSystem IS NULL OR MakingSystem = @MakingSystem AND (@MaterialMask IS NULL OR @MaterialMask = ProdCode)
		ORDER
		BY		Id
 
 
