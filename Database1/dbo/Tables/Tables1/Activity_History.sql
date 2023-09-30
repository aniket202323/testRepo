CREATE TABLE [dbo].[Activity_History] (
    [Activity_History_Id]           BIGINT         IDENTITY (1, 1) NOT NULL,
    [Activity_Desc]                 VARCHAR (1000) NULL,
    [Activity_Priority]             INT            NULL,
    [Activity_Status]               INT            NULL,
    [EntryOn]                       DATETIME       NULL,
    [Target_Duration]               INT            NULL,
    [Activity_Type_Id]              INT            NULL,
    [Auto_Complete]                 INT            NULL,
    [Comment_Id]                    INT            NULL,
    [End_Time]                      DATETIME       NULL,
    [Execution_Start_Time]          DATETIME       NULL,
    [Extended_Info]                 VARCHAR (255)  NULL,
    [External_Link]                 VARCHAR (255)  NULL,
    [KeyId]                         DATETIME       NULL,
    [KeyId1]                        INT            NULL,
    [Locked]                        TINYINT        NULL,
    [Overdue_Comment_Id]            INT            NULL,
    [PercentComplete]               FLOAT (53)     NULL,
    [PU_Id]                         INT            NULL,
    [Skip_Comment_Id]               INT            NULL,
    [Start_Time]                    DATETIME       NULL,
    [Tag]                           VARCHAR (7000) NULL,
    [Tests_To_Complete]             INT            NULL,
    [Title]                         VARCHAR (255)  NULL,
    [UserId]                        INT            NULL,
    [Activity_Id]                   BIGINT         NULL,
    [Modified_On]                   DATETIME       NULL,
    [DBTT_Id]                       TINYINT        NULL,
    [Sheet_Id]                      INT            NULL,
    [Column_Updated_BitMask]        VARCHAR (15)   NULL,
    [Lock_Activity_Security]        TINYINT        NULL,
    [Overdue_Comment_Security]      TINYINT        NULL,
    [System_Complete_Duration_time] DATETIME       NULL,
    [Complete_Type]                 TINYINT        NULL,
    [Display_Activity_Type_Id]      INT            NULL,
    [ActivityDetail_Comment_Id]     INT            NULL,
    [HasAvailableCells]             BIT            NULL,
    CONSTRAINT [Activity_History_PK_Id] PRIMARY KEY NONCLUSTERED ([Activity_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [ActivityHistory_IX_ActivityIdModifiedOn]
    ON [dbo].[Activity_History]([Activity_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[Activity_History_UpdDel]
 ON  [dbo].[Activity_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) --DataPurge
BEGIN
 	 DELETE Activity_History
 	 FROM Activity_History a 
 	 JOIN  Deleted b on b.Activity_Id = a.Activity_Id
END
