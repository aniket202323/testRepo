 
 
 
CREATE   PROCEDURE [dbo].[spLocal_MPWS_DISP_GetMaterialsToDispense]
	@ErrorCode			INT				OUTPUT,
	@ErrorMessage		VARCHAR(500)	OUTPUT,
	@MaterialCode		VARCHAR(50),
	@Statuses			VARCHAR(255),
	@DispenseStationId	INT,
	@AllowedMaterialsOnly	BIT = 0
--WITH ENCRYPTION 
AS	
 
SET NOCOUNT ON;
 
-------------------------------------------------------------------------------
-- Get list of materials needing to be dispensed
/*
declare @ErrorCode INT, @ErrorMessage VARCHAR(500)
exec spLocal_MPWS_DISP_GetMaterialsToDispense @ErrorCode OUTPUT, @ErrorMessage OUTPUT, NULL, 'RELEASED,DISPENSING', 3372
exec spLocal_MPWS_DISP_GetMaterialsToDispense @ErrorCode OUTPUT, @ErrorMessage OUTPUT,    0, 'RELEASED,DISPENSING', 3372
exec spLocal_MPWS_DISP_GetMaterialsToDispense @ErrorCode OUTPUT, @ErrorMessage OUTPUT, 6511, 'RELEASED,DISPENSING', 3372
 
select @ErrorCode, @ErrorMessage
*/
-- Date         Version Build	Author  
-- 06-Oct-2015  001     001		Susan Lee (GEIP)	Initial development
-- 10-Jun-2016	002		001		Jim Cameron (GE Digital)	Rewrite to return all fields
-- 22-Dec-2016	002		002		Jim Cameron (GE Digital)	Updated for OverrideQuantity
-- 08-Nov-2017  002     003     Susan Lee (GE Digital)		Change parameter MaterialId INT to MaterialCode and allow for partial match.
-- 11-Nov-2017  002     003     Susan Lee (GE Digital)		Filter BOMs by preweigh path
 
DECLARE @PathId		INT
DECLARE @PLId		INT
-------------------------------------------------------------------------------
--  Initialize output values
-------------------------------------------------------------------------------
SELECT	@ErrorCode		=	0,
		@ErrorMessage	=	'Initialized'
 
-------------------------------------------------------------------------------
-- Get PO path
-------------------------------------------------------------------------------
SELECT	
	@PathId	= Path_Id,
	@PLId = pu.PL_Id
FROM dbo.Prdexec_Paths pep
	JOIN dbo.Prod_Units_Base pu ON pu.PL_Id = pep.PL_Id
WHERE pu.PU_Id = @DispenseStationId
 
DECLARE @Bomfi TABLE
(
	PP_Id						INT,
	PP_Status_Desc				VARCHAR(50),
	BOM_Formulation_Item_Id		INT,
	BOMFI_Status				VARCHAR(50),
	Prod_Id						INT,
	Quantity					FLOAT,
	Eng_Unit_Id					INT,
	AllowedOnPU_Id				BIT DEFAULT 0
)
 
INSERT @Bomfi
	SELECT
		pp.PP_Id,
		pps.PP_Status_Desc,
		bomfi.BOM_Formulation_Item_Id,
		NULL,
		bomfi.Prod_Id,
		COALESCE(oq.Value, bomfi.Quantity) Quantity,
		bomfi.Eng_Unit_Id,
		0
	FROM dbo.Production_Plan pp
		JOIN dbo.Production_Plan_Statuses pps ON pps.PP_Status_Id = pp.PP_Status_Id
		JOIN dbo.Bill_Of_Material_Formulation_Item bomfi ON pp.BOM_Formulation_Id = bomfi.BOM_Formulation_Id
		JOIN dbo.Prod_Units_Base bompu ON bompu.PU_Id = bomfi.PU_Id AND bompu.pl_id = @PLId
		OUTER APPLY dbo.fnLocal_MPWS_GetUDP(bomfi.BOM_Formulation_Item_Id, 'OverrideQuantity',  'Bill_Of_Material_Formulation_Item') oq
	WHERE pp.Path_Id = @PathId
		AND pp.BOM_Formulation_Id IS NOT NULL
		AND pps.PP_Status_Desc IN (	SELECT
										x.y.value('.', 'varchar(50)') StatusDesc
									FROM (SELECT CAST('<p>' + REPLACE(@Statuses, ',', '</p><p>') + '</p>' AS XML) q) p
										CROSS APPLY q.nodes('/p/text()') x(y)
								)
 
