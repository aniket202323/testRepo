CREATE TABLE [dbo].[Prod_Events] (
    [Action_Reason_Enabled] BIT     CONSTRAINT [Prod_Events_DF_ActionReasonEnabled] DEFAULT ((0)) NOT NULL,
    [Action_Tree_Id]        INT     NULL,
    [Event_Type]            TINYINT NOT NULL,
    [Name_Id]               INT     NOT NULL,
    [PU_Id]                 INT     NOT NULL,
    [Research_Enabled]      BIT     CONSTRAINT [Prod_Events_DF_ResearchEnabled] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [ProdEvents_FK_NameId] FOREIGN KEY ([Name_Id]) REFERENCES [dbo].[Event_Reason_Tree] ([Tree_Name_Id]),
    CONSTRAINT [Prod_Events_UC_PUIdEventType] UNIQUE NONCLUSTERED ([PU_Id] ASC, [Event_Type] ASC)
);

