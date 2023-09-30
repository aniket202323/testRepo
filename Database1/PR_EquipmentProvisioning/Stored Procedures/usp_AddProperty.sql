
-- =============================================
-- Author:		Ryan Berry
-- Description:	Adds a property to an equipment instance
-- =============================================
CREATE PROCEDURE [PR_EquipmentProvisioning].[usp_AddProperty]
@EquipmentId UNIQUEIDENTIFIER, 
@PropertyName NVARCHAR(80),
@PropertyDataType int,
@PropertyValue NVARCHAR(255),
@PropertyUnitOfMeasure NVARCHAR(255),
@PropertyDescription NVARCHAR(255)
AS
BEGIN

	IF (SELECT COUNT(EquipmentId) FROM dbo.Equipment WHERE EquipmentId = @EquipmentId) = 0
	BEGIN
		RAISERROR('Invalid equipment instance.', 11, 1);
		RETURN 1
	END
	IF (@PropertyName IS NULL OR @PropertyName = '')
	BEGIN
		RAISERROR('Property name cannot be empty or null.', 11, 1);
		RETURN 1
	END
	-- check for leading spaces in property name
	IF (SELECT COUNT(*) WHERE @PropertyName LIKE '[a-Z]%') = 0
	BEGIN
		RAISERROR('Leading spaces are not permitted in the property name.', 11, 1);
		RETURN 1
	END
	IF (SELECT COUNT(Name) FROM dbo.Property_Equipment_EquipmentClass WHERE EquipmentId = @EquipmentId AND Name = @PropertyName) > 0
	BEGIN
		RAISERROR('A property with that name already exists on the equipment.', 11, 1);
		RETURN 1
	END
	IF (@PropertyDataType IS NULL OR @PropertyDataType < 0 OR @PropertyDataType > 13)
	BEGIN
		RAISERROR('Invalid property data type.', 11, 1);
		RETURN 1
	END


	BEGIN TRANSACTION
	BEGIN TRY

	DECLARE @c_GUIDEmpty uniqueidentifier
	SET @c_GUIDEmpty = '00000000-0000-0000-0000-000000000000'

	INSERT INTO [dbo].[Property_EquipmentClass] (
		EquipmentClassName,
		PropertyName,
		DataType,
		Value,
		UnitOfMeasure,
		Description,
		Constant,
		IsValueOverridden,
		IsDescriptionOverridden,
		IsUnitOfMeasureOverridden,
		TimeStamp,
		Version)
	VALUES (
		@EquipmentId,
		@PropertyName,
		@PropertyDataType,
		@PropertyValue,
		@PropertyUnitOfMeasure,
		@PropertyDescription,
		0,
		1,
		1,
		1,
		SYSUTCDATETIME(),
		1)

	INSERT INTO [dbo].[Property_Equipment_EquipmentClass] (
		EquipmentId,
		Id,
		Name,
		Class,
		Value,
		UnitOfMeasure,
		Description,
		Constant,
		IsValueOverridden,
		IsDescriptionOverridden,
		IsUnitOfMeasureOverridden,
		TimeStamp,
		Version)
	VALUES (
		@EquipmentId,
		NEWID(),
		@PropertyName,
		@EquipmentId,
		@PropertyValue,
		@PropertyUnitOfMeasure,
		@PropertyDescription,
		0,
		0,
		0,
		0,
		SYSUTCDATETIME(),
		1)

	 INSERT INTO [dbo].[StructuredTypeProperty] (
         Name,
         DefinedBy,
         DataType,
         LastBuiltName,
         LastBuiltDefinedBy,
         Version,
         TypeOwnerNamespace,
         TypeOwnerName)
	VALUES (
		@PropertyName,
		@c_GUIDEmpty,
		@PropertyDataType,
		@PropertyName,
		@c_GUIDEmpty,
		1,
		'Equipment',
		@EquipmentId
		)

	END TRY
	BEGIN CATCH
		ROLLBACK
		DECLARE @message nvarchar(1000) = ERROR_MESSAGE();
		RAISERROR(@message, 11, 1);
		RETURN 1
	END CATCH
		
	COMMIT
	RETURN 0
END