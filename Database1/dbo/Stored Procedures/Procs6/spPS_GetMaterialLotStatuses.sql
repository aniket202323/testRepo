CREATE PROCEDURE [dbo].[spPS_GetMaterialLotStatuses]
@ProdStatusId				    int = null,
@paramType                      nvarchar(200)

   AS
  if(@paramType='SEARCH')
    Begin
		SELECT ProdStatus_Id,Count_For_Inventory,Count_For_Production,Status_Valid_For_Input,ProdStatus_Desc FROM Production_Status
	END
  else if(@paramType='SEARCH_BY_MATERIALLOTSTATUSID')
 Begin
	SELECT ProdStatus_Id,Count_For_Inventory,Count_For_Production,Status_Valid_For_Input,ProdStatus_Desc
	 FROM Production_Status where ProdStatus_Id = @ProdStatusId
END

