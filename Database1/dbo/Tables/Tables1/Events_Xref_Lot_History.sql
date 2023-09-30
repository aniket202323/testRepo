CREATE TABLE [dbo].[Events_Xref_Lot_History] (
    [Events_Xref_Lot_History_Id] BIGINT       IDENTITY (1, 1) NOT NULL,
    [EventId]                    INT          NULL,
    [XRefId]                     BIGINT       NULL,
    [Modified_On]                DATETIME     NULL,
    [DBTT_Id]                    TINYINT      NULL,
    [Column_Updated_BitMask]     VARCHAR (15) NULL,
    CONSTRAINT [Events_Xref_Lot_History_PK_Id] PRIMARY KEY NONCLUSTERED ([Events_Xref_Lot_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [EventsXrefLotHistory_IX_XRefIdModifiedOn]
    ON [dbo].[Events_Xref_Lot_History]([XRefId] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[Events_Xref_Lot_History_UpdDel]
 ON  [dbo].[Events_Xref_Lot_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) --DataPurge
BEGIN
 	 DELETE Events_Xref_Lot_History
 	 FROM Events_Xref_Lot_History a 
 	 JOIN  Deleted b on b.EventId = a.EventId
END
