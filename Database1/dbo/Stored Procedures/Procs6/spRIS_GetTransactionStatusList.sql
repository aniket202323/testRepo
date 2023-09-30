
-- =============================================
-- Version:		<v1.0>
-- Create date: <18/Mar/2020>
-- Description:	<Store Proc for Retrieving Transaction statuses based on PU_Id and StatusId>
-- =============================================
CREATE PROCEDURE [dbo].[spRIS_GetTransactionStatusList] 
	@PU_Id nVARCHAR(15),
	@Status_Id nVARCHAR(MAX) = NULL
AS
BEGIN
	DECLARE @Final_Statuses TABLE (PU_Id INT, From_Status_Id INT, To_Status_Id INT)

	IF @Status_Id IS NOT NULL
	
		INSERT INTO @Final_Statuses (PU_Id, From_Status_Id, To_Status_Id)
			SELECT trans.PU_Id, ps.ProdStatus_Id, trans.To_ProdStatus_Id
			FROM prdExec_Trans trans JOIN Production_Status ps
			ON ps.ProdStatus_Id = trans.From_ProdStatus_Id
			WHERE trans.PU_Id = @PU_Id and ps.ProdStatus_Id IN (SELECT VALUE FROM STRING_SPLIT(@Status_Id, ',') WHERE RTRIM(VALUE) <> '');

	ELSE

		INSERT INTO @Final_Statuses (PU_Id, From_Status_Id, To_Status_Id)
			SELECT trans.PU_Id, trans.From_ProdStatus_Id, To_ProdStatus_Id
			FROM prdExec_Trans trans WHERE trans.PU_Id = @PU_Id;
	
	SELECT fs.From_Status_Id From_Status_Id, To_Status_Id To_Status_Id, ps.ProdStatus_Desc to_Status_Desc, temp.from_status_desc
	FROM @Final_Statuses fs JOIN Production_Status ps ON ps.ProdStatus_Id = fs.To_Status_Id
	CROSS APPLY (SELECT prodstatus_desc from_status_desc from Production_Status 
	where prodstatus_id = fs.from_status_id) as temp

END
