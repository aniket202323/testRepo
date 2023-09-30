CREATE TABLE [dbo].[Container_Location_History] (
    [Container_Location_History_Id] BIGINT       IDENTITY (1, 1) NOT NULL,
    [Comment_Id]                    INT          NULL,
    [Container_Id]                  INT          NULL,
    [Container_Status_Id]           INT          NULL,
    [Entry_On]                      DATETIME     NULL,
    [PU_Id]                         INT          NULL,
    [Timestamp]                     DATETIME     NULL,
    [User_Id]                       INT          NULL,
    [Modified_On]                   DATETIME     NULL,
    [DBTT_Id]                       TINYINT      NULL,
    [Column_Updated_BitMask]        VARCHAR (15) NULL,
    [ContLoc_Id]                    INT          NULL,
    [Location_id]                   INT          NULL,
    CONSTRAINT [Container_Location_History_PK_Id] PRIMARY KEY NONCLUSTERED ([Container_Location_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [ContainerLocationHistory_IX_ContainerIdPUIdModifiedOn]
    ON [dbo].[Container_Location_History]([Container_Id] ASC, [PU_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[Container_Location_History_UpdDel]
 ON  [dbo].[Container_Location_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
