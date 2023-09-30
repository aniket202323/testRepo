CREATE  PROCEDURE [dbo].spLocal_CmnWFGetUDPValues
	@KeyId			int,
	@TableName		varchar(50),
	@UDPString		varchar(50),
	@ReturnNull		bit = 0
 

AS
SET NOCOUNT ON

DECLARE	
@TableId		int,
@SPName			varchar(50),
@ErrMsg			varchar(25)


DECLARE @TableFields TABLE
(
TableFieldId				int,
TableFieldDesc				varchar(50),
FieldTypeDesc				varchar(100)
)


DECLARE @UDPValues TABLE (
UDPDesc						varchar(50),
UDPValues					varchar(7000),
TableFieldId				int,
DataType					varchar(100)
)

SET @SPName = 'spLocal_CmnWFGetUDPValues'


--1) Get the tableid 
SET @TableId  =(SELECT tableID from dbo.tables WITH(NOLOCK) WHERE tableName = @TableName )
IF @TableId IS NULL
BEGIN
	INSERT INTO dbo.Local_Debug(TimeStamp, CallingSP, Message)
	VALUES (getdate(),
			@SPName,
			'0005' +
			' Invalid Table = ' + @TableName
		)

		SELECT 0
		Return
END


--Get the list of table fields
INSERT @TableFields (TableFieldId,TableFieldDesc, FieldTypeDesc)
SELECT table_field_id, Table_Field_Desc, eft.Field_Type_Desc
FROM dbo.table_fields tf WITH(NOLOCK)
JOIN dbo.ED_FieldTypes eft WITH(NOLOCK) ON eft.ED_Field_Type_Id = tf.ED_Field_Type_Id
WHERE tableid = @TableId
	AND [Table_Field_Desc] LIKE '%'+@UDPString+'%'


IF (SELECT COUNT(*) FROM @TableFields)=0
BEGIN
	INSERT INTO dbo.Local_Debug(TimeStamp, CallingSP, Message)
	VALUES (getdate(),
		@SPName,
		'0005' +
		' No UDP matching string  = ' + @UDPString
	)

		SELECT 0
		Return
END




--Output

IF @ReturnNull = 1
BEGIN
	
	INSERT @UDPValues (UDPDesc, TableFieldId, DataType)
	SELECT TableFieldDesc, TableFieldId, FieldTypeDesc
		FROM @TableFields
		ORDER BY TableFieldDesc

	UPDATE u
		SET u.UDPValues = tfv.Value
		FROM @UDPValues u
		LEFT JOIN dbo.Table_Fields_Values tfv WITH(NOLOCK) ON u.TableFieldId = tfv.table_field_id
															AND tfv.TableId = @TableId
															AND tfv.KeyId = @KeyId	
	UPDATE @UDPValues
		SET UDPValues = 'NULL'
		WHERE UDPValues IS NULL;
										 
END
ELSE
BEGIN

	INSERT @UDPValues (UDPDesc, UDPValues, DataType)
	SELECT  tf.TableFieldDesc, tfv.value, TF.FieldTypeDesc
	FROM dbo.table_fields_values tfv WITH(NOLOCK)
	JOIN @TableFields TF	ON tfv.table_field_id = tf.TableFieldId
							AND tfv.TableId = @TableId
							AND tfv.KeyId = @KeyId

END



--First record set
SELECT COUNT(*) as 'COUNT' FROM @UDPValues


--SECOND record set
SELECT UDPDesc, UDPValues, DataType
FROM @UDPValues




SET NOCOUNT OFF
RETURN