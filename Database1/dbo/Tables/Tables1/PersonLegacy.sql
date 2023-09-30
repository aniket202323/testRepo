CREATE TABLE [dbo].[PersonLegacy] (
    [S95Id]       NVARCHAR (50)    NULL,
    [Name]        NVARCHAR (255)   NULL,
    [PersonId]    UNIQUEIDENTIFIER NOT NULL,
    [Description] NVARCHAR (255)   NULL,
    [Version]     BIGINT           DEFAULT ((1)) NULL,
    PRIMARY KEY CLUSTERED ([PersonId] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_Person_S95Id]
    ON [dbo].[PersonLegacy]([S95Id] ASC);

