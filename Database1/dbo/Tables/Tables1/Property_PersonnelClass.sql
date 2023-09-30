CREATE TABLE [dbo].[Property_PersonnelClass] (
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
    [PersonnelClassName]        NVARCHAR (200)   NOT NULL,
    [ItemId]                    UNIQUEIDENTIFIER NULL,
    [CustomDataTypeValueId]     UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([PersonnelClassName] ASC, [PropertyName] ASC),
    CONSTRAINT [FK_Property_PersonnelClass_QFDataType] FOREIGN KEY ([CustomDataTypeValueId]) REFERENCES [dbo].[QFDataTypePhrases] ([DataTypePhraseId]),
    CONSTRAINT [Property_PersonnelClass_BinaryItem_Relation1] FOREIGN KEY ([ItemId]) REFERENCES [dbo].[BinaryItem] ([ItemId]),
    CONSTRAINT [Property_PersonnelClass_PersonnelClass_Relation1] FOREIGN KEY ([PersonnelClassName]) REFERENCES [dbo].[PersonnelClass] ([PersonnelClassName]) ON UPDATE CASCADE
);


GO
ALTER TABLE [dbo].[Property_PersonnelClass] ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);


GO
CREATE NONCLUSTERED INDEX [NC_Property_PersonnelClass_ItemId]
    ON [dbo].[Property_PersonnelClass]([ItemId] ASC);


GO
CREATE TRIGGER [dbo].[trg_Property_PersonnelClass]
ON [dbo].[Property_PersonnelClass]
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

	UPDATE ppc
	SET CustomDataTypeValueId = 
		CASE (i.DataType)
			WHEN (@CustomDataType) THEN CONVERT(UNIQUEIDENTIFIER,i.Value)
			ELSE NULL
		END
	FROM dbo.Property_PersonnelClass ppc
	INNER JOIN inserted i 
		ON i.PersonnelClassName = ppc.PersonnelClassName 
		AND i.PropertyName = ppc.PropertyName
END