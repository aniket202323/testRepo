CREATE TABLE [dbo].[Property_Equipment_EquipmentClass] (
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
    [EquipmentId]               UNIQUEIDENTIFIER NOT NULL,
    [ItemId]                    UNIQUEIDENTIFIER NULL,
    [CustomDataTypeValueId]     UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([EquipmentId] ASC, [Name] ASC),
    CONSTRAINT [FK_Property_Equipment_EquipmentClass_QFDataType] FOREIGN KEY ([CustomDataTypeValueId]) REFERENCES [dbo].[QFDataTypePhrases] ([DataTypePhraseId]),
    CONSTRAINT [Property_Equipment_EquipmentClass_BinaryItem_Relation1] FOREIGN KEY ([ItemId]) REFERENCES [dbo].[BinaryItem] ([ItemId]),
    CONSTRAINT [Property_Equipment_EquipmentClass_Equipment_Relation1] FOREIGN KEY ([EquipmentId]) REFERENCES [dbo].[Equipment] ([EquipmentId])
);


GO
ALTER TABLE [dbo].[Property_Equipment_EquipmentClass] ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);


GO
CREATE NONCLUSTERED INDEX [IX_Property_Equipment_EquipmentClass_Name]
    ON [dbo].[Property_Equipment_EquipmentClass]([Name] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_Property_Equipment_EquipmentClass_Class]
    ON [dbo].[Property_Equipment_EquipmentClass]([Class] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_Property_Equipment_EquipmentClass_ItemId]
    ON [dbo].[Property_Equipment_EquipmentClass]([ItemId] ASC);


GO
CREATE TRIGGER [trg_Property_Equipment_EquipmentClass]
ON [dbo].[Property_Equipment_EquipmentClass]
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

	UPDATE peec
	SET CustomDataTypeValueId = 
		CASE (pec.DataType)
			WHEN (@CustomDataType) THEN CONVERT(UNIQUEIDENTIFIER,i.Value)
			ELSE NULL
		END 
	FROM dbo.Property_Equipment_EquipmentClass peec
	INNER JOIN inserted i
		ON i.EquipmentId = peec.EquipmentId 
		AND i.Name = peec.Name
	INNER JOIN dbo.Property_EquipmentClass pec 
		ON pec.EquipmentClassName = i.Class
		AND pec.PropertyName = i.Name
END