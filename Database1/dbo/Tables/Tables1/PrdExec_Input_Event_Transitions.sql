CREATE TABLE [dbo].[PrdExec_Input_Event_Transitions] (
    [End_Time]   DATETIME NULL,
    [Event_Id]   INT      NOT NULL,
    [PEI_Id]     INT      NOT NULL,
    [PEIP_Id]    INT      NOT NULL,
    [Start_Time] DATETIME NOT NULL
);


GO
CREATE CLUSTERED INDEX [PrdExec_Input_Event_Transitions_IX_]
    ON [dbo].[PrdExec_Input_Event_Transitions]([PEI_Id] ASC, [PEIP_Id] ASC, [Start_Time] ASC);


GO
CREATE NONCLUSTERED INDEX [PrdExecInputEventTransitions_IX_EventId]
    ON [dbo].[PrdExec_Input_Event_Transitions]([Event_Id] ASC);

