CREATE TABLE [dbo].[Event_Configuration_Data_History] (
    [Event_Configuration_Data_History_Id] BIGINT       IDENTITY (1, 1) NOT NULL,
    [EC_Id]                               INT          NULL,
    [ECV_Id]                              INT          NULL,
    [ED_Field_Id]                         INT          NULL,
    [Input_Precision]                     TINYINT      NULL,
    [Alias]                               VARCHAR (50) NULL,
    [ED_Attribute_Id]                     INT          NULL,
    [IsTrigger]                           TINYINT      NULL,
    [PEI_Id]                              INT          NULL,
    [PU_Id]                               INT          NULL,
    [Sampling_Offset]                     INT          NULL,
    [ST_Id]                               TINYINT      NULL,
    [Modified_On]                         DATETIME     NULL,
    [DBTT_Id]                             TINYINT      NULL,
    [Column_Updated_BitMask]              VARCHAR (15) NULL,
    CONSTRAINT [Event_Configuration_Data_History_PK_Id] PRIMARY KEY NONCLUSTERED ([Event_Configuration_Data_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [EventConfigurationDataHistory_IX_ECIdEDFieldIdModifiedOn]
    ON [dbo].[Event_Configuration_Data_History]([EC_Id] ASC, [ED_Field_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[Event_Configuration_Data_History_UpdDel]
 ON  [dbo].[Event_Configuration_Data_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
