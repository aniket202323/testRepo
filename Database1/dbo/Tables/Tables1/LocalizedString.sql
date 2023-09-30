CREATE TABLE [dbo].[LocalizedString] (
    [Id]        BIGINT         NOT NULL,
    [r_Default] NVARCHAR (255) NULL,
    [English]   NVARCHAR (255) NULL,
    [French]    NVARCHAR (255) NULL,
    [German]    NVARCHAR (255) NULL,
    [Chinese]   NVARCHAR (255) NULL,
    [Version]   BIGINT         NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);

