CREATE TABLE [dbo].[Sheet_Plots] (
    [Plot_Order]        TINYINT NOT NULL,
    [Sheet_Id]          INT     NOT NULL,
    [SPC_Trend_Type_Id] INT     NULL,
    [Var_Id1]           INT     NOT NULL,
    [Var_Id2]           INT     NULL,
    [Var_Id3]           INT     NULL,
    [Var_Id4]           INT     NULL,
    [Var_Id5]           INT     NULL,
    CONSTRAINT [Sheet_Plots_PK_SheetIdPlotOrder] PRIMARY KEY NONCLUSTERED ([Sheet_Id] ASC, [Plot_Order] ASC),
    CONSTRAINT [Sheet_Plots_FK_Sheets] FOREIGN KEY ([Sheet_Id]) REFERENCES [dbo].[Sheets] ([Sheet_Id]),
    CONSTRAINT [Sheet_Plots_FK_SPC_Trend_Types] FOREIGN KEY ([SPC_Trend_Type_Id]) REFERENCES [dbo].[SPC_Trend_Types] ([SPC_Trend_Type_Id]),
    CONSTRAINT [Sheet_Plots_FK_Variables1] FOREIGN KEY ([Var_Id1]) REFERENCES [dbo].[Variables_Base] ([Var_Id]),
    CONSTRAINT [Sheet_Plots_FK_Variables2] FOREIGN KEY ([Var_Id2]) REFERENCES [dbo].[Variables_Base] ([Var_Id]),
    CONSTRAINT [Sheet_Plots_FK_Variables3] FOREIGN KEY ([Var_Id3]) REFERENCES [dbo].[Variables_Base] ([Var_Id]),
    CONSTRAINT [Sheet_Plots_FK_Variables4] FOREIGN KEY ([Var_Id4]) REFERENCES [dbo].[Variables_Base] ([Var_Id]),
    CONSTRAINT [Sheet_Plots_FK_Variables5] FOREIGN KEY ([Var_Id5]) REFERENCES [dbo].[Variables_Base] ([Var_Id])
);

