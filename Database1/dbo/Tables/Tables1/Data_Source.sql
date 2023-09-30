CREATE TABLE [dbo].[Data_Source] (
    [DS_Id]       INT                  IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Active]      TINYINT              CONSTRAINT [DataSource_DF_Active] DEFAULT ((0)) NULL,
    [Bulk_Import] TINYINT              NULL,
    [DS_Desc]     [dbo].[Varchar_Desc] NOT NULL,
    CONSTRAINT [Data_Source_PK_DSId] PRIMARY KEY CLUSTERED ([DS_Id] ASC),
    CONSTRAINT [Data_Source_UC_DSDesc] UNIQUE NONCLUSTERED ([DS_Desc] ASC)
);

