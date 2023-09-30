CREATE PROCEDURE dbo.spEM_SaveExtendedAttributes
 	 @Table nvarchar(255),
 	 @Key int,
 	 @Field int,
 	 @FieldName nvarchar(50),
 	 @Value varchar(8000)
AS
DECLARE @TableId Int
SELECT @TableId = TableId from Tables where TableName = @Table
if @Field is null and @FieldName is null 
begin
 	 Declare @ids table (fieldkey int)
 	 if @Value is not null
 	 begin
 	  	 WHILE CHARINDEX(' ',@Value)>0
 	  	 BEGIN
 	  	  	 WHILE CHARINDEX(' ',@Value)=1 SET @Value=SUBSTRING(@Value,2,8000)
 	  	  	 IF LEN(@Value)>0 AND CHARINDEX(' ',@Value)>0
 	  	  	 BEGIN
 	  	  	  	 INSERT INTO @ids VALUES (CAST(LEFT(@Value,CHARINDEX(' ',@Value)-1) as int))
 	  	  	  	 SET @Value=SUBSTRING(@Value,CHARINDEX(' ',@Value)+1,8000)
 	  	  	 END
 	  	 END
 	  	 IF LEN(@Value)>0 INSERT INTO @ids VALUES (CAST(@Value as int))
 	 end
 	 delete from 
 	  	 tv 
 	 from 
 	  	 Table_Fields_Values tv 
 	  	 join Tables t on tv.TableId=t.TableId
 	  	 left join @ids ids on tv.Table_FIeld_Id=ids.fieldkey 
 	 where 
 	  	 ids.fieldkey is null 
 	  	 and t.TableName=@Table
 	  	 and tv.KeyId=@Key
end
else
begin
 	 if @Field is null
 	  	 if exists(select * from Table_Fields where Table_Field_Desc=@FieldName And TableId = @TableId)
 	  	  	 select @Field=Table_Field_Id from Table_Fields where Table_Field_Desc=@FieldName And TableId = @TableId
 	  	 else
 	  	 begin
 	  	  	 insert into Table_Fields (ED_Field_Type_Id,Table_Field_Desc,TableId) Values( 1,@FieldName,@TableId)
 	  	  	 set @Field=scope_identity()
 	  	 end
 	 if exists(select top 1 tv.KeyId from Table_Fields_Values tv where tv.TableId = @TableId and tv.KeyId=@Key and tv.Table_Field_Id=@Field)
 	  	 update tv set Value=@Value from Table_Fields_Values tv   where tv.TableId = @TableId and tv.KeyId=@Key and tv.Table_Field_Id=@Field
 	 else
 	  	 insert Table_Fields_Values (KeyId,TableId,Table_Field_Id,Value) Values (@Key,@TableId,@Field,@Value)
end
SET QUOTED_IDENTIFIER  OFF    SET ANSI_NULLS  ON 
