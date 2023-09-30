CREATE TABLE [dbo].[Counter] (
    [Id]         NVARCHAR (255) NOT NULL,
    [NextNumber] BIGINT         NULL,
    [Version]    BIGINT         NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);

