CREATE TABLE [dbo].[Batch_Results_Selections] (
    [Selection_Id]   INT     IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Analysis_Id]    INT     NOT NULL,
    [Batch_Event_Id] INT     NOT NULL,
    [Checked]        TINYINT CONSTRAINT [BatchResults_DF_Checked] DEFAULT ((0)) NOT NULL,
    [Event_Id]       INT     NOT NULL,
    [PU_Id]          INT     NOT NULL,
    [Selected]       TINYINT CONSTRAINT [BatchResults_DF_Selected] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [BatchResults_PK_SelectionId] PRIMARY KEY CLUSTERED ([Selection_Id] ASC),
    CONSTRAINT [BatchResultSelect_FK_AnalysisId] FOREIGN KEY ([Analysis_Id]) REFERENCES [dbo].[Report_Definitions] ([Report_Id]) ON DELETE CASCADE
);

