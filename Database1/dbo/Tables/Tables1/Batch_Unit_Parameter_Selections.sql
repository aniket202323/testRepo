CREATE TABLE [dbo].[Batch_Unit_Parameter_Selections] (
    [Selection_Id]   INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Analysis_Id]    INT           NOT NULL,
    [ParameterName]  VARCHAR (255) NULL,
    [Unit_Procedure] VARCHAR (255) NULL,
    [Var_Id]         INT           NOT NULL,
    CONSTRAINT [BatchUnitParameter_PK_SelectionId] PRIMARY KEY CLUSTERED ([Selection_Id] ASC),
    CONSTRAINT [BatchUnitParamSelect_FK_AnalysisId] FOREIGN KEY ([Analysis_Id]) REFERENCES [dbo].[Report_Definitions] ([Report_Id]) ON DELETE CASCADE
);

