CREATE TABLE [PR_OpcUa].[OpcUaGroup] (
    [ServerId]    UNIQUEIDENTIFIER NOT NULL,
    [GroupId]     UNIQUEIDENTIFIER NOT NULL,
    [Name]        NVARCHAR (255)   NOT NULL,
    [Description] NVARCHAR (255)   NULL,
    [Version]     BIGINT           NULL,
    CONSTRAINT [PK_OpcUaGroup] PRIMARY KEY CLUSTERED ([GroupId] ASC),
    CONSTRAINT [OpcUaGroup_OpcUaServer_Relation1] FOREIGN KEY ([ServerId]) REFERENCES [PR_OpcUa].[OpcUaServer] ([ServerId]) ON DELETE CASCADE
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_OpcUaGroup_ServerId_Name]
    ON [PR_OpcUa].[OpcUaGroup]([ServerId] ASC, [Name] ASC);

