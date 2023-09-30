--------------------------------------------------------------------------------
CREATE PROCEDURE	[dbo].[spLocal_Util_GetMasterBOMFormulations]
@DefaultBOMFamilyDesc	nvarchar(255),
@DefaultBOMDesc			nvarchar(255),
@BOMFormulationDesc		nvarchar(255) = Null				


--WITH ENCRYPTION
AS
SET NOCOUNT ON


DECLARE	@tOutput TABLE(
		Id							int IDENTITY (1,1),
		MasterBOMFormulationId		int,
		MasterBOMFormulationDesc	nvarchar(255),
		MasterBOMId					int,
		MasterBOMDesc				nvarchar(255),
		MasterBOMFamilyId			int,
		MasterBOMFamilyDesc			nvarchar(255))

--30-Mar-2020
IF  len(IsNull(@BOMFormulationDesc,'')) > 0
BEGIN
	INSERT	@tOutput(
			MasterBOMFormulationId,
			MasterBOMFormulationDesc,
			MasterBOMId,
			MasterBOMDesc,
			MasterBOMFamilyId,
			MasterBOMFamilyDesc)
	SELECT	bomfor.BOM_Formulation_Id,
			--bomfor.BOM_Formulation_Desc + P.Prod_Desc,
			P.Prod_Desc,
			bom.BOM_Id,
			bom.BOM_Desc,
			bomf.BOM_Family_Id,
			bomf.BOM_Family_Desc
			FROM	dbo.Bill_Of_Material_Formulation bomfor	with (nolock)
	join	dbo.Bill_Of_Material bom with (nolock) on bomfor.BOM_Id = bom.BOM_Id
	join	dbo.Bill_Of_Material_Family bomf with (nolock)	on bom.BOM_Family_Id = bomf.BOM_Family_Id
	join	dbo.Products_Base p with (nolock) on upper(bomfor.BOM_Formulation_Desc) = UPPER(p.Prod_Code)
	WHERE	bomf.BOM_Family_Desc = @DefaultBOMFamilyDesc and
			bom.BOM_Desc = @DefaultBOMDesc and
			--1.3			21-Apr-2020		A.Metlitski
			@BOMFormulationDesc = bomfor.BOM_Formulation_Desc
			--charindex(@BOMFormulationDesc, bomfor.BOM_Formulation_Desc) > 0
END
ELSE
BEGIN
	INSERT	@tOutput(
			MasterBOMFormulationId,
			MasterBOMFormulationDesc,
			MasterBOMId,
			MasterBOMDesc,
			MasterBOMFamilyId,
			MasterBOMFamilyDesc)
	SELECT	bomfor.BOM_Formulation_Id,
			--bomfor.BOM_Formulation_Desc + P.Prod_Desc,
			P.Prod_Desc,
			bom.BOM_Id,
			bom.BOM_Desc,
			bomf.BOM_Family_Id,
			bomf.BOM_Family_Desc
			FROM	dbo.Bill_Of_Material_Formulation bomfor	with (nolock)
	join	dbo.Bill_Of_Material bom with (nolock) on bomfor.BOM_Id = bom.BOM_Id
	join	dbo.Bill_Of_Material_Family bomf with (nolock)	on bom.BOM_Family_Id = bomf.BOM_Family_Id
	join	dbo.Products_Base p with (nolock) on upper(bomfor.BOM_Formulation_Desc) = UPPER(p.Prod_Code)
	WHERE	bomf.BOM_Family_Desc = @DefaultBOMFamilyDesc and
			bom.BOM_Desc = @DefaultBOMDesc 
END


SELECT * FROM @tOutput

RETURN


SET NOcount OFF