 
 
CREATE  PROCEDURE [dbo].[spLocal_MPWS_GENL_GetUDPValue]
	@KeyId		INT,
	@FieldDesc	VARCHAR(50),
	@TableName	VARCHAR(255)
 
AS	
-------------------------------------------------------------------------------
-- Gets a UDP value
 
/*
 5488140, 'BOMItemStatus', 'Bill_Of_Material_Formulation_Item'
*/
-- Date         Version Build Author  
-- 24-Sep-2015  001     001   Alex Judkowicz (GEIP)  Initial development	
-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------
DECLARE
  		@ErrorCode		INT,
		@ErrorMessage	VARCHAR(255),
		@UDPValue		VARCHAR(255)
 
SELECT	@ErrorCode		= 1,
		@ErrorMessage	= 'Success'
-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------
SELECT @UDPValue = tfv.Value
		FROM dbo.Table_Fields_Values tfv
			JOIN dbo.Table_Fields tf ON tfv.Table_Field_Id = tf.Table_Field_Id
			JOIN dbo.[Tables] t ON tfv.TableId = t.TableId
		WHERE tfv.KeyId = @KeyId
			AND tf.Table_Field_Desc = @FieldDesc
			AND t.TableName = @TableName
					
IF		@UDPValue	IS NULL
BEGIN
		SELECT	@ErrorCode = -1,
				@ErrorMessage = 'Property Not Found'
END
 
SELECT @UDPValue as value, @ErrorCode as ErrorCode, @ErrorMessage as ErrorMessage
 
 
 
 
 
 
 
 
 
 
