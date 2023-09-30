CREATE TABLE [dbo].[Local_eDH_RptDefinitions] (
    [RptDefinitionId] INT            IDENTITY (1, 1) NOT NULL,
    [DefinitionName]  NVARCHAR (255) NULL,
    [Definition]      NVARCHAR (MAX) NOT NULL,
    [UserName]        NVARCHAR (255) NULL,
    PRIMARY KEY CLUSTERED ([RptDefinitionId] ASC)
);

