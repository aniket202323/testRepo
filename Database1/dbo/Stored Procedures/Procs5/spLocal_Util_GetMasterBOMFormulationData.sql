--------------------------------------------------------------------------------
CREATE PROCEDURE	[dbo].[spLocal_Util_GetMasterBOMFormulationData]
					@MasterBOMFormulationId int
					
--WITH ENCRYPTION
AS
SET NOCOUNT ON


DECLARE		@tMasterBOMFormulation	table (
			Id						int	identity(1,1),
			BOMFormulationId		int,
			BOMFormulationCode		nvarchar(255),
			BOMFormulationDesc		nvarchar(255),
			BOMId					int,
			CommentId				int,
			Comment					nvarchar(max),
			EffectiveDate			datetime,
			EngUnitId				int,
			EngUnitDesc				nvarchar(255),
			ExpirationDate			nvarchar(255),
			Quantity_Precision		int,
			StandardQuantity		float)



DECLARE	@tBOMDetails1 TABLE(
		Id							int IDENTITY (1,1),
		MasterBOMFormulationId		int,
		MasterBOMFormulationItemId	int,
		OriginGroup					nvarchar(255),
		ProdId						int,
		ProdCode					nvarchar(255),
		ProdDesc					nvarchar(255),
		--Qty						int,
		Qty							float,
		UOMId						int,
		UOMDesc						nvarchar(255),
		ScrapFactor					float,
		PUId						int,
		Location					nvarchar(255),		
		AltProdId					int,
		AltProdCode					nvarchar(255),
		AltProdDesc					nvarchar(255),
		--AltQty					int,
		AltQty						float,
		AltUOMId					int,
		AltUOMDesc					nvarchar(255))

		DECLARE	@tBOMDetails TABLE(
		Id							int IDENTITY (1,1),
		MasterBOMFormulationId		int,
		MasterBOMFormulationItemId	int,
		OriginGroup					nvarchar(255),
		ProdId						int,
		ProdCode					nvarchar(255),
		ProdDesc					nvarchar(255),
		--Qty							int,
		Qty							float,
		UOMId						int,
		UOMDesc						nvarchar(255),
		ScrapFactor					float,
		PUId						int,
		Location					nvarchar(255),		
		AltProdId					int,
		AltProdCode					nvarchar(255),
		AltProdDesc					nvarchar(255),
		--AltQty					int,
		AltQty						float,
		AltUOMId					int,
		AltUOMDesc					nvarchar(255))

DECLARE @tTableFields table(
		id int identity (1,1),
		TableFieldId	int)

DECLARE @tPELinePaths table (
		Id int identity (1,1),
		PathId int)

