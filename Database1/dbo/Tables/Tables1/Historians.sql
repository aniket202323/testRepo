CREATE TABLE [dbo].[Historians] (
    [Hist_Id]         INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Alias]           VARCHAR (50)  NOT NULL,
    [Hist_Default]    BIT           CONSTRAINT [DF_Historians_Hist_Default] DEFAULT ((0)) NOT NULL,
    [Hist_OS_Id]      INT           NOT NULL,
    [Hist_Password]   VARCHAR (255) NULL,
    [Hist_Servername] VARCHAR (255) NULL,
    [Hist_Type_Id]    INT           NOT NULL,
    [Hist_Username]   VARCHAR (255) NULL,
    [Is_Active]       BIT           CONSTRAINT [Historians_DF_IsActive] DEFAULT ((1)) NOT NULL,
    [Is_Remote]       BIT           CONSTRAINT [Historians_DF_IsRemote] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [Historians_PK_HistId] PRIMARY KEY NONCLUSTERED ([Hist_Id] ASC),
    CONSTRAINT [Historians_FK_Hist_OS_Id] FOREIGN KEY ([Hist_OS_Id]) REFERENCES [dbo].[Operating_Systems] ([OS_Id]),
    CONSTRAINT [Historians_FK_Hist_Type_Id] FOREIGN KEY ([Hist_Type_Id]) REFERENCES [dbo].[Historian_Types] ([Hist_Type_Id]),
    CONSTRAINT [Historians_UC_Alias] UNIQUE NONCLUSTERED ([Alias] ASC)
);


GO
Create  TRIGGER dbo.Historians_Reload_InsUpdDel
 	 ON dbo.Historians
 	 FOR INSERT, UPDATE, DELETE
 	 AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 	 Declare @ShouldReload Int
 	 Select @ShouldReload = sp.Value 
 	  	 From Parameters p
 	  	 Join Site_Parameters sp on p.Parm_Id = sp.Parm_Id
 	  	 Where Parm_Name = 'Perform automatic service reloads'
 	 If @ShouldReload is null or @ShouldReload = 0 
 	  	 Return
/*
2  -Database Mgr
4  -Event Mgr
5  -Reader
6  -Writer
7  -Summary Mgr
8  -Stubber
9  -Message Bus
14 -Gateway
16 -Email Engine
17 -Alarm Manager
18 -FTP Engine
19 -Calculation Manager
20 -Print Server
22 -Schedule Mgr
*/
Update cxs_service set Should_Reload_Timestamp = DateAdd(minute,5,dbo.fnServer_CmnGetDate(getUTCdate())) where Service_Id in (4,5,6,7)
