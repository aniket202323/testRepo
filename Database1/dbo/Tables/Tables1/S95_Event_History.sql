CREATE TABLE [dbo].[S95_Event_History] (
    [S95_Event_History_Id]   BIGINT       IDENTITY (1, 1) NOT NULL,
    [Event_Type]             INT          NULL,
    [Char_Id]                INT          NULL,
    [Event_Id]               INT          NULL,
    [Modified_On]            DATETIME     NULL,
    [DBTT_Id]                TINYINT      NULL,
    [Column_Updated_BitMask] VARCHAR (15) NULL,
    CONSTRAINT [S95_Event_History_PK_Id] PRIMARY KEY NONCLUSTERED ([S95_Event_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [S95EventHistory_IX_EventIdModifiedOn]
    ON [dbo].[S95_Event_History]([Event_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[S95_Event_History_UpdDel]
 ON  [dbo].[S95_Event_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
