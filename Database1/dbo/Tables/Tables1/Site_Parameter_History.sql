CREATE TABLE [dbo].[Site_Parameter_History] (
    [Site_Parameter_History_Id] BIGINT         IDENTITY (1, 1) NOT NULL,
    [HostName]                  VARCHAR (50)   NULL,
    [Parm_Id]                   INT            NULL,
    [Value]                     VARCHAR (5000) NULL,
    [Parm_Required]             BIT            NULL,
    [Modified_On]               DATETIME       NULL,
    [DBTT_Id]                   TINYINT        NULL,
    [Column_Updated_BitMask]    VARCHAR (15)   NULL,
    CONSTRAINT [Site_Parameter_History_PK_Id] PRIMARY KEY NONCLUSTERED ([Site_Parameter_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [SiteParameterHistory_IX_ParmIdHostNameModifiedOn]
    ON [dbo].[Site_Parameter_History]([Parm_Id] ASC, [HostName] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[Site_Parameter_History_UpdDel]
 ON  [dbo].[Site_Parameter_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
