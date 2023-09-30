CREATE TABLE [dbo].[Variable_Alias] (
    [Dst_Var_Id] INT NOT NULL,
    [Src_Var_Id] INT NOT NULL,
    CONSTRAINT [Var_Alias_PK_SrcVarIdDstVarId] PRIMARY KEY CLUSTERED ([Src_Var_Id] ASC, [Dst_Var_Id] ASC),
    CONSTRAINT [Var_Alias_CC_SrcVarIdDstVarId] CHECK ([Src_Var_Id]<>[Dst_Var_Id]),
    CONSTRAINT [Var_Alias_FK_DstVarId] FOREIGN KEY ([Dst_Var_Id]) REFERENCES [dbo].[Variables_Base] ([Var_Id]),
    CONSTRAINT [Var_Alias_FK_SrcVarId] FOREIGN KEY ([Src_Var_Id]) REFERENCES [dbo].[Variables_Base] ([Var_Id])
);

