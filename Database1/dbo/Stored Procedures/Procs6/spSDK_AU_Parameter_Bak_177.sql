CREATE procedure [dbo].[spSDK_AU_Parameter_Bak_177]
@AppUserId int,
@Id int OUTPUT,
@AddDelete tinyint ,
@CustomizeByDept tinyint ,
@CustomizeByHost tinyint ,
@Description nvarchar(255) ,
@FieldType varchar(100) ,
@FieldTypeId int ,
@IsEncrypted bit ,
@IsEsignature tinyint ,
@Parameter nvarchar(50) ,
@ParameterCategory nvarchar(50) ,
@ParameterCategoryId int ,
@ParameterType varchar(200) ,
@ParameterTypeId tinyint ,
@ParmMax int ,
@ParmMin int ,
@System bit 
AS
Declare
  @Status int,
  @ErrorMsg varchar(500)
  Select @ErrorMsg = 'Object does not support Add/Update.' 
  Select @Status = 0
  -- Call to Import/Export SP goes here
  If (@Status <> 1)
    Select @ErrorMsg
  Return(@Status)
