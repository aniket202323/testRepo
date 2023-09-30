CREATE TABLE [dbo].[CXS_Route_Group] (
    [RG_Id]   SMALLINT             IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [RG_Desc] [dbo].[Varchar_Desc] NOT NULL,
    CONSTRAINT [CXS_Route_Group_PK_RGId] PRIMARY KEY CLUSTERED ([RG_Id] ASC),
    CONSTRAINT [CXS_Route_Group_UC_RGDesc] UNIQUE NONCLUSTERED ([RG_Desc] ASC)
);

