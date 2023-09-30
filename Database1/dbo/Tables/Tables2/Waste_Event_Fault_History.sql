CREATE TABLE [dbo].[Waste_Event_Fault_History] (
    [Waste_Event_Fault_History_Id] BIGINT        IDENTITY (1, 1) NOT NULL,
    [WEFault_Name]                 VARCHAR (100) NULL,
    [WEFault_Value]                VARCHAR (25)  NULL,
    [Event_Reason_Tree_Data_Id]    INT           NULL,
    [PU_Id]                        INT           NULL,
    [Reason_Level1]                INT           NULL,
    [Reason_Level2]                INT           NULL,
    [Reason_Level3]                INT           NULL,
    [Reason_Level4]                INT           NULL,
    [Source_PU_Id]                 INT           NULL,
    [WEFault_Id]                   INT           NULL,
    [Modified_On]                  DATETIME      NULL,
    [DBTT_Id]                      TINYINT       NULL,
    [Column_Updated_BitMask]       VARCHAR (15)  NULL,
    CONSTRAINT [Waste_Event_Fault_History_PK_Id] PRIMARY KEY NONCLUSTERED ([Waste_Event_Fault_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [WasteEventFaultHistory_IX_WEFaultIdModifiedOn]
    ON [dbo].[Waste_Event_Fault_History]([WEFault_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[Waste_Event_Fault_History_UpdDel]
 ON  [dbo].[Waste_Event_Fault_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