;WITH bomfis AS
(
	SELECT
		b.BOM_Formulation_Item_Id,
		p.Prod_Id MaterialId,
		p.Prod_Code Material,
		p.Prod_Desc MaterialDesc,
		--COUNT(b.PP_Id) OVER (PARTITION BY p.Prod_Id) NumOfPOs,	-- double counts a PO if material is in it more than once. in sql server 2012 could have been count(distinct b.pp_id)...
		DENSE_RANK() OVER (PARTITION BY p.Prod_Id ORDER BY b.PP_Id) + DENSE_RANK() OVER (PARTITION BY p.Prod_Id ORDER BY b.PP_Id DESC) - 1 NumOfPOs,	-- only counts a PO once.
		SUM(b.Quantity) TargetQty,
		eu.Eng_Unit_Code UOM,
		CASE WHEN pup.PU_Id IS NULL THEN 'N' ELSE 'Y' END OKToDispense
	FROM @Bomfi b
		JOIN dbo.Products_Base p ON b.Prod_Id = p.Prod_Id
		JOIN dbo.Engineering_Unit eu ON b.Eng_Unit_Id = eu.Eng_Unit_Id
		LEFT JOIN dbo.PU_Products pup ON pup.Prod_Id = b.Prod_Id
			AND pup.PU_Id = @DispenseStationId
	WHERE (p.Prod_Code LIKE '%' + @MaterialCode + '%' OR ISNULL(@MaterialCode, '') = '') 
	GROUP BY b.BOM_Formulation_Item_Id, p.Prod_Id, p.Prod_Code, p.Prod_Desc, b.pp_id, eu.Eng_Unit_Code, pup.PU_Id
)
, evt AS
(
	SELECT
		ed.PP_Id,
		ed.Event_Id,
		SUM(ed.Final_Dimension_X) DispensedWgt
	FROM dbo.Event_Details ed
		JOIN @Bomfi b ON b.PP_Id = ed.PP_Id
	GROUP BY ed.PP_Id, ed.Event_Id
)
, disp AS
(
	SELECT
		CAST(t.Result AS INT) BOMFormulationItemID,
		--pu.PU_Desc DispenseStation,
		ISNULL(SUM(DispensedWgt), 0.0) DispensedQty
	FROM evt
		JOIN dbo.Events e ON evt.Event_Id = e.Event_Id
		JOIN dbo.Tests t ON e.[Timestamp] = t.Result_On
		JOIN dbo.Variables_Base v ON t.Var_Id = v.Var_Id
			AND v.PU_Id = e.PU_Id
		OUTER APPLY dbo.fnLocal_MPWS_GetUDP(CAST(t.Result AS INT), 'DispenseStationId', 'Bill_Of_Material_Formulation_Item') ds
		LEFT JOIN dbo.Prod_Units_Base pu ON pu.PU_Id = ds.Value
	WHERE v.Test_Name = 'MPWS_DISP_BOMFIId'
	GROUP BY t.Result --, pu.PU_Desc
)
, dstat AS
(
	SELECT distinct
		peec.Value Material,
		pu.PU_Id DispStationId,
		pu.PU_Desc DispStation
	FROM dbo.EquipmentClass_EquipmentObject eeo
		JOIN dbo.Property_Equipment_EquipmentClass peec ON eeo.EquipmentId = peec.EquipmentId
		JOIN dbo.PAEquipment_Aspect_SOAEquipment pas ON peec.EquipmentId = pas.Origin1EquipmentId
		JOIN dbo.Prod_Units_Base pu ON pas.PU_Id = pu.PU_Id
	WHERE eeo.EquipmentClassName = 'Pre-Weigh - Dispense'
		AND peec.Name = 'DispenseMaterial'
)
SELECT
	b.MaterialId,
	b.Material,
	b.MaterialDesc,
	b.NumOfPOs,													-- number of process orders that require this material
	CAST(SUM(b.TargetQty) AS DECIMAL(10, 3)) TargetQty,						-- sum of PO line item qty for this material
	CAST(ISNULL(SUM(d.DispensedQty), 0.0) AS DECIMAL(10, 3))	DispensedQty,	-- sum of dispense events linked to the PO line items that require this material
	b.UOM,	
	b.OKToDispense,												-- 1 if material is not already assigned to another station and can be dispensed at this station
	dstat.DispStation											-- PU Desc of dispense station to which material is already assigned
FROM bomfis b
	LEFT JOIN disp d ON b.BOM_Formulation_Item_Id = d.BOMFormulationItemID
	LEFT JOIN dstat ON dstat.Material = b.Material
WHERE (@AllowedMaterialsOnly = 1 AND OKToDispense = 'Y') OR (@AllowedMaterialsOnly = 0)
GROUP BY b.MaterialId, b.Material, b.MaterialDesc, b.NumOfPOs, b.UOM, b.OKToDispense, dstat.DispStation
ORDER BY Material
 
SELECT	@ErrorCode		=	1,
		@ErrorMessage	=	'Success'
 
 
 
 
