CREATE TABLE [dbo].[Sheet_Column_History] (
    [Sheet_Column_History_Id] BIGINT       IDENTITY (1, 1) NOT NULL,
    [Result_On]               DATETIME     NULL,
    [Sheet_Id]                INT          NULL,
    [Approver_Reason_Id]      INT          NULL,
    [Approver_User_Id]        INT          NULL,
    [Comment_Id]              INT          NULL,
    [Signature_Id]            INT          NULL,
    [User_Reason_Id]          INT          NULL,
    [User_Signoff_Id]         INT          NULL,
    [Modified_On]             DATETIME     NULL,
    [DBTT_Id]                 TINYINT      NULL,
    [Column_Updated_BitMask]  VARCHAR (15) NULL,
    CONSTRAINT [Sheet_Column_History_PK_Id] PRIMARY KEY NONCLUSTERED ([Sheet_Column_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [SheetColumnHistory_IX_SheetIdResultOnModifiedOn]
    ON [dbo].[Sheet_Column_History]([Sheet_Id] ASC, [Result_On] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[Sheet_Column_History_UpdDel]
 ON  [dbo].[Sheet_Column_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) --DataPurge
BEGIN
 	 DELETE Sheet_Column_History
 	 FROM Sheet_Column_History a 
 	 JOIN  Deleted b on b.Sheet_Id = a.Sheet_Id
 	 and b.Result_On = a.Result_On
END
