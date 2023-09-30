
--------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_Util_GetMasterBOMFormulation
--------------------------------------------------------------------------------------------------
-- Author				: Sasha Metlitski, Symasol
-- Date created			: 25-Oct-2019	
-- Version 				: Version <1.0>
-- SP Type				: UI
-- Caller				: Called by BOM Utility UI
-- Description			: This Stored Procedue returns list of Master BOM Formulations for the Selected Path
-- Editor tab spacing	: 4
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ========		====	  		====					=====
-- 1.0			25-Oct-2019		A.Metlitski				Original

/*---------------------------------------------------------------------------------------------
Testing Code

exec dbo.spLocal_Util_GetMasterBOMFormulation 'PE Master', 'PE Master', '9100'
-----------------------------------------------------------------------------------------------*/


--------------------------------------------------------------------------------
CREATE PROCEDURE	[dbo].[spLocal_Util_GetMasterBOMFormulation]
@DefaultBOMFamilyDesc	nvarchar(255),
@DefaultBOMDesc			nvarchar(255),
@BOMFormulationDesc		nvarchar(255) = Null				


--WITH ENCRYPTION
AS
SET NOCOUNT ON


DECLARE	@tOutput TABLE(
		Id							int IDENTITY (1,1),
--		PathId						int,
--		PathCode					nvarchar(255),
		MasterBOMFormulationId		int,
		MasterBOMFormulationDesc	nvarchar(255),
		MasterBOMId					int,
		MasterBOMDesc				nvarchar(255),
		MasterBOMFamilyId			int,
		MasterBOMFamilyDesc			nvarchar(255))


If  len(IsNull(@BOMFormulationDesc,'')) > 0
begin
	INSERT	@tOutput(
			MasterBOMFormulationId,
			MasterBOMFormulationDesc,
			MasterBOMId,
			MasterBOMDesc,
			MasterBOMFamilyId,
			MasterBOMFamilyDesc)
	SELECT	bomfor.BOM_Formulation_Id,
			bomfor.BOM_Formulation_Desc,
			bom.BOM_Id,
			bom.BOM_Desc,
			bomf.BOM_Family_Id,
			bomf.BOM_Family_Desc
			FROM	dbo.Bill_Of_Material_Formulation bomfor	with (nolock)
	join	dbo.Bill_Of_Material bom on bomfor.BOM_Id = bom.BOM_Id
	join	dbo.Bill_Of_Material_Family bomf	on bom.BOM_Family_Id = bomf.BOM_Family_Id
	WHERE	bomf.BOM_Family_Desc = @DefaultBOMFamilyDesc and
			bom.BOM_Desc = @DefaultBOMDesc and
			--charindex(isnull(@BOMFormulationDesc,''), bomfor.BOM_Formulation_Desc) > 0
			charindex(@BOMFormulationDesc, bomfor.BOM_Formulation_Desc) > 0
end
else
begin
	INSERT	@tOutput(
			MasterBOMFormulationId,
			MasterBOMFormulationDesc,
			MasterBOMId,
			MasterBOMDesc,
			MasterBOMFamilyId,
			MasterBOMFamilyDesc)
	SELECT	bomfor.BOM_Formulation_Id,
			bomfor.BOM_Formulation_Desc,
			bom.BOM_Id,
			bom.BOM_Desc,
			bomf.BOM_Family_Id,
			bomf.BOM_Family_Desc
			FROM	dbo.Bill_Of_Material_Formulation bomfor	with (nolock)
	join	dbo.Bill_Of_Material bom on bomfor.BOM_Id = bom.BOM_Id
	join	dbo.Bill_Of_Material_Family bomf	on bom.BOM_Family_Id = bomf.BOM_Family_Id
	WHERE	bomf.BOM_Family_Desc = @DefaultBOMFamilyDesc and
			bom.BOM_Desc = @DefaultBOMDesc 
end


SELECT * from @tOutput

RETURN


SET NOcount OFF

