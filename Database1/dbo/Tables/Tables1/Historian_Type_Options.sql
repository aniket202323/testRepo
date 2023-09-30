CREATE TABLE [dbo].[Historian_Type_Options] (
    [Hist_Option_Default_Value] VARCHAR (1000) NULL,
    [Hist_Option_Id]            INT            NOT NULL,
    [Hist_Type_Id]              INT            NOT NULL,
    [HistTO_Id]                 INT            NOT NULL,
    CONSTRAINT [HistTypeOptions_PK] PRIMARY KEY NONCLUSTERED ([HistTO_Id] ASC),
    CONSTRAINT [HistTypeOpt_FK_HistOpt] FOREIGN KEY ([Hist_Option_Id]) REFERENCES [dbo].[Historian_Options] ([Hist_Option_Id]),
    CONSTRAINT [HistTypeOpt_FK_HistType] FOREIGN KEY ([Hist_Type_Id]) REFERENCES [dbo].[Historian_Types] ([Hist_Type_Id])
);


GO
CREATE UNIQUE CLUSTERED INDEX [Historian_Type_Options_IX_TypeOption]
    ON [dbo].[Historian_Type_Options]([Hist_Type_Id] ASC, [Hist_Option_Id] ASC);

