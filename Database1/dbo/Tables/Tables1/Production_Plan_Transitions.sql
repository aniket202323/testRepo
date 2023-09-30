CREATE TABLE [dbo].[Production_Plan_Transitions] (
    [PPT_Id]      INT      IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [End_Time]    DATETIME NULL,
    [PP_Id]       INT      NOT NULL,
    [PPStatus_Id] INT      NOT NULL,
    [Start_Time]  DATETIME NOT NULL,
    CONSTRAINT [PK_Production_Plan_Transitions] PRIMARY KEY NONCLUSTERED ([PPT_Id] ASC),
    CONSTRAINT [ProductionPlanTransitions_FKC_ProductionPlan] FOREIGN KEY ([PP_Id]) REFERENCES [dbo].[Production_Plan] ([PP_Id]) ON DELETE CASCADE,
    CONSTRAINT [ProductionPlanTransitions_FKC_ProductionPlanStatus] FOREIGN KEY ([PPStatus_Id]) REFERENCES [dbo].[Production_Plan_Statuses] ([PP_Status_Id]) ON DELETE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [ProductionPlanTransitions_IDX_PPIdEndTime]
    ON [dbo].[Production_Plan_Transitions]([PP_Id] ASC, [End_Time] ASC);

