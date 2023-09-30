CREATE TABLE [dbo].[Crew_Schedule_History] (
    [Crew_Schedule_History_Id] BIGINT       IDENTITY (1, 1) NOT NULL,
    [Crew_Desc]                VARCHAR (10) NULL,
    [End_Time]                 DATETIME     NULL,
    [PU_Id]                    INT          NULL,
    [Shift_Desc]               VARCHAR (10) NULL,
    [Start_Time]               DATETIME     NULL,
    [Comment_Id]               INT          NULL,
    [User_Id]                  INT          NULL,
    [CS_Id]                    INT          NULL,
    [Modified_On]              DATETIME     NULL,
    [DBTT_Id]                  TINYINT      NULL,
    [Column_Updated_BitMask]   VARCHAR (15) NULL,
    CONSTRAINT [Crew_Schedule_History_PK_Id] PRIMARY KEY NONCLUSTERED ([Crew_Schedule_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [CrewScheduleHistory_IX_CSIdModifiedOn]
    ON [dbo].[Crew_Schedule_History]([CS_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[Crew_Schedule_History_UpdDel]
 ON  [dbo].[Crew_Schedule_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
