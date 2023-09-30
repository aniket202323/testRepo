 
 
/*	-------------------------------------------------------------------------------
	dbo.fnLocal_MPWS_GetUDP
	
	Gets a UDP value
	
	Date			Version		Build	Author  
	03-Jun-2016		001			001		Jim Cameron (GEIP)		Initial development	
	12-Sep-2017		001			002		Susan Lee (GE Digital)	added join to table field's tableid
 
test
 
SELECT Value FROM dbo.fnLocal_MPWS_GetUDP(5488140, 'BOMItemStatus', 'Bill_Of_Material_Formulation_Item')
 
*/	-------------------------------------------------------------------------------
 
CREATE  FUNCTION [dbo].[fnLocal_MPWS_GetUDP] (@KeyId INT, @FieldDesc VARCHAR(50), @TableName VARCHAR(255))
 
RETURNS TABLE
 
AS
 
RETURN (SELECT tfv.Value
		FROM dbo.Table_Fields_Values tfv	WITH (NOLOCK)
			JOIN dbo.Table_Fields tf 		WITH (NOLOCK) ON tfv.Table_Field_Id = tf.Table_Field_Id
			JOIN dbo.[Tables] t 			WITH (NOLOCK) ON tfv.TableId = t.TableId AND tf.TableId = t.TableId
		WHERE tfv.KeyId = @KeyId
			AND tf.Table_Field_Desc = @FieldDesc
			AND t.TableName = @TableName)
	
 
 
 
