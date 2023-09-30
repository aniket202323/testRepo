 
 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_RPT_ContainerActivityHeader
	
	If query contains any results it should return Success and the table should return the raw material container information
	
	
	Date			Version		Build	Author  
	11-Aug-2016		001			001		Susan Lee (GEIP)		Initial development	
 
test
 
DECLARE @ErrorCode INT, @ErrorMessage VARCHAR(500)
EXEC dbo.spLocal_MPWS_RPT_ContainerActivityHeader @ErrorCode OUTPUT, @ErrorMessage OUTPUT, 'RMCIT-301'
 
SELECT @ErrorCode, @ErrorMessage
 
ContainerId
RMCIT-271
RMCIT-281
RMCIT-282
RMCIT-283
RMCIT-284
 
 
 
*/	-------------------------------------------------------------------------------
 
CREATE  PROCEDURE [dbo].[spLocal_MPWS_RPT_ContainerActivityHeader]
	@ErrorCode		INT				OUTPUT,
	@ErrorMessage	VARCHAR(500)	OUTPUT,
	@RMCNum			VARCHAR(50)
 
AS
 
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
 
DECLARE @tOutput TABLE
(
	Material		VARCHAR(50),
	MaterialDesc	VARCHAR(50),
	SAPLotId		VARCHAR(50)
);
 
BEGIN TRY
 
	-- raw material container for row 1
	INSERT @tOutput
		SELECT
			ISNULL(p.Prod_Code,'UNK')	,
			ISNULL(p.Prod_Desc,'UNK')	,
			ISNULL(t.Result,'UNK')
		FROM dbo.Events		e
		JOIN dbo.Products	p	ON p.Prod_Id = e.Applied_Product
		JOIN dbo.Tests		t	ON t.Event_Id = e.Event_Id
		JOIN dbo.Variables	v	ON v.Var_Id = t.Var_Id AND  v.Test_Name = 'MPWS_INVN_SAP_LOT'
		WHERE e.Event_Num = @RMCNum
		
 
		
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
 
 
SELECT
	 @RMCNum as RMCNumber,
	 Material,
	 MaterialDesc,
	 SAPLotId
FROM @tOutput
 
 
