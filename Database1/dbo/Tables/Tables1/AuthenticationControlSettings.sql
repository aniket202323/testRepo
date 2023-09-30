CREATE TABLE [dbo].[AuthenticationControlSettings] (
    [SettingName]        NVARCHAR (255) NOT NULL,
    [SettingValue]       NVARCHAR (255) NULL,
    [SettingDescription] NVARCHAR (255) NULL,
    [Version]            BIGINT         NULL,
    PRIMARY KEY CLUSTERED ([SettingName] ASC)
);

