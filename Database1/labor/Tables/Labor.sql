CREATE TABLE [labor].[Labor] (
    [Id]              BIGINT             IDENTITY (1, 1) NOT NULL,
    [LaborTypeId]     BIGINT             NOT NULL,
    [SegmentActualId] BIGINT             NOT NULL,
    [StartTime]       DATETIMEOFFSET (7) NOT NULL,
    [EndTime]         DATETIMEOFFSET (7) NULL,
    [AppliedTime]     BIGINT             NULL,
    [UserName]        NVARCHAR (100)     NOT NULL,
    [CreatedOn]       DATETIMEOFFSET (7) NOT NULL,
    [CreatedBy]       NVARCHAR (100)     NOT NULL,
    [ModifiedOn]      DATETIMEOFFSET (7) NULL,
    [ModifiedBy]      NVARCHAR (100)     NULL,
    [ReasonId]        BIGINT             DEFAULT (NULL) NULL,
    CONSTRAINT [Labor_pk] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_Labor_LaborType] FOREIGN KEY ([LaborTypeId]) REFERENCES [labor].[LaborType] ([Id])
);


GO
CREATE NONCLUSTERED INDEX [Ix_Labor]
    ON [labor].[Labor]([UserName] ASC, [SegmentActualId] ASC);

