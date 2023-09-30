CREATE TABLE [dbo].[Message_Definition] (
    [Application]       NVARCHAR (50)  NOT NULL,
    [Category_Id]       INT            NOT NULL,
    [Element_Name]      NVARCHAR (100) NOT NULL,
    [Element_Namespace] NVARCHAR (200) NOT NULL,
    [Message_Type]      INT            NOT NULL,
    [Schema_Id]         INT            NOT NULL,
    CONSTRAINT [MessageDefinition_PK_ApplicationMessageType] PRIMARY KEY CLUSTERED ([Application] ASC, [Message_Type] ASC),
    CONSTRAINT [MessageDefinition_CC_MessageType] CHECK ([Message_Type]>=(0)),
    CONSTRAINT [MessageDefinition_FK_CategoryId] FOREIGN KEY ([Category_Id]) REFERENCES [dbo].[Message_Category] ([Category_Id]),
    CONSTRAINT [MessageDefinition_FK_SchemaId] FOREIGN KEY ([Schema_Id]) REFERENCES [dbo].[Message_Schema] ([Schema_Id])
);


GO
CREATE NONCLUSTERED INDEX [MessageDefinition_IDX_SchemaId]
    ON [dbo].[Message_Definition]([Schema_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [MessageDefinition_IDX_CategoryId]
    ON [dbo].[Message_Definition]([Category_Id] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [MessageDefinition_UC_ElementNamespaceElementName]
    ON [dbo].[Message_Definition]([Element_Namespace] ASC, [Element_Name] ASC);

