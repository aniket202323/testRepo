CREATE TABLE [dbo].[Message_Schema] (
    [Schema_Id]        INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Contents]         NTEXT          NOT NULL,
    [Schema_Namespace] NVARCHAR (200) NOT NULL,
    [Schema_Uri]       NVARCHAR (200) NOT NULL,
    CONSTRAINT [MessageSchema_PK_SchemaId] PRIMARY KEY NONCLUSTERED ([Schema_Id] ASC)
);


GO
CREATE UNIQUE CLUSTERED INDEX [MessageSchema_UC_SchemaUriSchemaNamespace]
    ON [dbo].[Message_Schema]([Schema_Uri] ASC, [Schema_Namespace] ASC);

