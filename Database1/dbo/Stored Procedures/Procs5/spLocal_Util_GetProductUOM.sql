--------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_Util_GetProductUOM
--------------------------------------------------------------------------------------------------
-- Author				: Sasha Metlitski, Symasol
-- Date created			: 27-Nov-2019	
-- Version 				: Version <1.0>
-- SP Type				: UI
-- Caller				: Called by BOM Utility UI
-- Description			: Returns Unit Of Measure for the Selected Product
-- Editor tab spacing	: 4
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ========		====	  		====					=====
-- 1.0			06-Nov-2019		A.Metlitski				Original

/*---------------------------------------------------------------------------------------------
Testing Code

exec dbo.spLocal_Util_GetProductUOM 8235
-----------------------------------------------------------------------------------------------*/


------------------------------------------------------------ --------------------
CREATE PROCEDURE	[dbo].[spLocal_Util_GetProductUOM]
					@ProdId	int
--WITH ENCRYPTION
AS
SET NOCOUNT ON



DECLARE	@tProductUOM table(
		Id						int identity(1,1),
		ProdId					int,
		ProdCode				nvarchar(255),
		EngUnitId				int,
		EngUnitCode				nvarchar(255),
		MaterialDefinitionId	nvarchar (255))
		


INSERT	@tProductUOM (
		ProdId,
		ProdCode,
		EngUnitId,
		EngUnitCode,
		MaterialDefinitionId)
SELECT	p.Prod_Id,
		p.Prod_Code,
		eu.Eng_Unit_Id,
		eu.Eng_Unit_Code,
		md.MaterialDefinitionId
FROM	dbo.Products_Base p with (nolock)
join	dbo.Products_Aspect_MaterialDefinition pasmd with (nolock) on p.Prod_Id = pasmd.Prod_Id
join	dbo. Property_MaterialDefinition_MaterialClass pmdmc with (nolock) on pasmd.Origin1MaterialDefinitionId = pmdmc.MaterialDefinitionId 
join	dbo.MaterialDefinition md with (nolock) on pmdmc.MaterialDefinitionId = md.MaterialDefinitionId
join	dbo.MaterialClass mc with (nolock) on pmdmc.Class = mc.MaterialClassName
join	dbo.Engineering_Unit eu with (nolock) on upper(convert(varchar(255),pmdmc.Value)) = upper(eu.Eng_Unit_Code)
WHERE	p.Prod_Id = @ProdId			and
		upper(pmdmc.Name) = 'UOM'	and
		upper(mc.MaterialClassName) = 'BASE MATERIAL LINKAGE'
		

SELECT	top 1
		Id,
		ProdId,
		ProdCode,
		EngUnitId,
		EngUnitCode,
		MaterialDefinitionId
FROM	@tProductUOM



RETURN


SET NOcount OFF
