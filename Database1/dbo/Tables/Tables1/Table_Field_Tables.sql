CREATE TABLE [dbo].[Table_Field_Tables] (
    [Table_Field_Id] INT NOT NULL,
    [TableId]        INT NOT NULL,
    CONSTRAINT [TableFieldTables_TableFieldId] FOREIGN KEY ([Table_Field_Id]) REFERENCES [dbo].[Table_Fields] ([Table_Field_Id]),
    CONSTRAINT [TableFieldTables_TableId] FOREIGN KEY ([TableId]) REFERENCES [dbo].[Tables] ([TableId])
);

