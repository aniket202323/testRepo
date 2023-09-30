CREATE TABLE [dbo].[Event_Container_Transitions] (
    [ECT_Id]       INT      IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Container_Id] INT      NOT NULL,
    [End_Time]     DATETIME NULL,
    [Event_Id]     INT      NOT NULL,
    [Start_Time]   DATETIME NOT NULL,
    CONSTRAINT [EventContTrans_PK_CLST_Id] PRIMARY KEY NONCLUSTERED ([ECT_Id] ASC),
    CONSTRAINT [EventContTrans_FK_ContainerId] FOREIGN KEY ([Container_Id]) REFERENCES [dbo].[Containers] ([Container_Id])
);


GO
CREATE NONCLUSTERED INDEX [NC_Event_Container_Transitions_ks1]
    ON [dbo].[Event_Container_Transitions]([Container_Id] ASC, [Start_Time] ASC) WITH (FILLFACTOR = 100);


GO
CREATE NONCLUSTERED INDEX [NC_Event_Container_Transitions_ks2]
    ON [dbo].[Event_Container_Transitions]([Container_Id] ASC, [End_Time] ASC) WITH (FILLFACTOR = 100);


GO
CREATE NONCLUSTERED INDEX [NC_Event_Container_Transitions_ks3]
    ON [dbo].[Event_Container_Transitions]([Container_Id] ASC, [Event_Id] ASC) WITH (FILLFACTOR = 100);

