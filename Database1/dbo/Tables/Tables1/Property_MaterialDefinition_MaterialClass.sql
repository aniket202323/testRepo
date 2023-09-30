CREATE TABLE [dbo].[Property_MaterialDefinition_MaterialClass] (
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
    [MaterialDefinitionId]      UNIQUEIDENTIFIER NOT NULL,
    [ItemId]                    UNIQUEIDENTIFIER NULL,
    [CustomDataTypeValueId]     UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([MaterialDefinitionId] ASC, [Name] ASC),
    CONSTRAINT [FK_Property_MaterialDefinition_QFDataType] FOREIGN KEY ([CustomDataTypeValueId]) REFERENCES [dbo].[QFDataTypePhrases] ([DataTypePhraseId]),
    CONSTRAINT [Property_MaterialDefinition_MaterialClass_BinaryItem_Relation1] FOREIGN KEY ([ItemId]) REFERENCES [dbo].[BinaryItem] ([ItemId]),
    CONSTRAINT [Property_MaterialDefinition_MaterialClass_MaterialDefinition_Relation1] FOREIGN KEY ([MaterialDefinitionId]) REFERENCES [dbo].[MaterialDefinition] ([MaterialDefinitionId])
);


GO
ALTER TABLE [dbo].[Property_MaterialDefinition_MaterialClass] ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);


GO
CREATE NONCLUSTERED INDEX [IX_Property_MaterialDefinition_MaterialClass_Name]
    ON [dbo].[Property_MaterialDefinition_MaterialClass]([Name] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_Property_MaterialDefinition_MaterialClass_Class]
    ON [dbo].[Property_MaterialDefinition_MaterialClass]([Class] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_Property_MaterialDefinition_MaterialClass_ItemId]
    ON [dbo].[Property_MaterialDefinition_MaterialClass]([ItemId] ASC);


GO
CREATE TRIGGER [trg_Property_MaterialDefinition_MaterialClass]
ON [dbo].[Property_MaterialDefinition_MaterialClass]
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

	UPDATE pmmc
	SET CustomDataTypeValueId = 
		CASE (pmc.DataType)
			WHEN (@CustomDataType) THEN CONVERT(UNIQUEIDENTIFIER,i.Value)
			ELSE NULL
		END
	FROM dbo.Property_MaterialDefinition_MaterialClass pmmc
	INNER JOIN inserted i
		ON  i.MaterialDefinitionId = pmmc.MaterialDefinitionId
		AND i.Name = pmmc.Name
	INNER JOIN dbo.Property_MaterialClass pmc 
		ON pmc.MaterialClassName = i.Class
		AND pmc.PropertyName = i.Name
END