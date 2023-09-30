CREATE TABLE [dbo].[Event_Reason_Tree] (
    [Tree_Name_Id]     INT                  IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Group_Id]         INT                  NULL,
    [Tree_Name_Global] [dbo].[Varchar_Desc] NULL,
    [Tree_Name_Local]  [dbo].[Varchar_Desc] NOT NULL,
    [Tree_Name]        AS                   (case when (@@options&(512))=(0) then isnull([Tree_Name_Global],[Tree_Name_Local]) else [Tree_Name_Local] end),
    CONSTRAINT [Evt_Rsn_Tree_PK_TreeNameId] PRIMARY KEY CLUSTERED ([Tree_Name_Id] ASC),
    CONSTRAINT [EventReasonTree_FK_GroupId] FOREIGN KEY ([Group_Id]) REFERENCES [dbo].[Security_Groups] ([Group_Id]),
    CONSTRAINT [EvtRsnTree_UC_TreeNameLocal] UNIQUE NONCLUSTERED ([Tree_Name_Local] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Evt_Rsn_Tree_UC_TreeNameLocal]
    ON [dbo].[Event_Reason_Tree]([Tree_Name_Local] ASC);

