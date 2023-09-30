-------------------------------------------------------------------------------------------------

-------------------------------------[Creation Of Function]--------------------------------------
CREATE FUNCTION [dbo].[fnLocal_GetUDP] (@KeyId int, @FieldDesc varchar(50), @TableName varchar(255))
/*
-------------------------------------------------------------------------------------------------
Created by	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2006-03-02
Version		:	1.0.0
Purpose		:	
-------------------------------------------------------------------------------------------------
*/

RETURNS varchar(7000)

AS
BEGIN
	DECLARE 
	@TableId			int,
	@TableFieldId	int,
	@Value			varchar(7000)
	
	SET @TableId = (SELECT TableId FROM dbo.Tables WHERE TableName = @TableName)
	SET @TableFieldId = (SELECT Table_Field_Id FROM dbo.Table_Fields WHERE Table_Field_Desc = @FieldDesc)
	
	SET @Value =	(
						SELECT	Value
						FROM		dbo.Table_Fields_Values
						WHERE		KeyId = @KeyId
						AND		TableId = @TableId
						AND		Table_Field_Id = @TableFieldId
						)
	
	RETURN @Value
END

