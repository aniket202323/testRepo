CREATE TABLE [dbo].[OpcItem] (
    [ItemId]       UNIQUEIDENTIFIER NOT NULL,
    [Name]         NVARCHAR (255)   NULL,
    [FullName]     NVARCHAR (255)   NULL,
    [DataTypeId]   INT              NULL,
    [AccessRights] INT              NULL,
    [Version]      BIGINT           NULL,
    [GroupId]      UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([ItemId] ASC),
    CONSTRAINT [OpcItem_OpcGroup_Relation1] FOREIGN KEY ([GroupId]) REFERENCES [dbo].[OpcGroup] ([GroupId])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_OpcItem_GroupId_Name]
    ON [dbo].[OpcItem]([GroupId] ASC, [Name] ASC);

