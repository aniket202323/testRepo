CREATE TABLE [dbo].[AttributeValuesHistory] (
    [Attribute_Id]       INT            NOT NULL,
    [HistoricalAlarm_Id] INT            NOT NULL,
    [Value]              VARCHAR (1000) NOT NULL,
    CONSTRAINT [AttributeValuesHistory_PK_HistAlmIdAttid] PRIMARY KEY NONCLUSTERED ([HistoricalAlarm_Id] ASC, [Attribute_Id] ASC),
    CONSTRAINT [AttributeValuesHistory_FK_AttributeID] FOREIGN KEY ([Attribute_Id]) REFERENCES [dbo].[VendorAttributes] ([Attribute_Id])
);

