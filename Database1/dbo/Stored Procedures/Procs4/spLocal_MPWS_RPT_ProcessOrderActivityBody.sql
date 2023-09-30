 
 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_RPT_ProcessOrderActivityBody
		
	This sp returns body info for spLocal_MPWS_RPT_ProcessOrderActivityHeader
	
	Date			Version		Build	Author  
	09-Aug-2016		001			001		Jim Cameron (GEIP)		Initial development	
 
	If query contains any results it should return Success and the table should contain the following ordered by timestamp:
	1. All process order changes (go to the production plan history table) 
	2. All BOM changes (** Use UDE that is created when BOM changes occur from PO download) 
	3. Create/Insert dispense events 
	4. Dispense status changes 
	5. Create/Insert Kit events 
	6. Assign kit to carrier section events Kit status changes
	7. Assign dispense container to carrier section events (to kit)
 
test
 
DECLARE @ErrorCode INT, @ErrorMessage VARCHAR(500)
EXEC dbo.spLocal_MPWS_RPT_ProcessOrderActivityBody @ErrorCode OUTPUT, @ErrorMessage OUTPUT, '905045973-15'
 
SELECT @ErrorCode, @ErrorMessage
 
 
*/	-------------------------------------------------------------------------------
 
CREATE PROCEDURE [dbo].[spLocal_MPWS_RPT_ProcessOrderActivityBody]
	@ErrorCode		INT				OUTPUT,
	@ErrorMessage	VARCHAR(500)	OUTPUT,
	@ProcessOrder	VARCHAR(50)
 
AS
 
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
 
DECLARE @Results TABLE
(
	ProcessOrder	VARCHAR(50),	-- fields to return
	[Timestamp]		DATETIME,
	Activity		VARCHAR(50),
	ActivityData	VARCHAR(255),
	
	PathId			INT,			-- id's to link disp/kit/etc to the po
	PPId			INT,
	EventId			INT,
	BOM_F_Id		INT,
	BOM_FI_Id		INT
);
 
BEGIN TRY
 
--		1. All process order changes (go to the production plan history table) 
 
	;WITH poHist AS
	(
		SELECT
			pph.Path_Id,
			pph.BOM_Formulation_Id,
			pph.PP_Id,
			pph.Process_Order ProcessOrder,
			pph.Modified_On [Timestamp],
			pps.PP_Status_Desc Activity,
			ROW_NUMBER() OVER (PARTITION BY pph.PP_Id, pph.PP_Status_Id ORDER BY Modified_On) StatusRank
		FROM dbo.Production_Plan_History pph
			JOIN dbo.Production_Plan_Statuses pps ON pps.PP_Status_Id = pph.PP_Status_Id
			-- pph above has index on (PP_Id), pp below has index on (path_id, process_order) so use pp below so we can get PP_Id and use indexes for the query.
			JOIN dbo.Production_Plan pp ON pp.PP_Id = pph.PP_Id
			JOIN dbo.Prdexec_Paths pep ON pep.Path_Id = pp.Path_Id
			JOIN dbo.Prod_Lines_Base pl ON pep.PL_Id = pl.PL_Id
			JOIN dbo.Departments_Base d ON pl.Dept_Id = d.Dept_Id
		WHERE d.Dept_Desc = 'Pre-Weigh'
			AND pp.Process_Order = @ProcessOrder
	)
	INSERT @Results (ProcessOrder, [Timestamp], Activity, ActivityData, PathId, PPId, BOM_F_Id)
		SELECT
			ProcessOrder,
			[Timestamp],
			Activity,
			'',
			Path_Id,
			PP_Id,
			BOM_Formulation_Id
		FROM poHist 
		--WHERE StatusRank = 1
 
--		2. All BOM changes (** Use UDE that is created when BOM changes occur from PO download) 
 
--		3. Create/Insert dispense events
 
	;WITH disp AS
	(
		SELECT DISTINCT
			r.ProcessOrder,
			r.PathId,
			r.PPId,
			e.Event_Id,
			e.[Timestamp],
			ed.Initial_Dimension_X DispenseQty,
			CAST(t1.Result AS VARCHAR(25)) UOM,
			CAST(t2.Result AS INT) BOM_FI_Id
		FROM dbo.Event_Details ed
			JOIN dbo.Events e ON ed.Event_Id = e.Event_Id
			JOIN dbo.Variables_Base v1 ON v1.PU_Id = e.PU_Id
			JOIN dbo.Tests t1 ON t1.Result_On = e.[Timestamp]
				AND t1.Var_Id = v1.Var_Id
			JOIN dbo.Variables_Base v2 ON v2.PU_Id = e.PU_Id
			JOIN dbo.Tests t2 ON t2.Result_On = e.[Timestamp]
				AND t2.Var_Id = v2.Var_Id
			JOIN @Results r ON ed.PP_Id = r.PPId
		WHERE v1.Test_Name = 'MPWS_DISP_DISPENSE_UOM'
			AND v2.Test_Name = 'MPWS_DISP_BOMFIId'
	)
	INSERT @Results (ProcessOrder, [Timestamp], Activity, ActivityData, PathId, PPId, EventId, BOM_FI_Id)
		SELECT
			ProcessOrder,
			[Timestamp],
			'Dispense',
			CAST(CAST(DispenseQty AS DECIMAL(10, 3)) AS VARCHAR(25)) + ' ' + UOM,
			PathId,
			PPId,
			Event_Id,
			BOM_FI_Id
		FROM disp
 
--		4. Dispense status changes 
 
	INSERT @Results (ProcessOrder, [Timestamp], Activity, ActivityData, PathId, PPId, EventId, BOM_FI_Id)
		SELECT DISTINCT
			r.ProcessOrder,
			eh.Modified_On,
			'Dispense Status Change',
			ps.ProdStatus_Desc,
			r.PathId,
			r.PPId,
			eh.Event_Id,
			r.BOM_FI_Id
		FROM dbo.event_history eh
			JOIN @Results r ON r.EventId = eh.Event_Id
			JOIN dbo.production_status ps ON ps.prodstatus_id = eh.event_status
		WHERE r.Activity = 'Dispense';
 
 
--		5. Create/Insert Kit events 
 
	INSERT @Results (ProcessOrder, [Timestamp], Activity, ActivityData, PathId, PPId, EventId)
		SELECT DISTINCT
			r.ProcessOrder,
			e.[Timestamp],
			'Kitting',
			e.Event_Num,
			r.PathId,
			r.PPId,
			e.Event_Id
		FROM @Results r
			JOIN dbo.Event_Components ec ON ec.Source_Event_Id = r.EventId
			JOIN dbo.Events e ON e.Event_Id = ec.Event_Id
			JOIN dbo.Prod_Units_Base pu ON pu.PU_Id = e.PU_Id
		WHERE r.Activity = 'Dispense'
			AND pu.Equipment_Type = 'Kitting Station'
 
--		6. Assign kit to carrier section events Kit status changes
--		7. Assign dispense container to carrier section events (to kit)
	
	SELECT
		--*
		ProcessOrder,
		[Timestamp],
		Activity,
		ActivityData
	FROM @Results
	ORDER BY ProcessOrder, [Timestamp];
	
	SET @ErrorCode = 1;
	SET @ErrorMessage = 'Success';
	
END TRY
BEGIN CATCH
 
	SET @ErrorCode = ERROR_NUMBER()
	SET @ErrorMessage = ERROR_MESSAGE()
	
END CATCH;
 
 
