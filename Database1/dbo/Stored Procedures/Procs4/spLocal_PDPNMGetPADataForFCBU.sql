

CREATE	PROCEDURE [dbo].[spLocal_PDPNMGetPADataForFCBU]
	@FlagOnlyMasterPU		BIT				= 1,
	@PLNickNameRoutineId	INT				= 0,
	@PLIdMask				VARCHAR(MAX)	= NULL
AS
-------------------------------------------------------------------------------
-- This SP retrieves Production lines for the network manager to build the 
-- network for the P&G Baby Fam business unit
--
-- This sproc selects the PLs that have master PUs with a configured model
--
-- Date         Version Build  Author								Notes
-- 15-Apr-2016  001     001    Alex Judkowicz (GE Digital)			Initial development
-- 12-Sep-2016	001		002	   Alex Judkowicz (GE Digital)			Add support for PL Mask filtering		
/*
exec spLocal_PDPNMGetPADataForBFBU
exec spLocal_PDPNMGetPADataForBFBU 1, 1
exec spLocal_PDPNMGetPADataForBFBU 1, 1, '26,27,184'

*/
-------------------------------------------------------------------------------
SET NOCOUNT ON
-------------------------------------------------------------------------------
-- Declare variables
-------------------------------------------------------------------------------
DECLARE	@tOutput TABLE 
(
	Id			INT				IDENTITY(1,1)	NOT NULL,
	DeptId		INT				NULL,
	DeptDesc	VARCHAR(255)	NULL,
	PLId		INT				NULL,
	PLDesc		VARCHAR(255)	NULL,
	PLNickName	VARCHAR(255)	NULL,
	PUId		VARCHAR(255)	NULL,
	PUDesc		VARCHAR(255)	NULL,
	MasterPUId	INT				NULL,
	PUNickName	VARCHAR(255)	NULL
)

DECLARE	@tPLIds TABLE
(
	Id		INT	IDENTITY(1,1),
	PLId	INT
)
-------------------------------------------------------------------------------
-- Get all PLs that have at least 1 PU that has a model associated with it
--
-- The intention is to return at least all the required PLs for the network. 
-- It is better to return more PLs than it should then less, because is easier
-- to manually delete equipment things than to add them.
-------------------------------------------------------------------------------
IF	LEN(RTRIM(LTRIM(@PLIdMask))) > 0
BEGIN
		---------------------------------------------------------------------------------------
		-- Parse production line list
		---------------------------------------------------------------------------------------
		INSERT	@tPLIds (PLId)
				SELECT	*
						FROM	dbo.fnLocal_CmnParseList(@PLIdMask, ',')
		-------------------------------------------------------------------------------
		-- Selects only the produciton lines received in the mask
		-------------------------------------------------------------------------------
		INSERT	@tOutput (PUId, DeptId, DeptDesc, PLId, PLDesc, PLNickName, MasterPUId)
				SELECT	DISTINCT PU.PU_Id, PL.Dept_Id, D.Dept_Desc, PL.PL_Id, PL.PL_Desc, PL.PL_Desc,
						PU.Master_Unit
						FROM	dbo.Prod_Units PU			WITH (NOLOCK)
						JOIN	dbo.Prod_Lines PL			WITH (NOLOCK)
						ON		PU.PL_Id		= PL.PL_Id
						JOIN	dbo.Event_Configuration EC	WITH (NOLOCK)
						ON		PU.PU_Id		= EC.PU_Id
						--AND		EC.ET_Id		= 2
						JOIN	dbo.Departments D			WITH (NOLOCK)
						ON		D.Dept_Id		= PL.Dept_Id
						JOIN	@tPLIds T
						ON		T.PLId			= PL.PL_Id
						ORDER
						BY		PL.PL_Desc
END
ELSE
BEGIN
		-------------------------------------------------------------------------------
		-- No Production line filterting
		-------------------------------------------------------------------------------
		INSERT	@tOutput (PUId, DeptId, DeptDesc, PLId, PLDesc, PLNickName, MasterPUId)
				SELECT	DISTINCT PU.PU_Id, PL.Dept_Id, D.Dept_Desc, PL.PL_Id, PL.PL_Desc, PL.PL_Desc,
						PU.Master_Unit
						FROM	dbo.Prod_Units PU			WITH (NOLOCK)
						JOIN	dbo.Prod_Lines PL			WITH (NOLOCK)
						ON		PU.PL_Id		= PL.PL_Id
						JOIN	dbo.Event_Configuration EC	WITH (NOLOCK)
						ON		PU.PU_Id		= EC.PU_Id
						--AND		EC.ET_Id		= 2
						JOIN	dbo.Departments D			WITH (NOLOCK)
						ON		D.Dept_Id		= PL.Dept_Id
						ORDER
						BY		PL.PL_Desc
END
-------------------------------------------------------------------------------
-- Handle Master PU filter
-------------------------------------------------------------------------------
IF	@FlagOnlyMasterPU = 1	
	DELETE	@tOutput
			WHERE	MasterPUId IS NOT NULL
-------------------------------------------------------------------------------
-- Handle PL Nickname
-------------------------------------------------------------------------------
-- Routine#1: For EUS site. It returns the 2 righmost characters of the PLDesc
-------------------------------------------------------------------------------
IF	@PLNickNameRoutineId = 1
BEGIN
		UPDATE	@tOutput
				SET	PLNickName = RIGHT(PLDesc, 2)

		UPDATE	@tOutput
				SET	PLNickName	= '00'
					WHERE	ISNUMERIC(PLNickName) = 0
END


------------------------Flage DeptFirst & Line First------------------------------------------
DECLARE	@flagDeptAndPLId			TABLE
(
	DeptId		INT,
	PLId		INT,
	Id			INT,
	FlagDeptFirst INT,
	FlagLineFirst INT 
)

insert @flagDeptAndPLId (DeptId, PLId, Id, FlagDeptFirst, FlagLineFirst)  
(select distinct DeptId, PLId, Min(Id) MinId, NULL, NULL from @tOutput group by DeptId, PLId)

update @flagDeptAndPLId set FlagDeptFirst = 1 where id in (select MIN(id) from @flagDeptAndPLId group by DeptId)

update @flagDeptAndPLId set FlagLineFirst = 1

--select * from @flagDeptAndPLId 

--select distinct DeptId, PLId from @tOutput group by DeptId, PLId

-----------------------------------------------------------------------------
--Return output
-----------------------------------------------------------------------------
SELECT	R1.Id				Id,
		R1.PUId            PUId,
		R1.DeptId			DeptId,
		R1.DeptDesc		DeptDesc,
		R1.PLId			PLId,
		R1.PLDesc			PLDesc,
		R1.PLNickName		PLNickName,
		R1.PUDesc PUDesc,
		R2.FlagDeptFirst FlagDeptFirst,
		R2.FlagLineFirst FlagLineFirst
		FROM	@tOutput R1
		LEFT JOIN @flagDeptAndPLId R2
		ON R1.id = R2.id
		ORDER
		BY		R1.Id

				
 --GRANT EXEcute on dbo.spLocal_PDPNMGetPADataForBFBU to public
 
 
 BEGIN
  GRANT EXECUTE ON [dbo].[spLocal_PDPNMGetPADataForFCBU] to [Thingworx]
END
