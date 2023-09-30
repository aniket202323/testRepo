CREATE TABLE [dbo].[Transaction_Groups] (
    [Transaction_Grp_Id]   INT                  IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Transaction_Grp_Desc] [dbo].[Varchar_Desc] NOT NULL,
    CONSTRAINT [Trans_Grps_PK_TransGrpId] PRIMARY KEY CLUSTERED ([Transaction_Grp_Id] ASC)
);