DECLARE @ProcessOrder	nvarchar(255),
		@ThisTime		datetime,
		@YYYY			nvarchar(4),
		@YY				nvarchar(2),
		@MM				nvarchar(2),
		@DD				nvarchar(2),
		@HH				nvarchar(2),
		@MI				nvarchar(2),
		@SS				varchar(2),
		@BatchNumber	nvarchar(10),
		@BatchId		int,
		@ProdPointPUId	int,
		@PlannedDate	datetime,
		@ExpirationDate	nvarchar(8),
		@ProdId			int,
		@ProdCode		nvarchar(255),
		@MasterBOMFormulationDesc	nvarchar(255),
		@TableFieldId	int

			INSERT	@tMasterBOMFormulation(
					BOMFormulationId,
					BOMFormulationDesc,
					BOMId,
					CommentId,
					Comment,
					EffectiveDate,
					EngUnitId,
					EngUnitDesc,
					ExpirationDate,
					Quantity_Precision,
					StandardQuantity)
			SELECT	bomfor.BOM_Formulation_Id,
					bomfor.BOM_Formulation_Desc,
					bomfor.BOM_Id,
					bomfor.Comment_Id,
					c.Comment,
					bomfor.Effective_Date,
					bomfor.Eng_Unit_Id,
					eu.Eng_Unit_Desc,
					bomfor.Expiration_Date,
					bomfor.Quantity_Precision,
					bomfor.Standard_Quantity			
		FROM		dbo.Bill_Of_Material_Formulation bomfor WITH (NOLOCK)
		left join	dbo.Comments c WITH (NOLOCK) on bomfor.Comment_Id = c.Comment_Id
		join		dbo.Engineering_Unit eu WITH (NOLOCK) on bomfor.Eng_Unit_Id = eu.Eng_Unit_Id
		WHERE		bomfor.BOM_Formulation_Id = @MasterBOMFormulationId



	INSERT	@tBOMDetails1(
			MasterBOMFormulationId,
			MasterBOMFormulationItemId,
			ProdId,
			ProdCode,
			ProdDesc,
			Qty,
			UOMId,
			UOMDesc,
			ScrapFactor,
			PUId)
	SELECT	bomf.BOM_Formulation_Id,
			bomfi.BOM_Formulation_Item_Id,
			bomfi.Prod_Id,
			p.Prod_Code,
			p.Prod_Desc,
			bomfi.Quantity,
			bomfi.Eng_Unit_Id,
			eu.Eng_Unit_Desc,
			bomfi.Scrap_Factor,
			bomfi.PU_Id
	FROM	dbo.Bill_Of_Material_Formulation bomf	WITH (NOLOCK)
	join	dbo.Bill_Of_Material_Formulation_Item bomfi WITH (NOLOCK) on bomf.BOM_Formulation_Id = bomfi.BOM_Formulation_Id 
	join	dbo.products p WITH (NOLOCK) on bomfi.Prod_Id = p.Prod_Id
	join	dbo.Engineering_Unit eu WITH (NOLOCK) on bomfi.Eng_Unit_Id = eu.Eng_Unit_Id
	WHERE	bomf.BOM_Formulation_Id = @MasterBOMFormulationId


	UPDATE	tbd
	SET		tbd.OriginGroup = convert(nvarchar(255),pmdmc.Value)
	FROM	@tBOMDetails1 tbd
	join	dbo.Products_Base p on tbd.ProdId = p.Prod_Id
	join	dbo.Products_Aspect_MaterialDefinition pamd on p.Prod_Id = pamd.Prod_Id
	join	dbo.MaterialDefinition md on pamd.Origin1MaterialDefinitionId = md.MaterialDefinitionId
	join	dbo.Property_MaterialDefinition_MaterialClass pmdmc on md.MaterialDefinitionId = pmdmc.MaterialDefinitionId 
	WHERE	pmdmc.name = 'origin group' and pmdmc.Class = 'Base Material Linkage'


	UPDATE	tbd
	SET		tbd.Location = x.Foreign_Key
	FROM	@tBOMDetails1 tbd
	join	dbo.Data_Source_XRef x on tbd.PUId = x.Actual_Id
	join	dbo.Data_Source ds on x.DS_Id = ds.DS_Id
	join	dbo.tables t	on x.Table_Id = t.TableId
	WHERE	ds.DS_Desc = 'Open Enterprise' and
			t.TableName = 'Prod_Units'

	update	tbd
	SET		tbd.AltProdId = boms.Prod_Id,
			tbd.AltProdCode = p.Prod_code,
			tbd.AltProdDesc = p.Prod_Desc,
			tbd.AltQty		= tbd.Qty * boms.Conversion_Factor,
			tbd.AltUOMId = boms.Eng_Unit_Id,
			tbd.AltUOMDesc = eu.Eng_Unit_Desc
	FROM	@tBOMDetails1 tbd
	join	dbo.Bill_Of_Material_Substitution boms on tbd.MasterBOMFormulationItemId = boms.BOM_Formulation_Item_Id
	join	dbo.Products_Base p on boms.Prod_Id = p.Prod_Id
	join	dbo.Engineering_Unit eu on boms.Eng_Unit_Id = eu.Eng_Unit_Id

	INSERT	@tBOMDetails(		
			MasterBOMFormulationId,
			MasterBOMFormulationItemId,
			OriginGroup,
			ProdId,
			ProdCode,
			ProdDesc,
			Qty,
			UOMId,
			UOMDesc,
			ScrapFactor,
			PUId,
			Location,
			AltProdId,
			AltProdCode,
			AltProdDesc,
			AltQty,
			AltUOMId,
			AltUOMDesc)
	select	MasterBOMFormulationId,
			MasterBOMFormulationItemId,
			OriginGroup,
			ProdId,
			ProdCode,
			ProdDesc,
			Qty,
			UOMId,
			UOMDesc,
			ScrapFactor,
			PUId,
			Location,
			AltProdId,
			AltProdCode,
			AltProdDesc,
			AltQty,
			AltUOMId,
			AltUOMDesc
	FROM	@tBOMDetails1
	ORDER BY origingroup, ProdCode


	--Table Fields
	INSERT	@tTableFields (tableFieldId)
	SELECT	tf.Table_Field_Id
	FROM	dbo.table_fields tf WITH (NOLOCK)
	join	dbo.tables t WITH (NOLOCK) on tf.TableId = t.TableId
	WHERE	upper(t.TableName)			= 'PRDEXEC_INPUTS' 
	and		upper(tf.Table_Field_Desc)	= 'ORIGIN GROUP'


	SELECT	@TableFieldId = tf.Table_Field_Id 
	FROM	dbo.Table_Fields tf WITH (NOLOCK)
	join	dbo.tables tt on tf.TableId = tt.TableId
	WHERE	upper(tf.Table_Field_Desc)	= 'PE_GENERAL_ISPELINE'
	and		upper(tt.TableName)			= 'PRDEXEC_PATHS'

	--list of PE Lines
	INSERT	@tPELinePaths (
			PathId)
	SELECT	tfv.KeyId	
	FROM	dbo.Table_Fields_Values tfv WITH (NOLOCK)
	join	dbo.tables tt WITH (NOLOCK) on tfv.TableId = tt.TableId
	WHERE	tfv.Table_Field_Id = @TableFieldId
	and		UPPER(tt.TableName) = 'PRDEXEC_PATHS'
	--and		tfv.Value = '1'


	-- insert Origin Groups that don't have BOM Items
	INSERT	@tBOMDetails (OriginGroup)
	SELECT	DISTINCT	tfv.Value
	FROM	dbo.Table_Fields_Values tfv	WITH (NOLOCK)
	join	dbo.PrdExec_Inputs pexi WITH (NOLOCK) on tfv.KeyId = pexi.PEI_Id
	join	dbo.PrdExec_Path_Units pexu WITH (NOLOCK) on pexi.PU_Id = pexu.PU_Id
	--		join	dbo.Prdexec_Paths pex on pex.Path_Id = pexu.Path_Id
	join	@tPELinePaths pelines on pelines.PathId = pexu.Path_Id
	join	@tTableFields ttf on tfv.Table_Field_Id = ttf.TableFieldId
	WHERE	tfv.value not in (SELECT DISTINCT OriginGroup FROM @tBOMDetails)
	ORDER BY tfv.value

		
	SELECT * FROM @tMasterBOMFormulation
	SELECT * FROM @tBOMDetails


	RETURN

	SET NOcount OFF