CREATE TABLE [dbo].[Event_Reason_Category_Data] (
    [ERCD_Id]                   INT IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [ERC_Id]                    INT NOT NULL,
    [Event_Reason_Tree_Data_Id] INT NOT NULL,
    [Propegated_From_ETDId]     INT NULL,
    CONSTRAINT [EvtRsnCatData_PK_ERCIdERTDId] PRIMARY KEY CLUSTERED ([ERC_Id] ASC, [Event_Reason_Tree_Data_Id] ASC),
    CONSTRAINT [ERCategoryData_FK_ERCId] FOREIGN KEY ([ERC_Id]) REFERENCES [dbo].[Event_Reason_Catagories] ([ERC_Id]),
    CONSTRAINT [ERCategoryData_FK_EventReasonTreeDataId] FOREIGN KEY ([Event_Reason_Tree_Data_Id]) REFERENCES [dbo].[Event_Reason_Tree_Data] ([Event_Reason_Tree_Data_Id]),
    CONSTRAINT [ERCategoryData_FK_PropegatedFromETDId] FOREIGN KEY ([Propegated_From_ETDId]) REFERENCES [dbo].[Event_Reason_Tree_Data] ([Event_Reason_Tree_Data_Id])
);


GO
CREATE NONCLUSTERED INDEX [EvtRsnCatData_IDX_ERTDId]
    ON [dbo].[Event_Reason_Category_Data]([Event_Reason_Tree_Data_Id] ASC);

