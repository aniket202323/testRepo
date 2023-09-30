CREATE TABLE [dbo].[Event_Detail_History] (
    [Event_Detail_History_Id] BIGINT       IDENTITY (1, 1) NOT NULL,
    [Event_Id]                INT          NULL,
    [Alternate_Event_Num]     VARCHAR (50) NULL,
    [Blocked_In_Location]     TINYINT      NULL,
    [Comment_Id]              INT          NULL,
    [Entered_By]              INT          NULL,
    [Entered_On]              DATETIME     NULL,
    [Final_Dimension_A]       FLOAT (53)   NULL,
    [Final_Dimension_X]       FLOAT (53)   NULL,
    [Final_Dimension_Y]       FLOAT (53)   NULL,
    [Final_Dimension_Z]       FLOAT (53)   NULL,
    [Initial_Dimension_A]     FLOAT (53)   NULL,
    [Initial_Dimension_X]     FLOAT (53)   NULL,
    [Initial_Dimension_Y]     FLOAT (53)   NULL,
    [Initial_Dimension_Z]     FLOAT (53)   NULL,
    [Location_Id]             INT          NULL,
    [Order_Id]                INT          NULL,
    [Order_Line_Id]           INT          NULL,
    [Orientation_A]           FLOAT (53)   NULL,
    [Orientation_X]           FLOAT (53)   NULL,
    [Orientation_Y]           FLOAT (53)   NULL,
    [Orientation_Z]           FLOAT (53)   NULL,
    [PP_Id]                   INT          NULL,
    [PP_Setup_Detail_Id]      INT          NULL,
    [PP_Setup_Id]             INT          NULL,
    [Product_Definition_Id]   INT          NULL,
    [PU_Id]                   INT          NULL,
    [Shipment_Id]             INT          NULL,
    [Shipment_Item_Id]        INT          NULL,
    [Signature_Id]            INT          NULL,
    [Modified_On]             DATETIME     NULL,
    [DBTT_Id]                 TINYINT      NULL,
    [Column_Updated_BitMask]  VARCHAR (15) NULL,
    CONSTRAINT [Event_Detail_History_PK_Id] PRIMARY KEY NONCLUSTERED ([Event_Detail_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [EventDetailHistory_IX_EventIdModifiedOn]
    ON [dbo].[Event_Detail_History]([Event_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[Event_Detail_History_UpdDel]
 ON  [dbo].[Event_Detail_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) --DataPurge
BEGIN
 	 DELETE Event_Detail_History
 	 FROM Event_Detail_History a 
 	 JOIN  Deleted b on b.Event_Id = a.Event_Id
END
