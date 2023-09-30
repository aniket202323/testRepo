CREATE TABLE [dbo].[Event_Configuration_History] (
    [Event_Configuration_History_Id] BIGINT        IDENTITY (1, 1) NOT NULL,
    [PU_Id]                          INT           NULL,
    [Is_Active]                      TINYINT       NULL,
    [Comment_Id]                     INT           NULL,
    [EC_Desc]                        VARCHAR (50)  NULL,
    [ED_Model_Id]                    INT           NULL,
    [ESignature_Level]               INT           NULL,
    [ET_Id]                          TINYINT       NULL,
    [Event_Subtype_Id]               INT           NULL,
    [Exclusions]                     VARCHAR (255) NULL,
    [Extended_Info]                  VARCHAR (255) NULL,
    [External_Time_Zone]             VARCHAR (100) NULL,
    [Is_Calculation_Active]          TINYINT       NULL,
    [Max_Run_Time]                   INT           NULL,
    [Model_Group]                    INT           NULL,
    [PEI_Id]                         INT           NULL,
    [Priority]                       INT           NULL,
    [Retention_Limit]                INT           NULL,
    [Debug]                          BIT           NULL,
    [EC_Id]                          INT           NULL,
    [Modified_On]                    DATETIME      NULL,
    [DBTT_Id]                        TINYINT       NULL,
    [Column_Updated_BitMask]         VARCHAR (15)  NULL,
    [Move_EndTime_Interval]          INT           NULL,
    CONSTRAINT [Event_Configuration_History_PK_Id] PRIMARY KEY NONCLUSTERED ([Event_Configuration_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [EventConfigurationHistory_IX_ECIdModifiedOn]
    ON [dbo].[Event_Configuration_History]([EC_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[Event_Configuration_History_UpdDel]
 ON  [dbo].[Event_Configuration_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
