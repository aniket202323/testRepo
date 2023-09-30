CREATE TABLE [dbo].[Test_History] (
    [Test_History_Id]        BIGINT                IDENTITY (1, 1) NOT NULL,
    [Entry_On]               DATETIME              NULL,
    [Result_On]              DATETIME              NULL,
    [Var_Id]                 INT                   NULL,
    [Canceled]               BIT                   NULL,
    [Array_Id]               INT                   NULL,
    [Comment_Id]             INT                   NULL,
    [Entry_By]               INT                   NULL,
    [Event_Id]               INT                   NULL,
    [Locked]                 TINYINT               NULL,
    [Result]                 [dbo].[Varchar_Value] NULL,
    [Second_User_Id]         INT                   NULL,
    [Signature_Id]           INT                   NULL,
    [Test_Id]                BIGINT                NULL,
    [Modified_On]            DATETIME              NULL,
    [DBTT_Id]                TINYINT               NULL,
    [Column_Updated_BitMask] VARCHAR (15)          NULL,
    [IsVarMandatory]         BIT                   NULL,
    CONSTRAINT [Test_History_PK_Id] PRIMARY KEY NONCLUSTERED ([Test_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [TestHistory_IX_TestIdModifiedOn]
    ON [dbo].[Test_History]([Test_Id] ASC, [Modified_On] ASC);


GO
CREATE NONCLUSTERED INDEX [TestHistory_IX_VarIdResultOn]
    ON [dbo].[Test_History]([Var_Id] ASC, [Result_On] ASC);


GO
CREATE TRIGGER [dbo].[Test_History_UpdDel]
 ON  [dbo].[Test_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) --DataPurge
BEGIN
 	 DELETE Test_History
 	 FROM Test_History a 
 	 JOIN  Deleted b on b.Test_Id = a.Test_Id
END
