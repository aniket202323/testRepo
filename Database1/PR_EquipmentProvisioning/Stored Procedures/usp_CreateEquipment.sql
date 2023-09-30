--============================================
-- Author:		Ryan Berry
-- Description:	Creates a new equipment instance
-- =============================================
CREATE PROCEDURE [PR_EquipmentProvisioning].[usp_CreateEquipment]
@EquipmentName				NVARCHAR(50), 
@EquipmentDescription       NVARCHAR(255),
@EquipmentType              NVARCHAR(50),
@ParentEquipmentId          UNIQUEIDENTIFIER      
AS
BEGIN
	
	BEGIN TRANSACTION
	BEGIN TRY

		DECLARE @parentType nvarchar(50) = NULL
		IF @ParentEquipmentId IS NOT NULL
			SET @parentType = (SELECT Type FROM [dbo].[Equipment] WHERE EquipmentId  = @ParentEquipmentId)

		-- Validate equipment type against specified parent

		-- Any equipment type other than enterprise must have parent
		IF @EquipmentType != 'Enterprise'COLLATE Latin1_General_CS_AS AND @ParentEquipmentId IS NULL
			BEGIN
					RAISERROR('Invalid parent hierarchy.', 11, 1)
					RETURN 1
			END

		IF @EquipmentType = 'Enterprise'COLLATE Latin1_General_CS_AS
			BEGIN
				IF @ParentEquipmentId IS NOT NULL
				BEGIN
					RAISERROR('Invalid parent hierarchy.', 11, 1)
					RETURN 1
				END
			END
		ELSE IF @EquipmentType = 'Site' COLLATE Latin1_General_CS_AS
			BEGIN
				IF @parentType != 'Enterprise'
					BEGIN
						RAISERROR('Invalid parent hierarchy.', 11, 1)
						RETURN 1
					END
			END
		ELSE IF @EquipmentType = 'Area' COLLATE Latin1_General_CS_AS
			BEGIN
				IF @parentType != 'Site'
					BEGIN
						RAISERROR('Invalid parent hierarchy.', 11, 1)
						RETURN 1
					END
			END
		ELSE IF @EquipmentType = 'WorkCenter' COLLATE Latin1_General_CS_AS
			BEGIN
				IF @parentType != 'Area'
					BEGIN
						RAISERROR('Invalid parent hierarchy.', 11, 1)
						RETURN 1
					END
			END
		ELSE IF @EquipmentType = 'ProcessCell' COLLATE Latin1_General_CS_AS
			BEGIN
				IF @parentType != 'ProcessCell' AND @parentType != 'Area'
					BEGIN
						RAISERROR('Invalid parent hierarchy.', 11, 1)
						RETURN 1
					END
			END
		ELSE IF @EquipmentType = 'ProductionLine' COLLATE Latin1_General_CS_AS
			BEGIN
				IF @parentType != 'ProductionLine' AND @parentType != 'Area'
					BEGIN
						RAISERROR('Invalid parent hierarchy.', 11, 1)
						RETURN 1
					END
			END
		ELSE IF @EquipmentType = 'ProductionUnit' COLLATE Latin1_General_CS_AS
			BEGIN
				IF @parentType != 'ProductionUnit' AND @parentType != 'Area'
					BEGIN
						RAISERROR('Invalid parent hierarchy.', 11, 1)
						RETURN 1
					END
			END
		ELSE IF @EquipmentType = 'StorageZone' COLLATE Latin1_General_CS_AS
			BEGIN
				IF @parentType != 'StorageZone' AND @parentType != 'Area'
					BEGIN
						RAISERROR('Invalid parent hierarchy.', 11, 1)
						RETURN 1
					END
			END
		ELSE IF @EquipmentType = 'WorkUnit' COLLATE Latin1_General_CS_AS
			BEGIN
				IF @parentType != 'WorkUnit' AND @parentType != 'WorkCenter' AND @parentType != 'ProcessCell' AND @parentType != 'ProductionUnit' AND @parentType != 'ProductionLine' AND @parentType != 'StorageZone'
					BEGIN
						RAISERROR('Invalid parent hierarchy.', 11, 1)
						RETURN 1
					END
			END
		ELSE IF @EquipmentType = 'Unit' COLLATE Latin1_General_CS_AS
			BEGIN
				IF @parentType != 'Unit' AND @parentType != 'ProductionUnit' AND @parentType != 'ProcessCell'
					BEGIN
						RAISERROR('Invalid parent hierarchy.', 11, 1)
						RETURN 1
					END
			END
		ELSE IF @EquipmentType = 'WorkCell' COLLATE Latin1_General_CS_AS
			BEGIN
				IF @parentType != 'WorkCell' AND @parentType != 'ProductionLine'
					BEGIN
						RAISERROR('Invalid parent hierarchy.', 11, 1)
						RETURN 1
					END
			END
		ELSE IF @EquipmentType = 'StorageUnit' COLLATE Latin1_General_CS_AS
			BEGIN
				IF @parentType != 'StorageUnit' AND @parentType != 'StorageZone'
					BEGIN
						RAISERROR('Invalid parent hierarchy.', 11, 1)
						RETURN 1
					END
			END
		ELSE IF @EquipmentType = 'EquipmentModule' COLLATE Latin1_General_CS_AS
			BEGIN
				IF @parentType != 'EquipmentModule' AND @parentType != 'Unit' AND @parentType != 'StorageUnit' AND @parentType != 'WorkCell'
					BEGIN
						RAISERROR('Invalid parent hierarchy.', 11, 1)
						RETURN 1
					END
			END
		ELSE IF @EquipmentType = 'ControlModule' COLLATE Latin1_General_CS_AS
			BEGIN
				IF @parentType != 'ControlModule' AND @parentType != 'EquipmentModule'
					BEGIN
						RAISERROR('Invalid parent hierarchy.', 11, 1)
						RETURN 1
					END
			END
		ELSE
			BEGIN
				RAISERROR('Invalid equipment type.', 11, 1)
				RETURN 1
			END


		-- perform the creation
		DECLARE @equipmentId UNIQUEIDENTIFIER = NEWID();
		DECLARE @className nvarchar(36) = LOWER(CONVERT(nvarchar(36), @equipmentId)); --internal class id which is the lower case version of the GUID

		INSERT INTO [dbo].[Equipment] (EquipmentId, S95Id, Description, ParentEquipmentId, Type, Version)
		VALUES (@equipmentId, @EquipmentName, @EquipmentDescription, @ParentEquipmentId, @EquipmentType, 1);
	
		INSERT INTO [dbo].[EquipmentClass] (EquipmentClassName, Id, Description, Private, Version)
		VALUES (@equipmentId, @className, @EquipmentName, 1, 1);

		INSERT INTO [dbo].[EquipmentClass_EquipmentObject] (EquipmentClassName, EquipmentId, ClassOrder, Version)
		VALUES (@className, @equipmentId, 0, 1);

		INSERT INTO [dbo].[StructuredType] (Name, Id, Description, Namespace, IsPrivate, RecordPropertyHistory, Version)
		VALUES (@className, @equipmentId, @EquipmentName, 'Equipment', 1, 0, 1);
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