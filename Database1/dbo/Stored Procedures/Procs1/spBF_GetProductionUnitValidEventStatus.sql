CREATE PROCEDURE [dbo].[spBF_GetProductionUnitValidEventStatus] 
 	 @unit_id 	  	 INT = NULL,
 	 @pageNum 	  	 INT = 1,
 	 @pageSize 	  	 INT = 20
 	 
AS 
    SET NOCOUNT ON
 	 
 	 DECLARE @UnitStatus TABLE (
 	  	 RowNumber INT IDENTITY(1,1),
 	  	 UnitId INT,
 	  	 ValidStatus nVarChar(100),
 	  	 ProdStatusDesc nVarChar(100)
 	 )
 	 DECLARE @Count INT
BEGIN
 	  	 INSERT INTO @UnitStatus
 	  	 SELECT pes.pu_id, pes.Valid_Status, ps.ProdStatus_Desc 
 	  	 FROM dbo.PrdExec_Status pes WITH(NOLOCK)
 	  	 JOIN production_status ps WITH(NOLOCK) 
 	  	 ON pes.valid_status = ps.ProdStatus_Id
 	  	 WHERE pes.pu_id = @unit_id
 	  	 SELECT @Count = MAX(RowNumber) FROM @UnitStatus 
 	  	 IF(@Count > 0)
 	  	 BEGIN
 	  	  	 SELECT * FROM @UnitStatus 
 	  	  	 END
 	  	 ELSE
 	  	 BEGIN
 	  	  	 ---- Returning -999 when the entered Input ID is not present in DB
 	  	  	 SELECT -999
 	  	 END
END
