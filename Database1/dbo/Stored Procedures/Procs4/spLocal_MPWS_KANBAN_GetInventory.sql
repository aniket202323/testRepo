
CREATE PROCEDURE [dbo].[spLocal_MPWS_KANBAN_GetInventory]
	@Quantity DECIMAL OUTPUT,
	@GCAS VARCHAR(25) 

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
		 
SELECT @Quantity = SUM(CONVERT(DECIMAL,t1.Result)) 
	FROM Tests t1, Prod_Units_Base pu, Tables t, Table_Fields tf, Table_Fields_Values tfv, Events e, 
		Tests t2, Variables_Base v1, Variables_Base v2
	WHERE pu.PU_Id = e.PU_Id
	  AND e.Event_Status = 9
	  AND e.Event_Id = t1.Event_Id
	  AND e.Event_Id = t2.Event_Id
	  AND v1.Var_Id = t1.Var_Id
	  AND v2.Var_Id = t2.Var_Id
	  AND v1.Var_Desc = 'Quantity'
	  AND v2.Var_Desc = 'GCASNumber'
	  AND t2.Result = @GCAS
	  AND pu.PU_Id = tfv.KeyId
	  AND t.TableName = 'Prod_Units'
	  AND tf.Table_Field_Desc = 'Kanban'
	  AND tf.TableId = t.TableId
	  AND tfv.TableId = t.TableId
	  AND tfv.Table_Field_Id = tf.Table_Field_Id
	  AND tfv.Value = '1'

END
