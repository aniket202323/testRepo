CREATE TABLE [dbo].[Stored_Proc_Dependancies] (
    [SP_Depend_Id]        INT                       IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Maximum]             INT                       NULL,
    [Minimum]             INT                       NULL,
    [SP_Depend_Desc]      [dbo].[Varchar_Desc]      NOT NULL,
    [SP_Depend_Long_Desc] [dbo].[Varchar_Long_Desc] NULL,
    [SP_Id]               INT                       NOT NULL,
    CONSTRAINT [SPDep_PK_SPDependIdSPId] PRIMARY KEY NONCLUSTERED ([SP_Depend_Id] ASC, [SP_Id] ASC)
);

