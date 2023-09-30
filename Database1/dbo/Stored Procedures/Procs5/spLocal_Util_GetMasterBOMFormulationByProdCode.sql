--------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_Util_GetMasterBOMFormulationByProdCode
--------------------------------------------------------------------------------------------------
-- Author				: Sasha Metlitski, Symasol
-- Date created			: 13-Dec-2019	
-- Version 				: Version <1.0>
-- SP Type				: UI
-- Caller				: Called by BOM Utility UI
-- Description			: 
-- Editor tab spacing	: 4
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ========		====	  		====					=====
-- 1.0			13-Dec-2019		Sasha Metlitski			Original

/*---------------------------------------------------------------------------------------------
Testing Code

exec dbo.spLocal_Util_GetMasterBOMFormulationByProdCode '23910007', 'PE Master', 'PE Master'

-----------------------------------------------------------------------------------------------*/


--------------------------------------------------------------------------------
CREATE PROCEDURE	[dbo].[spLocal_Util_GetMasterBOMFormulationByProdCode]
					@ProdCode					nvarchar(255),
					@DefaultBOMFamilyDesc		nvarchar(255),
					@DefaultBOMDesc				nvarchar(255)
					


--WITH ENCRYPTION
AS
SET NOCOUNT ON

	DECLARE	@tOutput table(
			Id						int identity(1,10),
			BOMFormulationId		int,
			BOMFormulationDesc		nvarchar(255),
			BOMFormulationCode		nvarchar(255),
			BOMId					int,
			BOMDesc					nvarchar(255),
			BOMFamilyId				int,
			BOMFamilyDesc			nvarchar(255))

	INSERT	@tOutput (
			BOMFormulationId,
			BOMFormulationDesc,
			BOMFormulationCode,
			BOMId,
			BOMDesc,
			BOMFamilyId,
			BOMFamilyDesc)
	SELECT	bomfor.BOM_Formulation_Id,
			bomfor.BOM_Formulation_Desc,
			bomfor.BOM_Formulation_Code,
			bom.BOM_Id,
			bom.BOM_Desc,
			bomf.BOM_Family_Id,
			bomf.BOM_Family_Desc
	FROM	dbo.Products_Base p							with (nolock)
	join	dbo.Bill_Of_Material_Formulation	bomfor	with (nolock) on p.Prod_Code = bomfor.BOM_Formulation_Desc
	join	dbo.Bill_Of_Material				bom		with (nolock) on bomfor.BOM_Id = bom.BOM_Id
	join	dbo.Bill_Of_Material_Family			bomf	with (nolock) on bom.BOM_Family_Id = bomf.BOM_Family_Id
	WHERE	bomfor.BOM_Formulation_Desc			= @ProdCode 
	and		bom.BOM_Desc						= @DefaultBOMDesc 
	and		bomf.BOM_Family_Desc				= @DefaultBOMFamilyDesc


	SELECT	Id
			BOMFormulationId,
			BOMFormulationDesc,
			BOMFormulationCode,
			BOMId,
			BOMDesc,
			BOMFamilyId,
			BOMFamilyDesc
	FROM	@tOutput

RETURN


SET NOcount OFF
