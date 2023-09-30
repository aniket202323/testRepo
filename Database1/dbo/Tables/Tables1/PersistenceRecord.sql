CREATE TABLE [dbo].[PersistenceRecord] (
    [RecordId]            UNIQUEIDENTIFIER NOT NULL,
    [ActivityContextGuid] UNIQUEIDENTIFIER NULL,
    [PersistentData]      IMAGE            NULL,
    [RecordType]          NVARCHAR (255)   NULL,
    [Version]             BIGINT           NULL,
    [InstanceId]          UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([RecordId] ASC),
    CONSTRAINT [PersistenceRecord_WorkflowInstance_Relation1] FOREIGN KEY ([InstanceId]) REFERENCES [dbo].[WorkflowInstance] ([InstanceId])
);


GO
CREATE NONCLUSTERED INDEX [NC_PersistenceRecord_InstanceId]
    ON [dbo].[PersistenceRecord]([InstanceId] ASC);

