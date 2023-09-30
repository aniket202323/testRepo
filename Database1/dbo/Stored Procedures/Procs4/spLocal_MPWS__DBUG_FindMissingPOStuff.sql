 
 
 
CREATE  procedure [dbo].[spLocal_MPWS__DBUG_FindMissingPOStuff]
 
AS
 
DECLARE
	@Row		INT,
	@MaxRow		INT,
	@BomfiId	INT,
	@e			INT,
	@m			VARCHAR(255);
 
	DECLARE @bomfi TABLE
	(
		Id						INT IDENTITY,
		Path_Id					INT,
		PONum					VARCHAR(50),
		BOM_Formulation_Id		INT,
		BOM_Formulation_Item_Id	INT,
		BOM_ProdId				INT,
		BOM_ProdCode			VARCHAR(50),
		BOM_ProdDesc			VARCHAR(50),
		BOMQuantity				FLOAT,
		BOMItemStatusUPD		VARCHAR(50) DEFAULT '*MISSING*',
		BOMDispenseStationUPD	VARCHAR(50) DEFAULT '*MISSING*'
	)
	
	DECLARE @props TABLE
	(
		prod_id INT,
		DispenseInfoInterval	VARCHAR(50) DEFAULT '*MISSING*',
		DispenseInfoLink	VARCHAR(50) DEFAULT '*MISSING*',
		[DispenseInfo-SignatureRequired]	VARCHAR(50) DEFAULT '*MISSING*',
		DispenseRestrictions	VARCHAR(50) DEFAULT '*MISSING*',
		MandatoryTare	VARCHAR(50) DEFAULT '*MISSING*',
		MaterialClass	VARCHAR(50) DEFAULT '*MISSING*',
		MaterialNote	VARCHAR(50) DEFAULT '*MISSING*',
		MPWSToleranceLower	VARCHAR(50) DEFAULT '*MISSING*',
		MPWSToleranceUpper	VARCHAR(50) DEFAULT '*MISSING*',
		SafetyInfoInterval	VARCHAR(50) DEFAULT '*MISSING*',
		SafetyInfoLink	VARCHAR(50) DEFAULT '*MISSING*',
		[SafetyInfo-SignatureRequired]	VARCHAR(50) DEFAULT '*MISSING*'
	)
 
	-- get only the bomfi entries with a BOMItemStatus UDP. If they don't have the UDP then they aren't for pre-weigh.
	INSERT @bomfi (Path_Id, PONum, BOM_Formulation_Id, BOM_Formulation_Item_Id, BOM_ProdId, BOM_ProdCode, BOM_ProdDesc, BOMQuantity)
		SELECT
			pp.Path_Id,
			pp.Process_Order,
			bomfi.BOM_Formulation_Id,
			bomfi.BOM_Formulation_Item_Id,
			p.Prod_Id,
			p.Prod_Code,
			p.Prod_Desc,
			bomfi.Quantity
		FROM dbo.Production_Plan pp
			JOIN dbo.Bill_Of_Material_Formulation_Item bomfi ON bomfi.BOM_Formulation_Id = pp.BOM_Formulation_Id
			JOIN dbo.Products_Base p ON p.Prod_Id = bomfi.Prod_Id
		WHERE pp.Path_Id IN (83)
			--AND pp.PP_Id = 390768
	
	UPDATE @bomfi
		SET BOMDispenseStationUPD = ds.Value
		FROM @bomfi b
			CROSS APPLY dbo.fnLocal_MPWS_GetUDP(b.BOM_Formulation_Item_Id, 'DispenseStationId',     'Bill_Of_Material_Formulation_Item') ds
	
	UPDATE @bomfi
		SET BOMItemStatusUPD = bs.Value
		FROM @bomfi b
			CROSS APPLY dbo.fnLocal_MPWS_GetUDP(b.BOM_Formulation_Item_Id, 'BOMItemStatus',     'Bill_Of_Material_Formulation_Item') bs
			
	--UPDATE @bomfi
	--	SET BOMProdMaterialClass = CONVERT(VARCHAR(255), prop.Value)
	--	FROM @bomfi b
	--		JOIN dbo.Products_Aspect_MaterialDefinition prod ON prod.Prod_Id = b.BOM_ProdId
	--		JOIN dbo.Property_MaterialDefinition_MaterialClass prop ON prop.MaterialDefinitionId = prod.Origin1MaterialDefinitionId
	--	WHERE prop.Class = 'Pre-Weigh'
	--		AND prop.Name = 'MaterialClass'
	
	SET @MaxRow = (SELECT MAX(Id) FROM @bomfi);
	SET @Row = 1;
	
	WHILE @Row <= @MaxRow
	BEGIN
		
		SET @BomfiId = (SELECT BOM_Formulation_Item_Id FROM @bomfi WHERE Id = @Row);
		
		IF (SELECT BOMDispenseStationUPD FROM @bomfi WHERE Id = @Row) = '*MISSING*'
			EXEC dbo.spLocal_MPWS_GENL_CreateUpdateUDP @e output, @m output, @BomfiId,  'DispenseStationId',     'Bill_Of_Material_Formulation_Item', NULL
			
		IF (SELECT BOMItemStatusUPD FROM @bomfi WHERE Id = @Row) = '*MISSING*'
			EXEC dbo.spLocal_MPWS_GENL_CreateUpdateUDP @e output, @m output, @BomfiId,  'BOMItemStatus',     'Bill_Of_Material_Formulation_Item', 14
	
		SET @Row += 1;
		
	END;
	
	-- re-update after fixing missing udp's above
	
	UPDATE @bomfi
		SET BOMDispenseStationUPD = ds.Value
		FROM @bomfi b
			CROSS APPLY dbo.fnLocal_MPWS_GetUDP(b.BOM_Formulation_Item_Id, 'DispenseStationId',     'Bill_Of_Material_Formulation_Item') ds
	
	UPDATE @bomfi
		SET BOMItemStatusUPD = bs.Value
		FROM @bomfi b
			CROSS APPLY dbo.fnLocal_MPWS_GetUDP(b.BOM_Formulation_Item_Id, 'BOMItemStatus',     'Bill_Of_Material_Formulation_Item') bs
			
