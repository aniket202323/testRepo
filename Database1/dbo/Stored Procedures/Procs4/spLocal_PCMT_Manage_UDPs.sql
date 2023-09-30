





CREATE PROCEDURE [dbo].[spLocal_PCMT_Manage_UDPs]
/*-----------------------------------------------------------------------------------------------
Stored Procedure:		dbo.spLocal_PCMT_Manage_UDPs
Author:   				Patrick-Daniel Dubois (System Technologies for Industry Inc.)
Date Created:  		25-Apr-2008
SP Type:					PCMT
Editor Tab Spacing:	3

Description:
=========
	This stored procedure gets the UDP of the given table and key id
	It also Add, Update and delete UDPs

Called By:	- PCMT UDP management form

Revision Date			Who								What
========	===========	==========================	========================
1.0.0		25-Apr-2008	Patrick-Daniel Dubois(STI) Creation
*/

/*************************************************************/
	(
	@intOperationType INT,
	@KeyId				INT,
	@TableName			VARCHAR(50),
	@Value				VARCHAR(7000)=NULL,
	@TableFieldId		INT=NULL
	)
AS

SET NOCOUNT ON
/*
@intOperationType gives the kind of operation to be done on UDPs
	Case = 0 => Only Loads UDPs for the given @TableName and @KeyId
	Case = 1 => Insert a new UDP for the given @TableName, @KeyId, @Value and @TableFieldId
	Case = 2 => Update the value of the given UDP for the given @TableName, @KeyId and @TableFieldId
	Case = 3 => Delete the given UDP for the given @TableName, @KeyId and @TableFieldId
*/

DECLARE @TableId INT

SET @TableId= (SELECT TableId FROM Tables WHERE TableName=@TableName)

IF @intOperationType=1 
	BEGIN
		IF @TableId IS NOT NULL AND @TableFieldId IS NOT NULL AND @Value IS NOT NULL 
		BEGIN
			IF NOT EXISTS (SELECT * FROM dbo.Table_Fields_Values WHERE KeyId = @KeyId AND TableId = @TableId AND Table_Field_Id = @TableFieldId) 
			BEGIN
				INSERT INTO Table_Fields_Values(KeyId, TableId, Table_Field_Id, Value) 
					VALUES(@KeyId,@TableId,@TableFieldId,@Value) 
			END
			ELSE BEGIN
				UPDATE Table_Fields_Values 
					SET Value=@Value 
					WHERE KeyId=@KeyId AND TableId=@TableId AND Table_Field_Id=@TableFieldId	
			END
		END 
	END
ELSE	
	IF @intOperationType=2 
	BEGIN
		IF @TableId IS NOT NULL AND @TableFieldId IS NOT NULL AND @Value IS NOT NULL 
			BEGIN
				UPDATE Table_Fields_Values 
					SET Value=@Value 
					WHERE KeyId=@KeyId AND TableId=@TableId AND Table_Field_Id=@TableFieldId	
			END 
	END
	ELSE 
		IF @intOperationType=3 
		BEGIN
			IF @TableId IS NOT NULL AND @TableFieldId IS NOT NULL 
			BEGIN
				DELETE FROM Table_Fields_Values 
					WHERE KeyId=@KeyId AND TableId=@TableId AND Table_Field_Id=@TableFieldId
			END
		END

SELECT T.TableId, T.TableName, TFV.[Value],TF.Table_Field_Desc,EDFD.Field_Type_Desc,TFV.KeyId, TF.Table_Field_Id 
	FROM Tables T  
	JOIN Table_Fields_Values TFV ON TFV.TableId = T.TableId 
	JOIN Table_Fields TF ON TFV.Table_Field_Id = TF.Table_Field_Id  
	JOIN ED_FieldTypes EDFD ON EDFD.ED_Field_Type_Id = TF.ED_Field_Type_Id 
WHERE T.TableId=@TableId 
	AND TFV.KeyId= @KeyId
ORDER BY 
	TF.Table_Field_Desc

SET NOCOUNT OFF





