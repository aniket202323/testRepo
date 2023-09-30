





--------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_Util_GetMasterBOMFormulationData
--------------------------------------------------------------------------------------------------
-- Author				: Sasha Metlitski, Symasol
-- Date created			: 15-Nov-2019	
-- Version 				: Version <1.0>
-- SP Type				: UI
-- Caller				: Called by BOM Utility UI
-- Description			: This Stored Procedue returns data to display Create/Edit Master BOM Formulation Screen
-- Editor tab spacing	: 4
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ========		====	  		====					=====
-- 1.0			15-Nov-2019		A.Metlitski				Original
-- 1.1			26-Jan-2020		A.Metlitski				Validation that Origin Groups belongs to PE Lines only
--														Path UDP PE_GENERAL_ISPELINE==1
-- 1.2			30-Jan-2020		A.Metlitski				Modified Component Q-ty data type to float

/*---------------------------------------------------------------------------------------------
Testing Code

exec dbo.spLocal_Util_GetMasterBOMFormulationData 2914
exec dbo.spLocal_Util_GetMasterBOMFormulationData 2807

-----------------------------------------------------------------------------------------------*/


--------------------------------------------------------------------------------
CREATE PROCEDURE	[dbo].[spLocal_Util_GetMasterBOMFormulationData_WIP]
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
		from	dbo.Bill_Of_Material_Formulation bomfor with (nolock)
		left join	dbo.Comments c with (nolock) on bomfor.Comment_Id = c.Comment_Id
		join	dbo.Engineering_Unit eu with (nolock) on bomfor.Eng_Unit_Id = eu.Eng_Unit_Id
		where	bomfor.BOM_Formulation_Id = @MasterBOMFormulationId



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
select	bomf.BOM_Formulation_Id,
		bomfi.BOM_Formulation_Item_Id,
		bomfi.Prod_Id,
		p.Prod_Code,
		p.Prod_Desc,
		bomfi.Quantity,
		bomfi.Eng_Unit_Id,
		eu.Eng_Unit_Desc,
		bomfi.Scrap_Factor,
		bomfi.PU_Id
from	dbo.Bill_Of_Material_Formulation bomf	with (nolock)
join	dbo.Bill_Of_Material_Formulation_Item bomfi on bomf.BOM_Formulation_Id = bomfi.BOM_Formulation_Id 
join	dbo.products p on bomfi.Prod_Id = p.Prod_Id
join	dbo.Engineering_Unit eu on bomfi.Eng_Unit_Id = eu.Eng_Unit_Id
where	bomf.BOM_Formulation_Id = @MasterBOMFormulationId


update	tbd
set		tbd.OriginGroup = convert(nvarchar(255),pmdmc.Value)
from	@tBOMDetails1 tbd
join	dbo.Products_Base p on tbd.ProdId = p.Prod_Id
join	dbo.Products_Aspect_MaterialDefinition pamd on p.Prod_Id = pamd.Prod_Id
join	dbo.MaterialDefinition md on pamd.Origin1MaterialDefinitionId = md.MaterialDefinitionId
join	dbo.Property_MaterialDefinition_MaterialClass pmdmc on md.MaterialDefinitionId = pmdmc.MaterialDefinitionId 
where	pmdmc.name = 'origin group' and pmdmc.Class = 'Base Material Linkage'

select * from @tBOMDetails1
return


update	tbd
set		tbd.Location = x.Foreign_Key
from	@tBOMDetails1 tbd
join	dbo.Data_Source_XRef x on tbd.PUId = x.Actual_Id
join	dbo.Data_Source ds on x.DS_Id = ds.DS_Id
join	dbo.tables t	on x.Table_Id = t.TableId
where	ds.DS_Desc = 'Open Enterprise' and
		t.TableName = 'Prod_Units'

update	tbd
set		tbd.AltProdId = boms.Prod_Id,
		tbd.AltProdCode = p.Prod_code,
		tbd.AltProdDesc = p.Prod_Desc,
		tbd.AltQty		= tbd.Qty * boms.Conversion_Factor,
		tbd.AltUOMId = boms.Eng_Unit_Id,
		tbd.AltUOMDesc = eu.Eng_Unit_Desc
from	@tBOMDetails1 tbd
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
from	@tBOMDetails1
order by origingroup, ProdCode


--Table Fields
INSERT	@tTableFields (tableFieldId)
SELECT	tf.Table_Field_Id
FROM	dbo.table_fields tf
join	 dbo.tables t on tf.TableId = t.TableId
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
join	dbo.PrdExec_Inputs pexi on tfv.KeyId = pexi.PEI_Id
join	dbo.PrdExec_Path_Units pexu on pexi.PU_Id = pexu.PU_Id
--		join	dbo.Prdexec_Paths pex on pex.Path_Id = pexu.Path_Id
join	@tPELinePaths pelines on pelines.PathId = pexu.Path_Id
join	@tTableFields ttf on tfv.Table_Field_Id = ttf.TableFieldId
WHERE	tfv.value not in (SELECT DISTINCT OriginGroup FROM @tBOMDetails)
ORDER BY tfv.value

		
SELECT * FROM @tMasterBOMFormulation
SELECT * FROM @tBOMDetails


RETURN


SET NOcount OFF






