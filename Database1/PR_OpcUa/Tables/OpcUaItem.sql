CREATE TABLE [PR_OpcUa].[OpcUaItem] (
    [GroupId]      UNIQUEIDENTIFIER NOT NULL,
    [ItemId]       UNIQUEIDENTIFIER NOT NULL,
    [Name]         NVARCHAR (1000)  NOT NULL,
    [NodeId]       NVARCHAR (255)   NOT NULL,
    [DataTypeId]   INT              NULL,
    [AccessRights] INT              NULL,
    [Version]      BIGINT           NULL,
    CONSTRAINT [PK_OpcUaItem] PRIMARY KEY CLUSTERED ([ItemId] ASC),
    CONSTRAINT [OpcUaItem_OpcUaGroup_Relation1] FOREIGN KEY ([GroupId]) REFERENCES [PR_OpcUa].[OpcUaGroup] ([GroupId]) ON DELETE CASCADE
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_OpcUaItem_GroupId_Name]
    ON [PR_OpcUa].[OpcUaItem]([GroupId] ASC, [Name] ASC);

