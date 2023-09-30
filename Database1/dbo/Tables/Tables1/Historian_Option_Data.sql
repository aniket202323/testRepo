CREATE TABLE [dbo].[Historian_Option_Data] (
    [HOD_Id]         INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Hist_Id]        INT            NOT NULL,
    [Hist_Option_Id] INT            NOT NULL,
    [Value]          VARCHAR (1000) NULL,
    CONSTRAINT [HistOptData_PK_HistIdHistOptId] PRIMARY KEY NONCLUSTERED ([Hist_Id] ASC, [Hist_Option_Id] ASC),
    CONSTRAINT [HistOptData_FK_HistOpt] FOREIGN KEY ([Hist_Option_Id]) REFERENCES [dbo].[Historian_Options] ([Hist_Option_Id]),
    CONSTRAINT [HistOptData_FK_Historians] FOREIGN KEY ([Hist_Id]) REFERENCES [dbo].[Historians] ([Hist_Id])
);

