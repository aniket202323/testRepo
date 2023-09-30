CREATE TABLE [dbo].[FTP_Config] (
    [FC_Id]          INT                  IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Email_Failure]  VARCHAR (255)        NULL,
    [Email_Success]  VARCHAR (255)        NULL,
    [Email_Warning]  VARCHAR (255)        NULL,
    [FA_Id]          TINYINT              CONSTRAINT [FTP_Config_DF_FAId] DEFAULT ((2)) NOT NULL,
    [FC_Desc]        [dbo].[Varchar_Desc] NOT NULL,
    [FPA_Dest]       VARCHAR (50)         NULL,
    [FPA_Id]         TINYINT              CONSTRAINT [FTP_Config_DF_FPAId] DEFAULT ((1)) NOT NULL,
    [FTP_Engine]     VARCHAR (20)         NOT NULL,
    [FTT_Id]         TINYINT              CONSTRAINT [FTP_Config_DF_FTTId] DEFAULT ((1)) NOT NULL,
    [Host]           VARCHAR (20)         NOT NULL,
    [Interval]       INT                  NOT NULL,
    [Is_Active]      TINYINT              CONSTRAINT [FTP_Config_DF_IsActive] DEFAULT ((1)) NOT NULL,
    [Local_Path]     VARCHAR (255)        NOT NULL,
    [Mask]           VARCHAR (20)         NULL,
    [New_Name]       VARCHAR (25)         NULL,
    [OnError_Rename] TINYINT              NULL,
    [OnError_Stop]   TINYINT              NULL,
    [OS_Id]          INT                  CONSTRAINT [FTP_Config_DF_OSId] DEFAULT ((2)) NULL,
    [Password]       VARCHAR (25)         NULL,
    [Remote_Path]    VARCHAR (255)        NOT NULL,
    [User_Name]      VARCHAR (50)         NOT NULL,
    CONSTRAINT [FTP_Config_PK_FCId] PRIMARY KEY CLUSTERED ([FC_Id] ASC),
    CONSTRAINT [FTP_Config_FK_OSId] FOREIGN KEY ([OS_Id]) REFERENCES [dbo].[Operating_Systems] ([OS_Id])
);


GO
CREATE NONCLUSTERED INDEX [FTP_Config_ByFTPEngine]
    ON [dbo].[FTP_Config]([FTP_Engine] ASC);


GO
CREATE NONCLUSTERED INDEX [FTP_Config_U_FCDesc]
    ON [dbo].[FTP_Config]([FC_Desc] ASC);

