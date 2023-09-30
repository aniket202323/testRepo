 
 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_KIT_GetKitList_Test]
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
exec spLocal_MPWS_KIT_GetKitList_Test @ErrorCode OUTPUT, @ErrorMessage OUTPUT, 'CREATED', 'Released,Dispensing,Cancelled' , ''
select @ErrorCode, @ErrorMessage
 
declare @ErrorCode INT, @ErrorMessage VARCHAR(500)
exec spLocal_MPWS_KIT_GetKitList_Test @ErrorCode OUTPUT, @ErrorMessage OUTPUT, '', '' , ''
select @ErrorCode, @ErrorMessage
 
*/
-- Date         Version Build Author  
 
--TODO: Need to add Production Line
 
-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------
DECLARE @KitUnits TABLE
(
	PU_Id INT
)
 
DECLARE @Flag INT=0
DECLARE @SQL VARCHAR(1000)
 
CREATE	TABLE #tOutput
(
	Id						INT					IDENTITY(1,1)	NOT NULL,
	KitEventId				INT					NULL,
	[PONum]					VARCHAR(50)			NULL,	--Process order number
	[BatchNumber]			VARCHAR(50)			NULL,	--Batch status
	[POStatus]				VARCHAR(25)			NULL,	--PO status
	[ProductionLine]		VARCHAR(50)			NULL,	--PU_Desc of production unit: : Is this production line for preweigh or making?
	Kit						VARCHAR(50)			NULL,	--Kit event num
	[KitStatus]				VARCHAR(50)			NULL	--Kit event status
)
 
DECLARE  @tPOStatusMask TABLE (
 
POstatus				VARCHAR(70)							NULL
)
 
DECLARE  @tPOMask	 TABLE (
 
POMask					VARCHAR(70)							NULL
)
 
DECLARE  @tKitStatusMask TABLE (
 
KitStatusMask			VARCHAR(70)							NULL
)
------------------------------------------------------------------------------
--  Initialize output values
-------------------------------------------------------------------------------
SELECT	@ErrorCode		=	1,
		@ErrorMessage	=	'Success'
-------------------------------------------------------------------------------
-- Get Kit List
-------------------------------------------------------------------------------
--Get list of Kitting unit PU_Ids
INSERT INTO @KitUnits
	(PU_Id)
	SELECT PU_ID from dbo.Prod_Units_Base WHERE PU_Desc LIKE '%Kit%'
 
--Get results
INSERT INTO #tOutput
	(
		[PONum],
		KitEventId,
		[BatchNumber],
		[POStatus],
		[ProductionLine],
		Kit,
		[KitStatus]
		)
	SELECT 
		pp.Process_Order as [PONum],
		ke.Event_Id as KitEventId,
		psu.Pattern_Code as [BatchNumber],
		pps.PP_Status_Desc as [POStatus],
		pl.PL_Desc as [ProductionLine],
		ke.Event_Num as Kit,
		ps.ProdStatus_Desc as [KitStatus]
	FROM 
		@KitUnits ku
		JOIN dbo.[Events] ke on ke.PU_Id = ku.PU_Id	--Kits
		LEFT JOIN dbo.[Event_Details] ked ON ked.Event_Id = ke.Event_Id	--Kit
		LEFT JOIN dbo.Production_Status ps on ps.ProdStatus_Id = ke.Event_Status
		LEFT JOIN dbo.Production_Plan pp on pp.PP_Id = ked.PP_Id
		 JOIN dbo.Production_Plan_Statuses pps on pps.PP_Status_Id = pp.PP_Status_Id
		--AND pps.PP_Status_Desc in (SELECT * FROM dbo.fnLocal_CmnParseList (@POStatusMask,','))	--@POStatusMask
			AND pp.Path_Id in (SELECT path_id FROM Prdexec_Paths WHERE Path_Code like 'PW%') 
			--AND pp.Process_Order LIKE '%' + @POMask + '%'	--in ('PO2019','PO20','PO19')
		LEFT JOIN dbo.Production_Setup psu on psu.PP_Id = pp.PP_Id
		join dbo.Prod_Units_Base pu on ku.PU_Id = pu.PU_Id
		join dbo.Prod_Lines_Base pl on pu.PL_Id = pl.PL_Id
 
SET @SQL = 'SELECT * FROM #tOutput t'
 
IF @KitStatusMask <> ''                                       
	BEGIN
    SET @SQL = @SQL + ' ' + 'where t.KitStatus in(SELECT * FROM dbo.fnLocal_CmnParseList ('+''''+@KitStatusMask+''''+','+''''+','+''''+'))' 
    SET @flag = 1
END
              
IF @POStatusMask <> ''
BEGIN
	IF @Flag = 1
	BEGIN
    SET @SQL = @SQL + ' and '
    END
    ELSE
    BEGIN
    SET @SQL = @SQL + ' where '
    END
SET @SQL = @SQL + 't.POStatus in(SELECT * FROM dbo.fnLocal_CmnParseList ('+''''+@POStatusMask+''''+','+''''+','+''''+'))' 
SET @Flag = 1   
END       
                 
IF @POMask <> ''
BEGIN
    IF @Flag = 1
    BEGIN
    SET @sql = @sql + ' and '
    END
    ELSE
    BEGIN
    SET @sql = @sql + ' where '
    END 
SET @SQL = @SQL + 't.PONum in(SELECT * FROM dbo.fnLocal_CmnParseList ('+''''+@POMask+''''+','+''''+','+''''+'))' 
SET @Flag = 1   
END 
                 
EXECUTE(@SQL)   
-------------------------------------------------------------------------------
-- Insert A 'ALL'  dummy  record   
-------------------------------------------------------------------------------							
						
--INSERT	@tPOStatusMask(POstatus) VALUES ('ALL')    
    
--INSERT	@tPOStatusMask(POstatus)    
--SELECT DISTINCT POStatus  from #tOutput 
 
--SELECT * FROM @tPOStatusMask
 
--INSERT	@tPOMask(POMask) VALUES ('ALL')    
    
--INSERT	@tPOMask(POMask) 
--SELECT DISTINCT PONum  from #tOutput 
 
--SELECT * FROM @tPOMask
--INSERT	@tKitStatusMask(KitStatusMask) VALUES ('ALL')    
    
--INSERT	@tKitStatusMask(KitStatusMask) 
--SELECT DISTINCT KitStatus  from #tOutput 
 
--SELECT * FROM @tKitStatusMask
 
 
DROP TABLE #tOutput             
 
