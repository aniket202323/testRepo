CREATE TABLE [dbo].[Batch_Procedure_Selections] (
    [Selection_Id]   INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Analysis_Id]    INT           NOT NULL,
    [Operation]      VARCHAR (255) NULL,
    [Phase]          VARCHAR (255) NULL,
    [Unit_Procedure] VARCHAR (255) NULL,
    CONSTRAINT [BatchProcedure_PK_SelectionId] PRIMARY KEY CLUSTERED ([Selection_Id] ASC),
    CONSTRAINT [BatchProcedureSelect_FK_AnalysisId] FOREIGN KEY ([Analysis_Id]) REFERENCES [dbo].[Report_Definitions] ([Report_Id]) ON DELETE CASCADE
);

