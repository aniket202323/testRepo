CREATE TABLE [dbo].[Production_Plan_Starts_History] (
    [Production_Plan_Starts_History_Id] BIGINT       IDENTITY (1, 1) NOT NULL,
    [PP_Id]                             INT          NULL,
    [PU_Id]                             INT          NULL,
    [Start_Time]                        DATETIME     NULL,
    [Is_Production]                     BIT          NULL,
    [Comment_Id]                        INT          NULL,
    [End_Time]                          DATETIME     NULL,
    [pp_setup_id]                       INT          NULL,
    [User_Id]                           INT          NULL,
    [PP_Start_Id]                       INT          NULL,
    [Modified_On]                       DATETIME     NULL,
    [DBTT_Id]                           TINYINT      NULL,
    [Column_Updated_BitMask]            VARCHAR (15) NULL,
    CONSTRAINT [Production_Plan_Starts_History_PK_Id] PRIMARY KEY NONCLUSTERED ([Production_Plan_Starts_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [ProductionPlanStartsHistory_IX_PPStartIdStartTimeModifiedOn]
    ON [dbo].[Production_Plan_Starts_History]([PP_Start_Id] ASC, [Start_Time] ASC, [Modified_On] ASC);


GO
CREATE NONCLUSTERED INDEX [ProductionPlanStartsHistory_IX_PPId]
    ON [dbo].[Production_Plan_Starts_History]([PP_Id] ASC);


GO
CREATE TRIGGER [dbo].[Production_Plan_Starts_History_UpdDel]
 ON  [dbo].[Production_Plan_Starts_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
