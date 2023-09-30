
CREATE PROCEDURE dbo.spPO_getUdps
    @root_id                                                            bigint                                                     = null,
    @table_id                                                          int                                                           = null

AS

Declare @DatabaseTimeZone nvarchar(200)
select @DatabaseTimeZone = value from site_parameters where parm_id=192

    Create Table #Udps (rootId Int, tableId int, fieldId Int, fieldDesc nvarchar(max), fieldType int, fieldTypeDesc nvarchar(max), fieldValue nvarchar(max))

INSERT INTO #Udps(rootId, tableId, fieldId, fieldDesc, fieldType, fieldTypeDesc, fieldValue)
select Table_Fields_Values.KeyId as rootId , Table_Fields_Values.TableId as tableId, Table_Fields.Table_Field_Id as fieldId,
       Table_Field_Desc as fieldDesc, ED_FieldTypes.ED_Field_Type_Id as fieldType, Field_Type_Desc as fieldTypeDesc, Table_Fields_Values.Value as fieldValue
from Table_Fields_Values
         JOIN Table_Fields on Table_Fields_Values.Table_Field_Id = Table_Fields.Table_Field_Id
         JOIN ED_FieldTypes on Table_Fields.ED_Field_Type_Id = ED_FieldTypes.ED_Field_Type_Id where Table_Fields_Values.KeyId = @root_id and Table_Fields_Values.TableId = @table_id

    -- converting db time to UTC time if field type is datetime
Update #Udps
Set fieldValue = FORMAT (cast(fieldValue as datetime) at time zone @DatabaseTimeZone at time zone 'UTC', 'yyyy-MM-ddTHH:mm:ss.fffZ') where fieldType = 12


select * from #Udps
