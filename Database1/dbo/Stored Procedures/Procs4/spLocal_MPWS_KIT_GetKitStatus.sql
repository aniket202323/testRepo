 
 
 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_KIT_GetKitStatus
	
	
	Date			Version		Build	Author  
	25-Jul-2016		001			001		Jim Cameron (GEIP)		Initial development	
	
test
 
DECLARE @ErrorCode INT, @ErrorMessage VARCHAR(255), @KitStatus VARCHAR(50)
EXEC dbo.spLocal_MPWS_KIT_GetKitStatus @ErrorCode OUTPUT, @ErrorMessage OUTPUT, @KitStatus OUTPUT, 5488403
 
SELECT @ErrorCode, @ErrorMessage, @KitStatus
 
 
*/	-------------------------------------------------------------------------------
 
CREATE  PROCEDURE [dbo].[spLocal_MPWS_KIT_GetKitStatus]
	@ErrorCode		INT				OUTPUT,		-- Flag to indicate Success or Failure (1-Success,0-Failure)
	@ErrorMessage	VARCHAR(255)	OUTPUT,		-- Error Message to Write to Log File
	@KitStatus		VARCHAR(50)		OUTPUT,		-- Result, no table returned
	@KitEventId		INT							-- the Event_Id of the kit to get the status of
	
AS
 
SET NOCOUNT ON;
 
;WITH s AS
(
	-- anything below 'Kitting' is set to created, get Kitting's order no.
	SELECT 
		Phrase_Order 
	FROM dbo.Phrase p 
		JOIN dbo.Data_Type dt ON dt.Data_Type_Id = p.Data_Type_Id
	WHERE dt.Data_Type_Desc = 'MPWS_Statuses'
		AND p.Phrase_Value = 'Kitting'
		AND p.Active = 1
)
, kstat AS
(
	SELECT
		p.Phrase_Order StatusRank,
		Phrase_Value BOMStatus,
		CASE WHEN p.Phrase_Order < s.Phrase_Order OR p.Phrase_Order IS NULL THEN 'Created' ELSE Phrase_Value END KitStatus
	FROM dbo.Phrase p
		JOIN dbo.Data_Type dt ON dt.Data_Type_Id = p.Data_Type_Id
		CROSS APPLY s
	WHERE dt.Data_Type_Desc = 'MPWS_Statuses'
		AND p.Active = 1
)
, kit AS
(
	SELECT
		ke.Event_Id Kit_Event_Id,
		pps.PP_Status_Desc BOMItemStatus,
		CASE WHEN kstat.StatusRank IS NULL THEN 0 ELSE kstat.StatusRank END StatusRank,
		kstat.BOMStatus,
		CASE WHEN kstat.StatusRank IS NULL THEN 'Created' ELSE kstat.KitStatus END KitStatus
	FROM dbo.[Events] ke																					--Kit Event
		JOIN dbo.Event_Details ed ON ke.Event_Id = ed.Event_Id												--Kit event details
		JOIN dbo.Production_Plan pp ON pp.PP_Id = ed.PP_Id													--Prod Plan for Kit
		JOIN dbo.Prdexec_Paths pep ON pep.Path_Id = pp.Path_Id
		JOIN dbo.Prod_Lines_Base pl ON pep.PL_Id = pl.PL_Id
		JOIN dbo.Departments_Base d ON pl.Dept_Id = d.Dept_Id
		JOIN Bill_Of_Material_Formulation_Item bomfi ON bomfi.BOM_Formulation_Id = pp.BOM_Formulation_Id	--BOM ITems
		CROSS APPLY dbo.fnLocal_MPWS_GetUDP(bomfi.BOM_Formulation_Item_Id, 'BOMItemStatus', 'Bill_Of_Material_Formulation_Item') bs
		JOIN dbo.Production_Plan_Statuses pps ON pps.PP_Status_Id = bs.Value
		LEFT JOIN kstat ON kstat.BOMStatus = pps.PP_Status_Desc
	WHERE ke.Event_Id = @KitEventId OR @KitEventId IS NULL
		AND d.Dept_Desc = 'Pre-Weigh'
)
SELECT
	@KitStatus		= KitStatus,
	@ErrorCode		= 1,
	@ErrorMessage	= 'Success'
FROM kit
WHERE StatusRank = (SELECT MIN(StatusRank) FROM kit)
GROUP BY KitStatus
