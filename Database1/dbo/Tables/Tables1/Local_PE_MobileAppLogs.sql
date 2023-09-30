CREATE TABLE [dbo].[Local_PE_MobileAppLogs] (
    [Id]                   INT            IDENTITY (1, 1) NOT NULL,
    [Username]             NVARCHAR (255) NULL,
    [iPadAppVersion]       NVARCHAR (255) NULL,
    [iPadDeviceId]         NVARCHAR (255) NULL,
    [iPadDeviceName]       NVARCHAR (255) NULL,
    [iPadDeviceLocale]     NVARCHAR (255) NULL,
    [iPadSelectedLanguage] NVARCHAR (255) NULL,
    [iPadDefaultPath]      NVARCHAR (255) NULL,
    [IsMobile]             BIT            NULL,
    [OS]                   NVARCHAR (255) NULL,
    [OSVersion]            NVARCHAR (255) NULL,
    [Browser]              NVARCHAR (255) NULL,
    [BrowserVersion]       NVARCHAR (255) NULL,
    [BrowserLanguage]      NVARCHAR (255) NULL,
    [ScreenSize]           NVARCHAR (255) NULL,
    [EnteredOn]            DATETIME       NULL,
    CONSTRAINT [PK_Local_PE_MobileAppLogs] PRIMARY KEY CLUSTERED ([Id] ASC)
);

