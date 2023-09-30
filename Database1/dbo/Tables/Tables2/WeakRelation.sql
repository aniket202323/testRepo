CREATE TABLE [dbo].[WeakRelation] (
    [Id]           UNIQUEIDENTIFIER NOT NULL,
    [RelationName] NVARCHAR (255)   NULL,
    [StartTime]    DATETIME         NULL,
    [EndTime]      DATETIME         NULL,
    [Closed]       BIT              NULL,
    [IsSystem]     BIT              NULL,
    [Version]      BIGINT           NULL,
    [SourceId]     UNIQUEIDENTIFIER NULL,
    [TargetId]     UNIQUEIDENTIFIER NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [WeakRelation_ObjectAddress_Relation1] FOREIGN KEY ([SourceId]) REFERENCES [dbo].[ObjectAddress] ([Id]),
    CONSTRAINT [WeakRelation_ObjectAddress_Relation2] FOREIGN KEY ([TargetId]) REFERENCES [dbo].[ObjectAddress] ([Id])
);


GO
ALTER TABLE [dbo].[WeakRelation] ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_WeakRelation_SourceId_TargetId_RelationName_StartTime]
    ON [dbo].[WeakRelation]([SourceId] ASC, [TargetId] ASC, [RelationName] ASC, [StartTime] ASC);


GO
CREATE NONCLUSTERED INDEX [NC_WeakRelation_TargetId]
    ON [dbo].[WeakRelation]([TargetId] ASC);

