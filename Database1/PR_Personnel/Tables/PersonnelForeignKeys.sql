CREATE TABLE [PR_Personnel].[PersonnelForeignKeys] (
    [ForeignKeyId]        INT       IDENTITY (1, 1) NOT NULL,
    [ForeignKeyName]      [sysname] NULL,
    [SchemaName]          [sysname] NULL,
    [TableName]           [sysname] NULL,
    [ColumnName]          [sysname] NULL,
    [ReferenceTableName]  [sysname] NULL,
    [ReferenceColumnName] [sysname] NULL,
    CONSTRAINT [PK_PersonnelForeignKeys] PRIMARY KEY CLUSTERED ([ForeignKeyId] ASC)
);

