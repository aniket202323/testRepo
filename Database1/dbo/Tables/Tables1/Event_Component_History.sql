CREATE TABLE [dbo].[Event_Component_History] (
    [Event_Component_History_Id] BIGINT        IDENTITY (1, 1) NOT NULL,
    [Event_Id]                   INT           NULL,
    [Source_Event_Id]            INT           NULL,
    [Dimension_A]                FLOAT (53)    NULL,
    [Dimension_X]                FLOAT (53)    NULL,
    [Dimension_Y]                FLOAT (53)    NULL,
    [Dimension_Z]                FLOAT (53)    NULL,
    [Entry_On]                   DATETIME      NULL,
    [Extended_Info]              VARCHAR (255) NULL,
    [Parent_Component_Id]        INT           NULL,
    [PEI_Id]                     INT           NULL,
    [Signature_Id]               INT           NULL,
    [Start_Coordinate_A]         FLOAT (53)    NULL,
    [Start_Coordinate_X]         FLOAT (53)    NULL,
    [Start_Coordinate_Y]         FLOAT (53)    NULL,
    [Start_Coordinate_Z]         FLOAT (53)    NULL,
    [Start_Time]                 DATETIME      NULL,
    [Timestamp]                  DATETIME      NULL,
    [user_id]                    INT           NULL,
    [Report_As_Consumption]      BIT           NULL,
    [Component_Id]               INT           NULL,
    [Modified_On]                DATETIME      NULL,
    [DBTT_Id]                    TINYINT       NULL,
    [Column_Updated_BitMask]     VARCHAR (15)  NULL,
    CONSTRAINT [Event_Component_History_PK_Id] PRIMARY KEY NONCLUSTERED ([Event_Component_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [EventComponentHistory_IX_ComponentIdModifiedOn]
    ON [dbo].[Event_Component_History]([Component_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[Event_Component_History_UpdDel]
 ON  [dbo].[Event_Component_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) --DataPurge
BEGIN
 	 DELETE Event_Component_History
 	 FROM Event_Component_History a 
 	 JOIN  Deleted b on b.Component_Id = a.Component_Id
END
