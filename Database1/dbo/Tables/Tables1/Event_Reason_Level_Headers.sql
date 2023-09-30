CREATE TABLE [dbo].[Event_Reason_Level_Headers] (
    [Event_Reason_Level_Header_Id] INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Reason_Level]                 INT           NOT NULL,
    [Tree_Name_Id]                 INT           NOT NULL,
    [Level_Name_Global]            VARCHAR (100) NULL,
    [Level_Name_Local]             VARCHAR (100) NOT NULL,
    [Level_Name]                   AS            (case when (@@options&(512))=(0) then isnull([Level_Name_Global],[Level_Name_Local]) else [Level_Name_Local] end),
    CONSTRAINT [Evt_Rsn_Lev_Hdrs_PK_ERLHId] PRIMARY KEY CLUSTERED ([Event_Reason_Level_Header_Id] ASC),
    CONSTRAINT [Evt_Rsn_Lev_Hdrs_FK_TreeNameId] FOREIGN KEY ([Tree_Name_Id]) REFERENCES [dbo].[Event_Reason_Tree] ([Tree_Name_Id]),
    CONSTRAINT [Evt_Rsn_Lev_Hdrs_TNIdRsnLev] UNIQUE NONCLUSTERED ([Tree_Name_Id] ASC, [Reason_Level] ASC)
);


GO
CREATE NONCLUSTERED INDEX [Evt_Rsn_Lev_Hdrs_IDX_TNId]
    ON [dbo].[Event_Reason_Level_Headers]([Tree_Name_Id] ASC);

