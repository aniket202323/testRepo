CREATE TABLE [dbo].[Production_Starts_History] (
    [Production_Starts_History_Id] BIGINT       IDENTITY (1, 1) NOT NULL,
    [Prod_Id]                      INT          NULL,
    [PU_Id]                        INT          NULL,
    [Start_Time]                   DATETIME     NULL,
    [Confirmed]                    BIT          NULL,
    [Comment_Id]                   INT          NULL,
    [End_Time]                     DATETIME     NULL,
    [Event_Subtype_Id]             INT          NULL,
    [Second_User_Id]               INT          NULL,
    [Signature_Id]                 INT          NULL,
    [User_Id]                      INT          NULL,
    [Start_Id]                     INT          NULL,
    [Modified_On]                  DATETIME     NULL,
    [DBTT_Id]                      TINYINT      NULL,
    [Column_Updated_BitMask]       VARCHAR (15) NULL,
    CONSTRAINT [Production_Starts_History_PK_Id] PRIMARY KEY NONCLUSTERED ([Production_Starts_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [ProductionStartsHistory_IX_StartIdModifiedOn]
    ON [dbo].[Production_Starts_History]([Start_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[Production_Starts_History_UpdDel]
 ON  [dbo].[Production_Starts_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) --DataPurge
BEGIN
 	 DELETE Production_Starts_History
 	 FROM Production_Starts_History a 
 	 JOIN  Deleted b on b.Start_Id = a.Start_Id
END