select * from @bomfi order by ponum, path_id
 
insert @props(prod_id) select distinct bom_prodid from @bomfi
 
update @props 
set	[DispenseInfoInterval] = pvt.[DispenseInfoInterval],				
	[DispenseInfoLink] = pvt.[DispenseInfoLink],
	[DispenseInfo-SignatureRequired] = pvt.[DispenseInfo-SignatureRequired],
	[DispenseRestrictions] = pvt.[DispenseRestrictions],
	[MandatoryTare] = pvt.[MandatoryTare],
	[MaterialClass] = pvt.[MaterialClass],
	[MaterialNote] = pvt.[MaterialNote],
	[MPWSToleranceLower] = pvt.[MPWSToleranceLower],
	[MPWSToleranceUpper] = pvt.[MPWSToleranceUpper],
	[SafetyInfoInterval] = pvt.[SafetyInfoInterval],
	[SafetyInfoLink] = pvt.[SafetyInfoLink],
	[SafetyInfo-SignatureRequired] = pvt.[SafetyInfo-SignatureRequired]
	FROM @props pr
	JOIN
	(
		SELECT distinct
			pr.Prod_Id,
			prop.Name,
			substring(cast(prop.Value as varchar), 1, 50) Value
		FROM @props pr
			LEFT JOIN dbo.Products_Aspect_MaterialDefinition prod ON prod.Prod_Id = pr.Prod_Id
			LEFT JOIN dbo.Property_MaterialDefinition_MaterialClass prop ON prop.MaterialDefinitionId = prod.Origin1MaterialDefinitionId
		WHERE prop.Class = 'Pre-Weigh'
		) a
		PIVOT (MAX(Value) FOR Name IN ([DispenseInfoInterval],[DispenseInfoLink],[DispenseInfo-SignatureRequired],[DispenseRestrictions],[MandatoryTare],[MaterialClass],
										[MaterialNote],[MPWSToleranceLower],[MPWSToleranceUpper],[SafetyInfoInterval],[SafetyInfoLink],[SafetyInfo-SignatureRequired])) pvt
	on pr.prod_id = pvt.prod_id
	
select p.prod_code, p.prod_desc, pr.* 
from @props pr
	JOIN dbo.Products_Base p ON p.Prod_Id = pr.Prod_Id
 
