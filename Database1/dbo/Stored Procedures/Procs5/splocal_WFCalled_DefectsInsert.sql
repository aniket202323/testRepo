CREATE PROCEDURE [dbo].[splocal_WFCalled_DefectsInsert]
@WorkflowDefinitionId VARCHAR (1000) NULL, @TaskInstanceId VARCHAR (100) NULL, @TaskInstanceName VARCHAR (100) NULL, @TaskStepInstanceId VARCHAR (100) NULL, @TaskStepInstanceName VARCHAR (100) NULL, @Created VARCHAR (50) NULL, @DefectType VARCHAR (50) NULL, @DefectName VARCHAR (255) NULL, @ShortDescription VARCHAR (500) NULL, @DetailedDescription VARCHAR (3000) NULL, @Status VARCHAR (25) NULL, @EquipmentId VARCHAR (1000) NULL, @EquipmentName VARCHAR (255) NULL, @Category VARCHAR (100) NULL, @FoundById VARCHAR (1000) NULL, @FoundByName VARCHAR (60) NULL, @FixedById VARCHAR (1000) NULL, @FixedByName VARCHAR (60) NULL, @CorrectedById VARCHAR (1000) NULL, @CorrectedByName VARCHAR (60) NULL, @CorrectedDate VARCHAR (50) NULL, @CorrectedComments VARCHAR (3000) NULL, @TargetCorrectionDate VARCHAR (50) NULL, @ExternalHelpNeeded BIT NULL, @ExternalSystemReferenceNumber INT NULL, @FLNumber VARCHAR (20) NULL
WITH ENCRYPTION
AS
BEGIN
--The script body was encrypted and cannot be reproduced here.
    RETURN
END


