CREATE TABLE [dbo].[GB_RSum_Data] (
    [Conf_Index] [dbo].[Float_Pct]     NOT NULL,
    [Cp]         FLOAT (53)            NULL,
    [Cpk]        FLOAT (53)            NULL,
    [In_Limit]   [dbo].[Float_Pct]     NOT NULL,
    [In_Warning] [dbo].[Float_Pct]     NOT NULL,
    [Maximum]    FLOAT (53)            NULL,
    [Minimum]    FLOAT (53)            NULL,
    [Num_Values] INT                   NULL,
    [Pp]         FLOAT (53)            NULL,
    [Ppk]        FLOAT (53)            NULL,
    [RSum_Id]    INT                   NOT NULL,
    [StDev]      [dbo].[Float_Natural] NOT NULL,
    [Value]      [dbo].[Varchar_Value] NOT NULL,
    [Var_Id]     INT                   NOT NULL,
    CONSTRAINT [GB_RSum_PK_RSumIdVarId] PRIMARY KEY CLUSTERED ([RSum_Id] ASC, [Var_Id] ASC),
    CONSTRAINT [GB_RSum_Data_FK_RSumId] FOREIGN KEY ([RSum_Id]) REFERENCES [dbo].[GB_RSum] ([RSum_Id]),
    CONSTRAINT [GB_RSum_Data_FK_VarId] FOREIGN KEY ([Var_Id]) REFERENCES [dbo].[Variables_Base] ([Var_Id])
);


GO
CREATE NONCLUSTERED INDEX [GB_RSum_Data_By_ID]
    ON [dbo].[GB_RSum_Data]([RSum_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [GB_Rsum_Data_By_Var]
    ON [dbo].[GB_RSum_Data]([RSum_Id] ASC, [Var_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [GB_RSum_Data_IDX_VarId]
    ON [dbo].[GB_RSum_Data]([Var_Id] ASC);

