CREATE TABLE [dbo].[RevisionInfo] (
    [Revision]     BIGINT   NOT NULL,
    [UtcTimestamp] DATETIME NULL,
    [Version]      BIGINT   NULL,
    PRIMARY KEY CLUSTERED ([Revision] ASC)
);

