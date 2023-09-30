--------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_Util_GetPathOriginGroups
--------------------------------------------------------------------------------------------------
-- Author				: Sasha Metlitski, Symasol
-- Date created			: 06-Nov-2019	
-- Version 				: Version <1.0>
-- SP Type				: UI
-- Caller				: Called by BOM Utility UI
-- Description			: Returns List Of Origin Groups for the Selected Path to populate the Add/Edit Master BOM Formulation Screen
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

exec dbo.spLocal_Util_GetPathOriginGroups 42
-----------------------------------------------------------------------------------------------*/


--------------------------------------------------------------------------------
CREATE PROCEDURE	[dbo].[spLocal_Util_GetPathOriginGroups]
					@PathId					int
--WITH ENCRYPTION
AS
SET NOCOUNT ON



declare	@tOG table(
		id				int identity(1,1),
		OriginGroup		nvarchar(255))


insert	@tOG (
		OriginGroup)
select	distinct	tfv.Value
from	dbo.Table_Fields_Values tfv	with (nolock)
join	dbo.PrdExec_Inputs pexi on tfv.KeyId = pexi.PEI_Id
join	dbo.PrdExec_Path_Units pexu on pexi.PU_Id = pexu.PU_Id
join	dbo.Prdexec_Paths pex on pex.Path_Id = pexu.Path_Id
join	dbo.Table_Fields tf on tfv.Table_Field_Id = tf.Table_Field_Id
join	dbo.Tables t on tfv.TableId = t.TableId
where	pex.Path_Id			= @PathId and
		t.TableName			= 'PrdExec_Inputs' and
		tf.Table_Field_Desc = 'Origin Group'

select	Id as OriginGroupId,
		IsNull(OriginGroup,'') as OriginGroup
from	@tOG


RETURN


SET NOcount OFF
