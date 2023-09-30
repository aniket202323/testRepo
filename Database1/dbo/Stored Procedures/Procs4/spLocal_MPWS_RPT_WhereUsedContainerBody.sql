 
 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_RPT_WhereUsedContainerBody
	
	If query contains any results it should return Success and the table should return 
	all dispense containers dispensed from the specified raw material container.
	
	Date			Version		Build	Author  
	23-Jun-2016		001			001		Jim Cameron (GEIP)		Initial development	
	11-Aug-2016		001			002		Susan Lee (GE Digital)	Remove material information from table being returned - it is now being returned by a new header sproc.
	01-Jun-2017     001         003     Susan Lee (GE Digital)  left join on production plan and production setup to allow for misc. dispense that are not tied to a PO
	08-Nov-2017		001			004		Susan Lee (GE Digital)	Filter dispenses by dispense station, batch ID comes from RMC var, 
test
 
DECLARE @ErrorCode INT, @ErrorMessage VARCHAR(500)
EXEC dbo.spLocal_MPWS_RPT_WhereUsedContainerBody @ErrorCode OUTPUT, @ErrorMessage OUTPUT, 'RMCIT-070'
 
SELECT @ErrorCode, @ErrorMessage
 
ContainerId
RMCIT-271
RMCIT-281
RMCIT-282
RMCIT-283
RMCIT-284
 
*/	-------------------------------------------------------------------------------
 
CREATE  PROCEDURE [dbo].[spLocal_MPWS_RPT_WhereUsedContainerBody]
	@ErrorCode		INT				OUTPUT,
	@ErrorMessage	VARCHAR(500)	OUTPUT,
	@RMCNum			VARCHAR(50)
--WITH ENCRYPTION 
AS
 
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
 
BEGIN TRY
 
	-- raw material container
	;WITH rmc AS
	(
		SELECT
			e.Event_Id,
			p.Prod_Code Material,
			p.Prod_Desc MaterialDesc,
			t.Result LotNum
		FROM dbo.Events e
			JOIN dbo.Event_Details ed ON e.Event_Id = ed.Event_Id
			JOIN dbo.Products_Base p ON e.Applied_Product = p.Prod_Id
			JOIN dbo.Prod_Units_Base pu ON e.PU_Id = pu.PU_Id
			JOIN dbo.Variables_Base v ON v.PU_Id = e.PU_Id 
			LEFT JOIN dbo.Tests t ON t.Var_Id = v.Var_Id 
				AND t.Result_On = e.[Timestamp]
		WHERE pu.Equipment_Type = 'Receiving Station'
			AND v.Test_Name = 'MPWS_INVN_SAP_LOT'
			AND e.Event_Num = @RMCNum
	)		
	, paths AS
	(
		SELECT
			pep.Path_Id
		FROM dbo.Prdexec_Paths pep
			JOIN dbo.Prod_Lines_Base pl ON pep.PL_Id = pl.PL_Id
			JOIN dbo.Departments_Base d ON pl.Dept_Id = d.Dept_Id
		WHERE d.Dept_Desc = 'Pre-Weigh'
	)
	-- dispense events
	SELECT
		@RMCNum RMCNumber,
		e.[Timestamp] DispenseDatetime,
		e.Event_Num DispenseContainerNum,
		CAST(ed.Final_Dimension_X AS DECIMAL(10, 3)) DispenseContainerWgt,
		u.Username DispenseUser,
		pline.ProdLineDesc ProductionLine,
		rmc.LotNum SAPBatchNumber,
		pp.Process_Order PONum,
		t.Result UOM
	FROM dbo.Event_Details ed
		JOIN dbo.Events e ON ed.Event_Id = e.Event_Id
		JOIN dbo.Prod_Units_Base pu ON pu.PU_Id = e.PU_Id AND pu.Equipment_Type = 'Dispense Station'
		JOIN dbo.Production_Status ps ON e.Event_Status = ps.ProdStatus_Id
		LEFT JOIN dbo.Production_Setup pset ON pset.PP_Id = ed.PP_Id
		LEFT JOIN dbo.Production_Plan pp ON pp.PP_Id = ed.PP_Id
			AND pp.Path_Id IN (SELECT Path_Id FROM paths)
		OUTER APPLY dbo.fnLocal_MPWS_GetProductionLineInfoByPwPPId(pp.PP_Id) pline
		JOIN dbo.Users_Base u ON e.[User_Id] = u.[User_Id]
		JOIN dbo.Event_Components ec ON ec.Event_Id = e.Event_Id
		JOIN dbo.Events e2 ON e2.Event_id = ec.Source_Event_Id
		JOIN rmc ON rmc.Event_Id = e2.Event_Id
		JOIN dbo.Variables v ON v.PU_Id = e.PU_Id AND v.Test_Name = 'MPWS_DISP_DISPENSE_UOM'
		JOIN dbo.tests t ON t.Var_Id = v.Var_Id AND t.Result_On = e.TimeStamp

	ORDER BY DispenseDatetime;
		
	IF @@ROWCOUNT > 0
	BEGIN
		SET @ErrorCode = 1;
		SET @ErrorMessage = 'Success';
	END
	ELSE
	BEGIN
		SET @ErrorCode = -1;
		SET @ErrorMessage = 'No Items found';
	END
	
END TRY
BEGIN CATCH
 
	SET @ErrorCode = ERROR_NUMBER()
	SET @ErrorMessage = ERROR_MESSAGE()
	
END CATCH;
 
 
