CREATE TABLE [dbo].[PurgeConfig_Detail] (
    [Purge_Detail_Id] INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [ElementPerBatch] INT          NOT NULL,
    [PU_Id]           INT          NULL,
    [Purge_Id]        INT          NOT NULL,
    [RetentionMonths] INT          NOT NULL,
    [TableName]       VARCHAR (30) NULL,
    [Var_Id]          INT          NULL,
    CONSTRAINT [PK_PurgeConfig_Detail] PRIMARY KEY NONCLUSTERED ([Purge_Detail_Id] ASC),
    CONSTRAINT [PurgeConfigDetail_CC_ElementPerBatch] CHECK ([ElementPerBatch]>(99)),
    CONSTRAINT [PurgeConfigDetail_CC_Retension] CHECK ([RetentionMonths]>(2)),
    CONSTRAINT [PurgeConfigDetail_FK_PUId] FOREIGN KEY ([PU_Id]) REFERENCES [dbo].[Prod_Units_Base] ([PU_Id]) ON DELETE CASCADE,
    CONSTRAINT [PurgeConfigDetail_FK_PurgeId] FOREIGN KEY ([Purge_Id]) REFERENCES [dbo].[PurgeConfig] ([Purge_Id]) ON DELETE CASCADE,
    CONSTRAINT [PurgeConfigDetail_FK_VarId] FOREIGN KEY ([Var_Id]) REFERENCES [dbo].[Variables_Base] ([Var_Id]) ON DELETE CASCADE,
    CONSTRAINT [IX_PurgeConfig] UNIQUE CLUSTERED ([Purge_Id] ASC, [TableName] ASC, [PU_Id] ASC, [Var_Id] ASC)
);

