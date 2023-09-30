--------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_Util_CreateUpdateMasterBOMFormulation
--------------------------------------------------------------------------------------------------
-- Author				: Sasha Metlitski, Symasol
-- Date created			: 25-Oct-2019	
-- Version 				: Version <1.0>
-- SP Type				: UI
-- Caller				: Called by BOM Utility UI
-- Description			: Creates or Updates Master BOM Formulation (not associated with PO) under the BOM matching the Path Code 
-- Editor tab spacing	: 4
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ========		====	  		====					=====
-- 1.0			25-Oct-2019		A.Metlitski				Original

/*---------------------------------------------------------------------------------------------
--Testing Code

USE [GBDB]
GO

DECLARE @RC int
DECLARE @ErrCode int
DECLARE @ErrMessage nvarchar(255)
DECLARE @MasterBOMFormulationId int
DECLARE @DefaultBOMFamilyDesc nvarchar(255)
DECLARE @DefaultBOMDesc nvarchar(255)
DECLARE @MasterBOMFormulationDesc nvarchar(255)
DECLARE @User nvarchar(255)
DECLARE @EffectiveDate datetime
DECLARE @ExpiryDate datetime
DECLARE @Qty float
DECLARE @QtyPrec int
DECLARE @EngUnit nvarchar(255)
DECLARE @Comment nvarchar(max)


select
@DefaultBOMFamilyDesc  = 'PE Master',
@DefaultBOMDesc = 'PE Master',
@MasterBOMFormulationDesc = '99351668',
@User  = 'comxclient',
@EffectiveDate = getdate(),
@ExpiryDate = dateadd(YY, 1, getdate()),
@Qty = 100.33,
@QtyPrec = 3,
@EngUnit = 'KG',
@Comment = 'my comment'

-- TODO: Set parameter values here.

EXECUTE @RC = [dbo].[spLocal_Util_CreateUpdateMasterBOMFormulation] 
   @ErrCode OUTPUT
  ,@ErrMessage OUTPUT
  ,@MasterBOMFormulationId OUTPUT
  ,@DefaultBOMFamilyDesc
  ,@DefaultBOMDesc
  ,@MasterBOMFormulationDesc
  ,@User
  ,@EffectiveDate
  ,@Qty
  ,@QtyPrec
  ,@EngUnit
  ,@Comment
  
select  @ErrCode  ,@ErrMessage
-----------------------------------------------------------------------------------------------*/


--------------------------------------------------------------------------------
CREATE PROCEDURE			[dbo].[spLocal_Util_CreateUpdateMasterBOMFormulation]
							@ErrCode					int output,
							@ErrMessage					nvarchar(255) output,
							@MasterBOMFormulationId		int output,
							@DefaultBOMFamilyDesc		nvarchar(255),
							@DefaultBOMDesc				nvarchar(255),
							@MasterBOMFormulationDesc	nvarchar(255),
							@User						nvarchar(255),
							@EffectiveDate				datetime,
							@Qty						float,
							@QtyPrec					int,
							@EngUnit					nvarchar(255),
							@Comment					nvarchar(max)
							
			


--WITH ENCRYPTION
AS
SET NOCOUNT ON


DECLARE		@UserId				int,
			@MasterBOMFamilyId	int,
			@MasterBOMId		int,
			@EngUnitId			int,
			@RC					int,
			@ProdId				int


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

SELECT	@ErrCode = 0,
		@ErrMessage = 'No Error'

-- Validations
SELECT	@UserId = Null
SELECT	@userid = ub.User_Id
FROM	dbo.Users_Base ub with (nolock)
WHERE	ub.Username = @User

IF @UserId is Null
BEGIN
	SELECT	@ErrCode = -100,
			@ErrMessage = 'Invalid User'
	GOTO	EXITPROC
END

SELECT	@MasterBOMFamilyId = Null
SELECT	@MasterBOMFamilyId = f.BOM_Family_Id
FROM	dbo.Bill_Of_Material_Family f with (nolock)
WHERE	f.BOM_Family_Desc = @DefaultBOMFamilyDesc

if @MasterBOMFamilyId is Null
begin
	select	@ErrCode = -200,
			@ErrMessage = 'Invalid BOM Family'
	goto	EXITPROC
end

SELECT	@MasterBOMId = Null
SELECT	@MasterBOMId = bom.BOM_Id
FROM	dbo.Bill_Of_Material bom with (nolock)
WHERE	bom.BOM_Desc = @DefaultBOMDesc
and		bom.BOM_Family_Id = @MasterBOMFamilyId

if @MasterBOMId is Null
begin
	select	@ErrCode = -300,
			@ErrMessage = 'Invalid BOM'
	goto	EXITPROC
end

SELECT	@EngUnitId = Null
SELECT	@EngUnitId = eu.Eng_Unit_Id
from	dbo.Engineering_Unit eu with (nolock)
where	eu.Eng_Unit_Desc = @EngUnit

if @EngUnitId is Null
begin
	select	@ErrCode = -400,
			@ErrMessage = 'Invalid Eng Unit'
	goto	EXITPROC
end

select	@ProdId = Null
select	@ProdId = p.Prod_Id
from	dbo.products_base p with (nolock)
where	p.prod_code = @MasterBOMFormulationDesc

if @ProdId is Null
begin
	select	@ErrCode = -500,
			@ErrMessage = 'BOM Formulation Description should Match Product Code'
	goto	EXITPROC
end


select	@MasterBOMFormulationId = Null
select	@MasterBOMFormulationId = bomfor.BOM_Formulation_Id
from	dbo.Bill_Of_Material_Formulation bomfor with (nolock)
join	dbo.Bill_Of_Material bom with (nolock) on bomfor.BOM_Id = bom.BOM_Id
join	dbo.Bill_Of_Material_Family bomf with (nolock) on bom.BOM_Family_Id = bomf.BOM_Family_Id
where	bomfor.BOM_Formulation_Desc = @MasterBOMFormulationDesc
and		bom.BOM_Id = @MasterBOMId
and		bomf.BOM_Family_Id = @MasterBOMFamilyId

	EXECUTE @RC = [dbo].[spEM_BOMSaveFormulation] 
			@MasterBOMId,
			@EffectiveDate,
			Null,
			@Qty,
			@QtyPrec,
			@EngUnitId,
			@Comment,
			Null,
			@UserId,
			@MasterBOMFormulationDesc,
			@MasterBOMFormulationId OUTPUT

			if @RC < 0
			begin
				select	@ErrCode	= -500,
						@ErrMessage = 'Failed to execute spEM_BOMSaveFormulation'
				goto	EXITPROC

			end
	
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

	
EXITPROC:
		SELECT	Id,
				BOMFormulationId,
				BOMFormulationCode,
				BOMFormulationDesc,
				BOMId,
				CommentId,
				Comment,
				EffectiveDate,
				EngUnitId,
				EngUnitDesc,
				ExpirationDate,
				Quantity_Precision,
				StandardQuantity
		FROM	@tMasterBOMFormulation
	
RETURN


SET NOcount OFF
