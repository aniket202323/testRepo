CREATE TABLE [dbo].[GB_Dset_Data] (
    [DSet_Id] INT                   NOT NULL,
    [Value]   [dbo].[Varchar_Value] NOT NULL,
    [Var_Id]  INT                   NOT NULL,
    CONSTRAINT [GB_DSet_Data_PK_DsetIdVarId] PRIMARY KEY CLUSTERED ([DSet_Id] ASC, [Var_Id] ASC),
    CONSTRAINT [GB_DSet_Data_FK_DSetId] FOREIGN KEY ([DSet_Id]) REFERENCES [dbo].[GB_DSet] ([DSet_Id]),
    CONSTRAINT [GB_DSet_Data_FK_VarId] FOREIGN KEY ([Var_Id]) REFERENCES [dbo].[Variables_Base] ([Var_Id])
);


GO
CREATE NONCLUSTERED INDEX [GB_Dset_By_Id]
    ON [dbo].[GB_Dset_Data]([DSet_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [GB_DSet_Data_IDX_VarId]
    ON [dbo].[GB_Dset_Data]([Var_Id] ASC);

