CREATE TABLE [dbo].[Historian_Options] (
    [Field_Type_Id]    INT          NOT NULL,
    [Hist_Option_Desc] VARCHAR (25) NOT NULL,
    [Hist_Option_Id]   INT          NOT NULL,
    CONSTRAINT [HistOpt_PK_HistOptId] PRIMARY KEY CLUSTERED ([Hist_Option_Id] ASC),
    CONSTRAINT [HistOpt_FK_FieldType] FOREIGN KEY ([Field_Type_Id]) REFERENCES [dbo].[ED_FieldTypes] ([ED_Field_Type_Id]),
    CONSTRAINT [HistOpt_UC_HistOptDesc] UNIQUE NONCLUSTERED ([Hist_Option_Desc] ASC)
);

