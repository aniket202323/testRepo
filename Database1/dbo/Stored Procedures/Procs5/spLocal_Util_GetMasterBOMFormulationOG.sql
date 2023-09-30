
--------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_Util_GetMasterBOMFormulationOG
--------------------------------------------------------------------------------------------------
-- Author				: Sasha Metlitski, Symasol
-- Date created			: 25-Oct-2019	
-- Version 				: Version <1.0>
-- SP Type				: UI
-- Caller				: Called by BOM Utility UI
-- Description			: Returns List of Origin Groups for the Master BOM Formulation (not associated with PO)
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

execute			[dbo].[spLocal_Util_GetMasterBOMFormulationOG] 42, null
				
	

select * from prdexec_paths
-----------------------------------------------------------------------------------------------*/


--------------------------------------------------------------------------------
CREATE PROCEDURE			[dbo].[spLocal_Util_GetMasterBOMFormulationOG]
@PathId						int,
@MasterBOMFormulationId		int
			


--WITH ENCRYPTION
AS
SET NOCOUNT ON


DECLARE @DefaultBOMFamily		nvarchar(255),
		@PathCode				nvarchar(255),
		@BOMId					int,
		@PrdExecInputsTableId	int,
		@OrigingGroupUDP		nvarchar(255)

SELECT	@DefaultBOMFamily	=	'PE Master',
		@OrigingGroupUDP	=	'Origin Group'

DECLARE @tPathUnits table (
		PEPUId				int,
		PathId				int,
		IsProductionPoint	bit,
		IsSchedulePoint		bit,
		PUId				int,
		UnitOrder			int)

DECLARE @tPathInputs			table (
		PEI_Id					int,
		Alternate_Spec_Id		int,
		Def_Event_Comp_Sheet_Id	int,
		Event_Subtype_Id		int,
		Input_Name				nvarchar(255),
		Input_Order				int,
		Lock_Inprogress_Input	bit,
		Primary_Spec_Id			int,
		PU_Id					int)

DECLARE @tOriginGroups			table (
		OGId					int identity(1,1),
		OriginGroup				nvarchar(255))


INSERT		@tPathUnits 
SELECT		pexu.PEPU_Id,
			pexu.Path_Id,
			pexu.Is_Production_Point,
			pexu.Is_Schedule_Point,
			pexu.PU_Id,
			pexu.Unit_Order
FROM		dbo.PrdExec_Path_Units pexu WITH (NOLOCK)
WHERE		pexu.Path_Id = @PathId
ORDER BY	pexu.Unit_Order

INSERT		@tPathInputs 
SELECT		pexi.PEI_Id,
			pexi.Alternate_Spec_Id,
			pexi.Def_Event_Comp_Sheet_Id,
			pexi.Event_Subtype_Id,
			pexi.Input_Name,
			pexi.Input_Order,
			pexi.Lock_Inprogress_Input,
			pexi.Primary_Spec_Id,
			pexi.PU_Id
FROM		dbo.PrdExec_Inputs pexi WITH (NOLOCK) 
join		@tPathUnits tpu on pexi.PU_Id = tpu.PUId
ORDER BY	pexi.Input_Order

--select '@tPathUnits', * from @tPathUnits
--select '@tPathInputs', * from @tPathInputs

SELECT	@PrdExecInputsTableId = t.TableId
FROM	dbo.tables t	with (nolock)
WHERE	t.TableName = 'PrdExec_Inputs'

insert	@tOriginGroups (OriginGroup)
SELECT	DISTINCT tfv.Value
FROM	dbo.TABLE_FIELDS_VALUES tfv with (nolock)
join	dbo.tables t on tfv.TableId = t.TableId
join	dbo.Table_Fields tf on tfv.Table_Field_Id = tf.Table_Field_Id 
join	@tPathInputs tpi on tfv.KeyId = tpi.PEI_Id
WHERE	t.TableId = @PrdExecInputsTableId
and		tf.Table_Field_Desc = @OrigingGroupUDP
order by tfv.Value

select * from @tOriginGroups


RETURN


SET NOcount OFF

