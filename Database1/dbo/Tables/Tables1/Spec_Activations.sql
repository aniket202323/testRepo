CREATE TABLE [dbo].[Spec_Activations] (
    [SA_Id]   TINYINT              IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [SA_Desc] [dbo].[Varchar_Desc] NOT NULL,
    CONSTRAINT [Spec_Activations_PK_SAId] PRIMARY KEY CLUSTERED ([SA_Id] ASC)
);

