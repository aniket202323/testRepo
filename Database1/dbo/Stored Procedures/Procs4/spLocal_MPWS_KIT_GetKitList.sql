 
 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_KIT_GetKitList]
		@ErrorCode		INT		OUTPUT		,
		@ErrorMessage	VARCHAR(500) OUTPUT	,
		@KitStatusMask	VARCHAR(255) ,
		@POStatusMask	VARCHAR(255),
		@POMask			VARCHAR(255)
AS
 
SET NOCOUNT ON
-------------------------------------------------------------------------------
-- Gets Kit list 
/*
declare @ErrorCode INT, @ErrorMessage VARCHAR(500)
exec spLocal_MPWS_KIT_GetKitList @ErrorCode OUTPUT, @ErrorMessage OUTPUT, '', 'Released,Dispensing,Cancelled' , '0'
select @ErrorCode, @ErrorMessage
 
declare @ErrorCode INT, @ErrorMessage VARCHAR(500)
exec spLocal_MPWS_KIT_GetKitList @ErrorCode OUTPUT, @ErrorMessage OUTPUT, 'kitted', '' , ''
select @ErrorCode, @ErrorMessage
 
*/
-- Date         Version Build Author  
-- 2017-02-08	2		0		Susan Lee (GE Digital)	Updated filtering
--
 
 
-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------
DECLARE @KitUnits TABLE
(
	PU_Id INT
)
 
IF OBJECT_ID(N'tempdb..#tOutput') IS NOT NULL DROP TABLE #tOutput
 
CREATE	TABLE #tOutput
(
	Id						INT					IDENTITY(1,1)	NOT NULL,
	[PONum]					VARCHAR(50)			NULL,	--Process order number
	[BatchNumber]			VARCHAR(50)			NULL,	--Batch status
	[POStatus]				VARCHAR(25)			NULL,	--PO status
	[ProductionLine]		VARCHAR(50)			NULL,	--Making line
	Kit						VARCHAR(50)			NULL,	--Kit event num
	[KitStatus]				VARCHAR(50)			NULL,	--Kit event status
	[KitEventId]            INT                 NULL	--Kit eventId
)
 
DECLARE  @tPOStatus TABLE (
 
	POstatus			VARCHAR(70)							NULL
)
 
DECLARE  @tPONum	 TABLE (
 
	PONum				VARCHAR(70)							NULL
)
 
DECLARE  @tKitStatus TABLE (
 
	KitStatus			VARCHAR(70)							NULL
)
 
DECLARE @POStatusCount	INT	= 0,
		@PONumCount		INT	= 0,
		@KitStatusCount	INT = 0
				
------------------------------------------------------------------------------
--  Initialize output values
-------------------------------------------------------------------------------
SELECT	@ErrorCode		=	1,
		@ErrorMessage	=	'Success'
 
-------------------------------------------------------------------------------
--  Parse strings into table variables
-------------------------------------------------------------------------------
IF LEN(@kitstatusmask) > 1		-- ignore '0', '' or similar
BEGIN 
	INSERT	@tKitStatus (KitStatus)
			SELECT	*
			FROM	dbo.fnLocal_CmnParseListLong(@KitStatusMask,',')
	SELECT @KitStatusCount = @@ROWCOUNT
END
 
IF LEN(@POStatusMask) > 1		-- ignore '0', '' or similar
BEGIN 
	INSERT	@tPOStatus (POstatus)
			SELECT	*
			FROM	dbo.fnLocal_CmnParseListLong(@POStatusMask,',')
	SELECT @POStatusCount = @@ROWCOUNT
END
 
IF LEN(@POMask) > 1		-- ignore '0', '' or similar
BEGIN 
	INSERT	@tPONum (PONum)
			SELECT	*
			FROM	dbo.fnLocal_CmnParseListLong(@POMask,',')
	SELECT @PONumCount = @@ROWCOUNT
END
 
-------------------------------------------------------------------------------
-- Get Kitting PUs  
-- TODO: Kitting PUs are identified by class 'Preweigh - Kitting'
-------------------------------------------------------------------------------
INSERT INTO @KitUnits
	(PU_Id)
	SELECT PU_ID from dbo.Prod_Units_Base WHERE PU_Desc LIKE '%Kit%'  --4315
 
-------------------------------------------------------------------------------
-- Get Kit List
-------------------------------------------------------------------------------
INSERT INTO #tOutput
	(
		[PONum],
		[BatchNumber],
		[POStatus],
		[ProductionLine],
		Kit,
		[KitStatus],
		[KitEventId]
		)
	SELECT 
		pp.Process_Order as [PONum],
		info.ProdLineBatchNum as [BatchNumber],
		pps.PP_Status_Desc as [POStatus],
		info.ProdLineDesc as [ProductionLine],
		ke.Event_Num as Kit,
		ps.ProdStatus_Desc as [KitStatus],
		ke.Event_Id        as [KitEventId]
	FROM 
		@KitUnits ku
		JOIN dbo.[Events] ke on ke.PU_Id = ku.PU_Id	--Kits
		JOIN dbo.[Event_Details] ked ON ked.Event_Id = ke.Event_Id	--Kit
		JOIN dbo.Production_Status ps on ps.ProdStatus_Id = ke.Event_Status
		LEFT JOIN dbo.Production_Plan pp on pp.PP_Id = ked.PP_Id
		JOIN dbo.Production_Plan_Statuses pps on pps.PP_Status_Id = pp.PP_Status_Id
		CROSS APPLY dbo.fnLocal_MPWS_GetProductionLineInfoByPwPPId(pp.PP_Id) info
	WHERE (@kitstatuscount = 0 OR ps.prodstatus_desc IN (SELECT KitStatus FROM @tkitstatus))
		AND (@POStatusCount = 0 OR pps.PP_Status_Desc IN (SELECT POstatus FROM @tPOStatus))
		AND (@PONumCount = 0 OR pp.Process_Order IN (SELECT PONum FROM @tPONum))
		--JOIN @tKitStatus kitstatusm on ( kitstatusm.KitStatus = ps.ProdStatus_Desc OR @KitStatusCount = 0 )
		--JOIN @tPOStatus postatusm on ( postatusm.POstatus = pps.PP_Status_Desc OR @POStatusCount = 0 )
		--JOIN @tPONum ponumm on ( ponumm.PONum = pp.Process_Order OR @PONumCount = 0 )
	ORDER BY PONum,Kit
 
SELECT * from #tOutput
 
 
DROP TABLE #tOutput             
 
