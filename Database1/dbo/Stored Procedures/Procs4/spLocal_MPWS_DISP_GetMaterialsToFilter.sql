 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_DISP_GetMaterialsToFilter]
		@ErrorCode		INT				OUTPUT		,
		@ErrorMessage	VARCHAR(500)	OUTPUT		,
		@DispenseStationId	INT						,	-- PU_Id of dispense unit
		@POStatuses		VARCHAR(255)	=	'Released,Dispensing'  --defaulted to Released,Dispensing
--WITH ENCRYPTION
AS				
SET NOCOUNT ON
-------------------------------------------------------------------------------
-- Distinct list of materials in PO LIne items in "Released" or "Dispensing" status
/*
declare @ErrorCode INT, @ErrorMessage VARCHAR(500)
exec spLocal_MPWS_DISP_GetMaterialsToFilter @ErrorCode output, @ErrorMessage output, 6078
select @ErrorCode, @ErrorMessage
*/
-- Date         Version Build Author  
-- 06-Oct-2015  001     001    Susan Lee (GEIP)  Initial development
-- 10-Nov-2017  001     002    Susan Lee (GE Digital) Filter by preweigh BOM and Released/Dispensing statuses	
-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------


DECLARE		@DispenseMaterials	TABLE
(
	ProdId		INT,
	ProdCode	VARCHAR(50)
)
 
DECLARE		@tBOMFormulation	TABLE
(
	BOMFormulationId	INT	
)
 
DECLARE @tStatus	TABLE
(
	Id		INT	IDENTITY(1,1)	NOT NULL	,
	Status	VARCHAR(255)		NULL
)
 
DECLARE @PathId		INT,
		@PLId		INT

-------------------------------------------------------------------------------
--  Initialize output values
-------------------------------------------------------------------------------
SELECT	@ErrorCode		=	0,
		@ErrorMessage	=	'Initialized'
 
-------------------------------------------------------------------------------
--  Extract Statuses
-------------------------------------------------------------------------------
INSERT @tStatus (Status)
SELECT *
FROM dbo.fnLocal_CmnParseListLong(@POStatuses,',')
	
-------------------------------------------------------------------------------
-- Validate Parameters
-------------------------------------------------------------------------------
 

 
-------------------------------------------------------------------------------
-- Get PO path
-------------------------------------------------------------------------------
SELECT	@PathId	=	Path_Id,
		@PLId	=	pu.PL_Id
FROM	dbo.Prdexec_Paths		pep			WITH (NOLOCK)
JOIN	dbo.Prod_Units_Base		pu			WITH (NOLOCK)
	ON	pu.PL_Id	=	pep.PL_Id
WHERE	pu.PU_Id	=	@DispenseStationId
 
-------------------------------------------------------------------------------
-- Insert into list of BOM formulation Ids
-------------------------------------------------------------------------------
INSERT INTO @tBOMFormulation
	( BOMFormulationId )
SELECT	BOMf.BOM_Formulation_Id
FROM	dbo.Bill_Of_Material_Formulation		BOMf	WITH (NOLOCK)
JOIN	dbo.Production_Plan						pp		WITH (NOLOCK)
	ON	pp.BOM_Formulation_Id		=	BOMf.BOM_Formulation_Id
	AND pp.Path_Id					=	@PathId 

	
-------------------------------------------------------------------------------
-- Get list of dispense materials available to be dispensed
-------------------------------------------------------------------------------
 
INSERT INTO	@DispenseMaterials
(
		ProdId	,
		ProdCode
)
SELECT	DISTINCT 
		BOMfi.Prod_Id	,
		p.Prod_Code
FROM	Bill_Of_Material_Formulation_Item	BOMfi	WITH (NOLOCK)
JOIN	@tBOMFormulation					BOMf
	ON	BOMf.BOMFormulationId		=	BOMfi.BOM_Formulation_Id
JOIN	dbo.Table_Fields_Values				tfv		WITH (NOLOCK)
	ON	tfv.KeyId					=	BOMfi.BOM_Formulation_Item_Id
JOIN	dbo.Table_Fields					tf		WITH (NOLOCK) 
	ON	tf.Table_Field_Id			=	tfv.Table_Field_Id
JOIN	dbo.[Tables]						t		WITH (NOLOCK)
	ON	t.TableId					=	tf.TableId 
	AND t.TableId					=	tfv.TableId
JOIN	dbo.Products_Base						p		WITH (NOLOCK)
	ON	p.Prod_Id					=	BOMfi.Prod_Id
JOIN	dbo.Prod_Units_Base						bompu	WITH (NOLOCK)
	ON	bompu.PU_Id		=	bomfi.PU_Id
	AND bompu.PL_Id		=	@PLId
JOIN production_plan_statuses					pps		WITH (NOLOCK) 
	ON pps.PP_Status_Id =	tfv.Value
JOIN @tStatus									st 
	ON st.Status		=	pps.PP_Status_Desc
WHERE	tf.Table_Field_Desc			=	'BOMItemStatus'
	AND	t.TableName					=	'Bill_Of_Material_Formulation_Item'
 
-------------------------------------------------------------------------------
-- Return Data Table
-------------------------------------------------------------------------------
SELECT 		@ErrorMessage	=	'Success',
			@ErrorCode		=	1

SELECT
		ProdId		AS	MaterialID	,
		ProdCode	AS	Material	
FROM	@DispenseMaterials
ORDER BY ProdCode
 

