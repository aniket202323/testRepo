CREATE TABLE [dbo].[Local_eDH_Team] (
    [Id]              INT            IDENTITY (1, 1) NOT NULL,
    [TeamName]        NVARCHAR (100) NOT NULL,
    [TeamDescription] NVARCHAR (255) NULL,
    [Enable]          BIT            NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);

