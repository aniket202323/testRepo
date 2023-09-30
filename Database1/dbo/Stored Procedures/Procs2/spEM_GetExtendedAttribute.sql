CREATE PROCEDURE dbo.spEM_GetExtendedAttribute
            @Table nvarchar(255),
            @Key int,
            @Field int,
            @FieldName nvarchar(50)
AS
DECLARE @TableId Int
SELECT @TableId = TableId From Tables WHERE TableName=@Table
IF @Field is null
 	 IF exists(select * from Table_Fields where Table_Field_Desc=@FieldName And TableId = @TableId)
        select @Field=Table_Field_Id from Table_Fields where Table_Field_Desc=@FieldName And TableId = @TableId
SELECT top 1 tv.Value 
FROM Table_Fields_Values tv 
where  tv.KeyId=@Key and tv.Table_Field_Id=@Field  And TableId = @TableId
SET QUOTED_IDENTIFIER  OFF    SET ANSI_NULLS  ON 
