CREATE TABLE [dbo].[Event_Reason_Tree_Data] (
    [Event_Reason_Tree_Data_Id]   INT     IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Bottom_Of_Tree]              TINYINT NULL,
    [Comment_Required]            BIT     CONSTRAINT [Evt_Rsn_Tree_Data_DF_CmntReq] DEFAULT ((0)) NOT NULL,
    [ERT_Data_Order]              INT     NULL,
    [Event_Reason_Id]             INT     NOT NULL,
    [Event_Reason_Level]          INT     NULL,
    [Level1_Id]                   INT     NULL,
    [Level2_Id]                   INT     NULL,
    [Level3_Id]                   INT     NULL,
    [Level4_Id]                   INT     NULL,
    [Parent_Event_R_Tree_Data_Id] INT     NULL,
    [Parent_Event_Reason_Id]      INT     NULL,
    [Tree_Name_Id]                INT     NULL,
    CONSTRAINT [Evt_Rsn_Tree_Data_PK_ERTDId] PRIMARY KEY CLUSTERED ([Event_Reason_Tree_Data_Id] ASC),
    CONSTRAINT [Evt_Rsn_Tree_Data_FK_EvtRsnId] FOREIGN KEY ([Event_Reason_Id]) REFERENCES [dbo].[Event_Reasons] ([Event_Reason_Id]),
    CONSTRAINT [Evt_Rsn_Tree_Data_FK_PERId] FOREIGN KEY ([Parent_Event_Reason_Id]) REFERENCES [dbo].[Event_Reasons] ([Event_Reason_Id]),
    CONSTRAINT [Evt_Rsn_Tree_Data_FK_PERTDId] FOREIGN KEY ([Parent_Event_R_Tree_Data_Id]) REFERENCES [dbo].[Event_Reason_Tree_Data] ([Event_Reason_Tree_Data_Id]),
    CONSTRAINT [Evt_Rsn_Tree_Data_FK_TNameId] FOREIGN KEY ([Tree_Name_Id]) REFERENCES [dbo].[Event_Reason_Tree] ([Tree_Name_Id]),
    CONSTRAINT [eventreasonTreeData_UC_TreeidReasonidLevel] UNIQUE NONCLUSTERED ([Tree_Name_Id] ASC, [Event_Reason_Level] ASC, [Event_Reason_Id] ASC, [Parent_Event_R_Tree_Data_Id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [Evt_Rsn_Tree_Data_IDX_PERTDId]
    ON [dbo].[Event_Reason_Tree_Data]([Parent_Event_R_Tree_Data_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [Evt_Rsn_Tree_Data_IDX_TNIdRLev]
    ON [dbo].[Event_Reason_Tree_Data]([Tree_Name_Id] ASC, [Event_Reason_Level] ASC);

