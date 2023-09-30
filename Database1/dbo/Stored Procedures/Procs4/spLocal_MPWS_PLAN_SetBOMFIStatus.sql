 
 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_PLAN_SetBOMFIStatus
	
	Change BomfiStatus UDP to supplied status
	
	********
	WARNING: There is no logic to prevent an unwanted status change. You could set Dispensed back to Released or Hold/Cancelled to Dispensed.
	********
 
	Date			Version		Build	Author  
	25-May-2016		001			001		Jim Cameron (GEIP)		Initial development	
 
test
 
DECLARE @ErrorCode INT, @ErrorMessage VARCHAR(500)
EXEC dbo.spLocal_MPWS_PLAN_SetBOMFIStatus @ErrorCode OUTPUT, @ErrorMessage OUTPUT, 390883, 'Released'
SELECT @ErrorCode, @ErrorMessage
 
*/	-------------------------------------------------------------------------------
 
CREATE  PROCEDURE [dbo].[spLocal_MPWS_PLAN_SetBOMFIStatus]
	@ErrorCode		INT				OUTPUT,
	@ErrorMessage	VARCHAR(500)	OUTPUT,
	@PPId			INT,
	@NewStatusDesc	VARCHAR(50)
 
AS
 
SET NOCOUNT ON;
 
BEGIN TRY
 
	MERGE dbo.Table_Fields_Values WITH (HOLDLOCK) AS t
	USING (
			SELECT
				bomfi.BOM_Formulation_Item_Id KeyId,
				tf.Table_Field_Id,
				t.TableId,
				pps.PP_Status_Id Value
			FROM dbo.Production_Plan pp
				JOIN dbo.Bill_Of_Material_Formulation_Item bomfi ON bomfi.BOM_Formulation_Id = pp.BOM_Formulation_Id
				JOIN dbo.Prod_Units_Base pu ON pu.PU_Id = bomfi.PU_Id
				JOIN dbo.Prod_Lines_Base pl ON pl.PL_Id = pu.PL_Id
				JOIN dbo.Departments_Base d ON d.Dept_Id = pl.Dept_Id
				CROSS APPLY dbo.Production_Plan_Statuses pps
				CROSS APPLY dbo.Tables t
				CROSS APPLY dbo.Table_Fields tf
			WHERE pp.PP_Id = @PPId
				AND t.TableName = 'Bill_Of_Material_Formulation_Item'
				AND tf.Table_Field_Desc = 'BOMItemStatus'
				AND pps.PP_Status_Desc = @NewStatusDesc
				AND d.Dept_Desc = 'Pre-Weigh'
		) AS s
		ON t.KeyId = s.KeyId AND t.Table_Field_Id = s.Table_Field_Id AND t.TableId = s.TableId
	WHEN MATCHED 
		THEN UPDATE SET t.Value = s.Value
	WHEN NOT MATCHED BY TARGET 
		THEN INSERT (Keyid, Table_Field_Id, TableId, Value) VALUES (s.KeyId, s.Table_Field_Id, s.TableId, s.Value);
 
	SET @ErrorCode = 1;
	SET @ErrorMessage = 'Success';
 
END TRY
BEGIN CATCH
 
	SET @ErrorCode = ERROR_NUMBER()
	SET @ErrorMessage = ERROR_MESSAGE()
	
END CATCH;
