 
 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_RPT_KittingHeader
	
	This report is used to determine if a PO has been fully preweighed. 
	When the PO is fully dispensed this report provides a record of the dispenses 
	that must be kittted to deliver the complete PO to production.
	
	This sp returns header info for spLocal_MPWS_RPT_KittingBody
	
	Date			Version		Build	Author  
	16-Jun-2016		001			001		Jim Cameron (GEIP)		Initial development	
	10-Nov-2017		001			001		Susan Lee (GE Digital)	Update Batch Num & Ready For Production	
 
test
 
DECLARE @ErrorCode INT, @ErrorMessage VARCHAR(500)
EXEC dbo.spLocal_MPWS_RPT_KittingHeader @ErrorCode OUTPUT, @ErrorMessage OUTPUT, '20151120105909'
 
SELECT @ErrorCode, @ErrorMessage

 
*/	-------------------------------------------------------------------------------
 
CREATE  PROCEDURE [dbo].[spLocal_MPWS_RPT_KittingHeader]
	@ErrorCode		INT				OUTPUT,
	@ErrorMessage	VARCHAR(500)	OUTPUT,
	@ProcessOrder	VARCHAR(50)
--WITH ENCRYPTION 
AS
 
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	
DECLARE
	@PwPathId	INT;

BEGIN TRY
 
	SELECT
		@PwPathId = pep.Path_Id
	FROM dbo.Prdexec_Paths pep
		JOIN dbo.Prod_Lines_Base pl ON pep.PL_Id = pl.PL_Id
		JOIN dbo.Departments_Base d ON pl.Dept_Id = d.Dept_Id
	WHERE d.Dept_Desc = 'Pre-Weigh';

	;WITH hist AS
	(
		SELECT
			Path_Id,
			PP_Id,
			Released POReleaseDT,
			"Ready For Production" POReadyForProdDT
		FROM (
				SELECT
					pp.Path_Id,
					pp.PP_Id,
					pps.PP_Status_Desc,
					pph.Entry_On
				FROM dbo.Production_Plan_History pph
					JOIN dbo.Production_Plan pp ON pph.PP_Id = pp.PP_Id
					JOIN dbo.Production_Plan_Statuses pps ON pph.PP_Status_Id = pps.PP_Status_Id
				WHERE (pp.Process_Order = @ProcessOrder OR @ProcessOrder IS NULL)
					AND pps.PP_Status_Desc IN ('Released', 'Ready for Production')
					AND pph.Path_Id = @PwPathId
				) a
			PIVOT (MIN(Entry_On) FOR PP_Status_Desc IN ([Released], [Ready for Production])) pvt

	)
	SELECT
		@ProcessOrder ProcessOrder,
		info.ProdLineDesc ProductionLine,
		info.ProdLineBatchNum BatchId,
		p.Prod_Code Material,
		pp.Forecast_Quantity [BatchSize],
		eu.Eng_Unit_Code UOM,
		hist.POReleaseDT,
		hist.POReadyForProdDT
	FROM dbo.Production_Plan pp
		JOIN dbo.Products_Base p ON p.Prod_Id = pp.Prod_Id
		JOIN dbo.Production_Setup ps ON pp.PP_Id = ps.PP_Id
		JOIN dbo.Bill_Of_Material_Formulation bomf ON pp.BOM_Formulation_Id = bomf.BOM_Formulation_Id
		JOIN dbo.Engineering_Unit eu ON eu.Eng_Unit_Id = bomf.Eng_Unit_Id
		LEFT JOIN hist ON hist.PP_Id = pp.PP_Id 
			AND hist.Path_Id = pp.Path_Id
		CROSS APPLY dbo.fnLocal_MPWS_GetProductionLineInfoByPwPPId(hist.PP_Id) info					
	WHERE (pp.Process_Order = @ProcessOrder OR @ProcessOrder IS NULL)
		AND pp.Path_Id = @PwPathId;
	
	SET @ErrorCode = 1;
	SET @ErrorMessage = 'Success';
	
END TRY
BEGIN CATCH
 
	SET @ErrorCode = ERROR_NUMBER()
	SET @ErrorMessage = ERROR_MESSAGE()
	
END CATCH;
 
 
