CREATE TABLE [dbo].[Timed_Event_Fault_History] (
    [Timed_Event_Fault_History_Id] BIGINT        IDENTITY (1, 1) NOT NULL,
    [TEFault_Name]                 VARCHAR (100) NULL,
    [TEFault_Value]                VARCHAR (25)  NULL,
    [Event_Reason_Tree_Data_Id]    INT           NULL,
    [PU_Id]                        INT           NULL,
    [Reason_Level1]                INT           NULL,
    [Reason_Level2]                INT           NULL,
    [Reason_Level3]                INT           NULL,
    [Reason_Level4]                INT           NULL,
    [Source_PU_Id]                 INT           NULL,
    [TEFault_Id]                   INT           NULL,
    [Modified_On]                  DATETIME      NULL,
    [DBTT_Id]                      TINYINT       NULL,
    [Column_Updated_BitMask]       VARCHAR (15)  NULL,
    CONSTRAINT [Timed_Event_Fault_History_PK_Id] PRIMARY KEY NONCLUSTERED ([Timed_Event_Fault_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [TimedEventFaultHistory_IX_TEFaultIdModifiedOn]
    ON [dbo].[Timed_Event_Fault_History]([TEFault_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[Timed_Event_Fault_History_UpdDel]
 ON  [dbo].[Timed_Event_Fault_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
