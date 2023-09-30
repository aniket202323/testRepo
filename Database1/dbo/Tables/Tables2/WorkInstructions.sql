CREATE TABLE [dbo].[WorkInstructions] (
    [Id]      UNIQUEIDENTIFIER NOT NULL,
    [Data]    IMAGE            NULL,
    [Version] BIGINT           NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);

