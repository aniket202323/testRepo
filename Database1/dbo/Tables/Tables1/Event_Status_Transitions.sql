CREATE TABLE [dbo].[Event_Status_Transitions] (
    [EST_Id]       INT      IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [End_Time]     DATETIME NULL,
    [Event_Id]     INT      NOT NULL,
    [Event_Status] INT      NOT NULL,
    [PU_Id]        INT      NOT NULL,
    [Start_Time]   DATETIME NOT NULL,
    CONSTRAINT [PK_Event_Status_Transitions] PRIMARY KEY NONCLUSTERED ([EST_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [Event_StatTrans_By_Status]
    ON [dbo].[Event_Status_Transitions]([Event_Id] ASC, [Start_Time] ASC, [Event_Status] ASC);


GO
CREATE NONCLUSTERED INDEX [Event_StatTrans_By_StatusStartEndPUEvent]
    ON [dbo].[Event_Status_Transitions]([Event_Status] ASC, [Start_Time] ASC, [End_Time] ASC, [PU_Id] ASC, [Event_Id] ASC);

