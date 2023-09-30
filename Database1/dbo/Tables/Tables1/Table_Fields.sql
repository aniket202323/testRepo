CREATE TABLE [dbo].[Table_Fields] (
    [Table_Field_Id]   INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [ED_Field_Type_Id] INT          NOT NULL,
    [Table_Field_Desc] VARCHAR (50) NOT NULL,
    [TableId]          INT          NOT NULL,
    CONSTRAINT [TableFields_PK_TableFieldId] PRIMARY KEY CLUSTERED ([Table_Field_Id] ASC),
    CONSTRAINT [TableFields_FK_EDFieldTypes] FOREIGN KEY ([ED_Field_Type_Id]) REFERENCES [dbo].[ED_FieldTypes] ([ED_Field_Type_Id]),
    CONSTRAINT [TableFields_UC_TableIdFieldDesc] UNIQUE NONCLUSTERED ([TableId] ASC, [Table_Field_Desc] ASC)
);

