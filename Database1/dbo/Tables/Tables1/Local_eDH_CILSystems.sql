CREATE TABLE [dbo].[Local_eDH_CILSystems] (
    [CILSystemId] INT            IDENTITY (1, 1) NOT NULL,
    [Description] NVARCHAR (255) NOT NULL,
    [DBServer]    NVARCHAR (255) NULL,
    [Credentials] NVARCHAR (255) NULL,
    [Type]        NVARCHAR (50)  NULL,
    PRIMARY KEY CLUSTERED ([CILSystemId] ASC)
);

