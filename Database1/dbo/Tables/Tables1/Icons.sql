CREATE TABLE [dbo].[Icons] (
    [Icon_Id]        INT                  IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [DoNotDelete]    TINYINT              CONSTRAINT [DF_Icons_DoNotDelete] DEFAULT ((0)) NULL,
    [ForceOnInstall] BIT                  NULL,
    [Icon]           IMAGE                NULL,
    [Icon_Desc]      [dbo].[Varchar_Desc] NOT NULL,
    CONSTRAINT [Icons_PK_IconId] PRIMARY KEY NONCLUSTERED ([Icon_Id] ASC)
);

