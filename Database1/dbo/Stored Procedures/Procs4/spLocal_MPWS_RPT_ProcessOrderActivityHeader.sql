 
 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_RPT_ProcessOrderActivityHeader
		
	This sp returns header info for spLocal_MPWS_RPT_ProcessOrderActivityBody
	
	Date			Version		Build	Author  
	09-Aug-2016		001			001		Jim Cameron (GEIP)		Initial development	
 
test
 
DECLARE @ErrorCode INT, @ErrorMessage VARCHAR(500)
EXEC dbo.spLocal_MPWS_RPT_ProcessOrderActivityHeader @ErrorCode OUTPUT, @ErrorMessage OUTPUT, '20151120105909'
 
SELECT @ErrorCode, @ErrorMessage
 
 
*/	-------------------------------------------------------------------------------
 
CREATE  PROCEDURE [dbo].[spLocal_MPWS_RPT_ProcessOrderActivityHeader]
	@ErrorCode		INT				OUTPUT,
	@ErrorMessage	VARCHAR(500)	OUTPUT,
	@ProcessOrder	VARCHAR(50)
 
AS
 
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
 
BEGIN TRY
 
	SELECT
		pp.Process_Order ProcessOrder,
		p.Prod_Code MaterialCode,
		p.Prod_Desc MaterialDescription,
		info.ProdLineBatchNum BatchId,
		info.ProdLineDesc MakingLine
	FROM dbo.Production_Plan pp
		JOIN dbo.Products_Base p ON p.Prod_Id = pp.Prod_Id
			JOIN dbo.Prdexec_Paths pep ON pep.Path_Id = pp.Path_Id
			JOIN dbo.Prod_Lines_Base pl ON pep.PL_Id = pl.PL_Id
			JOIN dbo.Departments_Base d ON pl.Dept_Id = d.Dept_Id
		CROSS APPLY dbo.fnLocal_MPWS_GetProductionLineInfoByPwPPId(pp.PP_Id) info
	WHERE pp.Process_Order = @ProcessOrder
			AND d.Dept_Desc = 'Pre-Weigh';
			
	SET @ErrorCode = 1;
	SET @ErrorMessage = 'Success';
	
END TRY
BEGIN CATCH
 
	SET @ErrorCode = ERROR_NUMBER()
	SET @ErrorMessage = ERROR_MESSAGE()
	
END CATCH;
 
 
