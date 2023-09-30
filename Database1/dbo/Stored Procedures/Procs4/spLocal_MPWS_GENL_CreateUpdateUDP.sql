 
 
CREATE  PROCEDURE [dbo].[spLocal_MPWS_GENL_CreateUpdateUDP]
	@ErrorCode		INT				OUTPUT,
	@ErrorMessage	VARCHAR(255)	OUTPUT,
	@KeyId			INT,
	@FieldDesc		VARCHAR(50),
	@TableName		VARCHAR(255),
	@Value			VARCHAR(7000)
 
AS	
 
/*
 
-------------------------------------------------------------------------------
	
	Create or Update a UDP value
 
 
-- Date         Version Build Author  
-- 21-Jun-2016  001     001   Jim Cameron (GEIP)  Initial development	
 
declare @ErrorCode INT, @ErrorMessage VARCHAR(500)
exec dbo.spLocal_MPWS_GENL_CreateUpdateUDP @ErrorCode OUTPUT, @ErrorMessage OUTPUT, 5488140, 'BOMItemStatus', 'Bill_Of_Material_Formulation_Item', 14
 
select @ErrorCode, @ErrorMessage
 
 
*/
 
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
 
DECLARE
	@TableId		INT,
	@TableFieldId	INT,
	@TempValue		VARCHAR(7000);
 
SET @ErrorCode = 1;
 
SET @TableId = (SELECT TableId FROM dbo.Tables WHERE TableName = @TableName)
IF @TableId IS NULL
BEGIN
	SET @ErrorCode = -1;
	SET @ErrorMessage = 'Table name not found';
END
 
SET @TableFieldId = (SELECT Table_Field_Id FROM dbo.Table_Fields tf WHERE tf.Table_Field_Desc = @FieldDesc AND tf.TableId = @TableId)
IF @TableFieldId IS NULL
BEGIN
	SET @ErrorCode = -2;
	SET @ErrorMessage = 'Field description not found for table ' + @TableName;
END
 
-- check for bom item status of something like 'pending' instead of 1
IF @FieldDesc = 'BOMItemStatus' AND @TableName = 'Bill_Of_Material_Formulation_Item' AND ISNUMERIC(@Value) = 0
BEGIN
 
	-- try to look up id
	SELECT @TempValue = (SELECT PP_Status_Id FROM dbo.Production_Plan_Statuses WHERE PP_Status_Desc = @Value);
	
	-- if found and numeric then use that
	IF ISNUMERIC(@TempValue) = 1
	BEGIN
		SET @Value = @TempValue;
	END
	ELSE
	BEGIN
		-- not found, flag error
		SET @ErrorCode = -3;
		SET @ErrorMessage = 'Value: ' + @Value + ' supplied for Field: ' + @FieldDesc + ', Table: ' + @TableName + ' is invalid';
	END;
	
END;
	
IF @ErrorCode > 0
BEGIN
 
	MERGE dbo.Table_Fields_Values WITH (HOLDLOCK) AS t
	USING (
			SELECT
				@KeyId AS KeyId,
				@TableFieldId Table_Field_Id,
				@TableId TableId,
				@Value Value
		) AS s
		ON t.KeyId = s.KeyId AND t.Table_Field_Id = s.Table_Field_Id AND t.TableId = s.TableId
	WHEN MATCHED 
		THEN UPDATE SET t.Value = s.Value
	WHEN NOT MATCHED BY TARGET 
		THEN INSERT (Keyid, Table_Field_Id, TableId, Value) VALUES (s.KeyId, s.Table_Field_Id, s.TableId, s.Value);
 
	IF @@ROWCOUNT > 0
	BEGIN
		SET @ErrorCode		= 1;
		SET @ErrorMessage	= 'Success';
	END
	ELSE
	BEGIN
		SET @ErrorCode = -3;
		SET @ErrorMessage = 'Error creating/updating UDP';
	END
 
END
 
 
 
 
 
 
 
 
 
