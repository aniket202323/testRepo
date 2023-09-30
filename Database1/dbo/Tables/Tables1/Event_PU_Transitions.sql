CREATE TABLE [dbo].[Event_PU_Transitions] (
    [EPT_Id]      BIGINT   IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [End_Time]    DATETIME NULL,
    [Event_Id]    INT      NOT NULL,
    [PU_Id]       INT      NOT NULL,
    [Start_Time]  DATETIME NOT NULL,
    [Modified_on] DATETIME NOT NULL,
    CONSTRAINT [PK_EventPUTransitions] PRIMARY KEY NONCLUSTERED ([EPT_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [EventPUTrans_IDX_EventIdEndTime]
    ON [dbo].[Event_PU_Transitions]([Event_Id] ASC, [End_Time] ASC);


GO
CREATE NONCLUSTERED INDEX [EventPUTrans_IDX_EventIdModifiedon]
    ON [dbo].[Event_PU_Transitions]([Event_Id] ASC, [Modified_on] ASC);


GO
CREATE NONCLUSTERED INDEX [EventPUTrans_IDX_PuIdEndTime]
    ON [dbo].[Event_PU_Transitions]([PU_Id] ASC, [End_Time] ASC);

