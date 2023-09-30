 
 
 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_DASH_POPipeline
	
	Get number of PO's by status
 
	Date			Version		Build	Author  
	25-May-2016		001			001		Jim Cameron (GEIP)		Initial development	
 
test
 
DECLARE @ErrorCode INT, @ErrorMessage VARCHAR(500)
EXEC dbo.spLocal_MPWS_DASH_POPipeline @ErrorCode OUTPUT, @ErrorMessage OUTPUT, 83
SELECT @ErrorCode, @ErrorMessage
 
*/	-------------------------------------------------------------------------------
 
CREATE   PROCEDURE [dbo].[spLocal_MPWS_DASH_POPipeline]
	@ErrorCode		INT				OUTPUT,
	@ErrorMessage	VARCHAR(500)	OUTPUT,
	@ExecutionPath	INT
 
AS
 
SET NOCOUNT ON;
 
BEGIN TRY
 
	SELECT
		ROW_NUMBER() OVER (ORDER BY pOrder.Value) OrderNum,
		pps.PP_Status_Desc [Status],
		COUNT(*) NumOfPOs
	FROM dbo.Production_Plan pp
		JOIN dbo.Production_Plan_Statuses pps ON pp.PP_Status_Id = pps.PP_Status_Id
		CROSS APPLY dbo.fnLocal_MPWS_GetUDP(pp.PP_Status_Id, 'PreWeigh Order', 'Production_Plan_Statuses') pOrder
	WHERE pp.Path_Id = @ExecutionPath
		AND pps.PP_Status_Desc <> 'Complete'
	GROUP BY pOrder.Value, pps.PP_Status_Desc
	ORDER BY OrderNum;
 
	SET @ErrorCode = 1;
	SET @ErrorMessage = 'Success';
 
END TRY
BEGIN CATCH
 
	SET @ErrorCode = ERROR_NUMBER()
	SET @ErrorMessage = ERROR_MESSAGE()
	
END CATCH;
 
 
