 
 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_RPT_DetailedDispenseHeader
	
	This report is used to determine if a PO has been fully preweighed. 
	When the PO is fully dispensed this report provides a record of the dispenses 
	that must be kittted to deliver the complete PO to production.
	
	This sp returns header info for spLocal_MPWS_RPT_DetailedDispenseBody
	
	Date			Version		Build	Author  
	31-May-2016		001			001		Jim Cameron (GEIP)			Initial development	
	14-Jul-2017		001			002		Jim Cameron (GE Digital)	Added 'Unassigned' dispenses
    23-Oct-2017     001         003     Susan Lee (GE Digital)		look for all prweigh paths
test
 
DECLARE @ErrorCode INT, @ErrorMessage VARCHAR(500)
EXEC dbo.spLocal_MPWS_RPT_DetailedDispenseHeader @ErrorCode OUTPUT, @ErrorMessage OUTPUT, '905049758-30'
 
SELECT @ErrorCode, @ErrorMessage
 
*/	-------------------------------------------------------------------------------
 
CREATE  PROCEDURE [dbo].[spLocal_MPWS_RPT_DetailedDispenseHeader]
	@ErrorCode		INT				OUTPUT,
	@ErrorMessage	VARCHAR(500)	OUTPUT,
	@ProcessOrder	VARCHAR(50)
--WITH ENCRYPTION 
AS
 
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

------------------------------------------------------------------------------------
-- Declare vars
------------------------------------------------------------------------------------

DECLARE @PreweighDept VARCHAR(50) = 'Pre-Weigh' 
DECLARE @PWPaths TABLE
(
	PWPathId INT
)
------------------------------------------------------------------------------------
-- Get preweigh production paths
------------------------------------------------------------------------------------

INSERT INTO @PWPaths
(
	PWPathId
)
SELECT Path_Id 
FROM dbo.Prdexec_Paths pep
JOIN dbo.Prod_Lines_Base pl ON pl.PL_Id = pep.PL_Id
JOIN dbo.Departments_Base d ON d.Dept_Id = pl.Dept_Id
WHERE d.Dept_Desc = @PreweighDept

------------------------------------------------------------------------------------
-- Get PO info
------------------------------------------------------------------------------------


BEGIN TRY
 
	IF @ProcessOrder <> 'Unassigned'
	BEGIN
 
		;WITH hist AS
		(
			SELECT
				Path_Id,
				PP_Id,
				Released ReleaseDT,
				Ready ReadyForProdDT
			FROM (
					SELECT
						pp.Path_Id,
						pp.PP_Id,
						pps.PP_Status_Desc,
						pph.Entry_On
					FROM dbo.Production_Plan_History pph
						JOIN dbo.Production_Plan pp ON pph.PP_Id = pp.PP_Id
						JOIN dbo.Production_Plan_Statuses pps ON pph.PP_Status_Id = pps.PP_Status_Id
						JOIN dbo.Prdexec_Paths pep ON pep.Path_Id = pp.Path_Id
						JOIN dbo.Prod_Lines_Base pl ON pep.PL_Id = pl.PL_Id
						JOIN dbo.Departments_Base d ON pl.Dept_Id = d.Dept_Id
					WHERE (pp.Process_Order = @ProcessOrder OR @ProcessOrder IS NULL)
						AND pps.PP_Status_Desc IN ('Released', 'Ready')
						AND d.Dept_Desc = 'Pre-Weigh'
					) a
				PIVOT (MIN(Entry_On) FOR PP_Status_Desc IN ([Released], [Ready])) pvt
		)
		SELECT
			ISNULL(pp.Process_Order, '') ProcessOrder,
			info.ProdLineDesc ProductionSystem,
			ps.Pattern_Code BatchId,
			p.Prod_Code GCAS,
			pp.Forecast_Quantity [BatchSize],
			hist.ReleaseDT,
			hist.ReadyForProdDT
		FROM dbo.Production_Plan pp
			JOIN dbo.Products_Base p ON p.Prod_Id = pp.Prod_Id
			JOIN dbo.Production_Setup ps ON pp.PP_Id = ps.PP_Id
			JOIN @PWPaths pep ON pep.PWPathId = pp.Path_Id
			LEFT JOIN hist ON hist.PP_Id = pp.PP_Id
				AND hist.Path_Id = pp.Path_Id
			CROSS APPLY dbo.fnLocal_MPWS_GetProductionLineInfoByPwPPId(pp.PP_Id) info
		WHERE (pp.Process_Order = @ProcessOrder OR @ProcessOrder IS NULL);
			
 
	END
	ELSE
	BEGIN
 
		SELECT
			'Unassigned' ProcessOrder,
			'N/A' ProductionSystem,
			'N/A' BatchId,
			'Multiple' GCAS,
			'0' [BatchSize],
			NULL ReleaseDT,
			NULL ReadyForProdDT
 
	END;
 
	SET @ErrorCode = 1;
	SET @ErrorMessage = 'Success';
	
END TRY
BEGIN CATCH
 
	SET @ErrorCode = ERROR_NUMBER()
	SET @ErrorMessage = ERROR_MESSAGE()
	
END CATCH;
 
 
