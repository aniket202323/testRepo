CREATE TABLE [dbo].[Property_EquipmentClass] (
    [PropertyName]              NVARCHAR (200)   NOT NULL,
    [Description]               NVARCHAR (255)   NULL,
    [DataType]                  INT              NULL,
    [UnitOfMeasure]             NVARCHAR (255)   NULL,
    [Constant]                  BIT              NULL,
    [IsValueOverridden]         BIT              NULL,
    [IsDescriptionOverridden]   BIT              NULL,
    [IsUnitOfMeasureOverridden] BIT              NULL,
    [TimeStamp]                 DATETIME         NULL,
    [Value]                     SQL_VARIANT      NULL,
    [Version]                   BIGINT           NULL,
    [EquipmentClassName]        NVARCHAR (200)   NOT NULL,
    [ItemId]                    UNIQUEIDENTIFIER NULL,
    [CustomDataTypeValueId]     UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([EquipmentClassName] ASC, [PropertyName] ASC),
    CONSTRAINT [FK_Property_EquipmentClass_QFDataType] FOREIGN KEY ([CustomDataTypeValueId]) REFERENCES [dbo].[QFDataTypePhrases] ([DataTypePhraseId]),
    CONSTRAINT [Property_EquipmentClass_BinaryItem_Relation1] FOREIGN KEY ([ItemId]) REFERENCES [dbo].[BinaryItem] ([ItemId]),
    CONSTRAINT [Property_EquipmentClass_EquipmentClass_Relation1] FOREIGN KEY ([EquipmentClassName]) REFERENCES [dbo].[EquipmentClass] ([EquipmentClassName]) ON UPDATE CASCADE
);


GO
ALTER TABLE [dbo].[Property_EquipmentClass] ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);


GO
CREATE NONCLUSTERED INDEX [NC_Property_EquipmentClass_ItemId]
    ON [dbo].[Property_EquipmentClass]([ItemId] ASC);


GO
CREATE TRIGGER [dbo].[trg_Property_EquipmentClass]
ON [dbo].[Property_EquipmentClass]
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

	UPDATE pec
	SET CustomDataTypeValueId = 
		CASE (i.DataType)
			WHEN (@CustomDataType) THEN CONVERT(UNIQUEIDENTIFIER,i.Value)
			ELSE NULL
		END 
	FROM dbo.Property_EquipmentClass pec
	INNER JOIN inserted i 
		ON i.EquipmentClassName = pec.EquipmentClassName 
		AND i.PropertyName = pec.PropertyName
END