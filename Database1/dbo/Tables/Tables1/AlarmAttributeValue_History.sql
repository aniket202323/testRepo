CREATE TABLE [dbo].[AlarmAttributeValue_History] (
    [AlarmAttributeValue_History_Id] BIGINT         IDENTITY (1, 1) NOT NULL,
    [Alarm_Id]                       INT            NULL,
    [Attribute_Id]                   INT            NULL,
    [Value]                          VARCHAR (1000) NULL,
    [Alarm_Modified_On]              DATETIME       NULL,
    [Alarm_Modified_On_Ms]           INT            NULL,
    [Modified_On]                    DATETIME       NULL,
    [DBTT_Id]                        TINYINT        NULL,
    [Column_Updated_BitMask]         VARCHAR (15)   NULL,
    CONSTRAINT [AlarmAttributeValue_History_PK_Id] PRIMARY KEY NONCLUSTERED ([AlarmAttributeValue_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [AlarmAttributeValueHistory_IX_AlarmIdAttributeIdModifiedOn]
    ON [dbo].[AlarmAttributeValue_History]([Alarm_Id] ASC, [Attribute_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[AlarmAttributeValue_History_UpdDel]
 ON  [dbo].[AlarmAttributeValue_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
