CREATE TABLE [dbo].[OpcGroup] (
    [GroupId]     UNIQUEIDENTIFIER NOT NULL,
    [Name]        NVARCHAR (255)   NULL,
    [Description] NVARCHAR (255)   NULL,
    [UpdateRate]  INT              NULL,
    [Enabled]     BIT              NULL,
    [DeviceRead]  BIT              NULL,
    [Deadband]    FLOAT (53)       NULL,
    [Version]     BIGINT           NULL,
    [ServerId]    UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([GroupId] ASC),
    CONSTRAINT [OpcGroup_OpcServer_Relation1] FOREIGN KEY ([ServerId]) REFERENCES [dbo].[OpcServer] ([ServerId])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_OpcGroup_ServerId_Name]
    ON [dbo].[OpcGroup]([ServerId] ASC, [Name] ASC);

