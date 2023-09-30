CREATE TABLE [dbo].[CXS_Service] (
    [Service_Id]                 SMALLINT                   IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [ApplicationName]            VARCHAR (100)              NULL,
    [Auto_Start]                 TINYINT                    NULL,
    [Auto_Stop]                  TINYINT                    NULL,
    [Domain]                     VARCHAR (100)              NULL,
    [Is_Active]                  BIT                        CONSTRAINT [CXS_Service_DF_IsActive] DEFAULT ((1)) NOT NULL,
    [Listener_Address]           [dbo].[Varchar_IP_Address] NULL,
    [Listener_Port]              [dbo].[Int_TCP_Port]       NULL,
    [Monitor_Interval]           INT                        NULL,
    [Monitor_Service]            TINYINT                    NULL,
    [Node_Name]                  VARCHAR (50)               NULL,
    [Non_Responding_Kill_Script] VARCHAR (255)              NULL,
    [NTService_Name]             VARCHAR (50)               NULL,
    [Proficy_Service_Name]       VARCHAR (50)               NULL,
    [Reload_Flag]                INT                        NULL,
    [Restart_Non_Responding]     INT                        NULL,
    [Restart_Wait_Time]          INT                        NULL,
    [Service_Desc]               VARCHAR (100)              NULL,
    [Service_Display]            VARCHAR (100)              NULL,
    [Should_Reload_Timestamp]    DATETIME                   NULL,
    [Start_Check_Time]           INT                        NULL,
    [Start_Order]                INT                        NULL,
    [Stop_Check_Time]            INT                        NULL,
    [Time_Stamp]                 DATETIME                   NULL,
    CONSTRAINT [CXS_Service_PK_ServiceId] PRIMARY KEY CLUSTERED ([Service_Id] ASC),
    CONSTRAINT [CXSService_UC_ServiceDescNodeName] UNIQUE NONCLUSTERED ([Service_Desc] ASC, [Node_Name] ASC)
);


GO
Create  TRIGGER dbo.CXS_Reload_Upd
 	 ON dbo.Cxs_Service
 	 FOR  UPDATE
 	 AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare @ReloadFlag Int
Declare @ReloadTime DateTime
If (Select count(*) From INSERTED  	 Where Service_Id = 4 and Reload_Flag is not null) = 1
BEGIN
 	 Select @ReloadFlag = Reload_Flag, @ReloadTime = Time_Stamp From INSERTED Where Service_Id = 4 and Reload_Flag is not null
 	 Update Cxs_service Set Reload_Flag = @ReloadFlag,Time_Stamp = @ReloadTime Where Service_Id = 2
END
