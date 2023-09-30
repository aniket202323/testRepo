CREATE TABLE [dbo].[Event_Container_Data_History] (
    [Event_Container_Data_History_Id] BIGINT       IDENTITY (1, 1) NOT NULL,
    [Container_Id]                    INT          NULL,
    [Event_Id]                        INT          NULL,
    [Timestamp]                       DATETIME     NULL,
    [Dimension_A]                     FLOAT (53)   NULL,
    [Dimension_X]                     FLOAT (53)   NULL,
    [Dimension_Y]                     FLOAT (53)   NULL,
    [Dimension_Z]                     FLOAT (53)   NULL,
    [Entry_On]                        DATETIME     NULL,
    [Final_Dimension_A]               FLOAT (53)   NULL,
    [Final_Dimension_X]               FLOAT (53)   NULL,
    [Final_Dimension_Y]               FLOAT (53)   NULL,
    [Final_Dimension_Z]               FLOAT (53)   NULL,
    [Orientation_A]                   FLOAT (53)   NULL,
    [Orientation_X]                   FLOAT (53)   NULL,
    [Orientation_Y]                   FLOAT (53)   NULL,
    [Orientation_Z]                   FLOAT (53)   NULL,
    [User_Id]                         INT          NULL,
    [ECD_Id]                          INT          NULL,
    [Modified_On]                     DATETIME     NULL,
    [DBTT_Id]                         TINYINT      NULL,
    [Column_Updated_BitMask]          VARCHAR (15) NULL,
    CONSTRAINT [Event_Container_Data_History_PK_Id] PRIMARY KEY NONCLUSTERED ([Event_Container_Data_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [EventContainerDataHistory_IX_ECDIdModifiedOn]
    ON [dbo].[Event_Container_Data_History]([ECD_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[Event_Container_Data_History_UpdDel]
 ON  [dbo].[Event_Container_Data_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
