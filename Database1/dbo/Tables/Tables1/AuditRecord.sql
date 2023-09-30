CREATE TABLE [dbo].[AuditRecord] (
    [Id]                    INT              NOT NULL,
    [Message]               NVARCHAR (1023)  NULL,
    [Context]               NVARCHAR (255)   NULL,
    [r_User]                NVARCHAR (255)   NULL,
    [Location]              NVARCHAR (255)   NULL,
    [RecordTime]            DATETIME         NULL,
    [OccurrenceTime]        DATETIME         NULL,
    [TypeId]                NVARCHAR (50)    NULL,
    [TopicId]               NVARCHAR (50)    NULL,
    [Version]               BIGINT           NULL,
    [ElectronicSignatureId] UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [AuditRecord_ElectronicSignature_Relation1] FOREIGN KEY ([ElectronicSignatureId]) REFERENCES [dbo].[ElectronicSignature] ([Id])
);


GO
CREATE NONCLUSTERED INDEX [IX_AuditRecord_RecordTime]
    ON [dbo].[AuditRecord]([RecordTime] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_AuditRecord_ElectronicSignatureId]
    ON [dbo].[AuditRecord]([ElectronicSignatureId] ASC);

