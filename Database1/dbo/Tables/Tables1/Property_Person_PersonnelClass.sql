CREATE TABLE [dbo].[Property_Person_PersonnelClass] (
    [Name]                      NVARCHAR (255)   NOT NULL,
    [Class]                     NVARCHAR (255)   NULL,
    [Constant]                  BIT              NULL,
    [Id]                        NVARCHAR (255)   NULL,
    [IsTemplate]                BIT              NULL,
    [Description]               NVARCHAR (255)   NULL,
    [UnitOfMeasure]             NVARCHAR (255)   NULL,
    [IsUnitOfMeasureOverridden] BIT              NULL,
    [IsDescriptionOverridden]   BIT              NULL,
    [IsValueOverridden]         BIT              NULL,
    [TimeStamp]                 DATETIME         NULL,
    [Value]                     SQL_VARIANT      NULL,
    [Version]                   BIGINT           NULL,
    [PersonId]                  UNIQUEIDENTIFIER NOT NULL,
    [ItemId]                    UNIQUEIDENTIFIER NULL,
    [CustomDataTypeValueId]     UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([PersonId] ASC, [Name] ASC),
    CONSTRAINT [FK_Property_Person_PersonnelClass_QFDataType] FOREIGN KEY ([CustomDataTypeValueId]) REFERENCES [dbo].[QFDataTypePhrases] ([DataTypePhraseId]),
    CONSTRAINT [Property_Person_PersonnelClass_BinaryItem_Relation1] FOREIGN KEY ([ItemId]) REFERENCES [dbo].[BinaryItem] ([ItemId]),
    CONSTRAINT [Property_Person_PersonnelClass_Person_Relation1] FOREIGN KEY ([PersonId]) REFERENCES [PR_Authorization].[Person] ([PersonId])
);


GO
ALTER TABLE [dbo].[Property_Person_PersonnelClass] ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);


GO
CREATE NONCLUSTERED INDEX [IX_Property_Person_PersonnelClass_Name]
    ON [dbo].[Property_Person_PersonnelClass]([Name] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_Property_Person_PersonnelClass_Class]
    ON [dbo].[Property_Person_PersonnelClass]([Class] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_Property_Person_PersonnelClass_ItemId]
    ON [dbo].[Property_Person_PersonnelClass]([ItemId] ASC);


GO
CREATE TRIGGER [trg_Property_Person_PersonnelClass]
ON [dbo].[Property_Person_PersonnelClass]
FOR INSERT, UPDATE
AS
BEGIN
	-- check that rows were actually inserted/updated
	IF (@@ROWCOUNT = 0)
		RETURN
	SET NOCOUNT ON
	IF NOT EXISTS (SELECT * FROM inserted)
		RETURN

	DECLARE @CustomDataType INT = 18;

	UPDATE pppc
	SET CustomDataTypeValueId = 
		CASE (ppc.DataType)
			WHEN (@CustomDataType) THEN CONVERT(UNIQUEIDENTIFIER,i.Value)
			ELSE NULL
		END 
	FROM dbo.Property_Person_PersonnelClass pppc
	INNER JOIN inserted i
		ON i.PersonId = pppc.PersonId 
		AND i.Name = pppc.Name
	INNER JOIN dbo.Property_PersonnelClass ppc 
		ON ppc.PersonnelClassName = i.Class
		AND ppc.PropertyName = i.Name
END